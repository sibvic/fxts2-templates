Fill = {};
function Fill:SetValue(up_channel, dn_channel, value1, value2, mineColor, period)
    if value1 == nil or value2 == nil or mineColor ~= true then
        up_channel:setNoData(period);
        dn_channel:setNoData(period);
        return;
    end
    up_channel[period] = math.max(value1, value2);
    dn_channel[period] = math.min(value1, value2);
end