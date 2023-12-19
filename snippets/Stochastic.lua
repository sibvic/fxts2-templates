function CreateStochastic(source, high, low, length)
    local stoch = {};
    stoch.Source = source;
    stoch.High = high;
    stoch.Low = low;
    stoch.Length = length;
    function stoch:get(period)
        if period + self.Length >= self.Source:first() then
            return nil;
        end
        local low = mathex.min(self.Low, core.rangeTo(period, self.Length));
        local high = mathex.max(self.High, core.rangeTo(period, self.Length));
        if low == high then
            return 100;
        end
        return 100 * (self.Source[period] - low) / (high - low);
    end
    return stoch;
end