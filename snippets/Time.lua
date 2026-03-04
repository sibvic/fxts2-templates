Time = {};
function Time:DayOfWeek(source, period)
    local d = core.dateToTable(source:date(period));
    return d.wday - 1;
end
function Time:Monday(source, period)
    return 1;  -- Monday is represented as 1 in Lua's date table
end
function Time:Tuesday(source, period)
    return 2;  -- Tuesday is represented as 2 in Lua's date table
end
function Time:Wednesday(source, period)
    return 3;  -- Wednesday is represented as 3 in Lua's date table
end
function Time:Thursday(source, period)
    return 4;  -- Thursday is represented as 4 in Lua's date table
end
function Time:Friday(source, period)
    return 5;  -- Friday is represented as 5 in Lua's date table
end
function Time:Saturday(source, period)
    return 6;  -- Saturday is represented as 6 in Lua's date table
end
function Time:Sunday(source, period)
    return 0;  -- Sunday is represented as 0 in Lua's date table
end