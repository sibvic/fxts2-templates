# Trailing limit parameters

There are two options for the trailing limit: Favorable and Unfavorable.

## Favorable

In favorable the code start to trail limit when the position will have "Trailing Limit Trigger in Pips" of profit.

For example:

    Tailing limit: Favorable
    Trailing Limit Trigger in Pips: 5
    Trailing Limit Step in Pips: 1
    Position limit: 10

The code start to work when position will have 5 pips of profit. But the first move will be at 6 pips of profit (limit be moved to 11 pips).

This move designed to move limit upper and upper, so it almost never get hit (only at sudden spikes). Usually used with breakeven and stop tailing: When the trend moves in the favorable direction the limit moves along with the trend but stop moved close to the current price and start to trail. This allows to avoid limit of profit when trend goes into favorable direction and close the trade in case of trend reversal.

## Unfavorable

In unfavorable the code start to trail limit when the position will have "Trailing Limit Trigger in Pips" of loss.

For example:

    Tailing limit: Favorable
    Trailing Limit Trigger in Pips: 5
    Trailing Limit Step in Pips: 1
    Position limit: 10

The code start to work when position will have -5 pips of profit. But the first move will be at -6 pips of profit (limit be moved to 9 pips).