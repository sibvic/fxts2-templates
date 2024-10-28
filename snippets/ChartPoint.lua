ChartPoint = {};
function ChartPoint:FromIndex(index, price)
    local point = {};
    point.x = index;
    point.y = price;
    return point;
end