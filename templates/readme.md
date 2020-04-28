# Templates

## strategy_simple

Example of the simplest possible strategy. 

Features:

- Timeframe to trade
- Live/End of bar execution
- Stop/limit
- Close on opposite
- Alerts: message, sound, email

### Parameters

#### Price type

What price stream to use: bid or ask. This stream will be used as a source for the indicators.

#### Timeframe

What timeframe to use for the indicator source.

#### Allow strategy to trade

You can enable/disable trading using this parameter. You will get alerts only when trading is disabled.

#### Execution type

Strategy can check conditions on every tick (Live) or when the bar has closed. Live method will give you a faster reaction time but gives more false signals.

#### Account to trade on

Your account

#### Trade amount in lots

Defines the size of the opened positions. Defined in lots. The size of the lot depends on your account and symbol you trade. So, "1" can open "1 000 USD" position or "100 000 USD" positions depending on the type of your account. 

#### Set stop

Whether to set the stop for the opened trades. Used with "Stop, pips" parameter

#### Stop, pips

Distance to the stop order in pips.

#### Trailing stop order

Whether to use trailing for the stop order. Used with "Trailing in pips" parameter

#### Trailing in pips

Trailing stop in pips. Use "1" for dynamic trailing or >= 10 for the fixed trailing step.

#### Setp limit

Whether to set the limit for the opened trades. Used with "Limit, pips" parameter.

#### Limit, pips

Distance to the limit order in pips. 

#### Close on opposite

When set to true the strategy will close opposite trades when the signal detected. 
For example: if the strategy detects "long/buy" signal and then it will look for short trades and close them. 

#### Custom ID

Custom identification for the trades. Used to work with a set of trades only. 
For example: if you set custom ID, the signal is detected and the Close on the opposite feature is turned on then the strategy will ignore trades with Custom ID other than specified. This way you can run several strategies on the same instrument along with each other and they to dot touch trades from other strategies (if every strategy will use its own unique custom ID).

### Alerts parameters

#### Convert the date to

This option allows you to select timezone to use in the messages. The strategy will format dates in the messages in that selected timezone.

#### Show Alert

The strategy will show you a dialog with the alert when this option enabled.

#### Play sound

The strategy will play a sound on alert. Used with "Sound file" and "Recurrent sound" parameters.

#### Sound file

Sound file to play when the alert detected.

#### Recurrent sound

The strategy will play the sound in a loop when this option enabled.

#### Send email

The strategy will send you an email when this option enabled. Used with "Email" parameter.

#### Email

Email to send the alert to.

## strategy_simple_MTF_MI

strategy_simple with multi-instrument multi-timeframe trading feature.

## strategy_advanced/strategy_advanced_plus

You will need to copy-paste code for \\strategies\\custom\\snippets\\*.lua file at the end of the file. You can find these snippets on github: https://github.com/sibvic/fxts2-templates

Strategy template which includes all supported features so far. It's the most complex template. 

Features set:

- Multi-position entry (plus only)
- Signal reversal
- Heikin-Ashi as a source (plus only)
- Entry/exit timeframes
- Close on opposite
- Position cap
- Amount types: lots, % of equity, Risk % of equity
- Stop: no, pips, high/low, ATR (plus only)
- Close position on daily profit (plus only)
- Trading time
- Mandatory closing
- Alerts (including Telegram and Discord) (plus only)
- DDE alerts export (plus only)
- Order execution on other platforms (plus only)

[Description of template parameters](https://github.com/sibvic/fxts2-templates/wiki/base_strategy-Template-parameters)

You can setup the template by changing variables in "CUSTOMIZATION SECTION" and "USER DEFINED SECTION".

### STRATEGY_NAME

Strategy name.

### STRATEGY_VERSION 

Strategy version.

### PositionsCount

Number of positions to open with individual set of stop/limit parameters.

### IncludeTradingTime

Trading time parameters. You can turn it off if you never use it.

### UseOwnPositionsOnly

Whether to take into account positions created only by this strategy or take into account positions created by other strategies and by the user as well. If set to false the strategy may close positions created by the user and other strategies.

### DISABLE_ATR_STOP_LIMIT

Disables ATR stop and limit. 

### DISABLE_LIMIT_TRAILING

Disabled limit trailing.

### USE_CUSTOM_TIMEFRAMES

Enables custom timeframes like "m2".

### ENFORCE_entry_execution_type, ENFORCE_exit_execution_type

Allows to set entry/exit execution type and hide the related parameters.

### EXIT_TIMEFRAME_IN_PARAMS

Allows to hide separamet exit timeframe. When set to true the exit rules will use the same timeframe as entry rules.

### DISABLE_EXIT

Allows to disable exit logic in the strategy.

### DISABLE_HA_SOURCE

Allows to disable HA source in the strategy.

### DDEAlertsSupport

Support of alerts export using DDE (like Excel). Set it to true/false

### HISTORY_PRELOAD_BARS

History preload count

### RequestBidAsk

Whether to request both prices: bid and ask

### ENFORCE_POSITION_CAP

When set to true the parameters will close hidden and the features will be enabled and limited to 1 position only.

### CustomTimeframeDefined

Set it to true when you define your own timeframe and is_bid parameters.

### function CreateParameters()

Add your parameters in this function

### function CreateStopParameters(params, id)

Creates custom stop parameters. You can delete this function if you don't need custom stop logic. You can return false to use default stop logic and parameters.

### function CreateLimitParameters(params, id)

Creates custom limit parameters. You can delete this function if you don't need custom limit logic. You can return false to use default limit logic and parameters.

### function CreateIndicators(source)

Create your indicators in this function.

### function UpdateIndicators()
    
Update your indicators in this function.

### function GetEntryRate(source, bs, period)

TODO

### function SetCustomStop(position_desc, command, period) 

TODO

### function SetCustomLimit(position_desc, command, period) 

TODO

### function SaveCustomStopParameters(position_strategy, id) 

TODO

### function SaveCustomLimitParameters(position_strategy, id) 

TODO

### function CreateCustomBreakeven(position_desc, result, period) 

TODO

### function CreateCustomActions()

In this method you can add trading actions. There is two kind of actions: user-customizable and fixed ones. Add your actions to EntryActions or ExitActions. EntryActions will create entry orders and ExitActions will create exit orders.

#### User-customizable action

User-customizable action is an action which can be selected in the parameters. You can add it by calling AddAction in the CreateParameters function and CreateAction in this function.

Usage:

    local action1, isEntry1 = CreateAction(1);
    action1.Data = nil;
    action1.IsPass = function (source, period, periodFromLast, data) 
        return false; -- TODO: implement
    end
    if isEntry1 then
        EntryActions[#EntryActions + 1] = action1;
    else
        ExitActions[#ExitActions + 1] = action1;
    end

#### Fixed actions

Usage:

    local exitLongAction = {};
    exitLongAction.ActOnSwitch = false;
    exitLongAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    local exitShortAction = {};
    exitShortAction.ActOnSwitch = false;
    exitShortAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    local enterLongAction = {};
    enterLongAction.ActOnSwitch = true;
    enterLongAction.GetLog = function (source, period, periodFromLast, data)
        return "";
    end
    enterLongAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    local enterShortAction = {};
    enterShortAction.ActOnSwitch = true;
    enterShortAction.GetLog = function (source, period, periodFromLast, data)
        return "";
    end
    enterShortAction.IsPass = function (source, period, periodFromLast, data)
        return false; -- TODO: implement
    end

    if instance.parameters.Direction == "direct" then
        exitLongAction.Execute = CloseLong;
        exitShortAction.Execute = CloseShort;
        enterLongAction.Execute = GoLong;
        enterShortAction.Execute = GoShort;
        enterLongAction.ExecuteData = CreateBuyPositions();
        enterShortAction.ExecuteData = CreateSellPositions();
    else
        exitLongAction.Execute = CloseShort;
        exitShortAction.Execute = CloseLong;
        enterLongAction.Execute = GoShort;
        enterShortAction.Execute = GoLong;
        enterLongAction.ExecuteData = CreateSellPositions();
        enterShortAction.ExecuteData = CreateBuyPositions();
    end
    ExitActions[#ExitActions + 1] = exitLongAction;
    ExitActions[#ExitActions + 1] = exitShortAction;
    EntryActions[#EntryActions + 1] = enterLongAction;
    EntryActions[#EntryActions + 1] = enterShortAction;

## ZigZag

Template for the ZigZag indicators.

## divergence_indicator

Template for divergence indicators.

## Dashboard

Template of dashboard/scanner indicator.

## Dashboard_light

Light version of dashboard/scanner indicator. Only basic information are drawn. Optimized for the performance.

## Dashboard_light_instruments

The same as Dashboard_light for without timeframes. Only instruments will be shown.

## Heatmap

Template of a heatmap. Shows green/red/gray rectangle for each condition for each bar. Add your conditions to "conditions". Each condition should implement function GetSignal(period) and function Update(period, mode).

GetSignal should return 1 (green)/-1 (red)/other (gray) value.

## trailing_stop

Strategy template for a custom trailing stop.

## stop_limit_targets

Draws lines for the stop/limit targets.