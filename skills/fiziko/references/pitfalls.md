# fiziko pitfalls

- `randomseed :=` values of 4096 or more are rejected by MetaPost's
  default `scaled` arithmetic. Keep seeds small (e.g. 42).
- Do not declare or assign a variable named `floor`. It shadows the
  `floor` function and `fiziko.mp` wood-texture code then fails with
  "Isolated expression".
- Always set a fixed `randomseed` per figure. Hatching, stippling,
  and wood all sample randomly; without a seed every rebuild looks
  different.
- `prologues := 3` in every standalone `.mp` so labels are embedded
  and output carries an EPSF header.
- Finding `fiziko.mp`: `MPINPUTS` must keep its trailing separator
  (`...fiziko:` on POSIX, `...fiziko;` on Windows) so the normal
  search path stays available. Verify with `kpsewhich fiziko.mp`.
- TeX Live vs MiKTeX `mpost` disagree:
  - TeX Live: `(cd build && mpost ../examples/name.mp)`; no
    `-job-name`, no `-output-directory`.
  - MiKTeX (3.00): add `-job-name=<name> -output-directory=build`
    or it crashes at the first `btex` label.
- `luamplib` (LuaLaTeX embedding): TeX Live is fine; MiKTeX 2.42.8
  ships `luamplib.sty` without `luamplib.lua` — extract both from
  CTAN `luamplib.dtx` with `luatex luamplib.dtx` into a TEXMF root.
