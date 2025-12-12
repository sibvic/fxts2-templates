Plot = {};
function Plot:SetValueWithColor(plot, period, value, color)
    if period < 0 then
        return;
    end
    local clr, transp = Graphics:SplitColorAndTransparency(color);
    if transp == 100 or clr == nil then
        plot:setNoData(period);
        return nil;
    end
    if Plot:SetValue(plot, period, value) then
        plot:setColor(period, clr)
    end
end
function Plot:SetValue(plot, period, value)
    if period < 0 then
        return;
    end
    local clr, transp = Graphics:SplitColorAndTransparency(color);
    if not value then
        plot:setNoData(period);
        return false;
    end
    plot[period] = value;
    return true;
end