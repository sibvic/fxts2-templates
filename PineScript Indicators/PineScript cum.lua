function Init()
    indicator:name("PineScrip Cum indicator")
    indicator:description("")
    indicator:requiredSource(core.Tick)
    indicator:type(core.Oscillator)

    indicator.parameters:addGroup("Calculation")
    indicator.parameters:addGroup("Line Style")
    indicator.parameters:addInteger("width", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style", core.FLAG_LINE_STYLE)
    indicator.parameters:addColor("color", "Line Color", "", core.rgb(0, 255, 255))
end

local first
local source = nil

function Prepare(nameOnly)
    source = instance.source
    local name = profile:id() .. "(" .. instance.source:name() .. ")"
    instance:name(name)
    if (nameOnly) then
        return
    end

    first = source:first()

    Line = instance:addStream("Line", core.Line, name, "Line", instance.parameters.color, first)
    Line:setWidth(instance.parameters.width)
    Line:setStyle(instance.parameters.style)
end

function Update(period, mode)
    if period <= first or not source:hasData(period) then
        return
    end

    if period == first or not Line:hasData(period - 1) then
        Line[period] = source[period];
        return;
    end
    Line[period] = Line[period - 1] + source[period];
end