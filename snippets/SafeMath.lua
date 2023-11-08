function SafeMinus(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left - right;
end
function SafeGrater(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left > right;
end
function SafeLess(left, right)
    if left == nil or right == nil then
        return nil;
    end
    return left < right;
end