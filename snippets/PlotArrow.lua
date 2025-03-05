PlotArrow = {};
function PlotArrow:SetValue(plot, period, value, up_color, down_color)
    if not value then
        plot:setNoData(period);
        return;
    end
    if value >= 0 then
        plot:set(period, value, "\225", "\225");
        plot:setColor(period, up_color);
        return;
    end
    plot:set(period, value, "\226", "\226");
    plot:setColor(period, down_color);
end