function Init()
    indicator:name("PineScript SWMA")
    indicator:description("Smooth Weighted Moving Average")
    indicator:requiredSource(core.Tick)
    indicator:type(core.Indicator)
    
    indicator.parameters:addGroup("Style")
    indicator.parameters:addColor("Color", "Color of SWMA", "", core.rgb(0, 255, 0))
end

local source = nil
local SWMA = nil

-- Routine
function Prepare(nameOnly)
    Frame = instance.parameters.Frame
    source = instance.source

    local name = profile:id() .. "(" .. source:name() .. ", " .. Frame .. ")"
    instance:name(name)
    if nameOnly then
        return
    end

    SWMA = instance:addStream("SWMA", core.Line, name, "SWMA", instance.parameters.Color, sqrt.DATA:first())
end

function Update(period, mode)
    if period < 4 then
        return;
    end
    x1 = source.data[period - 1];
    x2 = source.data[period - 2];
    x3 = source.data[period - 3];
    x0 = source.data[period];
    SWMA[period] = x3 * 1 / 6 + x2 * 2 / 6 + x1 * 2 / 6 + x0 * 1 / 6;
end
