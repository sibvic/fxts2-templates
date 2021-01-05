-- Light dashboard template v.1.1

local Modules = {};

-- USER DEFINITIONS SECTION
local indi_name = "Dashboard";
local indi_id = "INDICATOR";
local indi_version = "1";

function CreateIndicators(source)
    local indicators = {};

    local indi = core.indicators:findIndicator(indi_id);
    assert(indi ~= nil, "Please download and install " .. indi_id .. ".lua indicator");
    local p = indi:parameters();
    p:setBoolean("UpDown", true);
    p:setInteger("PERIOD1", instance.parameters.PERIOD1);
    p:setDouble("BuyLevel", instance.parameters.BuyLevel);
    indicators[#indicators + 1] = indi:createInstance(source, p);

    return indicators;
end

function CreateParameters()
end

function GetLastSignal(indi, source)
    local up = indi:getTextOutput(0);
    local down = indi:getTextOutput(1);
    for i = 0, up:size() - 1 do
        if up:hasData(NOW - i) then
            return 1, "B";
        end
        if down:hasData(NOW - i) then
            return -1, "S";
        end
    end
    return 0, "-";
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
    indicator.parameters:addBoolean("all_instruments", "All instruments", "", false);
    for i = 1, 20, 1 do
        Add(i);
    end
    
    indicator.parameters:addGroup("Styling");
    indicator.parameters:addColor("up_color", "Up color", "", core.rgb(0, 255, 0));
    indicator.parameters:addColor("dn_color", "Down color", "", core.rgb(255, 0, 0));
    indicator.parameters:addColor("text_color", "Text color", "", core.rgb(0, 0, 0));
    indicator.parameters:addColor("background_color", "Background color", "", core.rgb(255, 255, 255));
    indicator.parameters:addColor("signal_background_color", "Active signal background color", "", core.rgb(250, 250, 210));
    indicator.parameters:addDouble("cells_gap", "Gap coefficient", "", 1.2);
    indicator.parameters:addColor("grid_color", "Grid color", "", core.rgb(128, 128, 128));
    indicator.parameters:addBoolean("draw_grid", "Draw grid", "", false);
    indicator.parameters:addString("grid_mode", "Grid mode", "", "v")
    indicator.parameters:addStringAlternative("grid_mode", "Horizontal", "", "h")
    indicator.parameters:addStringAlternative("grid_mode", "Vertical", "", "v")

    indicator.parameters:addInteger("signaler_ToTime", "Convert the date to", "", 6)
    indicator.parameters:addIntegerAlternative("signaler_ToTime", "EST", "", 1)
    indicator.parameters:addIntegerAlternative("signaler_ToTime", "UTC", "", 2)
    indicator.parameters:addIntegerAlternative("signaler_ToTime", "Local", "", 3)
    indicator.parameters:addIntegerAlternative("signaler_ToTime", "Server", "", 4)
    indicator.parameters:addIntegerAlternative("signaler_ToTime", "Financial", "", 5)
    indicator.parameters:addIntegerAlternative("signaler_ToTime", "Display", "", 6)
    
    indicator.parameters:addBoolean("signaler_show_alert", "Show Alert", "", true);
    indicator.parameters:addBoolean("signaler_play_sound", "Play Sound", "", false);
    indicator.parameters:addFile("signaler_sound_file", "Sound File", "", "");
    indicator.parameters:setFlag("signaler_sound_file", core.FLAG_SOUND);
    indicator.parameters:addBoolean("signaler_recurrent_sound", "Recurrent Sound", "", true);
    indicator.parameters:addBoolean("signaler_send_email", "Send Email", "", false);
    indicator.parameters:addString("signaler_email", "Email", "", "");
    indicator.parameters:setFlag("signaler_email", core.FLAG_EMAIL);
    indicator.parameters:addBoolean("signaler_show_popup", "Show Popup", "", false);
    indicator.parameters:addBoolean("signaler_debug_alert", "Print Into Log", "", false);
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

local items = {};
local instruments = {};
local timeframes = {};

local text_color;
local TIMER_ID = 1;
local last_id = 1;

local dde_server, dde_topic;
function PrepareInstrument(instrument)
    local symbol = {};
    symbol.Pair = instrument;
    symbol.Point = core.host:findTable("offers"):find("Instrument", symbol.Pair).PointSize;
    symbol.SymbolIndex = #instruments + 1;
    function symbol:DoLoad()
        self.Indicators = CreateIndicators(instance.source);
    end
    last_id = last_id + 2;
    items[#items + 1] = symbol;
    instruments[#instruments + 1] = instrument;
end

local timer_handle;
-- Cells builder v.1.3
local CellsBuilder = {};
CellsBuilder.GapCoeff = 1.2;
function CellsBuilder:Clear(context)
    self.Columns = {};
    self.RowHeights = {};
    self.Context = context;
end
function CellsBuilder:Add(font, text, color, column, row, mode, backgound, grid_pen, grid_top, grid_bottom)
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
    cell.GridPen = grid_pen;
    cell.DrawGridTop = grid_top;
    cell.DrawGridBottom = grid_bottom;
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
    local max_height = self:GetTotalHeight();
    local max_width = self:GetTotalWidth();
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
                local x_start = x + total_width;
                local y_start = y + total_height;
                local x_end = x + total_width + column.MaxWidth * self.GapCoeff;
                local y_end = y + total_height + self.RowHeights[i] * self.GapCoeff;
                self.Context:drawText(cell.Font, cell.Text, 
                    cell.Color, background, 
                    x_start + column.MaxWidth * (self.GapCoeff - 1) / 2, 
                    y_start + self.RowHeights[i] * (self.GapCoeff - 1) / 2, 
                    x_end, 
                    y_end,
                    cell.Mode);
                if cell.GridPen ~= nil then
                    if cell.DrawGridTop then
                        self.Context:drawLine(cell.GridPen, x_start, y_start, x_end, y_start); -- top
                    end
                    if cell.DrawGridBottom then
                        self.Context:drawLine(cell.GridPen, x_start, y_end, x_end, y_end); -- bottom
                    end
                    self.Context:drawLine(cell.GridPen, x_start, y_start, x_start, y_end); -- left
                    self.Context:drawLine(cell.GridPen, x_end, y_start, x_end, y_end); -- right
                end
            end
            if self.RowHeights[i] ~= nil then
                total_height = total_height + self.RowHeights[i] * self.GapCoeff;
            end
        end
        total_width = total_width + column.MaxWidth * self.GapCoeff;
    end
end

local email, ToTime, sound_file, show_alert, recurrent_sound, show_popup;
function Prepare(nameOnly)
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
    CellsBuilder.GapCoeff = instance.parameters.cells_gap;

    ToTime = instance.parameters.signaler_ToTime
    if ToTime == 1 then
        ToTime = core.TZ_EST
    elseif ToTime == 2 then
        ToTime = core.TZ_UTC
    elseif ToTime == 3 then
        ToTime = core.TZ_LOCAL
    elseif ToTime == 4 then
        ToTime = core.TZ_SERVER
    elseif ToTime == 5 then
        ToTime = core.TZ_FINANCIAL
    elseif ToTime == 6 then
        ToTime = core.TZ_TS
    end
    if instance.parameters.signaler_play_sound then
        sound_file = instance.parameters.signaler_sound_file;
        assert(sound_file ~= "", "Sound file must be chosen");
    end
    show_alert = instance.parameters.signaler_show_alert;
    recurrent_sound = instance.parameters.signaler_recurrent_sound;
    show_popup = instance.parameters.signaler_show_popup;
    signaler_debug_alert = instance.parameters.signaler_debug_alert;
    if instance.parameters.signaler_send_email then
        email = instance.parameters.signaler_email;
        assert(email ~= "", "E-mail address must be specified");
    end
end

local init = false;
local FONT = 1;
local FONT_TEXT = 2;
local BG_PEN = 3;
local BG_BRUSH = 4;
local GRID_PEN = 5;

local draw_grid, grid_mode;

function GetTableIndex(symbol)
    if grid_mode == "h" then
        return 2, symbol.SymbolIndex + 1;
    end

    return (symbol.SymbolIndex + 1), 2;
end

function DrawSignal(symbol, context)
    if symbol.Text == nil then
        return;
    end
    local row, column = GetTableIndex(symbol);
    if symbol.Signal == 0 or symbol.Signal == nil then
        CellsBuilder:Add(FONT_TEXT, symbol.Text, text_color, column, row, context.CENTER, backgound, GRID_PEN, true, false);
        return;
    end

    local backgound = -1;
    local color = symbol.Signal > 0 and instance.parameters.up_color or instance.parameters.dn_color;
    CellsBuilder:Add(FONT_TEXT, symbol.Text, color, column, row, context.CENTER, backgound, GRID_PEN, true, false);
end
function Draw(stage, context) 
    if stage ~= 2 then
        return;
    end
    if not init then
        context:createFont(FONT_TEXT, "Arial", 0, context:pointsToPixels(8), 0)
        context:createPen(BG_PEN, context.SOLID, 1, instance.parameters.background_color);
        context:createSolidBrush(BG_BRUSH, instance.parameters.background_color);
        draw_grid = instance.parameters.draw_grid;
        grid_mode = instance.parameters.grid_mode;
        if draw_grid then
            context:createPen(GRID_PEN, context.SOLID, 1, instance.parameters.grid_color);
        else
            GRID_PEN = nil;
        end
        init = true;
    end
    local title_w, title_h = context:measureText(FONT_TEXT, indi_name, 0);
    CellsBuilder:Clear(context);
    for i = 1, #timeframes do
        if grid_mode == "h" then
            CellsBuilder:Add(FONT_TEXT, timeframes[i], text_color, 1, (i + 1), context.CENTER);
        else
            CellsBuilder:Add(FONT_TEXT, timeframes[i], text_color, i + 1, 1, context.CENTER);
        end
    end
    for i = 1, #instruments do
        if grid_mode == "h" then
            CellsBuilder:Add(FONT_TEXT, instruments[i], text_color, i + 1, 1, context.CENTER);
        else
            CellsBuilder:Add(FONT_TEXT, instruments[i], text_color, 1, (i + 1), context.CENTER);
        end
    end
    for _, symbol in ipairs(items) do
        DrawSignal(symbol, context);
    end
    local width = math.max(title_w, CellsBuilder:GetTotalWidth());
    context:drawRectangle(BG_PEN, BG_BRUSH, context:right() - width, context:top(), context:right(), context:top() + title_h * 1.2 + CellsBuilder:GetTotalHeight());
    context:drawText(FONT_TEXT, indi_name, text_color, -1, context:right() - width, context:top(), context:right(), context:top() + title_h, 0);
    CellsBuilder:Draw(context:right() - width, context:top() + title_h * 1.2);
end

function Update(period, mode)
    for _, module in pairs(Modules) do if module.ExtUpdate ~= nil then module:ExtUpdate(nil, nil, nil); end end
end

function UpdateData()
    local offers = {};
    for _, symbol in ipairs(items) do
        if symbol.Indicators ~= nil then
            if offers[symbol.Pair] == nil then
                offers[symbol.Pair] = core.host:findTable("offers"):find("Instrument", symbol.Pair);
            end
            if symbol.LastUpdate ~= offers[symbol.Pair].Time then
                symbol.LastUpdate = offers[symbol.Pair].Time;
                for i, indicator in ipairs(symbol.Indicators) do
                    indicator:update(core.UpdateLast);
                end
                local signal, label = GetLastSignal(symbol.Indicators, symbol.Indicators[1].DATA);
                symbol.Signal = signal;
                symbol.Text = label;
                if signal ~= 0 and symbol.last_alert ~= symbol.Indicators[1].DATA:date(NOW) then
                    Signal(symbol.Indicators[1].DATA:instrument() .. "(" .. symbol.Indicators[1].DATA:barSize() .. "): " .. symbol.Text);
                    symbol.last_alert = symbol.Indicators[1].DATA:date(NOW);
                end
            end
		else
            symbol.Text = "...";
        end
    end
end

function FormatEmail(source, period, message)
    --format email subject
    local subject = message .. "(" .. source:instrument() .. ")";
    --format email text
    local delim = "\013\010";
    local signalDescr = "Signal: " .. (indi_name or "");
    local symbolDescr = "Symbol: " .. source:instrument();
    local messageDescr = "Message: " .. message;
    local ttime = core.dateToTable(core.host:execute("convertTime", core.TZ_EST, ToTime, source:date(period)));
    local dateDescr = string.format("Time:  %02i/%02i %02i:%02i", ttime.month, ttime.day, ttime.hour, ttime.min);
    local priceDescr = "Price: " .. source[period];
    local text = "You have received this message because the following signal alert was received:"
        .. delim .. signalDescr .. delim .. symbolDescr .. delim .. messageDescr .. delim .. dateDescr .. delim .. priceDescr;
    return subject, text;
end

function Signal(message, source)
    if source == nil then
        if instance.source ~= nil then
            source = instance.source;
        elseif instance.bid ~= nil then
            source = instance.bid;
        else
            local pane = core.host.Window.CurrentPane;
            source = pane.Data:getStream(0);
        end
    end
    if show_alert then
        terminal:alertMessage(source:instrument(), source[NOW], message, source:date(NOW));
    end

    if sound_file ~= nil then
        terminal:alertSound(sound_file, recurrent_sound);
    end

    if email ~= nil then
        terminal:alertEmail(email, profile:id().. " : " .. message, FormatEmail(source, NOW, message));
    end

    if signaler_debug_alert then
        core.host:trace(message);
    end

    if show_popup then
        local subject, text = FormatEmail(source, NOW, message);
        core.host:execute("prompt", 42, subject, text);
    end
end

local loading_finished = false;
function AsyncOperationFinished(cookie, success, message, message1, message2)
    for _, module in pairs(Modules) do if module.AsyncOperationFinished ~= nil then module:AsyncOperationFinished(cookie, success, message, message1, message2); end end
    if cookie == TIMER_ID then
        UpdateData();
        if not loading_finished then
            for _, symbol in ipairs(items) do
                symbol:DoLoad();
            end
            core.host:execute("setStatus", "");
            loading_finished = true;
        end
    end
end
