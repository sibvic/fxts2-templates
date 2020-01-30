# Templates

## strategy_simple

Example of the simplest possible strategy. 

## strategy_advanced

Strategy template which includes all supported features so far. It's the most complex template. 

Features set:

- Order execution on other platforms

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

### DDEAlertsSupport

Support of alerts export using DDE (like Excel). Set it to true/false

### HISTORY_PRELOAD_BARS

History preload count

### RequestBidAsk

Whether to request both prices: bid and ask

### ENFORCE_POSITION_CAP

TODO

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

## Heatmap

Template of a heatmap. Shows green/red/gray rectangle for each condition for each bar. Add your conditions to "conditions". Each condition should implement function GetSignal(period) and function Update(period, mode).

GetSignal should return 1 (green)/-1 (red)/other (gray) value.

## trailing_stop

Strategy template for a custom trailing stop.

## stop_limit_targets

Draws lines for the stop/limit targets.