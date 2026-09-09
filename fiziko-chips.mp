%    fiziko-chips 0.1.0
%    SoC die / factor-bar helpers on top of fiziko
%    Copyright 2026 Eden Gilbert
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

% Die / block / bar-chart helpers for SoC comparisons (e.g. Apple A14 vs M1).
% Builds on fiziko pens so stroke widths match the library.
%
% Usage:
%   input fiziko-chips;
%   beginfig(1);
%     drawChipDie(0, 0, 5cm, 5cm)(btex A14 etex);
%     drawChipBlock(0, 1cm, 2cm, 1cm)(btex CPU1 etex);
%     drawFactorBar(0, 0, 2.7cm, 0.32cm)(btex 2.7x etex);
%   endfig;

input fiziko;

% Centered die outline with light fill and title above.
def drawChipDie(expr cx, cy, w, h)(text title) =
begingroup
  save p;
  path p;
  p := ((-w/2, -h/2) -- (w/2, -h/2) -- (w/2, h/2) -- (-w/2, h/2) -- cycle) shifted (cx, cy);
  fill p withcolor 0.95white;
  draw p withpen thickpen;
  label.top(title, (cx, cy + h/2 + 0.3cm));
endgroup
enddef;

% Centered functional block with white fill and centered label.
def drawChipBlock(expr cx, cy, w, h)(text lbl) =
begingroup
  save p;
  path p;
  p := ((-w/2, -h/2) -- (w/2, -h/2) -- (w/2, h/2) -- (-w/2, h/2) -- cycle) shifted (cx, cy);
  fill p withcolor white;
  draw p withpen thinpen;
  label(lbl, (cx, cy));
endgroup
enddef;

% Horizontal solid bar starting at (x,y), length len, height ht, value label to the right.
def drawFactorBar(expr x, y, len, ht)(text vallen) =
begingroup
  save p;
  path p;
  p := (x, y - ht/2) -- (x + len, y - ht/2) -- (x + len, y + ht/2) -- (x, y + ht/2) -- cycle;
  fill p withcolor black;
  label.rt(vallen, (x + len + 0.12cm, y));
endgroup
enddef;

% Dashed 1.0x reference line for factor charts.
def drawFactorBaseline(expr xa, xb, yc) =
  draw (xa, yc) -- (xb, yc) dashed evenly withpen thinpen;
enddef;
