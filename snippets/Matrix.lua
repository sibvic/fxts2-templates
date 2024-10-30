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
function Matrix:NewFloat(rows, columns, initial_value)
    return Matrix:NewMatrix(rows, columns, initial_value);
end
function Matrix:NewTable(rows, columns, initial_value)
    return Matrix:NewMatrix(rows, columns, initial_value);
end
function Matrix:NewMatrix(rows, columns, initial_value)
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
    return matrix;
end