tables_monitor = {};
tables_monitor.Name = "Tables monitor";
tables_monitor.Version = "1.2";
tables_monitor.Debug = false;
tables_monitor._ids_start = nil;
tables_monitor._new_trade_id = nil;
tables_monitor._trade_listeners = {};
tables_monitor._closed_trade_listeners = {};
tables_monitor._close_order_listeners = {};
tables_monitor.closing_order_types = {};
function tables_monitor:ListenTrade(func)
    self._trade_listeners[#self._trade_listeners + 1] = func;
end
function tables_monitor:ListenCloseTrade(func)
    self._closed_trade_listeners[#self._closed_trade_listeners + 1] = func;
end
function tables_monitor:ListenCloseOrder(func)
    self._close_order_listeners[#self._close_order_listeners + 1] = func;
end
function tables_monitor:trace(str) if not self.Debug then return; end core.host:trace(self.Name .. ": " .. str); end
function tables_monitor:Init(parameters) end
function tables_monitor:Prepare(name_only)
    if name_only then return; end
    self._new_trade_id = self._ids_start;
    self._order_change_id = self._ids_start + 1;
    self._ids_start = self._ids_start + 2;
    core.host:execute("subscribeTradeEvents", self._order_change_id, "orders");
    core.host:execute("subscribeTradeEvents", self._new_trade_id, "trades");
end
function tables_monitor:OnNewModule(module) end
function tables_monitor:RegisterModule(modules) for _, module in pairs(modules) do self:OnNewModule(module); module:OnNewModule(self); end modules[#modules + 1] = self; self._ids_start = (#modules) * 100; end
function tables_monitor:ReleaseInstance() end
function tables_monitor:AsyncOperationFinished(cookie, success, message, message1, message2)
    if cookie == self._new_trade_id then
        local trade_id = message;
        local close_trade = success;
        if close_trade then
            local closed_trade = core.host:findTable("closed trades"):find("TradeID", trade_id);
            if closed_trade ~= nil then
                for _, callback in ipairs(self._closed_trade_listeners) do
                    callback(closed_trade);
                end
            end
        else
            local trade = core.host:findTable("trades"):find("TradeID", message);
            if trade ~= nil then
                for _, callback in ipairs(self._trade_listeners) do
                    callback(trade);
                end
            end
        end
    elseif cookie == self._order_change_id then
        local order_id = message;
        local order = core.host:findTable("orders"):find("OrderID", order_id);
        local fix_status = message1;
        if order ~= nil then
            if order.Stage == "C" then
                self.closing_order_types[order.OrderID] = order.Type;
                for _, callback in ipairs(self._close_order_listeners) do
                    callback(order);
                end
            end
        end
    end
end
function tables_monitor:ExtUpdate(id, source, period) end
if Modules ~= nil then
    tables_monitor:RegisterModule(Modules);
end