-- More information about this indicator can be found at:
-- http://fxcodebase.com/

--+------------------------------------------------------------------+
--|                               Copyright © 2019, Gehtsoft USA LLC |
--|                                            http://fxcodebase.com |
--+------------------------------------------------------------------+
--|                                      Developed by : Mario Jemic  |
--|                                          mario.jemic@gmail.com   |
--+------------------------------------------------------------------+
--|                                 Support our efforts by donating  |
--|                                    Paypal: https://goo.gl/9Rj74e |
--+------------------------------------------------------------------+
--|                                Patreon :  https://goo.gl/GdXWeN  |
--|                    BitCoin : 15VCJTLaz12Amr7adHSBtL9v8XomURo9RF  |
--|                BitCoin Cash: 1BEtS465S3Su438Kc58h2sqvVvHK9Mijtg  |
--|           Ethereum : 0x8C110cD61538fb6d7A2B47858F0c0AaBd663068D  |
--|                   LiteCoin : LLU8PSY2vsq7B9kRELLZQcKf5nJQrdeqwD  |
--+------------------------------------------------------------------+

-- START OF CUSTOMIZATION SECTION
-- Number of positions to open with individual set of stop/limit parameters.
local PositionsCount = 1;
-- Trading time parameters. You can turn it off if you never use it.
local IncludeTradingTime = true;
-- Whether to take into account positions created only by this strategy
-- or take into account positions created by other strategies and by the user as well.
-- If set to false the strategy may close positions created by the user and other strategies
local UseOwnPositionsOnly = true;

-- Support of alerts export using DDE
local DDEAlertsSupport = true;

-- History preload count
local HISTORY_PRELOAD_BARS = 300;

-- Whether to request both prices: bid and ask
local RequestBidAsk = false;

local ENFORCE_POSITION_CAP = false;

local STRATEGY_NAME = "Strategy Name";
local STRATEGY_VERSION = "1";
-- END OF CUSTOMIZATION SECTION

local Modules = {};
local EntryActions = {};
local ExitActions = {};
local LAST_ID = 2;

-- START OF USER DEFINED SECTION
-- Set it to true when you define your own timeframe and is_bid parameters
local CustomTimeframeDefined = false;

function CreateParameters() end
function CreateStopParameters(params, id) return false; end
function CreateLimitParameters(params, id) return false; end
function CreateIndicators(source) end

function UpdateIndicators()
    --indi:update(core.UpdateLast);
end

-- Entry rate for the entry orders
-- Return nil for market orders
function GetEntryRate(source, bs, period) return nil; end
function SetCustomStop(position_desc, command, period) return false; end
function SetCustomLimit(position_desc, command, period) return false; end
function SaveCustomStopParameters(position_strategy, id) end
function SaveCustomLimitParameters(position_strategy, id) end
function CreateCustomBreakeven(position_desc, result, period) return false; end

function CreateCustomActions()
    -- local action1, isEntry1 = CreateAction(1);
    -- action1.Data = nil;
    -- action1.IsPass = function (source, period, periodFromLast, data) return core.crossesOver(source.close, indi.Top, period); end
    -- if isEntry1 then
    --     EntryActions[#EntryActions + 1] = action1;
    -- else
    --     ExitActions[#ExitActions + 1] = action1;
    -- end
    local exitLongAction = {};
    exitLongAction.ActOnSwitch = false;
    exitLongAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    local exitShortAction = {};
    exitShortAction.ActOnSwitch = false;
    exitShortAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    local enterLongAction = {};
    enterLongAction.ActOnSwitch = true;
    enterLongAction.GetLog = function (source, period, periodFromLast, data)
        return "";
    end
    enterLongAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    local enterShortAction = {};
    enterShortAction.ActOnSwitch = true;
    enterShortAction.GetLog = function (source, period, periodFromLast, data)
        return "";
    end
    enterShortAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    if instance.parameters.Direction == "direct" then
        exitLongAction.Execute = CloseLong;
        exitShortAction.Execute = CloseShort;
        enterLongAction.Execute = GoLong;
        enterShortAction.Execute = GoShort;
        enterLongAction.ExecuteData = CreateBuyPositions();
        enterShortAction.ExecuteData = CreateSellPositions();
    else
        exitLongAction.Execute = CloseShort;
        exitShortAction.Execute = CloseLong;
        enterLongAction.Execute = GoShort;
        enterShortAction.Execute = GoLong;
        enterLongAction.ExecuteData = CreateSellPositions();
        enterShortAction.ExecuteData = CreateBuyPositions();
    end
    ExitActions[#ExitActions + 1] = exitLongAction;
    ExitActions[#ExitActions + 1] = exitShortAction;
    EntryActions[#EntryActions + 1] = enterLongAction;
    EntryActions[#EntryActions + 1] = enterShortAction;
end
-- END OF USER DEFINED SECTION

function Init()
    strategy:name(STRATEGY_NAME .. " v" .. STRATEGY_VERSION);
    strategy:description("");
    strategy:type(core.Both);
    strategy:setTag("Version", STRATEGY_VERSION);
    strategy:setTag("NonOptimizableParameters", "StartTime,StopTime,ToTime,signaler_ToTime,signaler_show_alert,signaler_play_soundsignaler_sound_file,signaler_recurrent_sound,signaler_send_email,signaler_email,signaler_show_popup,signaler_debug_alert,use_advanced_alert,advanced_alert_key");

    CreateParameters();

    strategy.parameters:addGroup("Trading");
    strategy.parameters:addString("Direction", "Type of Signal / Trade", "", "direct");
    strategy.parameters:addStringAlternative("Direction", "Direct", "", "direct");
    strategy.parameters:addStringAlternative("Direction", "Reverse", "", "reverse");
    trading_logic:Init(strategy.parameters);
    trading.AddLimitParameter = SetCustomLimit == nil;
    trading.AddBreakevenParameters = CreateCustomBreakeven == nil;
    trading:Init(strategy.parameters, PositionsCount);
    DailyProfitLimit:Init(strategy.parameters);
    strategy.parameters:addGroup("Time Parameters");
    strategy.parameters:addInteger("ToTime", "Convert the date to", "", core.TZ_TS);
    strategy.parameters:addIntegerAlternative("ToTime", "EST", "", core.TZ_EST);
    strategy.parameters:addIntegerAlternative("ToTime", "UTC", "", core.TZ_UTC);
    strategy.parameters:addIntegerAlternative("ToTime", "Local", "", core.TZ_LOCAL);
    strategy.parameters:addIntegerAlternative("ToTime", "Server", "", core.TZ_SERVER);
    strategy.parameters:addIntegerAlternative("ToTime", "Financial", "", core.TZ_FINANCIAL);
    strategy.parameters:addIntegerAlternative("ToTime", "Display", "", core.TZ_TS);
    
    if IncludeTradingTime then
        strategy.parameters:addString("StartTime", "Start Time for Trading", "", "00:00:00");
        strategy.parameters:addString("StopTime", "Stop Time for Trading", "", "24:00:00");
    end
    strategy.parameters:addBoolean("use_mandatory_closing", "Use Mandatory Closing", "", false);
    strategy.parameters:addString("mandatory_closing_exit_time", "Mandatory Closing Time", "", "23:59:59");
    strategy.parameters:addInteger("mandatory_closing_valid_interval", "Valid Interval for Operation, in second", "", 60);
    strategy.parameters:addGroup("Alert");
    signaler:Init(strategy.parameters);

    strategy.parameters:addBoolean("add_log", "Add log info to signals", "", false);
end

function CreateAction(id)
    local actionType = instance.parameters:getString("Action" .. id);
    local action = {};
    if actionType == "NO" then
        action.Execute = DisabledAction;
    elseif actionType == "SELL" then
        action.Execute = GoShort;
        action.ExecuteData = CreateSellPositions();
    elseif actionType == "BUY" then
        action.Execute = GoLong;
        action.ExecuteData = CreateBuyPositions();
    elseif actionType == "CLOSE" then
        action.Execute = CloseAll;
    end

    return action, actionType ~= "CLOSE";
end

function AddAction(id, name)
    strategy.parameters:addString("Action" .. id, name, "", "NO")
    strategy.parameters:addStringAlternative("Action" .. id, "No Action", "", "NO")
    strategy.parameters:addStringAlternative("Action" .. id, "Sell", "", "SELL")
    strategy.parameters:addStringAlternative("Action" .. id, "Buy", "", "BUY")
    strategy.parameters:addStringAlternative("Action" .. id, "Close Position", "", "CLOSE")
end

local MANDATORY_CLOSE_TIMER_ID = 1;
local TICKS_SOURCE_ID = 2;

local tick_source;
local ToTime;
local custom_id;
local OpenTime, CloseTime, exit_time;
local last_serial;

function CreateBuyPositions()
    local positions = {};
    if instance.parameters.allow_side == "sell" then
        return positions;
    end

    if PositionsCount == 1 then
        positions[#positions + 1] = CreatePositionStrategy(trading_logic.MainSource, "B", "");
        return positions;
    end
    for i = 1, PositionsCount do
        if instance.parameters:getBoolean("use_position_" .. i) then
            positions[#positions + 1] = CreatePositionStrategy(trading_logic.MainSource, "B", "_" .. i);
        end
    end
    return positions;
end

function CreateSellPositions()
    local positions = {};
    if instance.parameters.allow_side == "buy" then
        return positions;
    end
    if PositionsCount == 1 then
        positions[#positions + 1] = CreatePositionStrategy(trading_logic.MainSource, "S", "");
        return positions;
    end
    for i = 1, PositionsCount do
        if instance.parameters:getBoolean("use_position_" .. i) then
            positions[#positions + 1] = CreatePositionStrategy(trading_logic.MainSource, "S", "_" .. i);
        end
    end
    return positions;
end

local add_log;

function Prepare(name_only)
    trading_logic.HistoryPreloadBars = HISTORY_PRELOAD_BARS;
    trading_logic.RequestBidAsk = RequestBidAsk;
    add_log = instance.parameters.add_log;
    for _, module in pairs(Modules) do module:Prepare(nameOnly); end

    instance:name(profile:id() .. "(" .. instance.bid:name() ..  ")");
    if name_only then return ; end

    CreateIndicators(trading_logic.MainSource);
    CreateCustomActions();

    local valid;
    if IncludeTradingTime then
        OpenTime, valid = ParseTime(instance.parameters.StartTime);
        assert(valid, "Time " .. instance.parameters.StartTime .. " is invalid");
        CloseTime, valid = ParseTime(instance.parameters.StopTime);
        assert(valid, "Time " .. instance.parameters.StopTime .. " is invalid");
    end
    ToTime = instance.parameters.ToTime;
    trading_logic.DoTrading = EntryFunction;
    trading_logic.DoExit = ExitFunction;
    custom_id = profile:id() .. "_" .. instance.bid:name();

    if instance.parameters.use_mandatory_closing then
        exit_time, valid = ParseTime(instance.parameters.mandatory_closing_exit_time);
        assert(valid, "Time " .. instance.parameters.mandatory_closing_exit_time .. " is invalid");
        core.host:execute("setTimer", MANDATORY_CLOSE_TIMER_ID, math.max(instance.parameters.mandatory_closing_valid_interval / 2, 1));
    end
end

function CreatePositionStrategy(source, side, id)
    local position_strategy = {};
    if SetCustomStop == nil then
        position_strategy.StopType = instance.parameters:getString("stop_type" .. id);
    elseif SaveCustomStopParameters ~= nil then
        SaveCustomStopParameters(position_strategy, id);
    end
    if SetCustomLimit == nil then
        position_strategy.LimitType = instance.parameters:getString("limit_type" .. id);
        assert(position_strategy.LimitType ~= "stop" or position_strategy.StopType == "pips", "To use limit based on stop you need to set stop in pips");
    elseif SaveCustomLimitParameters ~= nil then
        SaveCustomLimitParameters(position_strategy, id);
    end

    position_strategy.Id = id;
    position_strategy.Side = side;
    position_strategy.Source = source;
    position_strategy.Amount = instance.parameters:getInteger("amount" .. id);
    if SetCustomStop == nil then
        position_strategy.Stop = instance.parameters:getDouble("stop" .. id);
        if position_strategy.StopType == "atr" then
            position_strategy.StopATR = core.indicators:create("ATR", source, position_strategy.Stop);
        end
        if instance.parameters:getBoolean("use_trailing" .. id) then
            position_strategy.Trailing = instance.parameters:getInteger("trailing" .. id);
        end
        position_strategy.AtrStopMult = instance.parameters:getDouble("atr_stop_mult" .. id);
    end
    if SetCustomLimit == nil then
        position_strategy.Limit = instance.parameters:getDouble("limit" .. id);
        if position_strategy.LimitType == "atr" then
            position_strategy.LimitATR = core.indicators:create("ATR", source, position_strategy.Limit);
        end
        position_strategy.AtrLimitMult = instance.parameters:getDouble("atr_limit_mult" .. id);
        position_strategy.TrailingLimitType = instance.parameters:getString("TRAILING_LIMIT_TYPE" .. id);
        position_strategy.TrailingLimitTrigger = instance.parameters:getDouble("TRAILING_LIMIT_TRIGGER" .. id);
        position_strategy.TrailingLimitStep = instance.parameters:getDouble("TRAILING_LIMIT_STEP" .. id);
    end
    if CreateCustomBreakeven == nil then
        position_strategy.UseBreakeven = instance.parameters:getBoolean("use_breakeven" .. id);
        position_strategy.BreakevenWhen = instance.parameters:getDouble("breakeven_when" .. id);
        position_strategy.BreakevenTo = instance.parameters:getDouble("breakeven_to" .. id);
        position_strategy.BreakevenTrailing = instance.parameters:getString("breakeven_trailing");
        position_strategy.BreakevenTrailingValue = instance.parameters:getInteger("trailing" .. id);
        if instance.parameters:getBoolean("breakeven_close" .. id) then
            position_strategy.BreakevenCloseAmount = instance.parameters:getDouble("breakeven_close_amount" .. id);
        end
        if position_strategy.UseBreakeven and tick_source == nil then
            tick_source, TICKS_SOURCE_ID = trading_logic:SubscribeHistory(position_strategy.Source.close:instrument(), "t1", true);
        end
    end

    function position_strategy:Open(period)
        local rate = nil;
        if GetEntryRate ~= nil then
            rate = GetEntryRate(self.Source, self.Side, period);
        end
        local command;
        if rate == nil then
            command = trading:MarketOrder(self.Source.close:instrument());
        else
            command = trading:EntryOrder(self.Source.close:instrument())
                :SetRate(rate);
        end
        command:SetSide(self.Side)
            :SetAccountID(instance.parameters.account)
            :SetAmount(self.Amount)
            :SetCustomID(custom_id);
        local default_stop = SetCustomStop == nil or not SetCustomStop(self, command, period);
        local default_limit = SetCustomLimit == nil or not SetCustomLimit(self, command, period);
        if default_stop then
            local stop_value;
            if self.StopType == "pips" then
                stop_value = self.Stop;
                command = command:SetPipStop(nil, self.Stop, self.Trailing);
            end
        end
        if default_limit then
            if self.LimitType == "pips" then
                command = command:SetPipLimit(nil, self.Limit);
            elseif self.LimitType == "stop" then
                command = command:SetPipLimit(nil, stop_value * self.Limit);
            end
        end
        local result = command:Execute();
        if default_stop then
            if self.StopType == "atr" then
                self.StopATR:update(core.UpdateLast);
                breakeven:CreateIndicatorTrailingController()
                    :SetRequestID(result.RequestID)
                    :SetTrailingTarget(breakeven.STOP_ID)
                    :SetIndicatorStream(self.StopATR.DATA, self.AtrStopMult, true);
            end
        end
        if default_limit then
            if self.LimitType == "atr" then
                self.LimitATR:update(core.UpdateLast);
                breakeven:CreateIndicatorTrailingController()
                    :SetRequestID(result.RequestID)
                    :SetTrailingTarget(breakeven.LIMIT_ID)
                    :SetIndicatorStream(self.LimitATR.DATA, self.AtrLimitMult, true);
            end
            self:CreateTrailingLimit(result);
        end
        local default_breakeven = CreateCustomBreakeven == nil or not CreateCustomBreakeven(self, result, period);
        if default_breakeven then
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
        end
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

function EnsureIndicatorInstalled(name)
    local profile = core.indicators:findIndicator(name);
    assert(profile ~= nil, "Please, download and install " .. name .. ".LUA indicator");
    return profile;
end

function ParseTime(time)
    local pos = string.find(time, ":");
    if pos == nil then
        return nil, false;
    end
    local h = tonumber(string.sub(time, 1, pos - 1));
    time = string.sub(time, pos + 1);
    pos = string.find(time, ":");
    if pos == nil then
        return nil, false;
    end
    local m = tonumber(string.sub(time, 1, pos - 1));
    local s = tonumber(string.sub(time, pos + 1));
    return (h / 24.0 +  m / 1440.0 + s / 86400.0),                          -- time in ole format
           ((h >= 0 and h < 24 and m >= 0 and m < 60 and s >= 0 and s < 60) or (h == 24 and m == 0 and s == 0)); -- validity flag
end

function InRange(now, openTime, closeTime)
    if openTime < closeTime then
        return now >= openTime and now <= closeTime;
    end
    if openTime > closeTime then
        return now > openTime or now < closeTime;
    end

    return now == openTime;
end

function ExtUpdate(id, source, period) for _, module in pairs(Modules) do if module.ExtUpdate ~= nil then module:ExtUpdate(id, source, period); end end end
function ReleaseInstance() for _, module in pairs(Modules) do if module.ReleaseInstance ~= nil then module:ReleaseInstance(); end end end

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
        signaler:Signal("Close all for " .. source.close:instrument(), source);
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
        signaler:Signal("Close long for " .. source.close:instrument(), source);
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
        signaler:Signal("Close short for " .. source.close:instrument(), source);
    end
end

function IsPositionLimitHit(side, side_limit)
    if ENFORCE_POSITION_CAP == true then
        local sideIt = trading:FindTrade();
        local allIt = trading:FindTrade();
        if UseOwnPositionsOnly then
            sideIt:WhenCustomID(custom_id);
            allIt:WhenCustomID(custom_id)
        end
        local side_positions = sideIt:Count();
        local positions = allIt:Count();
        return positions >= 1 or side_positions >= 1;
    end
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

function GoLong(source, period, positions, log)
    if instance.parameters.allow_trade then
        DoCloseOnOpposite("B");
        if IsPositionLimitHit("B", instance.parameters.no_of_buy_position) then
            signaler:Signal("Positions limit has been reached", source);
            return;
        end
        for _, position in ipairs(positions) do
            position:Open(period);
        end
    end
    local message = "Buy " .. source.close:instrument()
    if log ~= nil then
        message = message .. "\r\nSignal info: " .. log;
    end
    signaler:Signal(message, source);
    last_serial = source:serial(period);
end

function GoShort(source, period, positions, log)
    if instance.parameters.allow_trade then
        DoCloseOnOpposite("S");
        if IsPositionLimitHit("S", instance.parameters.no_of_sell_position) then
            signaler:Signal("Positions limit has been reached", source);
            return;
        end
        for _, position in ipairs(positions) do
            position:Open(period);
        end
    end
    local message = "Sell " .. source.close:instrument()
    if log ~= nil then
        message = message .. "\nSignal info: " .. log;
    end
    signaler:Signal(message, source);
    last_serial = source:serial(period);
end

function EntryFunction(source, period)
    UpdateIndicators();
    if last_serial == source:serial(period) then
        return;
    end
    local now = core.host:execute("convertTime", core.TZ_EST, ToTime, core.host:execute("getServerTime"));
    now = now - math.floor(now);
    if IncludeTradingTime then
        if not InRange(now, OpenTime, CloseTime) then
            return;
        end
    end

    local periodFromLast = source:size() - period - 1;
    for _, action in ipairs(EntryActions) do
        if action.IsPass(source, period, periodFromLast, action.Data) 
            and (not action.ActOnSwitch or not action.IsPass(source, period - 1, periodFromLast - 1, action.Data)) 
        then
            local log = nil;
            if add_log and action.GetLog ~= nil then
                log = action.GetLog(source, period, periodFromLast, action.Data);
            end
            action.Execute(source, period, action.ExecuteData, log);
        end
    end
end

function ExitFunction(source, period)
    UpdateIndicators();
    if last_serial == source:serial(period) then
        return;
    end
    local now = core.host:execute("convertTime", core.TZ_EST, ToTime, core.host:execute("getServerTime"));
    now = now - math.floor(now);
    if IncludeTradingTime then
        if not InRange(now, OpenTime, CloseTime) then
            return;
        end
    end

    local periodFromLast = period - source:size();
    for _, action in ipairs(ExitActions) do
        if action.IsPass(source, period, periodFromLast, action.Data) 
            and (not action.ActOnSwitch or not action.IsPass(source, period - 1, periodFromLast - 1, action.Data)) 
        then
            local log = nil;
            if add_log and action.GetLog ~= nil then
                log = action.GetLog(source, period, periodFromLast, action.Data);
            end
            action.Execute(source, period, action.ExecuteData, log);
        end
    end
end

function ExtAsyncOperationFinished(cookie, success, message, message1, message2)
    for _, module in pairs(Modules) do if module.AsyncOperationFinished ~= nil then module:AsyncOperationFinished(cookie, success, message, message1, message2); end end
    if cookie == MANDATORY_CLOSE_TIMER_ID then
        local now = core.host:execute("convertTime", core.TZ_EST, ToTime, core.host:execute("getServerTime"));
        now = now - math.floor(now);
        if InRange(now, exit_time, exit_time + (instance.parameters.mandatory_closing_valid_interval / 86400.0)) then
            local it = trading:FindTrade();
            if UseOwnPositionsOnly then
                it:WhenCustomID(custom_id);
            end
            it:Do(function (trade) trading:Close(trade); end );
            signaler:Signal("Mandatory closing");
        end
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");