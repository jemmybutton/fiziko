---
name: fiziko-chips
description: Draw SoC die-comparison diagrams (dies, functional blocks, area-factor bars) with fiziko-chips.mp on top of fiziko. Use when the user mentions chip diagrams, die floorplans, SoC comparisons like A14 vs M1, or area-factor bar charts in MetaPost.
license: GPL-3.0
compatibility: Requires MetaPost 3.x with fiziko.mp findable (see fiziko skill)
---

# fiziko-chips

`fiziko-chips.mp` inputs `fiziko.mp` and adds four helpers using
fiziko pens (`thinpen` for blocks/bars, `thickpen` for die outlines):

- `drawChipDie(expr cx, cy, w, h)(text title)` — centered die
  outline, light fill, title above.
- `drawChipBlock(expr cx, cy, w, h)(text lbl)` — white functional
  block with centered `btex` label.
- `drawFactorBar(expr x, y, len, ht)(text vallen)` — solid bar from
  `(x,y)`, value label to the right.
- `drawFactorBaseline(expr xa, xb, yc)` — dashed 1.0x reference line.

## Minimal example

```mp
input fiziko-chips;
prologues := 3;
beginfig(1);
  randomseed := 42;
  drawChipDie(0, 0, 5cm, 5cm)(btex A14 etex);
  drawChipBlock(0, 1cm, 2cm, 1cm)(btex CPU1 etex);
  drawFactorBar(0, -3cm, 2.7cm, 0.28cm)(btex 2.7 etex);
  drawFactorBaseline(-1cm, 4cm, -2.4cm);
endfig;
end.
```

Full A14-vs-M1 plate: [example](../../example-chips-a14-m1.mp).
Build and pitfalls: same `mpost` workflow as the `fiziko` skill
(fixed small `randomseed`, `prologues := 3`, MiKTeX vs TeX Live
`mpost` directory rules).
