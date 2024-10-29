function Init()
    indicator:name("PineScrip Cum indicator")
    indicator:description("")
    indicator:requiredSource(core.Bar)
    indicator:type(core.Indicator)

    indicator.parameters:addGroup("Calculation")
    indicator.parameters:addInteger("factor", "Factor", "", 3);
    indicator.parameters:addInteger("atrPeriod", "ATR Period", "", 10);
    indicator.parameters:addGroup("Line Style")
    indicator.parameters:addInteger("width", "Line width", "", 1, 1, 5)
    indicator.parameters:addInteger("style", "Line style", "", core.LINE_SOLID)
    indicator.parameters:setFlag("style", core.FLAG_LINE_STYLE)
    indicator.parameters:addColor("color", "Line Color", "", core.rgb(0, 255, 255))
end

local first
local source = nil
local supertrend;
local direction;
local atr;
local factor;
local upperBand, lowerBand;

function Prepare(nameOnly)
    source = instance.source
    local name = profile:id() .. "(" .. instance.source:name() .. ")"
    instance:name(name)
    if (nameOnly) then
        return
    end

    first = source:first()

    factor = instance.parameters.factor;
    atr = core.indicators:create("ATR", source, instance.parameters.atrPeriod);
    supertrend = instance:addStream("SUPERTREND", core.Line, name, "Supertrend", instance.parameters.color, first)
    supertrend:setWidth(instance.parameters.width)
    supertrend:setStyle(instance.parameters.style)
    direction = instance:addStream("DIRECTION", core.Line, name, "Direction", instance.parameters.color, first)
    upperBand = instance:addInternalStream(0, 0);
    lowerBand = instance:addInternalStream(0, 0);
end

function Update(period, mode)
    if period <= first or not source:hasData(period) then
        return
    end
    atr:update(mode);

    src = (source.high[period] + source.low[period]) / 2;
    upperBand[period] = src + factor * atr.DATA[period]
    lowerBand[period] = src - factor * atr.DATA[period]

    lowerBand[period] = (lowerBand[period] > lowerBand[period - 1] or source.close[period - 1] < lowerBand[period - 1]) and lowerBand[period] or lowerBand[period - 1]
    upperBand[period] = (upperBand[period] < upperBand[period - 1] or source.close[period - 1] > upperBand[period - 1]) and upperBand[period] or upperBand[period - 1]
    if supertrend[period - 1] == upperBand[period - 1] then
        direction[period] = source.close[period] > upperBand[period] and -1 or 1
    else
        direction[period] = source.close[period] < lowerBand[period] and 1 or -1
    end
    supertrend[period] = direction[period] == -1 and lowerBand[period] or upperBand[period]
end