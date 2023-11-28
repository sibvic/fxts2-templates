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
    function newTable:getRowDirection()
        if self.position == "top_left" or self.position == "top_right" or self.position == "top_middle" then
            return 1;
        end
        if self.position == "bottom_left" or self.position == "bottom_right" or self.position == "bottom_middle" then
            return -1;
        end
        return 0;
    end
    function newTable:getColumnDirection()
        if self.position == "top_left" or self.position == "bottom_left" or self.position == "middle_left" then
            return 1;
        end
        if self.position == "top_right" or self.position == "bottom_right" or self.position == "middle_right" then
            return -1;
        end
        return 0;
    end
    function newTable:measureCells(context)
        local columnWidths = {};
        local rowHeights = {};
        local cellSizes = {};
        for row = 1, #self.rows do
            cellSizes[row] = {};
            for column = 1, #self.rows[row] do
                local W, H = context:measureText(Table.FontId, self.rows[row][column].text, context.LEFT);
                if columnWidths[column] == nil or columnWidths[column] < W then
                    columnWidths[column] = W;
                end
                if rowHeights[row] == nil or rowHeights[row] < H then
                    rowHeights[row] = H;
                end
                cellSizes[row][column] = {};
                cellSizes[row][column].H = H;
                cellSizes[row][column].W = W;
            end
        end
        return rowHeights, columnWidths, cellSizes;
    end
    function newTable:Draw(stage, context)
        if self.bgcolor ~= nil and self.BgBrushId == nil then
            self.BgBrushId = Graphics:FindBrush(self.bgcolor, context);
        end
        if self.FramePenId == nil then
            self.FramePenId = Graphics:FindPen(self.border_width, self.border_color, self.border_style, context);
        end
        local rowHeights, columnWidths, cellSizes = self:measureCells(context);
        
        local rowDirection = self:getRowDirection();
        local columnDirection = self:getColumnDirection();
        local yStart = rowDirection == 1 and context:top() or context:bottom();
        local totalRows = #self.rows;
        for rowIt = 1, totalRows do
            local row = rowIt;
            if rowDirection == -1 then
                row = totalRows - rowIt + 1;
            end
            local xStart = columnDirection == 1 and context:left() or context:right(); 
            local totalCoumns = #self.rows[rowIt];
            for columnIt = 1, totalCoumns do
                local column = columnIt;
                if columnDirection == -1 then
                    column = totalCoumns - columnIt + 1;
                end

                local rectangle_x1;
                local rectangle_x2;
                local rectangle_y1;
                local rectangle_y2;
                if rowDirection == -1 then
                    rectangle_y1 = yStart - rowHeights[row];
                    rectangle_y2 = yStart;
                elseif rowDirection == 1 then
                    rectangle_y1 = yStart;
                    rectangle_y2 = yStart + rowHeights[row];
                end
                if columnDirection == -1 then
                    rectangle_x1 = xStart - columnWidths[column];
                    rectangle_x2 = xStart;
                    xStart = rectangle_x1;
                elseif columnDirection == 1 then
                    rectangle_x1 = xStart;
                    rectangle_x2 = xStart + columnWidths[column];
                    xStart = rectangle_x2;
                end
                local x = (rectangle_x1 + rectangle_x2) / 2;
                local text_x1 = x - cellSizes[row][column].W / 2;
                local text_x2 = text_x1 + cellSizes[row][column].W;
                local y = (rectangle_y1 + rectangle_y2) / 2;
                local text_y1 = y - cellSizes[row][column].H / 2;
                local text_y2 = y + cellSizes[row][column].H;
                if self.BgBrushId ~= nil then
                    context:drawRectangle(self.FramePenId, self.BgBrushId, rectangle_x1, rectangle_y1, rectangle_x2, rectangle_y2)
                end
                context:drawText(Table.FontId, self.rows[row][column].text, self.rows[row][column].text_color, -1, 
                    text_x1, text_y1, text_x2, text_y2, 0);
            end
            if rowDirection == -1 then
                yStart = yStart - rowHeights[row];
            elseif rowDirection == 1 then
                yStart = yStart + rowHeights[row];
            end
        end
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