Array = {};
function Array:NewArray(size)
    local newArray = {};
    newArray.arr = {};
    for i = 1, size, 1 do
        newArray.arr[i] = nil;
    end
    function newArray:Push(item)
        self.arr[#self.arr + 1] = item;
    end
    function newArray:Get(index)
        return self.arr[index + 1];
    end
    function newArray:Sum()
        local sum = 0;
        for i, v in ipairs(self.arr) do
            sum = sum + v;
        end
        return sum;
    end
    return newArray;
end
function Array:NewLine(size)
    return Array:NewArray(size);
end
function Array:NewInt(size)
    return Array:NewArray(size);
end
function Array:NewFloat(size)
    return Array:NewArray(size);
end
function Array:NewLabel(size)
    return Array:NewArray(size);
end
function Array:NewString(size)
    return Array:NewArray(size);
end