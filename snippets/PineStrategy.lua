PineStrategy = {};
PineStrategy.streams = {};
function PineStrategy:CreateEntrySignalV4(id)
    local signal = {};
    if self.streams["entry_signal" .. id] == nil then
        self.streams["entry_signal" .. id] = instance:addStream("entry_signal" .. id, core.Line, "Entry Signal Entry " .. id, "Entry Signal " .. id, core.colors().Red, 0, 0);
    end
    signal.stream = self.streams["entry_signal" .. id];
    function signal:Execute(period, id, long, qty, limit, stop, oca_name, oca_type, comment, when, alert_message)
        if when then
            self.stream[period] = long and 1 or -1;
        end
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
function PineStrategy:CreateCloseSignalV4(id)
    local signal = {};
    if self.streams["close_signal" .. id] == nil then
        self.streams["close_signal" .. id] = instance:addStream("close_signal" .. id, core.Line, "Close Signal Entry " .. id, "Close Signal " .. id, core.colors().Blue, 0, 0);
    end
    signal.stream = self.streams["close_signal" .. id];
    function signal:Execute(period, id, when, qty, qty_percent, comment, alert_message)
        if when then
            self.stream[period] = 1;
        end
    end
    return signal;
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