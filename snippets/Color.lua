Color = {};
function Color:GetR(color)
    return color % 256;
end
function Color:GetG(color)
    local R = Color:GetR(color);
    return ((color - R) / 256) % 256;
end
function Color:GetB(color)
    local R = Color:GetR(color);
    local G = Color:GetG(color);
    return ((color - R - G*256) /(256 * 256)) % 256;
end
function Color:GetRGB(color)
    local R = Color:GetR(color);
    local G = Color:GetG(color);
    return R, G, ((color - R - G*256) /(256 * 256)) % 256;
end
function Color:FromGradient(value, bottom_value, top_value, bottom_color, top_color)
    if (value == nil or top_value == nil) then
        return bottom_color;
    end
    if (bottom_value == nil) then
        return top_color;
    end
    local range = top_value - bottom_value;
    local rate = (value - bottom_value) / range;
    if (rate > 1) then
        return bottom_color;
    end
    if (rate < 0) then
        return top_color;
    end
    
    local bottomR, bottomG, bottomB = Color:GetRGB(bottom_color);
    local topR, topG, topB = Color:GetRGB(top_color);
    return core.rgb(bottomR + math.floor(rate * (topR - bottomR)), 
        bottomG + math.floor(rate * (topG - bottomG)), 
        bottomB + math.floor(rate * (topB - bottomB)), 0);
end