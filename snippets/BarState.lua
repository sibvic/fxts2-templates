function CreateIsFirst()
    local is_first = {};
    is_first.first = true;
    function is_first:IsFirst()
        local val = self.first;
        self.first = false;
        return val;
    end
    function is_first:Clear()
        self.first = true;
    end
    return is_first;
end