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
function Matrix:Col(matrix, column)
    if matrix == nil then
        return nil;
    end
    return matrix:Col(column);
end
function Matrix:Mult(matrix1, id2)
    if matrix1 == nil or id2 == nil then
        return nil;
    end
    if id2.rows ~= nil then
        return Matrix:MultMatrix(matrix1, id2);
    end
    if id2.arr ~= nil then
        return Matrix:MultArray(matrix1, id2);
    end
    return Matrix:MultScalar(matrix1, id2);
end
function Matrix:MultMatrix(matrix1, matrix2)
    local rowCount1 = #matrix1.rows;
    local colCount1 = rowCount1 > 0 and #matrix1.rows[1] or 0;
    local rowCount2 = #matrix2.rows;
    if colCount1 ~= rowCount2 then
        return nil;
    end
    local colCount2 = rowCount2 > 0 and #matrix2.rows[1] or 0;
    local result = Matrix:New(rowCount1, colCount2, nil);
    for r = 1, rowCount1 do
        for c = 1, colCount2 do
            local sum = 0;
            local ok = true;
            for k = 1, colCount1 do
                local v1 = matrix1:Get(r - 1, k - 1);
                local v2 = matrix2:Get(k - 1, c - 1);
                if v1 == nil or v2 == nil then
                    ok = false;
                    break;
                end
                sum = sum + v1 * v2;
            end
            if ok then
                result:Set(r - 1, c - 1, sum);
            end
        end
    end
    return result;
end
function Matrix:MultArray(matrix, array)
    local rowCount = #matrix.rows;
    local colCount = rowCount > 0 and #matrix.rows[1] or 0;
    local result = Array:New(rowCount, nil);
    for r = 1, rowCount do
        local sum = 0;
        local ok = true;
        for c = 1, colCount do
            local m = matrix:Get(r - 1, c - 1);
            local v = array:Get(c - 1);
            if m == nil or v == nil then
                ok = false;
                break;
            end
            sum = sum + m * v;
        end
        if ok then
            result:Set(r - 1, sum);
        end
    end
    return result;
end
function Matrix:MultScalar(matrix, scalar)
    local rowCount = #matrix.rows;
    local colCount = rowCount > 0 and #matrix.rows[1] or 0;
    local result = Matrix:New(rowCount, colCount, nil);
    for r = 1, rowCount do
        for c = 1, colCount do
            local v = matrix:Get(r - 1, c - 1);
            if v ~= nil then
                result:Set(r - 1, c - 1, v * scalar);
            end
        end
    end
    return result;
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
    function matrix:Col(column)
        local rowCount = #self.rows;
        if rowCount == 0 then
            return Array:New(0, nil);
        end
        local colIndex = column + 1;
        if colIndex < 1 or colIndex > #self.rows[1] then
            return nil;
        end
        local newArray = Array:New(rowCount, nil);
        for r = 1, rowCount do
            newArray.arr[r] = self.rows[r][colIndex];
        end
        return newArray;
    end
    return matrix;
end