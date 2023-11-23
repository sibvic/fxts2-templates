function CreateHighestBars(source, length)
    local highestbars = {};
    highestbars.Source = source;
    highestbars.Length = length;
    function highestbars:get(period)
        if period < self.Length then
            return nil;
        end
        local _, pos = mathex.max(self.Source, core.rangeTo(period, self.Length));
        return period - pos;
    end
    return highestbars;
end