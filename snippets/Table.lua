Table = {};
Table.AllTables = {};
function Table:Clear()
    Table.AllTables = {};
end
function Table:New(position, columns, rows)
    local newTable = {};
    newTable.position = position;
    newTable.border_width = 1;
    function newTable:SetBorderWidth(width)
        self.border_width = width;
        return self;
    end
    newTable.bgcolor = nil;
    function newTable:SetBgColor(color)
        self.bgcolor = color;
        return self;
    end
    newTable.border_color = core.colors().Gray;
    newTable.border_style = core.LINE_SOLID;
    function newTable:SetBorderColor(color)
        self.border_color = color;
        return self;
    end
    newTable.frame_color = core.colors().Gray;
    function newTable:SetFrameColor(color)
        self.frame_color = color;
        return self;
    end
    newTable.frame_width = 1;
    function newTable:SetFrameWidth(width)
        self.frame_width = width;
        return self;
    end
    newTable.rows = {};
    for i = 1, rows, 1 do
        newTable.rows[i] = {};
        for ii = 1, columns, 1 do
            local cell = {};
            cell.text = "";
            cell.text_color = core.COLOR_LABEL;
            newTable.rows[i][ii] = cell;
        end
    end
    function newTable:CellText(column, row, text)
        self.rows[row + 1][column + 1].text = text;
        return self;
    end
    function newTable:CellTextColor(column, row, color)
        self.rows[row + 1][column + 1].text_color = color;
        return self;
    end
    function newTable:GetCoordinates(context, W, H)
        if self.position == "top_left" then
            local x1 = context:left() + 5;
            local y1 = context:top() + 5;
            return x1, y1, x1 + W, y1 + H;
        elseif self.position == "top_right" then
            local x1 = context:right() - 5;
            local y1 = context:top() + 5;
            return x1 - W, y1, x1, y1 + H;
        end
    end
    function newTable:Draw(stage, context)
        if self.bgcolor ~= nil and self.BgBrushId == nil then
            self.BgBrushId = Graphics:FindBrush(self.bgcolor, context);
        end
        if self.FramePenId == nil then
            self.FramePenId = Graphics:FindPen(self.border_width, self.border_color, self.border_style, context);
        end

        local W, H = context:measureText(Table.FontId, self.rows[1][1].text, context.LEFT);
        x1, y1, x2, y2 = self:GetCoordinates(context, W, H);
        if self.BgBrushId ~= nil then
            context:drawRectangle(self.FramePenId, self.BgBrushId, x1, y1, x2, y2)
        end
        context:drawRectangle(self.FramePenId, -1, x1, y1, x2, y2)
        context:drawText(Table.FontId, self.rows[1][1].text, self.rows[1][1].text_color, -1, x1, y1, x2, y2, 0);
    end
    self.AllTables[#self.AllTables + 1] = newTable;
    return newTable;
end
function Table:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    if Table.FontId == nil then
        Table.FontId = Graphics:FindFont("Arial", 0, context:pointsToPixels(10), context.LEFT, context);
    end
    for id, table in pairs(self.AllTables) do
        table:Draw(stage, context);
    end
end