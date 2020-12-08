local MT4objects = {};
local OBJPROP_STYLE = "OBJPROP_STYLE";
local OBJPROP_WIDTH = "OBJPROP_WIDTH";
local OBJPROP_COLOR = "OBJPROP_COLOR";
local OBJPROP_BACK = "OBJPROP_BACK";
local OBJPROP_RAY = "OBJPROP_RAY";
local OBJPROP_TIME1 = "OBJPROP_TIME1";
local OBJPROP_PRICE1 = "OBJPROP_PRICE1";
local OBJPROP_TIME2 = "OBJPROP_TIME2";
local OBJPROP_PRICE2 = "OBJPROP_PRICE2";
local OBJPROP_ARROWCODE = "OBJPROP_ARROWCODE";
local OBJ_TEXT = "OBJ_TEXT";
local STYLE_DASH = "DASH";
local FALSE = false;
local TRUE = true;
local SYMBOL_LEFTPRICE = "SYMBOL_LEFTPRICE";
local SYMBOL_RIGHTPRICE = "SYMBOL_RIGHTPRICE";
local OBJ_TREND = "OBJ_TREND";
local OBJ_CHANNEL = "OBJ_CHANNEL";
local OBJ_ARROW = "OBJ_ARROW";
local OBJ_TRIANGLE = "OBJ_TRIANGLE";
local MT4Pens = {};
local MT4_LAST_PEN = 1;
function MT4GetPen(context, color)
    if MT4Pens[color] == nil then
        context:createPen(MT4_LAST_PEN, context.SOLID, 1, color);
        MT4Pens[color] = MT4_LAST_PEN;
    end
    return MT4Pens[color];
end
function MT4DrawTrend(context, obj)
    if obj[OBJPROP_TIME1] == 0 or obj[OBJPROP_TIME1] == nil then
        return;
    end
    if obj[OBJPROP_TIME2] == 0 or obj[OBJPROP_TIME2] == nil then
        return;
    end
    local pen = MT4GetPen(context, obj[OBJPROP_COLOR]);
    local x1 = context:positionOfDate(obj[OBJPROP_TIME1])
    local x2 = context:positionOfDate(obj[OBJPROP_TIME2])
    local _, y1 = context:pointOfPrice(obj[OBJPROP_PRICE1]);
    local _, y2 = context:pointOfPrice(obj[OBJPROP_PRICE2]);
    context:drawLine(pen, x1, y1, x2, y2);
end
function MT4DrawChannel(context, obj)
end
function MT4DrawArrow(context, obj)
end
function MT4DrawTriangle(context, obj)
end
function DrawMT4(stage, context)
    if stage ~= 2 then
        return;
    end
    if not MT4Init then
        MT4Init = true;
    end
    for id, obj in pairs(MT4objects) do
        if obj["OBJECT_TYPE"] == OBJ_TREND then
            MT4DrawTrend(context, obj);
        elseif obj["OBJECT_TYPE"] == OBJ_CHANNEL then
            MT4DrawChannel(context, obj);
        elseif obj["OBJECT_TYPE"] == OBJ_ARROW then
            MT4DrawArrow(context, obj);
        elseif obj["OBJECT_TYPE"] == OBJ_TRIANGLE then
            MT4DrawTriangle(context, obj);
        end
    end
end
function EnsureObjectCreated(id)
    id = string.upper(id);
    if MT4objects[id] == nil then
        MT4objects[id] = {};
    end
end
function ObjectSetText(id, text, font_size, font_name, font_color)
    id = string.upper(id);
    MT4objects[id]["TEXT"] = text;
    MT4objects[id]["FONT_SIZE"] = font_size;
    MT4objects[id]["FONT_NAME"] = font_name;
    MT4objects[id]["FONT_COLOR"] = font_color;
end
function ObjectSet(id, prop, val)
    id = string.upper(id);
    MT4objects[id][prop] = val;
end
function ObjectMove(id, index, x, y)
    if x == nil or y == nil then
        return;
    end
    id = string.upper(id);
    MT4objects[id]["OBJPROP_TIME" .. (index + 1)] = x;
    MT4objects[id]["OBJPROP_PRICE" .. (index + 1)] = y;
end
function ObjectGetValueByShift(id, shift)
    id = string.upper(id);
    local index_1 = core.findDate(source, MT4objects[id][OBJPROP_TIME1], false);
    local index_2 = core.findDate(source, MT4objects[id][OBJPROP_TIME2], false);
    local rate = (MT4objects[id][OBJPROP_PRICE2] - MT4objects[id][OBJPROP_PRICE1]) / (index_2 - index_1);
    return MT4objects[id][OBJPROP_PRICE1] + (shift - index_1) * rate;
end
function ObjectGet(id, prop)
    id = string.upper(id);
    return MT4objects[id][prop];
end
function ObjectDelete(id)
    id = string.upper(id);
    MT4objects[id] = nil;
end
function ObjectCreate(id, type, sub_window, x1, y1, x2, y2, x3, y3)
    id = string.upper(id);
    EnsureObjectCreated(id);
    MT4objects[id]["OBJECT_TYPE"] = type;
    MT4objects[id]["SUBWINDOW"] = sub_window;
    ObjectMove(id, 0, x1, y1);
    ObjectMove(id, 1, x2, y2);
    ObjectMove(id, 2, x3, y3);
end