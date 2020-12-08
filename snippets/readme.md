# Snippets

## signaler_indi

Shows signals of the indicator on the chart and sends an alert when running live.

You need to define alerts at the top of the file:

    local alerts = 
    { 
        {
            Stage = 102,
            UpCondition = function (period)
            end,
            DownCondition = function (period)
            end,
            OnChange = true
        }
    };

Stage: drawing stage. For example, 102: main chart for the oscillator, 2 - chart where the indicator was placed. You can find more information in the Indicore help.

OnChange: 

- when set to true: every condition will be called 2 times: for period and for period - 1. The arrow will be drawn when period returns true and period - 1 return false.
- when set to false: the arrow will be drawn every time condition returns true.

## Signaler

Sends an alert in the next ways: message dialog, popup (indicators only), sound alert, email, log, external receiver (Telegram/Discord/other trading platforms), DDE (like Excel). It can send commands to execute orders to other platforms (MT4/MT5/FXTS2).

## _empty_module

New module template.

## breakeven

Implements breakeven logic.

### PartialClose

Create a controller for a partial close on profit.

## DailyProfitLimit

Stops trading when the daily profit limit is hit.

## tables_monitor

Monitors tables and makes callbacks on table events.

## trading_logic

Basic trading logic. 

### SubscribeHistory

Subscribes for a source. Uses existing source if the source with the same parameters was already subscribed.

## trading

Trading routines.

### EntryOrder function

Create an order builder.

#### function builder:SetAccountID(accountID)

#### function builder:SetAmount(amount)

Sets number of lots.

#### function builder:SetRiskPercentOfEquityAmount(percent)

Sets number of lots in risk of % of equity. Stop need to be set as well. The number of lots will be calculated to loss % of equity in case the stop will be triggered. The stop need to be specified.

#### function builder:SetPercentOfEquityAmount(percent)

Sets number of lots in % of equity. The number of lots will be calculated to use % of equity (usable margin).

#### function builder:UpdateOrderType()

#### function builder:SetSide(buy_sell) 

#### function builder:SetRate(rate) 

#### function builder:SetLimit(limit)

#### function builder:UseDefaultCustomId()

#### function builder:SetCustomID(custom_id)

#### function builder:GetValueMap()

#### function builder:Execute()

Executes an order.

### MarketOrder function

Create market order.

#### function builder:SetAccountID(accountID)

#### function builder:SetAmount(amount)

Sets number of lots.

#### function builder:SetRiskPercentOfEquityAmount(percent)

Sets number of lots in risk of % of equity. Stop need to be set as well. The number of lots will be calculated to loss % of equity in case the stop will be triggered. The stop need to be specified.

#### function builder:SetPercentOfEquityAmount(percent)

Sets number of lots in % of equity. The number of lots will be calculated to use % of equity (usable margin).

#### function builder:SetSide(buy_sell)

#### function builder:SetPipLimit(limit_type, limit)

#### function builder:SetLimit(limit)

#### function builder:SetPipStop(stop_type, stop, trailing_stop)

#### function builder:SetStop(stop, trailing_stop)

#### function builder:SetCustomID(custom_id)

#### function builder:GetValueMap()

#### function builder:AddMetadata(id, val)

#### function builder:FillFields()

#### function builder:Execute()

Executes an order

## averages

Snippet for creation of averages and it's parameters.

## CellsBuilder

Draws a grid of strings using owner draw feature.

Example:

    local title = "Title";
    local title_w, title_h = context:measureText(FONT_ID, title, 0);
    CellsBuilder:Clear(context);
    for i, level in ipairs(levels) do
        CellsBuilder:Add(FONT_ID, tostring(level.name), text_color, 1, i, context.LEFT);
        local text = tostring(level.value);
        CellsBuilder:Add(FONT_ID, text, text_color, 2, i, context.LEFT);
    end

    local width = math.max(title_w, CellsBuilder:GetTotalWidth());
    context:drawText(FONT_ID, title, text_color, -1, context:right() - width, context:top(), context:right(), context:top() + title_h, 0);
    CellsBuilder:Draw(context:right() - width, context:top() + title_h * 1.2);

## sources

Helps to load several history streams and controls it's loading.

## storage

Provides persistent storage.

## MT4

Functions for partial emulation of MT4 features. Makes it easier to convert indicators and EA from MT4.