function SafeMinus(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left - right;
end
function SafeMultiply(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left * right;
end
function SafePlus(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left + right;
end
function SafeDivide(left, right)
    if left == nil or right == nil or right == 0 then
        return nil;
    end
    return left / right;
end
function SafeGreater(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left > right;
end
function SafeGE(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left >= right;
end
function SafeLess(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left < right;
end
function SafeLE(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left <= right;
end