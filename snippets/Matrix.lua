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
function Matrix:Transpose(matrix)
    if matrix == nil then
        return nil;
    end
    local rowCount = #matrix.rows;
    local colCount = rowCount > 0 and #matrix.rows[1] or 0;
    local result = Matrix:New(colCount, rowCount, nil);
    for r = 1, rowCount do
        for c = 1, colCount do
            result:Set(r - 1, c - 1, matrix:Get(r - 1, c - 1));
        end
    end
    return result;
end
function Matrix:Inv(matrix)
    if matrix == nil then
        return nil;
    end
    local n = #matrix.rows;
    local colCount = n > 0 and #matrix.rows[1] or 0;
    if n ~= colCount or n == 0 then
        return nil;
    end
    local a = {};
    for r = 1, n do
        a[r] = {};
        for c = 1, n do
            a[r][c] = matrix:Get(r - 1, c - 1);
        end
    end
    local inv = {};
    for r = 1, n do
        inv[r] = {};
        for c = 1, n do
            inv[r][c] = r == c and 1 or 0;
        end
    end
    local pivotEpsilon = 1e-14;
    for col = 1, n do
        local pivotRow = col;
        local maxVal = math.abs(a[col][col]);
        for r = col + 1, n do
            local v = math.abs(a[r][col]);
            if v > maxVal then
                maxVal = v;
                pivotRow = r;
            end
        end
        if maxVal < pivotEpsilon then
            return Matrix:New(n, n, nil);
        end
        if pivotRow ~= col then
            a[col], a[pivotRow] = a[pivotRow], a[col];
            inv[col], inv[pivotRow] = inv[pivotRow], inv[col];
        end
        local pivot = a[col][col];
        for c = 1, n do
            a[col][c] = a[col][c] / pivot;
            inv[col][c] = inv[col][c] / pivot;
        end
        for r = 1, n do
            if r ~= col then
                local factor = a[r][col];
                if factor ~= 0 then
                    for c = 1, n do
                        a[r][c] = a[r][c] - factor * a[col][c];
                        inv[r][c] = inv[r][c] - factor * inv[col][c];
                    end
                end
            end
        end
    end
    local result = Matrix:New(n, n, nil);
    for r = 1, n do
        for c = 1, n do
            result:Set(r - 1, c - 1, inv[r][c]);
        end
    end
    return result;
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