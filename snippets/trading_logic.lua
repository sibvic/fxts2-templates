trading_logic = {};
-- public fields
trading_logic.Name = "Trading logic";
trading_logic.Version = "1.12";
trading_logic.Debug = false;
trading_logic.DoTrading = nil;
trading_logic.DoExit = nil;
trading_logic.MainSource = nil;
trading_logic.HistoryPreloadBars = 300;
trading_logic.RequestBidAsk = false;
--private fields
trading_logic._histories = {};
trading_logic._ids_start = nil;
trading_logic._last_id = nil;
trading_logic._trading_source_id = nil;
function trading_logic:trace(str) if not self.Debug then return; end core.host:trace(self.Name .. ": " .. str); end
function trading_logic:OnNewModule(module) end
function trading_logic:RegisterModule(modules) for _, module in pairs(modules) do self:OnNewModule(module); module:OnNewModule(self); end modules[#modules + 1] = self; self._ids_start = (#modules) * 100; 
    self._last_id = self._ids_start - 1;
end
function trading_logic:Init(parameters)
    if not CustomTimeframeDefined then
        parameters:addBoolean("is_bid", "Price Type", "", true);
        parameters:setFlag("is_bid", core.FLAG_BIDASK);
        if not DISABLE_HA_SOURCE then
            parameters:addBoolean("ha_as_source", "Use HA as source", "", false);
        end
        parameters:addString("timeframe", "Entry Time frame", "", "m5");
        parameters:setFlag("timeframe", core.FLAG_BARPERIODS_EDIT);
    end
    if ENFORCE_entry_execution_type == nil then
        parameters:addString("entry_execution_type", "Entry Execution Type", "Once per bar close or on every tick", "EndOfTurn");
        parameters:addStringAlternative("entry_execution_type", "End of Turn", "", "EndOfTurn");
        parameters:addStringAlternative("entry_execution_type", "Live", "", "Live");
    end
    if not CustomTimeframeDefined and not DISABLE_EXIT and EXIT_TIMEFRAME_IN_PARAMS then
        parameters:addString("exit_timeframe", "Exit Time frame", "", "m5");
        parameters:setFlag("exit_timeframe", core.FLAG_BARPERIODS_EDIT);
    end
    if ENFORCE_exit_execution_type == nil and not DISABLE_EXIT then
        parameters:addString("exit_execution_type", "Exit Execution Type", "Once per bar close or on every tick", "Live");
        parameters:addStringAlternative("exit_execution_type", "End of Turn", "", "EndOfTurn");
        parameters:addStringAlternative("exit_execution_type", "Live", "", "Live");
    end
end
function trading_logic:GetLastPeriod(source_period, source, target)
    if source_period < 0 or target:size() < 2 then
        return nil;
    end
    local s1, e1 = core.getcandle(source:barSize(), source:date(source_period), -7, 0);
    local s2, e2 = core.getcandle(target:barSize(), target:date(NOW - 1), -7, 0);
    if e1 == e2 then
        return target:size() - 2;
    else
        return target:size() - 1;
    end
end
function trading_logic:GetPeriod(source_period, source, target)
    if source_period < 0 then
        return nil;
    end
    local source_date = source:date(source_period);
    local index = core.findDate(target, source_date, false);
    if index == -1 then
        return nil;
    end
    return index;
end
function trading_logic:SubscribeHistory(instrument, timeframe, is_bid)
    if instrument == nil then
        instrument = instance.bid:instrument();
    end
    if self._histories[instrument] == nil then
    self._histories[instrument] = {};
    end
    if self._histories[instrument][timeframe] == nil then
    self._histories[instrument][timeframe] = {};
    end
    local data = self._histories[instrument][timeframe][is_bid];
    if data == nil then
        data = {};
        data.id = self._last_id + 1;
        data.source = ExtSubscribe1(data.id, instrument, timeframe, self.HistoryPreloadBars, is_bid, "bar");
        self._last_id = self._last_id + 1;
        self._histories[instrument][timeframe][is_bid] = data;
    end
    return data.source, data.id;
end
function trading_logic:Prepare(name_only)
    if name_only then
        return;
    end
    local exit_timeframe = instance.parameters.exit_timeframe or instance.parameters.timeframe;
    if instance.parameters.ha_as_source then
        local MainSource, mainId = self:SubscribeHistory(nil, instance.parameters.timeframe, instance.parameters.is_bid);
        local ExitSource, exitId = self:SubscribeHistory(nil, exit_timeframe, instance.parameters.is_bid);
        
        local mainHA = core.indicators:create("HA", MainSource);
        self.MainSourceHA = mainHA;
        self.MainSource = mainHA:getCandleOutput(0);
        self._trading_source_id = mainId;
        
        local exitHA = core.indicators:create("HA", ExitSource);
        self.ExitSourceHA = exitHA;
        self.ExitSource = exitHA:getCandleOutput(0);
        self._exit_source_id = exitId;
    else
        self.MainSource, self._trading_source_id = self:SubscribeHistory(nil, instance.parameters.timeframe, instance.parameters.is_bid);
        self.ExitSource, self._exit_source_id = self:SubscribeHistory(nil, exit_timeframe, instance.parameters.is_bid);
    end
    if instance.parameters.entry_execution_type == "Live" or ENFORCE_entry_execution_type == "Live" then
        _, self._trading_source_id = self:SubscribeHistory(nil, "t1", instance.parameters.is_bid);
    end
    if instance.parameters.exit_execution_type == "Live" or ENFORCE_exit_execution_type == "Live" then
        _, self._exit_source_id = self:SubscribeHistory(nil, "t1", instance.parameters.is_bid);
    end
    if self.RequestBidAsk then
        if instance.parameters.is_bid then
            self.MainSourceBid = self.MainSource;
            self.MainSourceAsk, _ = self:SubscribeHistory(nil, instance.parameters.timeframe, not instance.parameters.is_bid);
        else
            self.MainSourceAsk = self.MainSource;
            self.MainSourceBid, _ = self:SubscribeHistory(nil, instance.parameters.timeframe, not instance.parameters.is_bid);
        end
    end
end
function trading_logic:ExtUpdate(id, source, period)
    if self.MainSourceHA ~= nil then
        self.MainSourceHA:update(core.UpdateLast);
    end
    if self.ExitSourceHA ~= nil then
        self.ExitSourceHA:update(core.UpdateLast);
    end
    if id == self._trading_source_id and self.DoTrading ~= nil then
        local period2 = period;
        if source ~= self.MainSource then
            period2 = core.findDate(self.MainSource, source:date(period), false);
            if period2 == -1 then
                return;
            end
        end
        self.DoTrading(self.MainSource, period2);
    end
    if id == self._exit_source_id and self.DoExit ~= nil then
        local period2 = period;
        if source ~= self.ExitSource then
            period2 = core.findDate(self.ExitSource, source:date(period), false);
            if period2 == -1 then
                return;
            end
        end
        self.DoExit(self.ExitSource, period2);
    end
end
trading_logic:RegisterModule(Modules);