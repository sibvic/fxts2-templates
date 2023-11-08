Array = {};
function Array:NewLine()
    local newArray = {};
    newArray.arr = {};
    function newArray:Push(item)
        self.arr[#self.arr + 1] = item;
    end
    function newArray:Get(index)
        return self.arr[index + 1];
    end
    return newArray;
end