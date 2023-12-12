BGColor = {};
BGColor.AllBGColors = {};
function BGColor:Clear()
end
function BGColor:Create()
    local newBGColor = {};
    newBGColor.Items = {};
    function newBGColor:Draw(stage, context)
        for date, bar in pairs(self.Items) do
            local index = core.findDate(instance.source, date, false);
            if index ~= -1 and index >= context:firstBar() and index <= context:lastBar() then
                if bar.PenId == nil then
                    bar.PenId = Graphics:FindPen(1, bar.Color, core.LINE_SOLID, context);
                end
                if bar.BrushId == nil then
                    bar.BrushId = Graphics:FindBrush(bar.Color, context);
                end
                x, xs, xe = context:positionOfBar(index);
                context:drawRectangle(bar.PenId, bar.BrushId, xs, context:top(), xe, context:bottom(), bar.Transparency);
            end
        end
    end
    function newBGColor:Set(period, clr)
        local date = instance.source:date(period);
        if clr == nil then
            newBGColor.Items[date] = nil;
            return;
        end
        if newBGColor.Items[date] == nil then
            newBGColor.Items[date] = {};
        end
        color, transp = Graphics:SplitColorAndTransparency(clr);
        newBGColor.Items[date].Color = color;
        newBGColor.Items[date].Transparency = transp;
        newBGColor.Items[date].PenId = nil;
        newBGColor.Items[date].BrushId = nil;
    end
    self.AllBGColors[#self.AllBGColors + 1] = newBGColor
    return newBGColor;
end
function BGColor:Draw(stage, context)
    if stage ~= 0 then
        return;
    end
    for i, bgcolor in ipairs(self.AllBGColors) do
        bgcolor:Draw(stage, context);
    end
end