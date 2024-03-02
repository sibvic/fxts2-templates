local PositionsCount = 1;

dofile(core.app_path() .. "\\strategies\\custom\\snippets\\logger.lua")

local INDICATOR_VERSION = "1";
-- END OF CUSTOMIZATION SECTION

local Modules = {};
local EntryActions = {};
local ExitActions = {};

-- START OF USER DEFINED SECTION
local lines_top = {};
local lines_bottom = {};
local executed_up = {};
local executed_down = {};

function CreateCustomActions()
    local action1, isEntry1 = CreateAction(1);
    action1.IsPass = function (source, period) 
        return false; -- TODO: Add condition
    end
    action1.ActOnSwitch = true;
    action1.Name = "Action 1";
    if isEntry1 then
        EntryActions[#EntryActions + 1] = action1;
    else
        ExitActions[#ExitActions + 1] = action1;
    end
    local action2, isEntry2 = CreateAction(2);
    action2.IsPass = function (source, period) 
        return false; -- TODO: Add condition
    end
    action2.ActOnSwitch = true;
    action2.Name = "Action 2";
    if isEntry2 then
        EntryActions[#EntryActions + 1] = action2;
    else
        ExitActions[#ExitActions + 1] = action2;
    end
    -- TODO: Add more actions if required
end

function Init()
    --TODO: indicator parameters here
    -- TODO: Add more actions if required
    -- AddAction(1, "Condition 1");
    -- AddAction(2, "Condition 2");

    trading:Init(indicator.parameters, PositionsCount);
    indicator.parameters:addGroup("Alerts");
    signaler:Init(indicator.parameters);
    indicator.parameters:addBoolean("add_log", "Add log info to signals", "", false);
    indicator.parameters:addFile("log_file", "Log file (csv)", "You can open it in Excel", core.app_path() .. "\\log\\trading_indicator_adaptive.csv");
end

function CreateAction(id)
    local actionType = instance.parameters:getString("Action" .. id);
    local action = {};
    if actionType == "NO" then
        action.Execute = DisabledAction;
    elseif actionType == "SELL" then
        action.Execute = GoShort;
    elseif actionType == "BUY" then
        action.Execute = GoLong;
    elseif actionType == "CLOSE" then
        action.Execute = CloseAll;
    end

    return action, actionType ~= "CLOSE";
end

local buy_positions = {};
local sell_positions = {};
local last_serial;
local add_log;

function Prepare(nameOnly)
    for _, module in pairs(Modules) do module:Prepare(nameOnly); end
    --TODO: insert indicator parameters hading

    if (nameOnly) then
        return
    end
    add_log = instance.parameters.add_log;
    CreateCustomActions();

    --TODO: insert streams creation
    if PositionsCount == 1 then
        buy_positions[#buy_positions + 1] = CreatePositionStrategy(source, "B", "");
        sell_positions[#sell_positions + 1] = CreatePositionStrategy(source, "S", "");
    else
        for i = 1, PositionsCount do
            if instance.parameters:getBoolean("use_position_" .. i) then
                buy_positions[#buy_positions + 1] = CreatePositionStrategy(source, "B", "_" .. i);
                sell_positions[#sell_positions + 1] = CreatePositionStrategy(source, "S", "_" .. i);
            end
        end
    end
    if add_log then
        logger:Start(instance.parameters.log_file);
        logger:AddHeader("bar_date");
        logger:AddHeader("action");
        logger:FlushHeaders();
    end
end

function CreatePositionStrategy(source, side, id)
    local position_strategy = {};
    position_strategy.StopType = instance.parameters:getString("stop_type" .. id);
    position_strategy.LimitType = instance.parameters:getString("limit_type" .. id);
    assert(position_strategy.LimitType ~= "stop" or position_strategy.StopType == "pips", "To use limit based on stop you need to set stop in pips");

    position_strategy.Side = side;
    position_strategy.Source = source;
    position_strategy.Amount = instance.parameters:getInteger("amount" .. id);
    position_strategy.Stop = instance.parameters:getDouble("stop" .. id);
    if position_strategy.StopType == "atr" then
        position_strategy.StopATR = core.indicators:create("ATR", source, position_strategy.Stop);
    end
    if instance.parameters:getBoolean("use_trailing" .. id) then
        position_strategy.Trailing = instance.parameters:getInteger("trailing" .. id);
    end
    position_strategy.Limit = instance.parameters:getDouble("limit" .. id);
    if position_strategy.LimitType == "atr" then
        position_strategy.LimitATR = core.indicators:create("ATR", source, position_strategy.Limit);
    end
    position_strategy.AtrStopMult = instance.parameters:getDouble("atr_stop_mult" .. id);
    position_strategy.AtrLimitMult = instance.parameters:getDouble("atr_limit_mult" .. id);
    position_strategy.TrailingLimitType = instance.parameters:getString("TRAILING_LIMIT_TYPE" .. id);
    position_strategy.TrailingLimitTrigger = instance.parameters:getDouble("TRAILING_LIMIT_TRIGGER" .. id);
    position_strategy.TrailingLimitStep = instance.parameters:getDouble("TRAILING_LIMIT_STEP" .. id);

    position_strategy.UseBreakeven = instance.parameters:getBoolean("use_breakeven" .. id);
    position_strategy.BreakevenWhen = instance.parameters:getDouble("breakeven_when" .. id);
    position_strategy.BreakevenTo = instance.parameters:getDouble("breakeven_to" .. id);
    position_strategy.BreakevenTrailing = instance.parameters:getString("breakeven_trailing");
    position_strategy.BreakevenTrailingValue = instance.parameters:getInteger("trailing" .. id);
    if instance.parameters:getBoolean("breakeven_close" .. id) then
        position_strategy.BreakevenCloseAmount = instance.parameters:getDouble("breakeven_close_amount" .. id);
    end
    if position_strategy.UseBreakeven and tick_source == nil then
        tick_source = ExtSubscribe(TICKS_SOURCE_ID, position_strategy.Source:instrument(), "t1", true, "tick");
    end

    function position_strategy:Open(period)
        local command = trading:MarketOrder(position_strategy.Source:instrument())
            :SetSide(self.Side)
            :SetAccountID(instance.parameters.account)
            :SetAmount(self.Amount)
            :SetCustomID(custom_id);
        local stop_value;
        if self.StopType == "pips" then
            stop_value = self.Stop;
            command = command:SetPipStop(nil, self.Stop, self.Trailing);
        end
        if self.LimitType == "pips" then
            command = command:SetPipLimit(nil, self.Limit);
        elseif self.LimitType == "stop" then
            command = command:SetPipLimit(nil, stop_value * self.Limit);
        end
        local result = command:Execute();
        if self.StopType == "atr" then
            self.StopATR:update(core.UpdateLast);
            breakeven:CreateIndicatorTrailingController()
                :SetRequestID(result.RequestID)
                :SetTrailingTarget(breakeven.STOP_ID)
                :SetIndicatorStream(self.StopATR.DATA, self.AtrStopMult, true);
        end
        if self.LimitType == "atr" then
            self.LimitATR:update(core.UpdateLast);
            breakeven:CreateIndicatorTrailingController()
                :SetRequestID(result.RequestID)
                :SetTrailingTarget(breakeven.LIMIT_ID)
                :SetIndicatorStream(self.LimitATR.DATA, self.AtrLimitMult, true);
        end
        if self.UseBreakeven then
            local controller = breakeven:CreateController()
                :SetRequestID(result.RequestID)
                :SetWhen(self.BreakevenWhen)
                :SetTo(self.BreakevenTo);
            if self.BreakevenTrailing == "set" then
                controller:SetTrailing(self.BreakevenTrailingValue);
            end
            if self.BreakevenCloseAmount ~= nil then
                controller:SetPartialClose(self.BreakevenCloseAmount);
            end
        end
        self:CreateTrailingLimit(result);
    end
    function position_strategy:CreateTrailingLimit(result)
        if self.TrailingLimitType == "Unfavorable" then
            breakeven:CreateTrailingLimitController()
                :SetDirection(-1)
                :SetTrigger(self.TrailingLimitTrigger)
                :SetStep(self.TrailingLimitStep)
                :SetRequestID(result.RequestID);
        elseif self.TrailingLimitType == "Favorable" then
            breakeven:CreateTrailingLimitController()
                :SetDirection(1)
                :SetTrigger(self.TrailingLimitTrigger)
                :SetStep(self.TrailingLimitStep)
                :SetRequestID(result.RequestID);
        end
    end
    return position_strategy;
end

function DoCloseOnOpposite(side)
    if instance.parameters.close_on_opposite then
        local it = trading:FindTrade():WhenSide(trading:getOppositeSide(side))
        if UseOwnPositionsOnly then
            it:WhenCustomID(custom_id);
        end
        it:Do(function (trade) trading:Close(trade); end);
    end
end

function DisabledAction(source, period) return false; end

function CloseAll(source, period)
    local closedCount = 0;
    if instance.parameters.allow_trade then
        local it = trading:FindTrade();
        if UseOwnPositionsOnly then
            it:WhenCustomID(custom_id);
        end
        closedCount = it:Do(function (trade) trading:Close(trade); end);
    end
    if closedCount > 0 then
        signaler:Signal("Close all for " .. source:instrument(), source);
    end
end

function CloseLong(source, period)
    local closedCount = 0;
    if instance.parameters.allow_trade then
        local it = trading:FindTrade():WhenSide("B");
        if UseOwnPositionsOnly then
            it:WhenCustomID(custom_id);
        end
        closedCount = it:Do(function (trade) trading:Close(trade); end);
    end
    if closedCount > 0 then
        signaler:Signal("Close long for " .. source:instrument(), source);
    end
end

function CloseShort(source, period)
    local closedCount = 0;
    if instance.parameters.allow_trade then
        local it = trading:FindTrade():WhenSide("S");
        if UseOwnPositionsOnly then
            it:WhenCustomID(custom_id);
        end
        closedCount = it:Do(function (trade) trading:Close(trade); end);
    end
    if closedCount > 0 then
        signaler:Signal("Close short for " .. source:instrument(), source);
    end
end

function IsPositionLimitHit(side, side_limit)
    if not instance.parameters.position_cap then
        return false;
    end
    local sideIt = trading:FindTrade();
    local allIt = trading:FindTrade();
    if UseOwnPositionsOnly then
        sideIt:WhenCustomID(custom_id);
        allIt:WhenCustomID(custom_id)
    end
    local side_positions = sideIt:Count();
    local positions = allIt:Count();
    return positions >= instance.parameters.no_of_positions or side_positions >= side_limit;
end

function GoLong(source, period)
    if instance.parameters.allow_trade then
        DoCloseOnOpposite("B");
        if IsPositionLimitHit("B", instance.parameters.no_of_buy_position) then
            signaler:Signal("Positions limit has been reached", source);
            return;
        end
        for _, position in ipairs(buy_positions) do
            position:Open(period);
        end
    end
    signaler:Signal("Buy " .. source:instrument(), source);
    last_serial = source:serial(period);
end

function GoShort(source, period)
    if instance.parameters.allow_trade then
        DoCloseOnOpposite("S");
        if IsPositionLimitHit("S", instance.parameters.no_of_sell_position) then
            signaler:Signal("Positions limit has been reached", source);
            return;
        end
        for _, position in ipairs(sell_positions) do
            position:Open(period);
        end
    end
    signaler:Signal("Sell " .. source:instrument(), source);
    last_serial = source:serial(period);
end

local last_period = -1
local last_serial_action;

function Update(period, mode)
    for _, module in pairs(Modules) do if module.ExtUpdate ~= nil then module:ExtUpdate(nil, source, period); end end
    if last_period > period then
        last_serial_action = nil;
    end
    last_period = period
    --TODO add indicator logic
    if period < source:size() - 1 or last_serial_action == source:serial(period) then
        return;
    end
    
    if add_log ~= nil then
        logger:Clear();
        logger:AddValue("bar_date", core.formatDate(source:date(period)));
    end
    last_serial_action = source:serial(period);
    for _, action in ipairs(EntryActions) do
        if action.IsPass(source, period) and (not action.ActOnSwitch or not action.IsPass(source, period - 1)) then
            logger:AddValue("action", action.Name);
            action.Execute(source, period);
        end
    end

    for _, action in ipairs(ExitActions) do
        if action.IsPass(source, period) and (not action.ActOnSwitch or not action.IsPass(source, period - 1)) then
            logger:AddValue("action", action.Name);
            action.Execute(source, period);
        end
    end
    if add_log then logger:FlushValues(); end
end

function AsyncOperationFinished(cookie, success, message, message1, message2)
    for _, module in pairs(Modules) do if module.AsyncOperationFinished ~= nil then module:AsyncOperationFinished(cookie, success, message, message1, message2); end end
end

dofile(core.app_path() .. "\\strategies\\custom\\snippets\\trading.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\breakeven.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\tables_monitor.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\signaler.lua")
