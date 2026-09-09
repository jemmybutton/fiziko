% Example: Apple A14 vs M1 die comparison using fiziko-chips.
% Data from TechInsights A14/M1 table (factors are M1 / A14).
input fiziko-chips;
prologues := 3;

beginfig(1);
  randomseed := 42;

  % Two dies: M1 ~1.37x area, so ~1.17x side length.
  drawChipDie(-3.5cm, 2cm, 5cm, 5cm)(btex A14 etex);
  drawChipDie(3.5cm, 2cm, 5.85cm, 5.85cm)(btex M1 etex);

  % A14 blocks (schematic).
  drawChipBlock(-4.2cm, 3.0cm, 2.0cm, 0.9cm)(btex CPU1 etex);
  drawChipBlock(-4.2cm, 2.0cm, 2.0cm, 0.8cm)(btex CPU2 etex);
  drawChipBlock(-4.2cm, 1.0cm, 2.0cm, 0.9cm)(btex GPU etex);
  drawChipBlock(-2.0cm, 2.5cm, 1.8cm, 0.7cm)(btex NPU etex);
  drawChipBlock(-2.0cm, 1.5cm, 1.8cm, 0.7cm)(btex DDR etex);

  % M1 blocks (schematic, doubled where table says 2.0x cores).
  drawChipBlock(2.6cm, 3.2cm, 2.4cm, 1.2cm)(btex CPU1 x2 etex);
  drawChipBlock(2.6cm, 2.0cm, 2.4cm, 0.8cm)(btex CPU2 etex);
  drawChipBlock(2.6cm, 0.8cm, 2.4cm, 1.2cm)(btex GPU x2 etex);
  drawChipBlock(5.0cm, 2.8cm, 2.0cm, 0.7cm)(btex NPU etex);
  drawChipBlock(5.0cm, 1.6cm, 2.0cm, 0.9cm)(btex DDR x2 etex);

  % Factor bars (M1 / A14). Baseline x= -6cm, 1.0 = 1cm.
  label.lft(btex DDR 2.7x etex, (-6cm, -2.0cm));
  drawFactorBar(-5.5cm, -2.0cm, 2.7cm, 0.28cm)(btex 2.7 etex);
  label.lft(btex CPU1 2.1x etex, (-6cm, -2.7cm));
  drawFactorBar(-5.5cm, -2.7cm, 2.1cm, 0.28cm)(btex 2.1 etex);
  label.lft(btex GPU 2.1x etex, (-6cm, -3.4cm));
  drawFactorBar(-5.5cm, -3.4cm, 2.1cm, 0.28cm)(btex 2.1 etex);
  label.lft(btex Die 1.4x etex, (-6cm, -4.1cm));
  drawFactorBar(-5.5cm, -4.1cm, 1.4cm, 0.28cm)(btex 1.4 etex);
  label.lft(btex NPU 0.9x etex, (-6cm, -4.8cm));
  drawFactorBar(-5.5cm, -4.8cm, 0.9cm, 0.28cm)(btex 0.9 etex);

  drawFactorBaseline(-5.5cm, 3cm, -1.4cm);
  label.rt(btex 1.0 baseline etex, (3cm, -1.4cm));
endfig;
end.
