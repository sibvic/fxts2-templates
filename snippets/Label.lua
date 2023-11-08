Label = {};
Label.AllLabels = {};
function Label:New(id, period, price)
    local newLabel = {};
    newLabel.X = period;
    newLabel.Y = price;
    newLabel.Text = "";
    newLabel.BGColor = core.colors().Black;
    newLabel.TextColor = core.colors().Red;
    function newLabel:SetText(text)
        self.Text = text;
        return self;
    end
    function newLabel:SetColor(clr)
        self.BGColor = clr;
        return self;
    end
    function newLabel:SetTextColor(clr)
        self.TextColor = clr;
        return self;
    end
    function newLabel:Draw(stage, context)
        local W, H = context:measureText(Label.FontId, self.Text, context.LEFT);
        visible, y = context:pointOfPrice(newLabel.Y);
        x1, x = context:positionOfBar(newLabel.X)
        context:drawText(Label.FontId, self.Text, self.TextColor, -1, x - W / 2, y - H / 2, x + W /2, y + H / 2, 0);
    end
    self.AllLabels[id] = newLabel;
    return newLabel;
end
function Label:Draw(stage, context)
    if stage ~= 2 then
        return;
    end
    if Label.FontId == nil then
        Label.FontId = 1;
        context:createFont(Label.FontId, "Arial", 0, context:pointsToPixels(10), context.LEFT);
    end
    for id, label in pairs(self.AllLabels) do
        label:Draw(stage, context);
    end
end