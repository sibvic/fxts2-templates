PolyLine = {};
PolyLine.AllLines = {};
function PolyLine:GetAll()
    local array = Array:New();
    array.arr = PolyLine.AllLines;
    return array;
end
function PolyLine:Clear()
    PolyLine.AllLines = {};
end
function PolyLine:Prepare(max_lines_count)
    PolyLine.max_lines_count = max_lines_count;
end
function PolyLine:SetLineColor(line, clr)
    if line == nil then
        return;
    end
    line:SetLineColor(clr);
end
function PolyLine:SetFillColor(line, clr)
    if line == nil then
        return;
    end
    line:SetFillColor(clr);
end
function PolyLine:SetLineStyle(line, style)
    if line == nil then
        return;
    end
    line:SetLineStyle(style);
end
function PolyLine:SetLineWidth(line, width)
    if line == nil then
        return;
    end
    line:SetLineWidth(width);
end
function PolyLine:SetCurved(line, curved)
    if line == nil then
        return;
    end
    line:SetCurved(curved);
end
function PolyLine:SetClosed(line, closed)
    if line == nil then
        return;
    end
    line:SetClosed(closed);
end
function PolyLine:SetXLocInit(line, xloc)
    if line == nil then
        return;
    end
    line:SetXLocInit(xloc);
end
function PolyLine:SetForceOverlay(line, force)
    if line == nil then
        return;
    end
    line:SetForceOverlay(force);
end
function PolyLine:Copy(line)
    if line == nil then
        return nil;
    end
    local newLine = PolyLine:New();
    newLine.XLoc = line.XLoc;
    newLine.Color = line.Color;
    newLine.ColorTransparency = line.ColorTransparency;
    newLine.FillColor = line.FillColor;
    newLine.FillColorTransparency = line.FillColorTransparency;
    newLine.Width = line.Width;
    newLine.Style = line.Style;
    newLine.Curved = line.Curved;
    newLine.Closed = line.Closed;
    newLine.ForceOverlay = line.ForceOverlay;
    newLine.X1 = line.X1;
    newLine.Y1 = line.Y1;
    newLine.X2 = line.X2;
    newLine.Y2 = line.Y2;
    newLine.Extend = line.Extend;
    if line.Points ~= nil then
        newLine.Points = Array:New();
        for i = 0, line.Points:Size() - 1 do
            local p = line.Points:Get(i);
            newLine.Points:Push({ t = p.t, x = p.x, y = p.y });
        end
    else
        newLine.Points = nil;
    end
    return newLine;
end
function PolyLine:New(points)
    local newLine = {};
    newLine.Points = nil;
    if points ~= nil then
        local enum = points.ToEnum and Array:Enum(points) or points;
        if enum ~= nil and #enum > 0 then
            newLine.Points = Array:New();
            for i = 1, #enum do
                local p = enum[i];
                newLine.Points:Push({ t = p.t, x = p.x, y = p.y });
            end
        end
    end
    newLine.XLoc = "bar_index";
    newLine.Color = core.colors().Blue;
    newLine.ColorTransparency = 0;
    newLine.FillColor = nil;
    newLine.FillColorTransparency = nil;
    newLine.Width = 1;
    newLine.Style = "solid";
    newLine.Curved = false;
    newLine.Closed = false;
    newLine.ForceOverlay = false;
    newLine.Extend = "none";
    function newLine:SetLineColor(clr)
        self.ColorTransparency = (math.floor(clr / 16777216) % 255);
        self.Color = clr - self.ColorTransparency * 16777216;
        self.PenId = nil;
        return self;
    end
    function newLine:SetFillColor(clr)
        if clr == nil then
            self.FillColor = nil;
            self.FillColorTransparency = nil;
        else
            self.FillColorTransparency = (math.floor(clr / 16777216) % 255);
            self.FillColor = clr - self.FillColorTransparency * 16777216;
        end
        self.BrushId = nil;
        return self;
    end
    function newLine:SetLineStyle(style)
        self.Style = style;
        self.PenId = nil;
        return self;
    end
    function newLine:SetLineWidth(width)
        self.Width = width;
        self.PenId = nil;
        return self;
    end
    function newLine:SetCurved(curved)
        self.Curved = curved;
        return self;
    end
    function newLine:SetClosed(closed)
        self.Closed = closed;
        return self;
    end
    function newLine:SetXLocInit(xloc)
        self.XLoc = xloc;
        return self;
    end
    function newLine:SetForceOverlay(force)
        self.ForceOverlay = force;
        return self;
    end
    function newLine:getStyleForContext()
        if self.Style == "solid" or self.Style == "arrow_left" or self.Style == "arrow_both" or self.Style == "arrow_right" then
            return core.LINE_SOLID;
        elseif self.Style == "dotted" then
            return core.LINE_DOT;
        elseif self.Style == "dashed" then
            return core.LINE_DASH;
        end
        return core.LINE_SOLID;
    end
    function newLine:converXToPoints(context, x)
        if self.XLoc == "bar_time" then
            return context:positionOfDate(x / 86400000);
        end
        local _, x1 = context:positionOfBar(x);
        return x1;
    end
    function newLine:chartPointToScreen(context, cp)
        local px;
        if self.XLoc == "bar_time" then
            _, px = context:positionOfDate(ToIndicoreTime(cp.t));
        else
            px = self:converXToPoints(context, cp.x);
        end
        local _, py = context:pointOfPrice(cp.y);
        return px, py;
    end
    function newLine:Draw(stage, context)
        if self.Width == nil then
            return;
        end
        if self.PenId == nil then
            self.PenId = Graphics:FindPen(self.Width, self.Color, self:getStyleForContext(), context);
        end
        if self.Points ~= nil and self.Points:Size() >= 2 then
            local n = self.Points:Size();
            local x0, y0 = self:chartPointToScreen(context, self.Points:Get(0));
            local x_last, y_last = x0, y0;
            for i = 1, n - 1 do
                local x2, y2 = self:chartPointToScreen(context, self.Points:Get(i));
                context:drawLine(self.PenId, x_last, y_last, x2, y2, self.ColorTransparency);
                x_last, y_last = x2, y2;
            end
            if self.Closed and n >= 3 then
                context:drawLine(self.PenId, x_last, y_last, x0, y0, self.ColorTransparency);
            end
            return;
        end
    end
    PolyLine:AddNewLine(newLine);
    return newLine;
end
function PolyLine:AddNewLine(newLine)
    self.AllLines[#self.AllLines + 1] = newLine;
    if #self.AllLines > self.max_lines_count then
        table.remove(self.AllLines, 1);
    end
end
function PolyLine:Delete(line)
    for i = 1, #self.AllLines do
        if self.AllLines[i] == line then
            table.remove(self.AllLines, i);
            return;
        end
    end
end
function PolyLine:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    for i, value in ipairs(self.AllLines) do
        value:Draw(stage, context);
    end
end
