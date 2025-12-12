Time = {};
function Time:DayOfWeek(source, period)
    local d = core.dateToTable(source:date(period));
    return d.wday - 1;
end