function CreateFixnan()
    local fixnan = {};
    fixnan._stream = instance:addInternalStream(0, 0); 
    function fixnan:set(period, value)
        if value == nil then
            if period == 0 or not self._stream:hasData(period - 1) then
                return nil;
            end
            self._stream[period] = self._stream[period - 1];
        else
            self._stream[period] = value;
        end
        return self._stream[period];
    end
    return fixnan;
end