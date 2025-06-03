dofile(core.app_path() .. "\\strategies\\custom\\snippets\\sources.lua")

local timeframes = {
    {name = "m1", value = "m1", enabled = false},
    {name = "m5", value = "m5", enabled = false},
    {name = "m15", value = "m15", enabled = true},
    {name = "m30", value = "m30", enabled = false},
    {name = "H1", value = "H1", enabled = true},
    {name = "H2", value = "H2", enabled = false},
    {name = "H3", value = "H3", enabled = false},
    {name = "H4", value = "H4", enabled = true},
    {name = "H6", value = "H6", enabled = false},
    {name = "H8", value = "H8", enabled = false},
    {name = "D1", value = "D1", enabled = false},
    {name = "W1", value = "W1", enabled = false},
    {name = "M1", value = "M1", enabled = false}
};
function Init()
    indicator:name("Heatmap indicator")
    indicator:description("")
    indicator:requiredSource(core.Bar)
    indicator:type(core.Oscillator)

    indicator.parameters:addGroup("Indicator Parameters");
    --todo: add indicator parameters

    indicator.parameters:addGroup("Timeframe Selection");
    for _, tf in ipairs(timeframes) do
        indicator.parameters:addBoolean("use_" .. tf.name, "Use " .. tf.name, "", tf.enabled);
    end

    indicator.parameters:addGroup("Style")
    indicator.parameters:addColor("up_color", "Up Color", "", core.COLOR_UPCANDLE)
    indicator.parameters:addColor("down_color", "Down Color", "", core.COLOR_DOWNCANDLE)
    indicator.parameters:addColor("neutral_color", "Neutral Color", "", core.rgb(128, 128, 128))
    indicator.parameters:addColor("labels_color", "Label Color", "", core.COLOR_LABEL)
end

local source;
local conditions = {};

function CreateIndicator(src)
    return nil;--todo: create indicator
end

function Prepare(nameOnly)
    source = instance.source;
    local name = string.format("%s(%s)", profile:id(), source:name());
    instance:name(name);
    if nameOnly then
        return ;
    end

    for i, tf in ipairs(timeframes) do
        if instance.parameters:getBoolean("use_" .. tf.name) then
            local condition = {};
            condition.src = sources:Request(i, source, tf.value);
            condition.indi = CreateIndicator(condition.src);
            condition.Name = tf.name;
            function condition:Update(period, mode)
                self.indi:update(mode);
            end
            function condition:GetSignal(period)
                local index = core.findDate(self.indi.DATA, source:date(period), false);
                if (index <= 0) then
                    return 0;
                end
                --todo: implement
                return 0;
            end
            conditions[#conditions + 1] = condition;
        end
    end
    instance:ownerDrawn(true);
end

function ReleaseInstance()
end

function AsyncOperationFinished(cookie, successful, message, message1, message2)
    if sources:AsyncOperationFinished(cookie, successful, message, message1, message2) then
        instance:updateFrom(0);
    end
end

function Update(period, mode)
    for index, condition in ipairs(conditions) do
        condition:Update(period, mode)
    end
end

local init = false;

local UP_PEN_ID = 1;
local UP_BRUSH_ID = 2;
local DOWN_PEN_ID = 3;
local DOWN_BRUSH_ID = 4;
local NEUTRAL_PEN_ID = 5;
local NEUTRAL_BRUSH_ID = 6;
local FONT_ID = 7;
local labels_color;

function Draw(stage, context)
    if stage ~= 0 or #conditions == 0 then
        return
    end

    context:setClipRectangle(context:left(), context:top(), context:right(), context:bottom())
    if not init then
        local up_color = instance.parameters.up_color;
        local down_color = instance.parameters.down_color;
        local neutral_color = instance.parameters.neutral_color;
        context:createPen(UP_PEN_ID, context.SOLID, 1, up_color);
        context:createSolidBrush(UP_BRUSH_ID, up_color);
        context:createPen(DOWN_PEN_ID, context.SOLID, 1, down_color);
        context:createSolidBrush(DOWN_BRUSH_ID, down_color);
        context:createPen(NEUTRAL_PEN_ID, context.SOLID, 1, neutral_color);
        context:createSolidBrush(NEUTRAL_BRUSH_ID, neutral_color);
        context:createFont(FONT_ID, "Arial", 0, context:pointsToPixels(10), 0);
        labels_color = instance.parameters.labels_color;
        init = true
    end

    local first = math.max(source:first(), context:firstBar());
    local last = math.min(context:lastBar(), source:size() - 1);
    local total_height = context:bottom() - context:top();
    local cell_height = total_height / #conditions;

    for period = first, last do
        local x, x_start, x_end = context:positionOfBar(period);
        for index, condition in ipairs(conditions) do
            local signal = condition:GetSignal(period);
            local y_from = context:top() + cell_height * (index - 1);
            local y_to = y_from + cell_height - 1;
            if signal == 1 then
                context:drawRectangle(UP_PEN_ID, UP_BRUSH_ID, x_start, y_from, x_end, y_to);
            elseif signal == -1 then
                context:drawRectangle(DOWN_PEN_ID, DOWN_BRUSH_ID, x_start, y_from, x_end, y_to);
            else
                context:drawRectangle(NEUTRAL_PEN_ID, NEUTRAL_BRUSH_ID, x_start, y_from, x_end, y_to);
            end
        end
    end
    for index, condition in ipairs(conditions) do
        if condition.Name ~= nil then
            local x_to = context:right();
            local w, h = context:measureText(FONT_ID, condition.Name, 0);
            local x_from = x_to - w;
            local y_from = context:top() + cell_height * (index - 1) + (cell_height - 1 - h) / 2;
            local y_to = y_from + cell_height - 1 - (cell_height - 1 - h) / 2;

            context:drawText(FONT_ID, condition.Name, labels_color, -1, x_from, y_from, x_to, y_to, 0);
        end
    end
end
