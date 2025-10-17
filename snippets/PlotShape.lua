PlotShape = {};
function PlotShape:SetValue(plot, period, source, value, text, label, location, color)
    local clr, transp = Graphics:SplitColorAndTransparency(color);
    if not value or transp == 100 then
        plot:setNoData(period);
        return;
    end
    if location == "abovebar" or location == "top" then
        plot:set(period, source.high[period], text, label);
        if clr ~= nil then
            plot:setColor(period, clr);
        end
        return;
    end
    if location == "belowbar" or location == "bottom" then
        plot:set(period, source.low[period], text, label);
        if clr ~= nil then
            plot:setColor(period, clr);
        end
        return;
    end
    plot:set(period, value, text, label);
    if clr ~= nil then
        plot:setColor(period, clr);
    end
end