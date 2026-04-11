Matrix = {};
function Matrix:Get(matrix, row, column)
    if matrix == nil then
        return nil;
    end
    return matrix:Get(row, column);
end
function Matrix:Set(matrix, row, column, value)
    if matrix == nil then
        return nil;
    end
    return matrix:Set(row, column, value);
end
function Matrix:Row(matrix, row)
    if matrix == nil then
        return nil;
    end
    return matrix:Row(row);
end
function Matrix:New(rows, columns, initial_value)
    local matrix = {};
    matrix.rows = {};
    for i = 1, rows, 1 do
        matrix.rows[i] = {};
        for ii = 1, columns, 1 do
            matrix.rows[i][ii] = initial_value;
        end
    end
    function matrix:Get(row, column)
        return self.rows[row + 1][column + 1];
    end
    function matrix:Set(row, column, value)
        self.rows[row + 1][column + 1] = value;
    end
    function matrix:Row(row)
        local raw = self.rows[row + 1];
        if raw == nil then
            return nil;
        end
        local n = #raw;
        local newArray = Array:New(n, nil);
        for i = 1, n do
            newArray.arr[i] = raw[i];
        end
        return newArray;
    end
    return matrix;
end