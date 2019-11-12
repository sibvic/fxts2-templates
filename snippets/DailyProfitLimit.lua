DailyProfitLimit = {};
-- public fields
DailyProfitLimit.Name = "Daily Profit Limit";
DailyProfitLimit.Version = "1.2";
DailyProfitLimit.Debug = false;
--private fields
DailyProfitLimit._ids_start = nil;
DailyProfitLimit._tz = nil;
DailyProfitLimit._signaler = nil;

function DailyProfitLimit:trace(str) if not self.Debug then return; end core.host:trace(self.Name .. ": " .. str); end
function DailyProfitLimit:OnNewModule(module) if module.Name == "Signaler" then self._signaler = module; end end
function DailyProfitLimit:RegisterModule(modules) for _, module in pairs(modules) do self:OnNewModule(module); module:OnNewModule(self); end modules[#modules + 1] = self; self._ids_start = (#modules) * 100; end

function DailyProfitLimit:Init(parameters)
    parameters:addBoolean("close_on_day_profit", "Close positions on daily profit", "", false)
    parameters:addDouble("day_profit_limit", "Day profit limit, $", "", 0)
end

function DailyProfitLimit:Prepare(name_only)
    if name_only then return; end
    if instance.parameters.close_on_day_profit then
        core.host:execute("subscribeTradeEvents", self._ids_start, "trades");
    end
end

function DailyProfitLimit:AsyncOperationFinished(cookie, success, message, message1, message2)
    if cookie == self._ids_start then
        local trade_id = message;
        local close_trade = success;
        if close_trade then
            local closed_trade = core.host:findTable("closed trades"):find("TradeID", trade_id);
            if closed_trade ~= nil and closed_trade.OQTXT == custom_id then
                self:UpdateDayPL();
                self.state.day_pl = self.state.day_pl + closed_trade.GrossPL;
            end
        end
    end
end

function DailyProfitLimit:ExtUpdate(id, source, period)
    if not instance.parameters.close_on_day_profit then
        return;
    end
    self:UpdateDayPL();
    local day_pl = self:GetDayPL();
    local date = source:date(NOW)
    local trading_day_offset  = core.host:execute("getTradingDayOffset");
    local trading_week_offset = core.host:execute("getTradingWeekOffset");
    local s, e = core.getcandle("D1", date, trading_day_offset, trading_week_offset)
    if day_pl >= instance.parameters.day_profit_limit and self.state.last_profit_reached ~= s then
        if self.Signaler ~= nil then
            self.Signaler:Signal("Daily profit target reached");
        end
        trading:FindTrade()
            :WhenCustomID(custom_id)
            :Do(
                function (trade) 
                    trading:Close(trade);
                end
            )
        self.state.last_profit_reached = s;
    end
end

DailyProfitLimit.state = {};
function DailyProfitLimit:UpdateDayPL()
    local trading_day_offset  = core.host:execute("getTradingDayOffset");
    local trading_week_offset = core.host:execute("getTradingWeekOffset");
    local date = trading_logic.MainSource:date(NOW)
    local s, e = core.getcandle("D1", date, trading_day_offset, trading_week_offset)
    if self.state.day_pl_date ~= s then
        self.state.day_pl_date = s
        self.state.day_pl = 0
        local enum = core.host:findTable("trades"):enumerator();
        local row = enum:next();
        while row ~= nil do
            if row.QTXT == custom_id then
                self.state[row.TradeID] = row.GrossPL;
            end
            row = enum:next();
        end
    end
end

function DailyProfitLimit:GetDayPL()
    local current = 0;
    local enum = core.host:findTable("trades"):enumerator();
    local row = enum:next();
    while row ~= nil do
        if row.QTXT == custom_id then
            local pl_start = self.state[row.TradeID];
            if pl_start == nil then
                pl_start = 0;
            end
            current = current + row.GrossPL - pl_start;
        end
        row = enum:next();
    end
    return self.state.day_pl + current;
end

DailyProfitLimit:RegisterModule(Modules);

