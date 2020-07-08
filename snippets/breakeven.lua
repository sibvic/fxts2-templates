breakeven = {};
-- public fields
breakeven.Name = "Breakeven";
breakeven.Version = "3.0";
breakeven.Debug = false;
--private fields
breakeven._moved_stops = {};
breakeven._request_id = nil;
breakeven._used_stop_orders = {};
breakeven._ids_start = nil;
breakeven._trading = nil;
breakeven._controllers = {};

function breakeven:trace(str) if not self.Debug then return; end core.host:trace(self.Name .. ": " .. str); end
function breakeven:OnNewModule(module)
    if module.Name == "Trading" then 
        self._trading = module;
    elseif module.Name == "Tables monitor" then
        module:ListenCloseTrade(BreakevenOnClosedTrade);
    elseif module.Name == "Signaler" then
        self._signaler = module;
    elseif module.Name == "Storage" then
        self._storage = module;
    end
end
function BreakevenOnClosedTrade(closed_trade)
    for _, controller in ipairs(breakeven._controllers) do
        if controller.TradeID == closed_trade.TradeID then
            controller._trade = core.host:findTable("trades"):find("TradeID", closed_trade.TradeIDRemain);
            controller.TradeID = closed_trade.TradeIDRemain;
        elseif controller.TradeID == closed_trade.TradeIDRemain then
            controller._executed = true;
            controller._close_percent = nil;
        end
    end
end
function breakeven:RegisterModule(modules) for _, module in pairs(modules) do self:OnNewModule(module); module:OnNewModule(self); end modules[#modules + 1] = self; self._ids_start = (#modules) * 100; end

function breakeven:Init(parameters)
end

function breakeven:Prepare(nameOnly)
    if breakeven._storage == nil then
        return;
    end
    local enum = core.host:findTable("trades"):enumerator();
    local trade = enum:next();
    while trade ~= nil do
        if breakeven._storage:ReadNumber("BE_" .. trade.TradeID) == 1 then
            self:CreateBreakeven():Restore(trade.TradeID);
        end
        trade = enum:next();
    end
end

function breakeven:ReleaseInstance()
    for _, controller in ipairs(self._controllers) do
        if controller.Save ~= nil then
            controller:Save();
        end
    end
end

function breakeven:ExtUpdate(id, source, period)
    for _, controller in ipairs(self._controllers) do
        controller:DoBreakeven();
    end
end

function breakeven:round(num, idp)
    if idp and idp > 0 then
        local mult = 10 ^ idp
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end

function breakeven:CreateBaseController()
    local controller = {};
    controller._parent = self;
    controller._executed = false;
    function controller:SetTrade(trade)
        self._trade = trade;
        self.TradeID = trade.TradeID;
        return self;
    end
    function controller:GetOffer()
        if self._offer == nil then
            local order = self:GetOrder();
            if order == nil then
                order = self:GetTrade();
            end
            self._offer = core.host:findTable("offers"):find("Instrument", order.Instrument);
        end
        return self._offer;
    end
    function controller:SetRequestID(trade_request_id)
        self._request_id = trade_request_id;
        return self;
    end
    function controller:GetOrder()
        if self._order == nil and self._request_id ~= nil then
            self._order = core.host:findTable("orders"):find("RequestID", self._request_id);
            if self._order ~= nil then
                self.OrderID = self._order.OrderID;
            end
        end
        return self._order;
    end
    function controller:GetTrade()
        if self._trade == nil and self._request_id ~= nil then
            self._trade = core.host:findTable("trades"):find("OpenOrderReqID", self._request_id);
            if self._trade == nil then
                return nil;
            end
            self.TradeID = self._trade.TradeID;
            self._initial_limit = self._trade.Limit;
            self._initial_stop = self._trade.Stop;
        end
        return self._trade;
    end
    return controller;
end

function breakeven:CreateMartingale(openFunction)
    local controller = self:CreateBaseController();
    controller.OpenFunction = openFunction;
    function controller:SetStep(step)
        self._step = step;
        return self;
    end
    function controller:SetLotSizingValue(martingale_lot_sizing_val)
        self._martingale_lot_sizing_val = martingale_lot_sizing_val;
        return self;
    end
    function controller:SetStop(Stop)
        self._martingale_stop = Stop;
        return self;
    end
    function controller:SetLimit(Limit)
        self._martingale_limit = Limit;
        return self;
    end
    function controller:DoBreakeven()
        if self._executed then
            return false;
        end
        local trade = self:GetTrade();
        if trade == nil then
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        if self._current_lot == nil then
            self._current_lot = trade.AmountK;
        end
        local pipSize = self:GetOffer().PointSize;
        if trade.BS == "B" then
            local movement = (trade.Close - trade.Open) / pipSize;
            local enoughtMovement = false;
            if self._step >= 0 then
                enoughtMovement = movement <= -self._step;
            else
                enoughtMovement = movement >= -self._step;
            end
            if enoughtMovement then
                self._current_lot = self._current_lot * self._martingale_lot_sizing_val;
                local result = self.OpenFunction("B", math.floor(self._current_lot + 0.5), trade);
                self._trade = nil;
                self:SetRequestID(result.RequestID);
                if self._signaler ~= nil then
                    local command = string.format("action=create symbol=%s side=buy quantity=%s"
                        , trade.Instrument
                        , tostring(math.floor(self._current_lot + 0.5)));
                    self._signaler:SendCommand(command);
                end
                return true;
            end
        else
            local movement = (trade.Open - trade.Close) / pipSize;
            if self._step >= 0 then
                enoughtMovement = movement <= -self._step;
            else
                enoughtMovement = movement >= -self._step;
            end
            if enoughtMovement then
                self._current_lot = self._current_lot * self._martingale_lot_sizing_val;
                local result = self.OpenFunction("S", math.floor(self._current_lot + 0.5), trade);
                self._trade = nil;
                self:SetRequestID(result.RequestID);
                if self._signaler ~= nil then
                    local command = string.format("action=create symbol=%s side=sell quantity=%s"
                        , trade.Instrument
                        , tostring(math.floor(self._current_lot + 0.5)));
                    self._signaler:SendCommand(command);
                end
                return true;
            end
        end
        self:UpdateStopLimits();
        return true;
    end
    function controller:CloseAll()
        core.host:trace("Closing all positions");
        local it = trading:FindTrade():WhenCustomID(CustomID)
        it:Do(function (trade) trading:Close(trade); end);
        if self._signaler ~= nil then
            signaler:SendCommand("action=close");
        end
        self._executed = true;
    end
    function controller:UpdateStopLimits()
        local trade = self:GetTrade();
        if trade == nil then
            return;
        end
        local offer = self:GetOffer();
        local bAmount = 0;
        local bPriceSumm = 0;
        local sAmount = 0;
        local sPriceSumm = 0;
        trading:FindTrade()
            :WhenCustomID(CustomID)
            :Do(function (trade)
                if trade.BS == "B" then
                    bAmount = bAmount + trade.AmountK
                    bPriceSumm = bPriceSumm + trade.Open * trade.AmountK;
                else
                    sAmount = sAmount + trade.AmountK
                    sPriceSumm = sPriceSumm + trade.Open * trade.AmountK;
                end
            end);
        local avgBPrice = bPriceSumm / bAmount;
        local avgSPrice = sPriceSumm / sAmount;
        local totalAmount = bAmount + sAmount;
        local avgPrice = avgBPrice * (bAmount / totalAmount) + avgSPrice * (sAmount / totalAmount);
        local stopPrice, limitPrice;
        if trade.BS == "B" then
            if self._martingale_stop ~= nil then
                stopPrice = avgPrice - self._martingale_stop * offer.PointSize;
                if trade.Close <= stopPrice then
                    self:CloseAll();
                end
                return;
            end
            if self._martingale_limit ~= nil then
                limitPrice = avgPrice + self._martingale_limit * offer.PointSize;
                if trade.Close >= limitPrice then
                    self:CloseAll();
                end
            end
            return;
        end
        if self._martingale_stop ~= nil then
            stopPrice = avgPrice + self._martingale_stop * offer.PointSize;
            if trade.Close >= stopPrice then
                self:CloseAll();
                return;
            end
        end
        if self._martingale_limit ~= nil then
            limitPrice = avgPrice - self._martingale_limit * offer.PointSize;
            if trade.Close <= limitPrice then
                self:CloseAll();
            end
        end
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

breakeven.STOP_ID = 1;
breakeven.LIMIT_ID = 2;

function breakeven:CreateOrderTrailingController()
    local controller = self:CreateBaseController();
    function controller:SetTrailingTarget(id)
        self._target_id = id;
        return self;
    end
    function controller:MoveUpOnly()
        self._up_only = true;
        return self;
    end
    function controller:SetIndicatorStream(stream, multiplicator, is_distance)
        self._stream = stream;
        self._stream_in_distance = is_distance;
        self._stream_multiplicator = multiplicator;
        return self;
    end
    function controller:SetIndicatorStreamShift(x, y)
        self._stream_x_shift = x;
        self._stream_y_shift = y;
        return self;
    end
    function controller:DoBreakeven()
        if self._executed then
            return false;
        end
        local order = self:GetOrder();
        if order == nil or (self._move_command ~= nil and not self._move_command.Finished) then
            return true;
        end
        if not order:refresh() then
            self._executed = true;
            return false;
        end
        local streamPeriod = NOW;
        if self._stream_x_shift ~= nil then
            streamPeriod = streamPeriod - self._stream_x_shift;
        end
        if not self._stream:hasData(streamPeriod) then
            return true;
        end
        return self:DoOrderTrailing(order, streamPeriod);
    end
    function controller:DoOrderTrailing(order, streamPeriod)
        local new_level;
        local offer = self:GetOffer();
        if self._stream_in_distance then
            local tick = self._stream:tick(streamPeriod) * self._stream_multiplicator;
            if self._stream_y_shift ~= nil then
                tick = tick + self._stream_y_shift * offer.PointSize;
            end
            if order.BS == "B" then
                new_level = breakeven:round(offer.Bid + tick, offer.Digits);
            else
                new_level = breakeven:round(offer.Ask - tick, offer.Digits);
            end
        else
            local tick = self._stream:tick(streamPeriod);
            if self._stream_y_shift ~= nil then
                if order.BS == "B" then
                    tick = tick - self._stream_y_shift * offer.PointSize;
                else
                    tick = tick + self._stream_y_shift * offer.PointSize;
                end
            end
            new_level = breakeven:round(tick, offer.Digits);
        end
        if self._up_only then
            if order.BS == "B" then
                if order.Rate >= new_level then
                    return true;
                end
            else
                if order.Rate <= new_level then
                    return true;
                end
            end
        end
        if self._min_profit ~= nil then
            if order.BS == "B" then
                if (offer.Bid - new_level) / offer.PointSize < self._min_profit then
                    return true;
                end
            else
                if (new_level - offer.Ask) / offer.PointSize < self._min_profit then
                    return true;
                end
            end
        end
        if order.Rate ~= new_level then
            self._move_command = self._parent._trading:ChangeOrder(order, new_level, order.TrlMinMove);
        end
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:CreateIndicatorTrailingController()
    local controller = self:CreateBaseController();
    function controller:SetTrailingTarget(id)
        self._target_id = id;
        return self;
    end
    function controller:MoveUpOnly()
        self._up_only = true;
        return self;
    end
    function controller:SetMinProfit(min_profit)
        self._min_profit = min_profit;
        return self;
    end
    function controller:SetIndicatorStream(stream, multiplicator, is_distance)
        self._stream = stream;
        self._stream_in_distance = is_distance;
        self._stream_multiplicator = multiplicator;
        return self;
    end
    function controller:SetIndicatorStreamShift(x, y)
        self._stream_x_shift = x;
        self._stream_y_shift = y;
        return self;
    end
    function controller:DoBreakeven()
        if self._executed then
            return false;
        end
        local trade = self:GetTrade();
        if trade == nil or (self._move_command ~= nil and not self._move_command.Finished) then
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        local streamPeriod = NOW;
        if self._stream_x_shift ~= nil then
            streamPeriod = streamPeriod - self._stream_x_shift;
        end
        if not self._stream:hasData(streamPeriod) then
            return true;
        end
        if self._target_id == breakeven.STOP_ID then
            return self:DoStopTrailing(trade, streamPeriod);
        elseif self._target_id == breakeven.LIMIT_ID then
            return self:DoLimitTrailing(trade, streamPeriod);
        end
        return self:DoOrderTrailing(trade, streamPeriod);
    end
    function controller:DoStopTrailing(trade, streamPeriod)
        local new_level;
        local offer = self:GetOffer();
        if self._stream_in_distance then
            local tick = self._stream:tick(streamPeriod) * self._stream_multiplicator;
            if self._stream_y_shift ~= nil then
                tick = tick + self._stream_y_shift * offer.PointSize;
            end
            if trade.BS == "B" then
                new_level = breakeven:round(trade.Open - tick, offer.Digits);
            else
                new_level = breakeven:round(trade.Open + tick, offer.Digits);
            end
        else
            local tick = self._stream:tick(streamPeriod);
            if self._stream_y_shift ~= nil then
                if trade.BS == "B" then
                    tick = tick + self._stream_y_shift * offer.PointSize;
                else
                    tick = tick - self._stream_y_shift * offer.PointSize;
                end
            end
            new_level = breakeven:round(self._stream:tick(streamPeriod), offer.Digits);
        end
        if self._min_profit ~= nil then
            if trade.BS == "B" then
                if (new_level - trade.Open) / offer.PointSize < self._min_profit then
                    return true;
                end
            else
                if (trade.Open - new_level) / offer.PointSize < self._min_profit then
                    return true;
                end
            end
        end
        if self._up_only then
            if trade.BS == "B" then
                if trade.Stop >= new_level then
                    return true;
                end
            else
                if trade.Stop <= new_level then
                    return true;
                end
            end
            return true;
        end
        if trade.Stop ~= new_level then
            self._move_command = self._parent._trading:MoveStop(trade, new_level);
        end
        return true;
    end
    function controller:DoLimitTrailing(trade, streamPeriod)
        assert(self._up_only == nil, "Not implemented!!!");
        local new_level;
        local offer = self:GetOffer();
        if self._stream_in_distance then
            local tick = self._stream:tick(streamPeriod) * self._stream_multiplicator;
            if self._stream_y_shift ~= nil then
                tick = tick + self._stream_y_shift * offer.PointSize;
            end
            if trade.BS == "B" then
                new_level = breakeven:round(trade.Open + tick, offer.Digits);
            else
                new_level = breakeven:round(trade.Open - tick, offer.Digits);
            end
        else
            local tick = self._stream:tick(streamPeriod);
            if self._stream_y_shift ~= nil then
                if trade.BS == "B" then
                    tick = tick - self._stream_y_shift * offer.PointSize;
                else
                    tick = tick + self._stream_y_shift * offer.PointSize;
                end
            end
            new_level = breakeven:round(tick, offer.Digits);
        end
        if self._min_profit ~= nil then
            if trade.BS == "B" then
                if (trade.Open - new_level) / offer.PointSize < self._min_profit then
                    return true;
                end
            else
                if (new_level - trade.Open) / offer.PointSize < self._min_profit then
                    return true;
                end
            end
        end
        if trade.Limit ~= new_level then
            self._move_command = self._parent._trading:MoveLimit(trade, new_level);
        end
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:CreateTrailingLimitController()
    local controller = self:CreateBaseController();
    function controller:SetDirection(direction)
        self._direction = direction;
        return self;
    end
    function controller:SetTrigger(trigger)
        self._trigger = trigger;
        return self;
    end
    function controller:SetStep(step)
        self._step = step;
        return self;
    end
    function controller:DoBreakeven()
        if self._executed then
            return false;
        end
        local trade = self:GetTrade();
        if trade == nil or (self._move_command ~= nil and not self._move_command.Finished) then
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        if self._direction == 1 then
            if trade.PL >= self._trigger then
                local offer = self:GetOffer();
                local target_limit;
                if trade.BS == "B" then
                    target_limit = self._initial_limit + self._step * offer.PointSize; 
                else
                    target_limit = self._initial_limit - self._step * offer.PointSize; 
                end
                self._initial_limit = target_limit;
                self._trigger = self._trigger + self._step;
                self._move_command = self._parent._trading:MoveLimit(trade, target_limit);
                return true;
            end
        elseif self._direction == -1 then
            if trade.PL <= -self._trigger then
                local offer = self:GetOffer();
                local target_limit;
                if trade.BS == "B" then
                    target_limit = self._initial_limit - self._step * offer.PointSize; 
                else
                    target_limit = self._initial_limit + self._step * offer.PointSize; 
                end
                self._initial_limit = target_limit;
                self._trigger = self._trigger + self._step;
                self._move_command = self._parent._trading:MoveLimit(trade, target_limit);
                return true;
            end
        else
            core.host:trace("No direction is set for the trailing limit");
        end
        return true;
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:ActionOnTrade(action)
    local controller = self:CreateBaseController();
    controller._action = action;
    function controller:DoBreakeven()
        if self._executed then
            return false;
        end
        local trade = self:GetTrade();
        if trade == nil then
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        self._action(trade, self);
        self._executed = true;
        return true;
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:CreateOnCandleClose()
    local controller = self:CreateBaseController();
    controller._trailing = 0;
    function controller:SetSource(source)
        self._source = source;
        return self;
    end
    function controller:SetBarsToLive(bars_to_live)
        self._bars_to_live = bars_to_live;
        return self;
    end
    function controller:DoBreakeven()
        if self._executed then
            return true;
        end
        local trade = self:GetTrade();
        if trade == nil then
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        local index = core.findDate(self._source, trade.Time, false);
        if self._source:size() - 1 - index >= self._bars_to_live then
            self._command = self._parent._trading:Close(trade);
            self._executed = true;
            return false;
        end
        return true;
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:PartialClose()
    local controller = self:CreateBaseController();
    controller._trailing = 0;
    function controller:SetWhen(when)
        self._when = when;
        return self;
    end
    function controller:SetPartialClose(amountPercent)
        self._close_percent = amountPercent;
        return self;
    end
    function controller:DoPartialClose()
        
    end
    function controller:DoBreakeven()
        if self._close_percent == nil then
            return true;
        end
        local trade = self:GetTrade();
        if trade == nil then
            return true;
        end
        if not trade:refresh() then
            self._close_percent = nil;
            return false;
        end
        if trade.PL >= self._when then
            local base_size = core.host:execute("getTradingProperty", "baseUnitSize", trade.Instrument, trade.AccountID);
            local to_close = breakeven:round(trade.Lot * self._close_percent / 100.0 / base_size) * base_size;
            trading:PartialClose(trade, to_close);
            self._close_percent = nil;
        end
        return true;
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:CreateBreakeven()
    local controller = self:CreateBaseController();
    controller._trailing = 0;
    function controller:SetWhen(when)
        self._when = when;
        return self;
    end
    function controller:SetTo(to)
        self._to = to;
        return self;
    end
    function controller:SetTrailing(trailing)
        self._trailing = trailing
        return self;
    end
    function controller:SetPartialClose(amountPercent)
        self._close_percent = amountPercent;
        return self;
    end
    function controller:getTo()
        local trade = self:GetTrade();
        local offer = self:GetOffer();
        if trade.BS == "B" then
            return offer.Bid - (trade.PL - self._to) * offer.PointSize;
        else
            return offer.Ask + (trade.PL - self._to) * offer.PointSize;
        end
    end
    function controller:DoPartialClose()
        local trade = self:GetTrade();
        if trade == nil then
            self._close_percent = nil;
            return true;
        end
        if not trade:refresh() then
            self._close_percent = nil;
            return false;
        end
        local base_size = core.host:execute("getTradingProperty", "baseUnitSize", trade.Instrument, trade.AccountID);
        local to_close = breakeven:round(trade.Lot * self._close_percent / 100.0 / base_size) * base_size;
        trading:PartialClose(trade, to_close);
        self._close_percent = nil;
        return true;
    end
    function controller:DoBreakeven()
        if self._executed then
            if breakeven._storage ~= nil then
                local trade = self:GetTrade();
                breakeven._storage:SaveNumber("BE_" .. trade.TradeID, 1);
            end
            if self._close_percent ~= nil then
                if self._command ~= nil and self._command.Finished or self._command == nil then
                    return self:DoPartialClose();
                end
            end
            return false;
        end
        local trade = self:GetTrade();
        if trade == nil then
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        if trade.PL >= self._when then
            if self._to ~= nil then
                self._command = self._parent._trading:MoveStop(trade, self:getTo(), self._trailing);
            end
            self._executed = true;
            return false;
        end
        return true;
    end
    function controller:Save()
        if self._executed or breakeven._storage == nil then
            return;
        end
        local trade = self:GetTrade();
        if trade ~= nil then
            breakeven._storage.SaveNumber("BE_" .. trade.TradeID, 1);
            breakeven._storage:SaveNumber("BE_" .. trade.TradeID .. "_when", self._when);
            breakeven._storage:SaveNumber("BE_" .. trade.TradeID .. "_to", self._to);
            breakeven._storage:SaveNumber("BE_" .. trade.TradeID .. "_trailing", self._trailing);
            breakeven._storage:SaveNumber("BE_" .. trade.TradeID .. "_close_percent", self._close_percent);
        end
    end
    function controller:Restore(tradeID)
        self._when = breakeven._storage:ReadNumber("BE_" .. trade.TradeID .. "_when");
        self._to = breakeven._storage:ReadNumber("BE_" .. trade.TradeID .. "_to");
        self._trailing = breakeven._storage:ReadNumber("BE_" .. trade.TradeID .. "_trailing");
        self._close_percent = breakeven._storage:ReadNumber("BE_" .. trade.TradeID .. "_close_percent");
    end
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end

function breakeven:RestoreTrailingOnProfitController(controller)
    controller._parent = self;
    function controller:SetProfitPercentage(profit_pr, min_profit)
        self._profit_pr = profit_pr;
        self._min_profit = min_profit;
        return self;
    end
    function controller:GetClosedTrade()
        if self._closed_trade == nil and self.RequestID ~= nil then
            self._closed_trade = core.host:findTable("closed trades"):find("OpenOrderReqID", self._request_id);
            if self._closed_trade == nil then return nil; end
        end
        if not self._closed_trade:refresh() then return nil; end
        return self._closed_trade;
    end
    function controller:getStopPips(trade)
        local stop = trading:FindStopOrder(trade);
        if stop == nil then
            return nil;
        end
        local offer = self:GetOffer();
        if trade.BS == "B" then
            return (stop.Rate - trade.Open) / offer.PointSize;
        else
            return (trade.Open - stop.Rate) / offer.PointSize;
        end
    end
    function controller:DoBreakeven()
        if self._executed then
            return false;
        end
        if self._move_command ~= nil and not self._move_command.Finished then
            return true;
        end
        local trade = self:GetTrade();
        if trade == nil then
            if self:GetClosedTrade() ~= nil then
                self._executed = true;
            end
            return true;
        end
        if not trade:refresh() then
            self._executed = true;
            return false;
        end
        if trade.PL < self._min_profit then
            return true;
        end
        local new_stop = trade.PL * (self._profit_pr / 100);
        local current_stop = self:getStopPips(trade);
        if current_stop == nil or current_stop < new_stop then
            local offer = self:GetOffer();
            if trade.BS == "B" then
                if not trailing_mark:hasData(NOW) then
                    trailing_mark[NOW] = trade.Close;
                end
                self._move_command = self._parent._trading:MoveStop(trade, trade.Open + new_stop * offer.PointSize);
            else
                if not trailing_mark:hasData(NOW) then
                    trailing_mark[NOW] = trade.Close;
                end
                self._move_command = self._parent._trading:MoveStop(trade, trade.Open - new_stop * offer.PointSize);
            end
            return true;
        end
        return true;
    end
end

function breakeven:CreateTrailingOnProfitController()
    local controller = self:CreateBaseController();
    controller._trailing = 0;
    self:RestoreTrailingOnProfitController(controller);
    self._controllers[#self._controllers + 1] = controller;
    return controller;
end
breakeven:RegisterModule(Modules);