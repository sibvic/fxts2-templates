Line = {};
Line.AllLines = {};
Line.NextId = 10;
Line.Pens = {};
function Line:FindPen(width, color, context)
    for i, pen in ipairs(Line.Pens) do
        if pen.Width == width and pen.Color == color then
            context:createPen(pen.Id, context:convertPenStyle(core.LINE_SOLID), width, color);
            return pen.Id;
        end
    end
    local newPen = {};
    newPen.Id = Line.NextId;
    newPen.Width = width;
    newPen.Color = color;
    context:createPen(newPen.Id, context:convertPenStyle(core.LINE_SOLID), width, color);
    Line.NextId = Line.NextId + 1;
    Line.Pens[#Line.Pens + 1] = newPen;
    return newPen.Id;
end
function Line:New(x1, y1, x2, y2)
    local newLine = {};
    newLine.X1 = x1;
    newLine.Y1 = y1;
    newLine.X2 = x2;
    newLine.Y2 = y2;
    function newLine:SetXY1(x, y)
        self.X1 = x;
        self.Y1 = y;
    end
    function newLine:SetXY2(x, y)
        self.X2 = x;
        self.Y2 = y;
    end
    function newLine:SetColor(clr)
        self.Color = clr;
        self.PenValid = false;
    end
    function newLine:SetWidth(width)
        self.Width = width;
        self.PenValid = false;
    end
    function newLine:Draw(stage, context)
        if self.Y1 == nil or self.Y2 == nil then
            return;
        end
        if not self.PenValid then
            self.PenId = Line:FindPen(self.Width, self.Color, context);
            self.PenValid = true;
        end
        _, y1 = context:pointOfPrice(self.Y1);
        _, x1 = context:positionOfBar(self.X1);
        _, y2 = context:pointOfPrice(self.Y2);
        _, x2 = context:positionOfBar(self.X2);
        context:drawLine(self.PenId, x1, y1, x2, y2);
    end
    self.AllLines[#self.AllLines + 1] = newLine;
    return newLine;
end
function Line:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    for i, value in ipairs(self.AllLines) do
        value:Draw(stage, context);
    end
end