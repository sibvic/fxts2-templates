
local indi_alerts = {}; -- SHOULD BE INCLUDED!!!
local alert_stages = { 2 };

function IsUpCondition(period)
    return core.crossesOver(Indicator.DATA, 0, period);
end

function IsDownCondition(period)
    return core.crossesUnder(Indicator.DATA, 0, period);
end

function Init()
    indicator:name("CCI with targets")
    indicator:description("")
    indicator:requiredSource(core.Bar)
    indicator:type(core.Indicator)
    
    indicator.parameters:addString("TF", "Indicator Time Frame", "", "D1")
    indicator.parameters:setFlag("TF", core.FLAG_BARPERIODS_EDIT)
    indicator.parameters:addInteger("cci_period", "CCI Period", "Period", 20)
    
    indicator.parameters:addDouble("Level1", "1. Target Ratio", "", 1)
    indicator.parameters:addDouble("Level2", "2. Target Ratio", "", 1.5)
    indicator.parameters:addDouble("Level3", "3. Target Ratio", "", 2)
    indicator.parameters:addDouble("Level4", "Trigger Line (in pips)", "", 0)

    indicator.parameters:addBoolean("Historical", "Show Historical", "", true)
    indicator.parameters:addString("ShowLabel", "Show Label", "", "no")
    indicator.parameters:addStringAlternative("ShowLabel", "Do not show", "", "no")
    indicator.parameters:addStringAlternative("ShowLabel", "At the left", "", "left")
    indicator.parameters:addStringAlternative("ShowLabel", "At the right", "", "right")

    indicator.parameters:addInteger("Lookback", "Label Lookback Period", "", 100)

    indicator.parameters:addGroup("Line Style")
    indicator.parameters:addColor("StartLineColor", "Start Line Color", "", core.rgb(0, 0, 255))
    indicator.parameters:addInteger("width1", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style1", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style1", core.FLAG_LINE_STYLE)

    indicator.parameters:addGroup("Label Style")
    indicator.parameters:addColor("LabelColor", "Label Color", "", core.COLOR_LABEL)
    indicator.parameters:addBoolean("LabelBackground", "Add Label Background", "", false)
    indicator.parameters:addColor("LabelBackgroundColor", "Label Background Color", "", core.COLOR_BACKGROUND)
    indicator.parameters:addInteger("FontSize", "Label Size", "", 8)
    indicator.parameters:addColor("StopLineColor", "Stop Line Color", "", core.rgb(255, 0, 0))
    indicator.parameters:addInteger("width2", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style2", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style2", core.FLAG_LINE_STYLE)

    indicator.parameters:addColor("TargetLineColor1", "1. Target Line Color", "", core.rgb(0, 255, 0))
    indicator.parameters:addInteger("width3", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style3", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style3", core.FLAG_LINE_STYLE)

    indicator.parameters:addColor("TargetLineColor2", "2. Target  Line Color", "", core.rgb(0, 255, 0))
    indicator.parameters:addInteger("width4", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style4", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style4", core.FLAG_LINE_STYLE)

    indicator.parameters:addColor("TargetLineColor3", "3. Target  Line Color", "", core.rgb(0, 255, 0))
    indicator.parameters:addInteger("width5", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style5", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style5", core.FLAG_LINE_STYLE)

    indicator.parameters:addColor("TargetLineColor4", "Trigger Line Color", "", core.rgb(0, 255, 0))
    indicator.parameters:addInteger("width6", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style6", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style6", core.FLAG_LINE_STYLE)

    indi_alerts:AddParameters(indicator.parameters);
    indi_alerts:AddAlert("CCI/0")
end

local Number = 1
local Size
local Show
local Live
local FIRST = true
local OnlyOnce
local UpTrendColor, DownTrendColor
local OnlyOnceFlag
local ShowAlert
local Shift = 0

local first
local source = nil
local btf_source = nil
local position = nil

local FontSize, LabelColor, font

local Level1, Level2, Level3, Level4
local LabelBackgroundColor
local LabelBackground
local Historical, ShowLabel
local Lookback
local TF
local dayoffset
local weekoffset
local cci_period

local labels = {}
local last_label_id = 0;
function CreateLabel(color, style, width)
    local label = {};
    label.Id = last_label_id + 1;
    label.LabelId = last_label_id + 2;
    label.Color = color;
    label.Style = style;
    label.Width = width;
    last_label_id = label.LabelId;
    function label:Draw(p, color)
        local str = win32.formatNumber(self.Rate, false, source:getPrecision());
        core.host:execute("drawLine", New(p, self.Id), self.DateEnd, self.Rate, self.Date, self.Rate, self.Color, self.Style, self.Width, str)
        if not LabelBackground and ShowLabel ~= "no" then
            if ShowLabel == "left" then
                core.host:execute("drawLabel1", New(p, self.LabelId), self.DateEnd, core.CR_CHART, self.Rate, core.CR_CHART, core.H_Right, core.V_Top, font, LabelColor, self.Text)
            else
                core.host:execute("drawLabel1", New(p, self.LabelId), self.Date, core.CR_CHART, self.Rate, core.CR_CHART, core.H_Left, core.V_Top, font, LabelColor, self.Text)                date = source:date(period)
            end
        end
    end
    return label;
end

function Prepare(nameOnly)
    local name = profile:id() .. "(" .. instance.source:name() .. ")"
    instance:name(name)
    if (nameOnly) then
        return
    end
    indi_alerts:Prepare();
    indi_alerts.source = instance.source;
    instance:drawOnMainChart(true);
    instance:ownerDrawn(true);
    cci_period = instance.parameters.cci_period;

    dayoffset  = core.host:execute("getTradingDayOffset")
    weekoffset = core.host:execute("getTradingWeekOffset")
    source = instance.source
    TF = instance.parameters.TF
    local s1, e1, s2, e2
    s1, e1 = core.getcandle(source:barSize(), 0, 0, 0)
    s2, e2 = core.getcandle(TF, 0, 0, 0)
    assert((e1 - s1) <= (e2 - s2), "The chosen time frame must be equal to or bigger than the chart time frame!")

    btf_source = core.host:execute("getSyncHistory", source:instrument(), TF, source:isBid(), 0, 100, 101)
    loading    = true

    LabelBackgroundColor = instance.parameters.LabelBackgroundColor
    LabelBackground = instance.parameters.LabelBackground
    FontSize = instance.parameters.FontSize
    LabelColor = instance.parameters.LabelColor
    Historical = instance.parameters.Historical
    ShowLabel = instance.parameters.ShowLabel

    font = core.host:execute("createFont", "Arial", FontSize, false, false)

    OnlyOnceFlag = true
    FIRST = true
    OnlyOnce = instance.parameters.OnlyOnce
    Show = instance.parameters.Show
    Live = instance.parameters.Live
    Lookback = instance.parameters.Lookback

    Level1 = instance.parameters.Level1
    Level2 = instance.parameters.Level2
    Level3 = instance.parameters.Level3
    Level4 = instance.parameters.Level4
    
    labels[#labels + 1] = CreateLabel(instance.parameters.StartLineColor, instance.parameters.style1, instance.parameters.width1);
    labels[#labels + 1] = CreateLabel(instance.parameters.StopLineColor, instance.parameters.style2, instance.parameters.width2);
    labels[#labels + 1] = CreateLabel(instance.parameters.TargetLineColor1, instance.parameters.style3, instance.parameters.width3);
    labels[#labels + 1] = CreateLabel(instance.parameters.TargetLineColor2, instance.parameters.style4, instance.parameters.width4);
    labels[#labels + 1] = CreateLabel(instance.parameters.TargetLineColor3, instance.parameters.style5, instance.parameters.width5);
    if Level4 ~= 0 then
        labels[#labels + 1] = CreateLabel(instance.parameters.TargetLineColor4, instance.parameters.style6, instance.parameters.width6);
    end

    first = source:first() + 1

    position = instance:addInternalStream(0, 0)

    Indicator = core.indicators:create("CCI", btf_source, cci_period);

    FIRST_CANDLE = nil
end

local init = false
function Draw(stage, context)
    indi_alerts:Draw(stage, context, source);
    if stage ~= 2 then
        return
    end
    if not init then
        context:createFont(2, "Arial", 0, context:pointsToPixels(FontSize), 0)
        context:createSolidBrush(3, LabelBackgroundColor)
        init = true
    end
    for _, label in ipairs(labels) do
        DrawLabel(label, context)
    end
end

function DrawLabel(label, context)
    if label.Text ~= nil then
        local visible, y = context:pointOfPrice(label.Rate)
        local width, height = context:measureText(2, label.Text, 0)
        local x
        local pos
        if ShowLabel == "left" then
            x = context:positionOfDate(label.DateEnd)
            pos = context.RIGHT + context.TOP
        else
            x = context:positionOfDate(label.Date) - width
            pos = context.LEFT + context.TOP
        end
        context:drawText(2, label.Text, LabelColor, LabelBackgroundColor, x, y - height, x + width, y, pos)
    end
end

local ID = 0
local ids = {}
function New(period, id)
    if ids[period] == nil then
        ids[period] = {}
    end
    if ids[period][id] == nil then
        ids[period][id] = ID + 1
        ID = ID + 1
    end
    return ids[period][id]
end

function GetPeriod(period)
    local Candle = core.getcandle(TF, source:date(period), dayoffset, weekoffset)
    if loading or btf_source:size() == 0 then
        return false
    end
    if period < source:first() then
        return false
    end

    local p = core.findDate(btf_source, Candle, false)
    -- candle is not found
    if p < 0 then
        return false
    else
        return p
    end
end

function GetPrevPeriod(p)
    if p == 0 then
        return -1;
    end
    local prev_date = btf_source:date(p - 1);
    return core.findDate(source, prev_date, false);
end

function Update(period, mode)
    Indicator:update(mode);
    local p = GetPeriod(period)
    if not p then
        return
    end
    if period < first then
        ID = 0
        return
    elseif period == first then
        ID = 0
    end
    local prev_period = GetPrevPeriod(p);
    if (period == first or prev_period == -1) then
        position[period] = 0
    else
        position[period] = position[period - 1]
    end

    if position[period] ~= -1 and IsDownCondition(period) then
        position[period] = -1
    elseif position[period] ~= 1 and IsUpCondition(period) then
        position[period] = 1
    end

    if (not Historical and period < source:size() - 1) or (Historical and period < source:size() - 1 - Lookback) then
        return
    end

    local p = FindLast(period)
    local Delta
    if p ~= 0 then
        local signalVal = source.close[period];
        if position[p] == 1 then
            Delta = math.abs(signalVal - source.high[p])
            labels[1].Rate = source.high[p]
            labels[2].Rate = source.high[p] - Delta;
            labels[3].Rate = source.high[p] + Delta * Level1
            labels[4].Rate = source.high[p] + Delta * Level2
            labels[5].Rate = source.high[p] + Delta * Level3
            if labels[6] ~= nil then
                labels[6].Rate = source.high[p] + source:pipSize() * Level4
            end
        elseif position[p] == -1 then
            Delta = math.abs(signalVal - source.low[p])
            labels[1].Rate = source.low[p]
            labels[2].Rate = source.low[p] + Delta;
            labels[3].Rate = source.low[p] - Delta * Level1
            labels[4].Rate = source.low[p] - Delta * Level2
            labels[5].Rate = source.low[p] - Delta * Level3
            if labels[6] ~= nil then
                labels[6].Rate = source.low[p] - source:pipSize() * Level4
            end
        else
            return;
        end
        labels[1].Text = string.format("Entry : %s", labels[1].Rate)
        labels[2].Text = string.format("Stop : %s (%s)", labels[2].Rate, win32.formatNumber(Delta / source:pipSize(), false, 1))
        labels[3].Text = string.format("1. Target : %s (%s)", win32.formatNumber(labels[3].Rate, false, source:getPrecision()), win32.formatNumber(Delta * Level1 / source:pipSize(), false, 1))
        labels[4].Text = string.format("2. Target : %s (%s)", win32.formatNumber(labels[4].Rate, false, source:getPrecision()), win32.formatNumber((Delta * Level2) / source:pipSize(), false, 1))
        labels[5].Text = string.format("3. Target : %s (%s)", win32.formatNumber(labels[5].Rate, false, source:getPrecision()), win32.formatNumber((Delta * Level3) / source:pipSize(), false, 1))
        if labels[6] ~= nil then
            labels[6].Text = string.format("Trigger : %s (%s)", win32.formatNumber(labels[6].Rate, false, source:getPrecision()), win32.formatNumber(Level4, false, 1))
        end

        for i,label in ipairs(labels) do
            label.Date = source:date(period)
            label.DateEnd = source:date(p)
            label:Draw(p);
        end
    end
    for _, alert in ipairs(indi_alerts.Alerts) do Activate(alert, period, period ~= source:size() - 1); end
end

function Activate(alert, period, historical_period)
    if indi_alerts.Live ~= "Live" then period = period - 1; end
    alert.Alert[period] = 0;
    if not alert.ON then
        if indi_alerts.FIRST then indi_alerts.FIRST = false; end
        return;
    end
    if alert.id == 1 then
        if (IsUpCondition(period)) then
            alert:UpAlert(source, period, alert.Label .. ". Bull pattern", source.high[period], historical_period);
        elseif (IsDownCondition(period)) then
            alert:DownAlert(source, period, alert.Label .. ". Bear pattern", source.low[period], historical_period);
        end
    end

    if indi_alerts.FIRST then indi_alerts.FIRST = false; end
end

function ReleaseInstance()
    core.host:execute("deleteFont", font)
end

function FindLast(period)
    for i = period, first, -1 do
        if position[i] ~= position[i - 1] then
            return i
        end
    end

    return 0;
end

-- the function is called when the async operation is finished
function AsyncOperationFinished(cookie)
    indi_alerts:AsyncOperationFinished(cookie, success, message, message1, message2)
    if cookie == 100 then
        loading = false
        instance:updateFrom(0)
    elseif cookie == 101 then
        loading = true
    end
end
