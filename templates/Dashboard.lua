-- Dashboard template v.1.1

local timeframes_list = {"m1", "m5", "m15", "m30", "H1", "H2", "H3", "H4", "H6", "H8", "D1", "W1", "M1"};
local Modules = {};

-- USER DEFINITIONS SECTION
local indi_name = "Williams's Highs and Lows Dashboard";
local indi_id = "DOUBLE OBOS INDICATOR WITH CCI FILTER";
local indi_version = "1";

function CreateIndicator(source)
    local indi = core.indicators:findIndicator(indi_id);
    assert(indi ~= nil, "Please download and install " .. indi_id .. ".lua indicator");
    local p = indi:parameters();
    p:setBoolean("UpDown", true);
    p:setBoolean("Show1", instance.parameters.Show1);
    p:setBoolean("Show2", instance.parameters.Show2);
    p:setInteger("PERIOD1", instance.parameters.PERIOD1);
    p:setInteger("PERIOD2", instance.parameters.PERIOD2);
    p:setInteger("Lookback", instance.parameters.Lookback);
    p:setInteger("TradeLength", instance.parameters.TradeLength);
    p:setInteger("OB_level", instance.parameters.OB_level);
    p:setInteger("OS_level", instance.parameters.OS_level);
    p:setBoolean("UseFilter", instance.parameters.UseFilter);
    p:setInteger("CCIPeriod", instance.parameters.CCIPeriod);
    p:setInteger("CCILookback", instance.parameters.CCILookback);
    p:setDouble("BuyLevel", instance.parameters.BuyLevel);
    p:setDouble("SellLevel", instance.parameters.SellLevel);
    p:setBoolean("show_output", true);
    return indi:createInstance(source, p);
end

function CreateParameters()
end

function GetLastSignal(indi, source)
    local up = indi:getTextOutput(0);
    local down = indi:getTextOutput(1);
    for i = 0, up:size() - 1 do
        if up:hasData(NOW - i) then
            return 1, source:date(NOW - i);
        end
        if down:hasData(NOW - i) then
            return -1, source:date(NOW - i);
        end
    end
    return 0;
end
-- ENF OF USER DEFINITIONS SECTION

function Init()
    indicator:name(indi_name .. " v." .. indi_version);
    indicator:description("");
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("Version", indi_version)

    CreateParameters();

    indicator.parameters:addGroup("Instruments");
    indicator.parameters:addBoolean("all_instruments", "All instruments", "", true);
    for i = 1, 20, 1 do
        Add(i);
    end
    
    indicator.parameters:addGroup("Time Frame Selector");
    for i = 1, #timeframes_list do
        AddTimeFrame(i, timeframes_list[i], true);
    end

    indicator.parameters:addColor("up_color", "Up color", "", core.rgb(0, 255, 0));
    indicator.parameters:addColor("dn_color", "Down color", "", core.rgb(255, 0, 0));
    indicator.parameters:addColor("text_color", "Text color", "", core.rgb(0, 0, 0));
    indicator.parameters:addColor("background_color", "Background color", "", core.rgb(255, 255, 255));
    indicator.parameters:addColor("signal_background_color", "Active signal background color", "", core.rgb(250, 250, 210));
    signaler:Init(indicator.parameters);
end

function Add(id)
    local Init = {"EUR/USD", "USD/JPY", "GBP/USD", "USD/CHF", "EUR/CHF"
                , "AUD/USD", "USD/CAD", "NZD/USD", "EUR/GBP", "EUR/JPY"
                , "GBP/JPY", "CHF/JPY", "GBP/CHF", "EUR/AUD", "EUR/CAD"
                , "AUD/CAD", "AUD/JPY", "CAD/JPY", "NZD/JPY", "GBP/CAD"
            };
    indicator.parameters:addBoolean("use_pair" .. id, "Use This Slot", "", id <= 5);
    indicator.parameters:addString("Pair" .. id, "Pair", "", Init[id]);
    indicator.parameters:setFlag("Pair" .. id, core.FLAG_INSTRUMENTS);
end

function AddTimeFrame(id, FRAME, DEFAULT)
    indicator.parameters:addBoolean("Use" .. id, "Show " .. FRAME, "", DEFAULT); 
end

local symbols = {};
local instruments = {};
local timeframes = {};

local text_color;
local TIMER_ID = 1;
local last_id = 1;

function PrepareInstrument(instrument)
    local timeframe_index = 1;
    for ii = 1, #timeframes_list do
        use = instance.parameters:getBoolean("Use" .. ii);
        if use then
            local symbol = {};
            symbol.Pair = instrument;
            symbol.Point = core.host:findTable("offers"):find("Instrument", symbol.Pair).PointSize;
            symbol.TF = timeframes_list[ii];
            symbol.LoadingId = last_id + 1;
            symbol.LoadedId = last_id + 2;
            symbol.Loading = true;
            symbol.SymbolIndex = #instruments + 1;
            symbol.TimeframeIndex = timeframe_index;
            function symbol:DoLoad()
                self.Source = core.host:execute("getSyncHistory", self.Pair, self.TF, instance.source:isBid(), 300, self.LoadedId, self.LoadingId);
                self.Indicator = CreateIndicator(self.Source);
                assert(self.Indicator:getTextOutputCount() > 0, "Selected indicator doesn't have any text outputs. The dashboard works with text outputs only!");
            end
            last_id = last_id + 2;
            symbols[#symbols + 1] = symbol;
            timeframes[timeframe_index] = timeframes_list[ii];
            timeframe_index = timeframe_index + 1;
        end
    end
    instruments[#instruments + 1] = instrument;
end

local timer_handle;

function Prepare(nameOnly)
    signaler:Prepare(nameOnly);
    instance:name(indi_name);
    if nameOnly then
        return;
    end
    text_color = instance.parameters.text_color;

    if instance.parameters.all_instruments then
        local enum = core.host:findTable("offers"):enumerator();
        local row = enum:next();
        while (row ~= nil) do
            PrepareInstrument(row.Instrument);
            row = enum:next();
        end
    else
        for i = 1, 20, 1 do
            if instance.parameters:getBoolean("use_pair" .. i) then
                PrepareInstrument(instance.parameters:getString("Pair" .. i));
            end
        end
    end
    timer_handle = core.host:execute("setTimer", TIMER_ID, 1);
    core.host:execute("setStatus", "Loading");
    instance:ownerDrawn(true);
end

-- Cells builder v.1.3
local CellsBuilder = {};
CellsBuilder.GapCoeff = 1.2;
function CellsBuilder:Clear(context)
    self.Columns = {};
    self.RowHeights = {};
    self.Context = context;
end
function CellsBuilder:Add(font, text, color, column, row, mode, backgound)
    if self.Columns[column] == nil then
        self.Columns[column] = {};
        self.Columns[column].Rows = {};
        self.Columns[column].MaxWidth = 0;
        self.Columns[column].MaxHeight = 0;
        self.Columns[column].MaxRowIndex = 0;
    end
    local cell = {};
    cell.Text = text;
    cell.Font = font;
    cell.Color = color;
    local w, h = self.Context:measureText(font, text, mode);
    cell.Width = w;
    cell.Height = h;
    cell.Mode = mode;
    cell.Background = backgound;
    self.Columns[column].Rows[row] = cell;
    if self.Columns[column].MaxRowIndex < row then
        self.Columns[column].MaxRowIndex = row;
    end
    if self.Columns[column].MaxWidth < w then
        self.Columns[column].MaxWidth = w;
    end
    if self.RowHeights[row] == nil or self.RowHeights[row] < h then
        self.RowHeights[row] = h;
    end
end
function CellsBuilder:GetTotalWidth()
    local width = 0;
    for columnIndex, column in ipairs(self.Columns) do
        width = width + column.MaxWidth * self.GapCoeff;
    end
    return width;
end
function CellsBuilder:GetTotalHeight()
    local height = 0;
    for i = 0, self.Columns[1].MaxRowIndex do
        if self.RowHeights[i] ~= nil then
            height = height + self.RowHeights[i] * self.GapCoeff;
        end
    end
    return height;
end
function CellsBuilder:Draw(x, y)
    local total_width = 0;
    for columnIndex, column in ipairs(self.Columns) do
        local total_height = 0;
        for i = 0, column.MaxRowIndex do
            local cell = column.Rows[i];
            if cell ~= nil then
                local background = -1;
                if cell.Background ~= nil then
                    background = cell.Background;
                end
                self.Context:drawText(cell.Font, cell.Text, 
                    cell.Color, background, 
                    x + total_width, 
                    y + total_height, 
                    x + total_width + column.MaxWidth, 
                    y + total_height + cell.Height,
                    cell.Mode);
            end
            if self.RowHeights[i] ~= nil then
                total_height = total_height + self.RowHeights[i] * self.GapCoeff;
            end
        end
        total_width = total_width + column.MaxWidth * self.GapCoeff;
    end
end

function FormatTime(time)
    local diff = core.host:execute("getServerTime") - time;
    if (diff > 1) then
        return math.floor(diff) .. " d.";
    end
    local diff_date = core.dateToTable(diff);
    if (diff_date.hour > 0) then
        return diff_date.hour .. " h.";
    end
    if (diff_date.min > 0) then
        return diff_date.min .. " min.";
    end
    return "now";
end

local init = false;
local FONT = 1;
local FONT_TEXT = 2;
local BG_PEN = 3;
local BG_BRUSH = 4;
function Draw(stage, context) 
    if stage ~= 2 then
        return;
    end
    if not init then
        context:createFont(FONT, "Wingdings", 0, context:pointsToPixels(8), 0)
        context:createFont(FONT_TEXT, "Arial", 0, context:pointsToPixels(8), 0)
        context:createPen(BG_PEN, context.SOLID, 1, instance.parameters.background_color);
        context:createSolidBrush(BG_BRUSH, instance.parameters.background_color);
        init = true;
    end
    local title_w, title_h = context:measureText(FONT_TEXT, indi_name, 0);
    CellsBuilder:Clear(context);
    for i = 1, #timeframes do
        CellsBuilder:Add(FONT_TEXT, timeframes[i], text_color, 1, (i + 1) * 2, context.LEFT);
    end
    for i = 1, #instruments do
        CellsBuilder:Add(FONT_TEXT, instruments[i], text_color, i + 1, 1, context.CENTER);
    end
    for _, symbol in ipairs(symbols) do
        if not symbol.Loading then
            if symbol.Updated == nil then
                symbol.Indicator:update(core.UpdateLast);
                symbol.Updated = true;
            end
            local signal, time = GetLastSignal(symbol.Indicator, symbol.Source);
            local row = (symbol.TimeframeIndex + 1) * 2;
            local column = symbol.SymbolIndex + 1;
            if signal == 0 then
                CellsBuilder:Add(FONT_TEXT, "-", text_color, column, row, context.CENTER);
                CellsBuilder:Add(FONT_TEXT, "-", text_color, column, row + 1, context.CENTER);
            elseif signal == 1 then
                local is_current_bar = symbol.Source:date(NOW) <= time;
                local backgound = -1;
                if is_current_bar then
                    backgound = instance.parameters.signal_background_color;
                end
                CellsBuilder:Add(FONT, "\233", instance.parameters.up_color, column, row, context.CENTER, backgound);
                CellsBuilder:Add(FONT_TEXT, FormatTime(time), text_color, column, row + 1, context.CENTER);
                if is_current_bar and symbol.last_alert ~= time then
                    signaler:Signal(symbol.Pair .. ", " .. symbol.TF .. ": Open Long");
                    symbol.last_alert = time;
                end
            else
                local is_current_bar = symbol.Source:date(NOW) <= time;
                local backgound = -1;
                if is_current_bar then
                    backgound = instance.parameters.signal_background_color;
                end
                CellsBuilder:Add(FONT, "\234", instance.parameters.dn_color, column, row, context.CENTER, backgound);
                CellsBuilder:Add(FONT_TEXT, FormatTime(time), text_color, column, row + 1, context.CENTER);
                if is_current_bar and symbol.last_alert ~= time then
                    signaler:Signal(symbol.Pair .. ", " .. symbol.TF .. ": Open Short");
                    symbol.last_alert = time;
                end
            end
        end
    end
    local width = math.max(title_w, CellsBuilder:GetTotalWidth());
    context:drawRectangle(BG_PEN, BG_BRUSH, context:right() - width, context:top(), context:right(), context:top() + title_h * 1.2 + CellsBuilder:GetTotalHeight());
    context:drawText(FONT_TEXT, indi_name, text_color, -1, context:right() - width, context:top(), context:right(), context:top() + title_h, 0);
    CellsBuilder:Draw(context:right() - width, context:top() + title_h * 1.2);
end

function Update(period, mode)
    for _, module in pairs(Modules) do if module.ExtUpdate ~= nil then module:ExtUpdate(nil, nil, nil); end end
    for _, symbol in ipairs(symbols) do
        if symbol.Indicator ~= nil then
            symbol.Indicator:update(core.UpdateLast);
        end
    end
end

local MAX_LOADING = 10;

function AsyncOperationFinished(cookie, success, message, message1, message2)
    for _, module in pairs(Modules) do if module.AsyncOperationFinished ~= nil then module:AsyncOperationFinished(cookie, success, message, message1, message2); end end
    if cookie == TIMER_ID then
        local loading_count = 0;
        for _, symbol in ipairs(symbols) do
            if symbol.Source == nil then
                symbol:DoLoad();
                loading_count = loading_count + 1;
            elseif symbol.Loading then
                loading_count = loading_count + 1;
            end
            if loading_count == MAX_LOADING then
                return;
            end
        end
        core.host:execute("setStatus", "");
        core.host:execute("killTimer", timer_handle);
    else
        for _, symbol in ipairs(symbols) do
            if cookie == symbol.LoadingId then
                symbol.Loading = true;
                return;
            elseif cookie == symbol.LoadedId then
                symbol.Loading = false;
                return;
            end
        end
    end
end
