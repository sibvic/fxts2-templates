function CreateLowestBars(source, length)
    local lowestbars = {};
    lowestbars.Source = source;
    lowestbars.Length = length;
    function lowestbars:get(period)
        if period < self.Length then
            return nil;
        end
        local _, pos = mathex.min(self.Source, core.rangeTo(period, self.Length));
        return period - pos;
    end
    return lowestbars;
end