---
name: Charts with fl_chart
description: Build or change charts on the stats screen. Use when editing VolumeChart, adding a chart, or replacing the hand-rolled bar chart with a real fl_chart widget.
---

# Charts with fl_chart

`fl_chart` 0.68.0 is declared in `pubspec.yaml` but **is not imported anywhere in `lib/`**.
`VolumeChart` in `lib/ui/screens/widgets/stats_widgets.dart` is hand-built out of
`Container`s inside a horizontal `ListView.builder` — real rectangles, no charting library.

Latest release is **1.2.0** (sdk `^3.6.2`, flutter `>=3.27.4`). The 0.x → 1.x jump changed
several APIs, so verify against the docs for the version you actually pin rather than
copying snippets from a blog.

## Decide first: keep or adopt

The hand-rolled chart works and needs no dependency. Adopt `fl_chart` when you need
something it cannot express — axis labels, tooltips, a line trend, a pie breakdown, touch
interaction. If a bar chart of five values is still the requirement, staying hand-rolled
keeps the dependency list smaller.

If you adopt it, bump to `^1.2.0` in the same change and use the 1.x API.

## Core widgets

```dart
BarChart(
  BarChartData(
    barGroups: [
      for (final (i, stat) in stats.indexed)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stat.volumeKg,
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
    ],
    alignment: BarChartAlignment.spaceAround,
    titlesData: FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${stats[value.toInt()].date.day}/${stats[value.toInt()].date.month}'),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: FlGridData(show: true, drawVerticalLine: false),
    borderData: FlBorderData(show: false),
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Theme.of(context).colorScheme.inverseSurface,
      ),
    ),
  ),
)
```

Key parameters that differ between 0.x and 1.x:

- `BarChartRodData` takes **`toY`** (required) and optional `fromY`, `width`, `color` or
  `gradient`, `borderRadius`, `rodStackItems`, `backDrawRodData`.
- `getTitlesWidget` is `(double value, TitleMeta meta) => Widget` and must return a widget
  (returning `SideTitleWidget` is 0.x style).
- `BarTouchTooltipData` uses `getTooltipColor` / `getTooltipItem` callbacks.
- `FlBorderData(show: false)` to drop the default border box.
- `LineChartBarData` needs `spots` (`List<FlSpot>`), `isCurved`, `barWidth`, `dotData`.
- `PieChartData` needs `sections` of `PieChartSectionData(value:, color:, title:)`;
  `gradient` overrides `color` when both are set.

## Rules

- Wrap every chart in a `SizedBox(height: ...)`. Without one the chart takes unbounded
  height and overflows. `VolumeChart` already does this at 150.
- Feed `minY: 0` when values are non-negative, otherwise the baseline floats mid-chart.
- Theme everything from `Theme.of(context)` — charts must follow light/dark.
  `AppTheme` seeds both brightnesses from the same slate, so a hard-coded
  `Colors.blue` will look wrong in one mode.
- Hoist the `BarChartData` construction out of `build()` if the data is static for the
  frame; it is a large object graph.
- Handle the empty case before rendering. `VolumeChart` returns `SizedBox.shrink()` when
  `last5.isEmpty` — keep that.
- Charts do not have intrinsic text scaling. If a chart must be accessible, pair it with
  a semantic label or a textual summary.

## `intl` and `collection`

Both are still listed in `pubspec.yaml` but **neither is imported in `lib/`**.
`AGENTS.md` says they are no longer dependencies — that claim is wrong. They are dead
weight today. If you add date formatting to a chart axis, `intl` is already available;
otherwise remove both in a cleanup commit.
