PlotShape = {};
function PlotShape:SetValue(plot, period, source, value, text, label, location, color)
    local clr, transp = Graphics:SplitColorAndTransparency(color);
    if not value or transp == 100 then
        plot:setNoData(period);
        return;
    end
    if location == "abovebar" or location == "top" then
        plot:set(period, source.high[period], text, label, clr);
        return;
    end
    if location == "belowbar" or location == "bottom" then
        plot:set(period, source.low[period], text, label, clr);
        return;
    end
    plot:set(period, value, text, label, clr);
end