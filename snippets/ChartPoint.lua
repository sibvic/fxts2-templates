ChartPoint = {};
function ChartPoint:FromIndex(index, price)
    local point = {};
    point.x = index;
    point.y = price;
    return point;
end
function chartpoint_Getprice(chartPoint)
    if chartPoint == nil then
        return nil;
    end
    return chartPoint.y;
end
function chartpoint_Getindex(chartPoint)
    if chartPoint == nil then
        return nil;
    end
    return chartPoint.x;
end