function Init()
    indicator:name("PineScript ALMA");
    indicator:description("ALMA");
    indicator:requiredSource(core.Tick);
    indicator:type(core.Indicator);

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("length", "Number of bars (length)", "", 14, 2, 1000);
    indicator.parameters:addDouble("offset", "Controls tradeoff between smoothness (closer to 1) and responsiveness (closer to 0).", "", 0.85);
    indicator.parameters:addDouble("sigma", "Changes the smoothness of ALMA. The larger sigma the smoother ALMA.", "", 6);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrALMA", "Color", "", core.rgb(0, 255, 255));
    indicator.parameters:addInteger("widthALMA", "Width", "", 1, 1, 5);
    indicator.parameters:addInteger("styleALMA", "Style", "", core.LINE_SOLID);
    indicator.parameters:setFlag("styleALMA", core.FLAG_LEVEL_STYLE);
end
-- Routine
local ALMA;
local source;
local first;
local length;
local offset;
local sigma;

function Prepare()
    length = instance.parameters.length;
    offset = instance.parameters.offset;
    sigma = instance.parameters.sigma;
    source = instance.source;
    first = source:first();

    local name = profile:id() .. "(" .. source:name() .. ", " .. length .. ", " .. offset .. ", " .. sigma .. ")";
    instance:name(name);
    first = source:first() + length - 1;
    ALMA = instance:addStream("ALMA", core.Line, name, "ALMA", instance.parameters.clrALMA, first);
    ALMA:setWidth(instance.parameters.widthALMA);
    ALMA:setStyle(instance.parameters.styleALMA);
end

function Update(period)
    if period >= first then
        m = offset * (length - 1)
        s = length / sigma
        norm = 0.0
        sum = 0.0
        for i = 0, length - 1 do
            weight = math.exp(-1 * math.pow(i - m, 2) / (2 * math.pow(s, 2)))
            norm = norm + weight
            sum = sum + source[period - length - 1] * weight
        end
        ALMA[period] = sum / norm
    end
end
