Timeframe = {};
function Timeframe:Period()
    local bar_size = instance.source:barSize();
    if bar_size == "t1" then
        return "t";
    elseif string.sub(bar_size, 1, 1) == "m" then
        local seconds = tonumber(string.sub(bar_size, 2));
        return tostring(seconds);
    elseif string.sub(bar_size, 1, 1) == "H" then
        local seconds = 60 * tonumber(string.sub(bar_size, 2));
        return tostring(seconds);
    elseif string.sub(bar_size, 1, 1) == "D" then
        return "D";
    elseif string.sub(bar_size, 1, 1) == "W" then
        return "D";
    elseif string.sub(bar_size, 1, 1) == "M" then
        return "M";
    end
    return "0";
end
function Timeframe:IsIntraday()
    local bar_size = instance.source:barSize();
    if bar_size == "t1" then
        return true;
    elseif string.sub(bar_size, 1, 1) == "m" then
        return true;
    elseif string.sub(bar_size, 1, 1) == "H" then
        return true;
    end
    return false;
end
function Timeframe:Interval()
    local bar_size = instance.source:barSize();
    if bar_size == "t1" then
        return "0";
    elseif string.sub(bar_size, 1, 1) == "m" then
        return tonumber(string.sub(bar_size, 2));
    elseif string.sub(bar_size, 1, 1) == "H" then
        return tonumber(string.sub(bar_size, 2));
    elseif string.sub(bar_size, 1, 1) == "D" then
        return "1";
    elseif string.sub(bar_size, 1, 1) == "W" then
        return "1";
    elseif string.sub(bar_size, 1, 1) == "M" then
        return "1";
    end
    return "0";
end
function Timeframe:InSeconds(timeframe, source)
    if timeframe == "M" then
        return 86400 * 30;
    elseif timeframe == "D" then
        return 86400;
    elseif timeframe == "t" then
        return 1;
    else
        local minutes = tonumber(timeframe);
        if minutes == nil then
            return nil;
        end
        return minutes * 60;
    end
    return nil;
end
function Timeframe:GetBarSize(timeframe)
    if timeframe == "M" then
        return "M1";
    elseif timeframe == "D" then
        return "D1";
    elseif timeframe == "t" then
        return "t1";
    else
        local minutes = tonumber(timeframe);
        if minutes == 1 then
            return "m1";
        elseif minutes == 5 then
            return "m5";
        elseif minutes == 15 then
            return "m15";
        elseif minutes == 30 then
            return "m30";
        elseif minutes == 60 then
            return "h1";
        elseif minutes == 120 then
            return "h2";
        elseif minutes == 180 then
            return "h3";
        elseif minutes == 240 then
            return "h4";
        elseif minutes == 360 then
            return "h6";
        elseif minutes == 480 then
            return "h8";
        end
    end
    return nil;
end
function Timeframe:Change(timeframe, source, period)
    if period <= 0 then
        return false;
    end
    local barSize = Timeframe:GetBarSize(timeframe);
    if barSize == nil then
        return false;
    end
    tradingWeekOffset = core.host:execute("getTradingWeekOffset");
    tradingDayOffset = core.host:execute("getTradingDayOffset");
    local currentDate = core.getcandle(barSize, source:date(period), tradingDayOffset, tradingWeekOffset);
    local prevDate = core.getcandle(barSize, source:date(period - 1), tradingDayOffset, tradingWeekOffset);
    return currentDate ~= prevDate;
end