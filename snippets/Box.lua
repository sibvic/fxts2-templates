Box = {};
Box.AllBoxs = {};
function Box:Clear()
    Box.AllBoxs = {};
end
function Box:New(id, left, top, right, bottom)
    local newBox = {};
    newBox.Left = left;
    newBox.Top = top;
    newBox.Right = right;
    newBox.Bottom = bottom;
    newBox.BorderColor = core.colors().Blue;
    newBox.BgColor = core.colors().Blue;
    newBox.BorderWidth = 1;
    newBox.BorderStyle = core.LINE_SOLID;
    function newBox:SetBGColor(clr)
        self.BgColorTransparency = (math.floor(clr / 16777216) % 256);
        self.BgColor = clr - self.BgColorTransparency * 16777216;
        self.BrushId = nil;
    end
    function newBox:SetBorderColor(clr)
        self.BorderColor = clr;
        self.PenId = nil;
    end
    function newBox:Draw(stage, context)
        if self.PenId == nil then
            self.PenId = Graphics:FindPen(self.BorderWidth, self.BorderColor, self.BorderStyle, context);
        end
        if self.BrushId == nil then
            self.BrushId = Graphics:FindBrush(self.BgColor, context);
        end
        _, y1 = context:pointOfPrice(self.Top);
        _, x1 = context:positionOfBar(self.Left);
        _, y2 = context:pointOfPrice(self.Bottom);
        _, x2 = context:positionOfBar(self.Right);
        context:drawRectangle(self.PenId, self.BrushId, x1, y1, x2, y2, self.BgColorTransparency)
        context:drawRectangle(self.PenId, -1, x1, y1, x2, y2)
    end
    self.AllBoxs[id] = newBox;
    return newBox;
end
function Box:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    for id, Box in pairs(self.AllBoxs) do
        Box:Draw(stage, context);
    end
end