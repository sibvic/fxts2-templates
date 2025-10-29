PineStrategy = {};
PineStrategy.streams = {};
function PineStrategy:CreateEntrySignalV4(id)
    local signal = {};
    if self.streams["entry_signal" .. id] == nil then
        self.streams["entry_signal" .. id] = instance:addStream("entry_signal" .. id, core.Line, "Entry Signal " .. id, "Entry Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream = self.streams["entry_signal" .. id];
    function signal:Execute(period, id, long, qty, limit, stop, oca_name, oca_type, comment, when, alert_message)
        if when then
            self.stream[period] = long and 1 or -1;
        end
    end
    return signal;
end
function PineStrategy:CreateEntrySignalV5(id)
    local signal = {};
    if self.streams["entry_signal" .. id] == nil then
        self.streams["entry_signal" .. id] = instance:addStream("entry_signal" .. id, core.Line, "Entry Signal " .. id, "Entry Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream = self.streams["entry_signal" .. id];
    function signal:Execute(period, id, long, qty, limit, stop, oca_name, oca_type, comment, when, alert_message)
        if when then
            self.stream[period] = long and 1 or -1;
        end
    end
    return signal;
end
function PineStrategy:CreateCloseSignalV4(id)
    local signal = {};
    if self.streams["close_signal" .. id] == nil then
        self.streams["close_signal" .. id] = instance:addStream("close_signal" .. id, core.Line, "Close Signal " .. id, "Close Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream = self.streams["close_signal" .. id];
    function signal:Execute(period, id, when, qty, qty_percent, comment, alert_message)
        if when then
            self.stream[period] = 1;
        end
    end
    return signal;
end
function PineStrategy:CreateCloseSignalV5(id)
    local signal = {};
    if self.streams["close_signal" .. id] == nil then
        self.streams["close_signal" .. id] = instance:addStream("close_signal" .. id, core.Line, "Close Signal " .. id, "Close Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream = self.streams["close_signal" .. id];
    function signal:Execute(period, id, comment, qty, qty_percent, alert_message, immediately, disable_alert)
        if immediately then
            self.stream[period] = long and 1 or -1;
        end
    end
    return signal;
end
function PineStrategy:CreateExitSignalV4(id)
    local signal = {};
    local stream_id_1 = "exit_signal" .. id .. "_tp";
    local stream_id_2 = "exit_signal" .. id .. "_sl";
    if self.streams[stream_id_1] == nil then
        self.streams[stream_id_1] = instance:addStream(stream_id_1, core.Line, "TP Signal " .. id, "TP Signal " .. id, core.colors().Red, 0, 0);
        self.streams[stream_id_2] = instance:addStream(stream_id_2, core.Line, "SL Signal " .. id, "SL Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream_tp = self.streams[stream_id_1];
    signal.stream_sl = self.streams[stream_id_2];
    function signal:Execute(period, id, from_entry, qty, qty_percent, profit, limit, loss, stop, trail_price, trail_points, trail_offset, oca_name, comment, when, alert_message)
        if when then
            self.stream_sl[period] = limit;
            self.stream_tp[period] = stop;
        end
    end
    return signal;
end
function PineStrategy:CreateExitSignalV5(id)
    local signal = {};
    local stream_id_1 = "exit_signal" .. id .. "_tp";
    local stream_id_2 = "exit_signal" .. id .. "_sl";
    if self.streams[stream_id_1] == nil then
        self.streams[stream_id_1] = instance:addStream(stream_id_1, core.Line, "TP Signal " .. id, "TP Signal " .. id, core.colors().Red, 0, 0);
        self.streams[stream_id_2] = instance:addStream(stream_id_2, core.Line, "SL Signal " .. id, "SL Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream_tp = self.streams[stream_id_1];
    signal.stream_sl = self.streams[stream_id_2];
    function signal:Execute(period, id, from_entry, qty, qty_percent, profit, limit, loss, stop, trail_price, trail_points, trail_offset, oca_name, comment, 
            comment_profit, comment_loss, comment_trailing, alert_message, alert_profit, alert_loss, alert_trailing, disable_alert)
        self.stream_sl[period] = limit;
        self.stream_tp[period] = stop;
    end
    return signal;
end
function PineStrategy:EntryV4(id, long, qty, limit, stop, oca_name, oca_type, comment, when, alert_message)
    if not when then
        return;
    end
    core.host:trace(alert_message or id);
end
function PineStrategy:EntryV5(id, direction, qty, limit, stop, oca_name, oca_type, comment, when, alert_message)
    if not when then
        return;
    end
    core.host:trace(alert_message or id);
end
function PineStrategy:CloseV4(id, when, qty, qty_percent, comment, alert_message)
    if not when then
        return;
    end
    core.host:trace(alert_message or id);
end
function PineStrategy:CloseV5(id, comment, qty, qty_percent, alert_message, immediately, disable_alert)
    if disable_alert == true then
        return;
    end
    core.host:trace(alert_message or id);
end
function PineStrategy:Equity(account)
    local accounts = core.host:findTable("accounts");
    if account == nil then
        local enum = accounts:enumerator();
        local row = enum:next();
        while row ~= nil do
            return row.Equity;
        end
        return 0;
    end
    return accounts:find("AccountID", account).Equity;
end
function PineStrategy:PositionSize(symbol)
    local enum = core.host:findTable("trades"):enumerator();
    local row = enum:next();
    local total = 0;
    while row ~= nil do
        if row.Instrument == symbol then
            if row.BS == "B" then
                total = total + row.Lot;
            else
                total = total - row.Lot;
            end
        end
        row = enum:next();
    end
    return total;
end
function PineStrategy:PositionAvgPrice(symbol)
    return 0;
end