-- START OF CUSTOMIZATION SECTION
-- Trading time parameters. You can turn it off if you never use it.
local IncludeTradingTime = true;
-- Whether to take into account positions created only by this strategy
-- or take into account positions created by other strategies and by the user as well.
-- If set to false the strategy may close positions created by the user and other strategies
local UseOwnPositionsOnly = true;

-- History preload count
local HISTORY_PRELOAD_BARS = 300;
-- Whether to request both prices: bid and ask
local RequestBidAsk = false;
-- wether to allow timeframes like m2 (true) or limit to the standard ones (false)
local USE_CUSTOM_TIMEFRAMES = false;

local ENFORCE_POSITION_CAP = false;

-- Enforce execution type. When set to Live/EndOfTurn the execution type parameters will be hiden
local ENFORCE_entry_execution_type = nil; -- Live/EndOfTurn
local ENFORCE_exit_execution_type = nil; -- Live/EndOfTurn
local EXIT_TIMEFRAME_IN_PARAMS = false;
local DISABLE_EXIT = true;
local DISABLE_HA_SOURCE = false;

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

-- You can create custom exit logic for the opened position/order
function CreateExitController(positionResult)
end
-- Restore exit controllers for orders and trades after FXTS2/strategy was restarted
function RestoreExitControllerForOrder(order)
end
function RestoreExitControllerForTrade(trade)
end

function OnNewBar(source, period) end
function CreateParameters() end
function CreateStopParameters(params, id) return false; end
function CreateLimitParameters(params, id) return false; end
function CreateEntryIndicators(source) end
function CreateExitIndicators(source) end

function UpdateIndicators()
    --indi:update(core.UpdateLast);
end

function LogIndicatorsHeaders(log)
    --log[#log + 1] = indi.DATA:name();
end

function LogIndicatorsValues(log, period)
    --log[indi.DATA:name()] = tostring(indi.DATA[period]);
end

-- Entry rate for the entry orders
-- Return nil for market orders
function GetEntryRate(source, bs, period) return nil; end
function SetCustomStop(position_desc, command, period, periods_from_last, source) return false; end
function SetCustomLimit(position_desc, command, period, periods_from_last, source) return false; end
function SaveCustomStopParameters(position_desc, id) end
function SaveCustomLimitParameters(position_desc, id) end
function CreateCustomBreakeven(position_desc, result, period, periods_from_last) return false; end

function CreateCustomActions()
    -- local action1, isEntry1 = CreateAction(1);
    -- action1.Data = nil;
    -- action1.ActOnSwitch = true;
    -- action1.AddLog = function (source, period, periodFromLast, data, values)
    --     --values["Buy value name"] = value;
    -- end
    -- action1.IsPass = function (source, period, periodFromLast, data)
    --     return false; -- TODO: implement
    -- end
    -- action1.IsPass = function (source, period, periodFromLast, data) return core.crossesOver(source.close, indi.Top, period); end
    -- if isEntry1 then
    --     EntryActions[#EntryActions + 1] = action1;
    -- else
    --     ExitActions[#ExitActions + 1] = action1;
    -- end
    if not DISABLE_EXIT then
        local exitLongAction = {};
        exitLongAction.ActOnSwitch = false;
        exitLongAction.Cache = {};
        exitLongAction.IsPass = function (source, period, periodFromLast, data)
            return false; -- TODO: implement
        end

        local exitShortAction = {};
        exitShortAction.ActOnSwitch = false;
        exitShortAction.Cache = {};
        exitShortAction.IsPass = function (source, period, periodFromLast, data)
            return false; -- TODO: implement
        end
        if instance.parameters.Direction == "direct" then
            exitLongAction.Execute = CloseLong;
            exitShortAction.Execute = CloseShort;
        else
            exitLongAction.Execute = CloseShort;
            exitShortAction.Execute = CloseLong;
        end
        ExitActions[#ExitActions + 1] = exitLongAction;
        ExitActions[#ExitActions + 1] = exitShortAction;
    end

    local enterLongAction = {};
    enterLongAction.ActOnSwitch = true;
    enterLongAction.Cache = {};
    enterLongAction.AddHeaders = function (headers, data)
        --headers[#headers + 1] = "Buy value name";
        --headers[#headers + 1] = "Long passed";
    end
    enterLongAction.AddLog = function (source, period, periodFromLast, data, values)
        --values["Buy value name"] = value;
        --values["Long passed"] = self:IsPass(source, period, periodFromLast, data);
    end
    enterLongAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end
    AddLongCondition(enterLongAction);

    local enterShortAction = {};
    enterShortAction.ActOnSwitch = true;
    enterShortAction.Cache = {};
    enterShortAction.AddHeaders = function (headers, data)
        --headers[#headers + 1] = "Sell value name";
        --headers[#headers + 1] = "Short passed";
    end
    enterShortAction.AddLog = function (source, period, periodFromLast, data, values)
        --values["Sell value name"] = value;
        --values["Short passed"] = self:IsPass(source, period, periodFromLast, data);
    end
    enterShortAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end
    AddShortCondition(enterShortAction);
end

function GetSignalSerial(source, period)
    --if renko.DATA:size() < 2 then
    --     return nil;
    --end
    --return renko.DATA:date(NOW);
    return source:serial(period);
end
-- END OF USER DEFINED SECTION

function AddLongCondition(condition)
    if instance.parameters.Direction == "direct" then
        condition.Execute = GoLong;
        condition.ExecuteData = CreateBuyPositions(trading_logic.MainSource);
    else
        condition.Execute = GoShort;
        condition.ExecuteData = CreateSellPositions(trading_logic.MainSource);
    end
    EntryActions[#EntryActions + 1] = condition;
end
function AddShortCondition(condition)
    if instance.parameters.Direction ~= "direct" then
        condition.Execute = GoLong;
        condition.ExecuteData = CreateBuyPositions(trading_logic.MainSource);
    else
        condition.Execute = GoShort;
        condition.ExecuteData = CreateSellPositions(trading_logic.MainSource);
    end
    EntryActions[#EntryActions + 1] = condition;
end

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
    trading:Init(strategy.parameters, 1);
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

    strategy.parameters:addBoolean("add_log", "Write log", "", false);
    strategy.parameters:addFile("log_file", "Log file (csv)", "You can open it in Excel", core.app_path() .. "\\log\\" .. STRATEGY_NAME .. ".csv");
end

function CreateAction(id)
    local actionType = instance.parameters:getString("Action" .. id);
    local action = {};
    action.Cache = {};
    if actionType == "NO" then
        action.Execute = DisabledAction;
    elseif actionType == "SELL" then
        action.Execute = GoShort;
        action.ExecuteData = CreateSellPositions(trading_logic.MainSource);
    elseif actionType == "BUY" then
        action.Execute = GoLong;
        action.ExecuteData = CreateBuyPositions(trading_logic.MainSource);
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

function CreatePositions(side, source)
    local positions = {};
    positions[#positions + 1] = CreatePositionStrategy(source, side, "");
    return positions;
end

function CreateBuyPositions(source)
    if instance.parameters.allow_side == "sell" then
        return {};
    end
    return CreatePositions("B", source);
end

function CreateSellPositions(source)
    if instance.parameters.allow_side == "buy" then
        return {};
    end
    return CreatePositions("S", source);
end

local add_log;
local log_file;
local use_mandatory_closing;
local headers = {};

function Prepare(name_only)
    trading_logic.HistoryPreloadBars = HISTORY_PRELOAD_BARS;
    trading_logic.RequestBidAsk = RequestBidAsk;
    add_log = instance.parameters.add_log;
    for _, module in pairs(Modules) do module:Prepare(nameOnly); end

    instance:name(profile:id() .. "(" .. instance.bid:name() ..  ")");
    if name_only then 
        return ; 
    end
    use_mandatory_closing = instance.parameters.use_mandatory_closing;

    CreateEntryIndicators(trading_logic.MainSource);
    CreateExitIndicators(trading_logic.ExitSource);
    CreateCustomActions();

    if add_log then
        log_file = io.open(instance.parameters.log_file, "w");
        headers[#headers + 1] = "date";
        for _, action in ipairs(EntryActions) do
            if action.AddLog ~= nil then
                action.AddHeaders(headers, action.Data);
            end
        end
        for _, action in ipairs(ExitActions) do
            if action.AddLog ~= nil then
                action.AddHeaders(headers, action.Data);
            end
        end
        LogIndicatorsHeaders(headers);
        for i, header in ipairs(headers) do
            log_file:write(header .. ";")
        end
        log_file:write("\n");
    end

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
    if instance.parameters.custom_id ~= "" then
        custom_id = instance.parameters.custom_id;
    else
        custom_id = profile:id() .. "_" .. instance.bid:name();
    end

    if use_mandatory_closing then
        exit_time, valid = ParseTime(instance.parameters.mandatory_closing_exit_time);
        assert(valid, "Time " .. instance.parameters.mandatory_closing_exit_time .. " is invalid");
        core.host:execute("setTimer", MANDATORY_CLOSE_TIMER_ID, math.max(instance.parameters.mandatory_closing_valid_interval / 2, 1));
    end
    local it = trading:FindTrade();
    if UseOwnPositionsOnly then
        it:WhenCustomID(custom_id);
    end
    it:Do(function (trade) RestoreExitControllerForTrade(trade); end);
    local it = trading:FindOrder();
    if UseOwnPositionsOnly then
        it:WhenCustomID(custom_id);
    end
    it:Do(function (order) RestoreExitControllerForOrder(order); end);
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
        assert(position_strategy.LimitType ~= "stop" or position_strategy.StopType == "pips" or CreateStopParameters ~= nil, "To use limit based on stop you need to set stop in pips");
    elseif SaveCustomLimitParameters ~= nil then
        SaveCustomLimitParameters(position_strategy, id);
    end

    position_strategy.Id = id;
    position_strategy.Side = side;
    position_strategy.Source = source;
    position_strategy.Amount = instance.parameters:getInteger("amount" .. id);
    position_strategy.Amount_Type = instance.parameters:getString("amount_type" .. id);
    if SetCustomStop == nil then
        position_strategy.Stop = instance.parameters:getDouble("stop" .. id);
        if instance.parameters:getBoolean("use_trailing" .. id) then
            position_strategy.Trailing = instance.parameters:getInteger("trailing" .. id);
        end
    end
    if SetCustomLimit == nil then
        position_strategy.Limit = instance.parameters:getDouble("limit" .. id);
    end
    if CreateCustomBreakeven == nil then
        position_strategy.be = trading:GetBreakeven(id);
        if position_strategy.be.UseBreakeven and tick_source == nil then
            tick_source, TICKS_SOURCE_ID = trading_logic:SubscribeHistory(position_strategy.Source.close:instrument(), "t1", true);
        end
    end

    function position_strategy:SetDefaultLimit(command, stop_value, period)
        if self.LimitType == "pips" then
            return command:SetPipLimit(nil, self.Limit);
        end
        if self.LimitType == "stop" then
            if stop_value == nil then
                if command.valuemap.RateStop ~= nil then
                    if self.Side == "B" then
                        stop_value = (instance.ask[NOW] - command.valuemap.RateStop) / instance.bid:pipSize();
                    else
                        stop_value = (command.valuemap.RateStop - instance.bid[NOW]) / instance.bid:pipSize();
                    end
                else
                    stop_value = command.valuemap.PegPriceOffsetPipsStop;
                end
            end
            return command:SetPipLimit(nil, stop_value * self.Limit);
        end
        if self.LimitType == "highlow" then
            if self.Side == "B" then
                return command:SetPipLimit(nil, (self.Source.high[period] - self.Source.close[period]) / self.Source:pipSize() + self.Limit);
            end
            return command:SetPipLimit(nil, (self.Source.close[period] - self.Source.low[period]) / self.Source:pipSize() + self.Limit);
        end
        return command;
    end

    function position_strategy:Open(period, periods_from_last)
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
            :SetCustomID(custom_id)
            :SetExecutionType(instance.parameters.execution_mode);
        if self.Amount_Type == "lots" then
            command:SetAmount(self.Amount)
        elseif self.Amount_Type == "risk_equity" then
            command:SetRiskPercentOfEquityAmount(self.Amount)
        elseif self.Amount_Type == "equity" then
            command:SetPercentOfEquityAmount(self.Amount)
        elseif self.Amount_Type == "margin" then
            command:SetPercentOfMarginAmount(self.Amount)
        end
        local default_stop = SetCustomStop == nil or not SetCustomStop(self, command, period, periods_from_last, source);
        local default_limit = SetCustomLimit == nil or not SetCustomLimit(self, command, period, periods_from_last, source);
        if default_stop then
            local stop_value;
            if self.StopType == "pips" then
                stop_value = self.Stop;
                command = command:SetPipStop(nil, self.Stop, self.Trailing);
            elseif self.StopType == "highlow" then
                if self.Side == "B" then
                    stop_value = (self.Source.close[period] - self.Source.low[period]) / self.Source:pipSize() + self.Stop;
                    command = command:SetPipStop(nil, stop_value, self.Trailing);
                else
                    stop_value = (self.Source.high[period] - self.Source.close[period]) / self.Source:pipSize() + self.Stop;
                    command = command:SetPipStop(nil, stop_value, self.Trailing);
                end
            end
        end
        if default_limit then
            command = self:SetDefaultLimit(command, stop_value, period);
        end
        local result = command:Execute();
        if result.Finished and not result.Success then
            return result;
        end
        CreateExitController(result);
        local default_breakeven = CreateCustomBreakeven == nil or not CreateCustomBreakeven(self, result, period, periods_from_last);
        if default_breakeven then
            self.be:AddBreakeven(result);
        end
        return result;
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
    if openTime == closeTime then
        return true;
    end
    if openTime < closeTime then
        return now >= openTime and now <= closeTime;
    end
    if openTime > closeTime then
        return now > openTime or now < closeTime;
    end

    return now == openTime;
end

local log_values;
function ExtUpdate(id, source, period)
    if id == trading_logic._trading_source_id then
        OnNewBar(source, period);
    end
    if use_mandatory_closing and core.host.Trading:getTradingProperty("isSimulation") then
        DoMandatoryClosing();
    end
    trading_logic:UpdateIndicators();
    UpdateIndicators();
    if log_file ~= nil then
        log_values = {};
        log_values["date"] = core.formatDate(core.host:execute("getServerTime"));
        LogIndicatorsValues(log_values, period);
    end
    for _, module in pairs(Modules) do if module.ExtUpdate ~= nil then module:ExtUpdate(id, source, period); end end 
    if log_file ~= nil then
        for i, header in ipairs(headers) do
            log_file:write(tostring(log_values[header]) .. ";");
        end
        log_file:write("\n");
        log_file:flush();
    end
end
function ReleaseInstance() 
    for _, module in pairs(Modules) do if module.ReleaseInstance ~= nil then module:ReleaseInstance(); end end 
    if log_file ~= nil then
        log_file:close();
    end
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
        local sideIt = trading:FindTrade()
            :WhenSide(side);
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
    local sideIt = trading:FindTrade()
        :WhenSide(side);
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
            position:Open(period, source:size() - period - 1);
        end
    end
    local message = "Buy " .. source.close:instrument()
    if log ~= nil then
        message = message .. "\r\nSignal info: " .. log;
    end
    signaler:Signal(message, source);
    last_serial = GetSignalSerial(source, period);
end

function GoShort(source, period, positions, log)
    if instance.parameters.allow_trade then
        DoCloseOnOpposite("S");
        if IsPositionLimitHit("S", instance.parameters.no_of_sell_position) then
            signaler:Signal("Positions limit has been reached", source);
            return;
        end
        for _, position in ipairs(positions) do
            position:Open(period, source:size() - period - 1);
        end
    end
    local message = "Sell " .. source.close:instrument()
    if log ~= nil then
        message = message .. "\nSignal info: " .. log;
    end
    signaler:Signal(message, source);
    last_serial = GetSignalSerial(source, period);
end
function EntryFunction(source, period)
    local current_serial = GetSignalSerial(source, period);
    if last_serial == current_serial then
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
        local isPass = action.IsPass(source, period, periodFromLast, action.Data);
        action.Cache[current_serial] = isPass;
        if action.CurrentSerial ~= current_serial then
            action.LastSerial = action.CurrentSerial;
            action.CurrentSerial = current_serial;
        end

        if add_log and action.AddLog ~= nil then
            action.AddLog(source, period, periodFromLast, action.Data, log_values);
        end

        if isPass and (not action.ActOnSwitch or action.Cache[action.LastSerial] == false) then
            action.Execute(source, period, action.ExecuteData);
        end
    end
end

function ExitFunction(source, period)
    local current_serial = GetSignalSerial(source, period);
    if last_serial == current_serial then
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
    for _, action in ipairs(ExitActions) do
        local isPass = action.IsPass(source, period, periodFromLast, action.Data);
        action.Cache[current_serial] = isPass;
        if action.CurrentSerial ~= current_serial then
            action.LastSerial = action.CurrentSerial;
            action.CurrentSerial = current_serial;
        end
        
        if add_log and action.AddLog ~= nil then
            action.AddLog(source, period, periodFromLast, action.Data, log_values);
        end
        
        if isPass and (not action.ActOnSwitch or action.Cache[action.LastSerial] == false) then
            action.Execute(source, period, action.ExecuteData);
        end
    end
end

function DoMandatoryClosing()
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

function ExtAsyncOperationFinished(cookie, success, message, message1, message2)
    for _, module in pairs(Modules) do if module.AsyncOperationFinished ~= nil then module:AsyncOperationFinished(cookie, success, message, message1, message2); end end
    if cookie == MANDATORY_CLOSE_TIMER_ID then
        DoMandatoryClosing();
    end
end

dofile(core.app_path() .. "\\strategies\\standard\\include\\helper.lua");

dofile(core.app_path() .. "\\strategies\\custom\\snippets\\breakeven.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\signaler.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\tables_monitor.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\trading_logic.lua")
dofile(core.app_path() .. "\\strategies\\custom\\snippets\\trading.lua")