Linefill = {};
Linefill.AllLinefills = {};
function Linefill:Clear()
    Linefill.AllLinefills = {};
end
function Linefill:SetColor(Linefill, clr)
    if Linefill == nil then
        return;
    end
    Linefill:SetColor(clr);
end
function Linefill:New(line1, line2)
    for i, fill in ipairs(Linefill.AllLinefills) do
        if fill.Line1 == line1 and fill.Line2 == line2 then
            return fill;
        end
    end
    local newLinefill = {};
    newLinefill.Line1 = line1;
    newLinefill.Line2 = line2;
    newLinefill.Color = core.colors().Blue;
    function newLinefill:SetColor(clr, transparency)
        self.Color = clr;
        self.ColorTransparency = transparency and transparency or (math.floor(clr / 16777216) % 255);
        self.PenId = nil;
        self.BrushId = nil;
    end
    function newLinefill:Draw(stage, context)
        if self.Line1 == nil or self.Line2 == nil then
            return;
        end
        if self.PenId == nil then
            self.PenId = Graphics:FindPen(1, self.Color, core.LINE_SOLID, context);
        end
        if self.BrushId == nil then
            self.BrushId = Graphics:FindBrush(self.Color, context);
        end
        
        local points = context:createPoints();
        _, y1 = context:pointOfPrice(self.Line1:GetY1());
        _, x1 = context:positionOfBar(self.Line1:GetX1());
        _, y2 = context:pointOfPrice(self.Line1:GetY2());
        _, x2 = context:positionOfBar(self.Line1:GetX2());
        points:add(x1, y1);
        points:add(x2, y2);
        _, y1 = context:pointOfPrice(self.Line2:GetY1());
        _, x1 = context:positionOfBar(self.Line2:GetX1());
        _, y2 = context:pointOfPrice(self.Line2:GetY2());
        _, x2 = context:positionOfBar(self.Line2:GetX2());
        points:add(x2, y2);
        points:add(x1, y1);
        context:drawPolygon(self.PenId, self.BrushId, points, self.ColorTransparency);
    end
    self.AllLinefills[#self.AllLinefills + 1] = newLinefill;
    return newLinefill;
end
function Linefill:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    for i, value in ipairs(self.AllLinefills) do
        value:Draw(stage, context);
    end
end