-- Pine Script compatible: ta.percentile_nearest_rank(source, length, percentage)
-- percentage is 0..100 (TradingView / Pine semantics).
-- Install this file as: [Application]/snippets/PINESCRIPT PERCENTILE NEAREST RANK.lua

local source;
local DATA;

local function percentile_nearest_rank(sample, percentage)
    local n = #sample
    if n == 0 then
        return nil;
    end
    table.sort(sample);
    local k = math.ceil(percentage / 100 * n);
    if k < 1 then
        k = 1;
    end
    if k > n then
        k = n;
    end
    return sample[k];
end

function Init()
    indicator:name("PINESCRIPT PERCENTILE NEAREST RANK");
    indicator:description("Nearest-rank percentile (Pine ta.percentile_nearest_rank)");
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);
    indicator.parameters:addInteger("length", "Length", "Number of bars (sample size)", 14);
    indicator.parameters:addDouble("percentage", "Percentage", "Percentile in 0..100", 50, 0, 100);
end

function Prepare(nameOnly)
    source = instance.source;
    local name = string.format("%s(%s)", profile:id(), source:name());
    instance:name(name);
    if nameOnly then
        return;
    end
    DATA = instance:addStream("DATA", core.Line, "DATA", "Percentile nearest rank", core.colors().Blue, 0, 0);
end

function Update(period, mode)
    local len = instance.parameters.length;
    local pct = instance.parameters.percentage;
    if len < 1 or period < len - 1 then
        return;
    end
    local buf = {};
    for i = 0, len - 1 do
        buf[#buf + 1] = source:tick(period - i);
    end
    local v = percentile_nearest_rank(buf, pct);
    DATA:set(period, v, mode);
end

function AsyncOperationFinished(cookie, success, message, message1, message2)
end
