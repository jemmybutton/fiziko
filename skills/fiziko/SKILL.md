---
name: fiziko
description: Draw black-and-white physics illustrations with the fiziko MetaPost library (shaded spheres and tubes, variable-width lines, hatching, refraction, globes, knots, wood texture). Use when the user mentions fiziko, MetaPost physics diagrams, pulleys, springs, lenses, telescopes, globes, or knots plates.
license: GPL-3.0
compatibility: Requires MetaPost 3.x (TeX Live or MiKTeX) with mpost on PATH
---

# fiziko

MetaPost library (`fiziko.mp`) for black-and-white physics-textbook
illustrations. Primitives: variable-width `brush` lines, shaded `sphere` /
`tube`, hatching and stippling, `refractionPath` optics, globes with
built-in coastlines, rope/knot cords with crossing detection, wood texture.

## Setup

`fiziko.mp` must be findable via `MPINPUTS` or the TEXMF tree:

```sh
# per-project
export MPINPUTS="/path/to/fiziko:"
# permanent (TeX Live)
mkdir -p ~/Library/texmf/metapost/fiziko
cp fiziko.mp ~/Library/texmf/metapost/fiziko/
kpsewhich fiziko.mp
```

## Minimal standalone figure

```mp
input fiziko;
prologues := 3;
beginfig(1);
  randomseed := 42;
  draw sphere(2cm);
endfig;
end.
```

```sh
mpost -interaction=nonstopmode -halt-on-error file.mp
```

Inside LuaLaTeX (`luamplib`): `\everymplib{input fiziko; randomseed:=42;}`
then `mplibcode` environments. Labels between `btex`/`etex` are typeset
by the document.

## Key globals

- Stroke scale: `defineMinStrokeWidth(1/5pt)` sets `thinpen`,
  `thickpen`, `fatpen`, shading density.
- Light: `defineLightDirection(-1/8pi, 1/8pi)`; flip with
  `invertedLight := true`.
- Shadows: `shadowsEnabled` plus `shadowPath[]` / `shadowDepth[]`.

## Pitfalls

See [pitfalls](references/pitfalls.md). Short version:

- `randomseed` must be below 4096 (MetaPost `scaled` limit).
- Never name a variable `floor`; it shadows the builtin and breaks
  the wood texture with an "Isolated expression" error.
- Fix the seed: textures use random sampling and change on rebuild.
- TeX Live `mpost`: run from inside the output dir instead of
  `-output-directory` (the `btex` step writes an `mpx` file it must
  reread). MiKTeX `mpost` needs `-job-name=<name>`.
- Convert `-1.eps` output with Ghostscript; keep `prologues := 3`.
