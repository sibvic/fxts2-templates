Chart = {};
function Chart:SetLeftVisibleBar(index)
    self.leftVisibleBar = index;
end
function Chart:SetRightVisibleBar(index)
    self.rightVisibleBar = index;
end
local function timeOfBar(source, index, fallback)
    local first = source:first();
    local last = source:size() - 1;
    if index == nil then
        index = fallback;
    end
    if index == nil or index < first then
        index = first;
    end
    if index > last then
        index = last;
    end
    if index < first then
        return nil;
    end
    return source:date(index) * 86400000;
end
function Chart:LeftVisibleBarTime(source)
    return timeOfBar(source, self.leftVisibleBar, source:first());
end
function Chart:RightVisibleBarTime(source)
    return timeOfBar(source, self.rightVisibleBar, source:size() - 1);
end
