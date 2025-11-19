Fill = {};
function Fill:SetValue(up_channel, dn_channel, value1, value2, mineColor, period)
    if not value1:hasData(period) or not value2:hasData(period) or mineColor ~= true then
        up_channel:setNoData(period);
        dn_channel:setNoData(period);
        return;
    end
    up_channel[period] = math.max(value1[period], value2[period]);
    dn_channel[period] = math.min(value1[period], value2[period]);
end