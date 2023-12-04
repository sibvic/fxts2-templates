Line = {};
Line.AllLines = {};
function Line:Clear()
    Line.AllLines = {};
end
function Line:SetXY1(line, x, y)
    if line == nil then
        return;
    end
    line:SetXY1(x, y);
end
function Line:SetXY2(line, x, y)
    if line == nil then
        return;
    end
    line:SetXY2(x, y);
end
function Line:SetX1(line, x)
    if line == nil then
        return;
    end
    line:SetX1(x);
end
function Line:SetX2(line, x)
    if line == nil then
        return;
    end
    line:SetX2(x);
end
function Line:SetY1(line, y)
    if line == nil then
        return;
    end
    line:SetY1(y);
end
function Line:SetY2(line, y)
    if line == nil then
        return;
    end
    line:SetY2(y);
end
function Line:SetColor(line, clr)
    if line == nil then
        return;
    end
    line:SetColor(clr);
end
function Line:SetWidth(line, width)
    if line == nil then
        return;
    end
    line:SetWidth(width);
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
    function newLine:SetX1(x)
        self.X1 = x;
    end
    function newLine:SetX2(x)
        self.X2 = x;
    end
    function newLine:SetY1(y)
        self.Y1 = y;
    end
    function newLine:SetY2(y)
        self.Y2 = y;
    end
    newLine.Color = core.colors().Blue;
    function newLine:SetColor(clr)
        self.Color = clr;
        self.PenValid = false;
    end
    newLine.Width = 1;
    function newLine:SetWidth(width)
        self.Width = width;
        self.PenValid = false;
    end
    function newLine:Draw(stage, context)
        if self.Y1 == nil or self.Y2 == nil then
            return;
        end
        if not self.PenValid then
            self.PenId = Graphics:FindPen(self.Width, self.Color, core.LINE_SOLID, context);
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
function Line:Delete(line)
    for i = 1, #self.AllLines do
        if self.AllLines[i] == line then
            table.remove(self.AllLines, i);
            return;
        end
    end
end
function Line:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    for i, value in ipairs(self.AllLines) do
        value:Draw(stage, context);
    end
end