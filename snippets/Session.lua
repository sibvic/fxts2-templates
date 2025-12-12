Session = {};

function Session:IsFirstBarRegular(source, period)
    if period <= 0 then
        return false;
    end
    tradingWeekOffset = core.host:execute("getTradingWeekOffset");
    tradingDayOffset = core.host:execute("getTradingDayOffset");
    local currentDate = core.getcandle("D1", source:date(period), tradingDayOffset, tradingWeekOffset);
    local prevDate = core.getcandle("D1", source:date(period - 1), tradingDayOffset, tradingWeekOffset);
    return currentDate ~= prevDate;
end