# Templates

## base_strategy

Base strategy template.

## ZigZag

Template for the ZigZag indicators.

## divergence_indicator

Template for divergence indicators.

## Dashboard

Template of dashboard/scanner indicator.

## Heatmap

Template of a heatmap. Shows green/red/gray rectangle for each condition for each bar. Add your conditions to "conditions". Each condition should implement function GetSignal(period) and function Update(period, mode).

GetSignal should return 1 (green)/-1 (red)/other (gray) value.