Variable = {};
function Variable:Create()
    local var = {};
    var._init = false;
    var._hist = {};
    var._last_period = nil;
    function var:Clear()
        self._init = false;
        self._value = nil;
        self._hist = {};
    end
    function var:Get(period, shift)
        if (shift ~= nil) then
            local target_period = period - shift;
            local found_value = nil;
            for k, v in pairs(self._hist) do
                if k > target_period then
                    return found_value;
                end
                found_value = v;
            end
            return found_value;
        end
        return self._value;
    end
    function var:Set(period, value)
        if (self._last_period ~= period and self._last_period ~= nil) then
            self._hist[self._last_period] = self._value;
        end
        self._value = value;
        self._last_period = period;
        self._init = true;
    end
    function var:IsInitialized()
        return self._init;
    end
    return var;
end