%    fiziko 0.1.3
%    MetaPost library for physics textbook illustrations
%    Copyright 2018 Sergey Slyusarev
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


%
% Here we define some things of general interest
%

pi := 3.1415926;
radian := 180/pi;

vardef sin primary x = (sind(x*radian)) enddef;

vardef cos primary x = (cosd(x*radian)) enddef;

vardef log (expr n, b) =
    save rv;
    numeric rv;
    if n > 0:
        rv := (mlog(n)/mlog(b));
    else:
        rv := 0;
    fi;
    rv
enddef;

vardef arcsind primary x = angle((1+-+x,x)) enddef;

vardef arccosd primary x = angle((x,1+-+x)) enddef;

vardef arcsin primary x = ((arcsind(x))/radian) enddef;

vardef arccos primary x = ((arccosd(x))/radian) enddef;

vardef angleRad primary x = angle(x)/radian enddef;

vardef dirRad primary x = dir(x*radian) enddef;

% used here and there.

vardef sign (expr x)=
    if x > 0: 1 fi
    if x < 0: -1 fi
    if x = 0: 1 fi
enddef;

% This is inverted `clip`

primarydef i maskedWith p =
begingroup
    save q, invertedmask, resultimage;
    pair q[];
    path invertedmask;
    picture resultimage;
    resultimage := i;
    q1 := ulcorner(i) shifted (-1, 1);
    q3 := lrcorner(i) shifted (1, -1);
    q2 := (xpart(q3), ypart(q1));
    q4 := (xpart(q1), ypart(q3));
    bp := ypart((ulcorner(p)--llcorner(p)) firstIntersectionTimes p);
    invertedmask := (subpath (bp, length(p) + bp) of p) -- q1 -- q2 -- q3 -- q4 -- q1 -- cycle;
    clip resultimage to invertedmask;
    resultimage
endgroup
enddef;

%
% Since metapost is somewhat unpredictable in determining where paths intersect, here's macro
% that returns first intersection times with first path (ray) priority.
% Actually, it is so in most cases, but sometimes second path can take precedence,
% so the macro just checks whether reversing 'q' changes something
%

primarydef p firstIntersectionTimes q =
begingroup
    save t;
    pair t[];
    t1 := p intersectiontimes q;
    t2 := p intersectiontimes reverse(q);
    if xpart(t1) < xpart(t2):
        t3 := t1;
    else:
        t3 := (xpart(t2), length(q) - ypart(t2));
    fi;
    if xpart(t1) < 0: t3 := t2; fi;
    t3
endgroup
enddef;

% This checks if point a is inside of closed path p

primarydef a isInside p =
begingroup
    save ang, v, i, rv, pp;
    boolean rv;
    pair pp[];
    ang := 0;
    for i := 0 step 1/4 until (length(p)):
        pp1 := (point i of p) - a;
        pp2 := (point i + 1/4 of p) - a;
        if (pp1 <> (0, 0)) and (pp2 <> (0, 0)):
            v := angle(pp1) - angle(pp2);
            if v > 180: v := v - 360; fi; if v < -180: v := v + 360; fi;
            ang := ang + v;
        fi;
    endfor;
    if abs(ang) > 355:
        rv := true;
    else:
        rv := false;
    fi;
    rv
endgroup
enddef;

%
% sometimes it's useful to put some arrows along the path. this macro puts them
% in the middles of the segments that have length no less than midArrowLimit;
%

midArrowLimit := 1cm;

def drawmidarrow (expr p) text t =
begingroup
    save i, j, q;
    path q;
    j := 0;
    for i := 1 upto length(p):
        if arclength(subpath(i-1, i) of p) >= midArrowLimit:
            q := subpath(j, i - 1/2) of p;
            j := i - 1/2;
            draw q t;
            filldraw arrowhead q t;
        fi;
    endfor;
    draw subpath(j, length(p)) of p t;
endgroup
enddef;

% This macro marks angles, unsurprisingly

def markAngle (expr a, o, b) (text t) =
begingroup
    save p, an, d;
    numeric an[], d[];
    pair p;
    an1 := angle(a-o);
    an2 := angle(b-o) - an1;
    if (an2 < 0): an2 := an2 + 360; fi;
    an3 := an1 + 1/2an2;
    p := center(t);
    d1 := abs(ulcorner(t)-lrcorner(t));
    if (an2 < 90) and (an2 > 0):
        d2 := max(1/3cm, (d1/(abs(sind(an2))*1/3cm))*1/3cm);
    else:
        d2 := 1/3cm;
    fi;
    draw subpath (0, 8an2/360) of fullcircle scaled 2d2 rotated an1 shifted o withpen thinpen;
    draw (t) shifted -p shifted o shifted (dir(an3)*(d2 + d1));
endgroup
enddef;

%
% Here we define some auxilary global variables
%

% Offset path algorithm can subdivide original path in order to be more precise
offsetPathSteps := 4;

% The following macro sets all the values related to minimal stroke width at once.
% It can be used to easily redefine all of them.
def defineMinStrokeWidth (expr msw) =
    % We don't want to display strokes that are too thin to print. Default value
    % is subject to change when needed.
    minStrokeWidth := msw;
    maxShadingStrokeWidth := 2minStrokeWidth;

    % At some point it's useless to display even dashes
    minDashStrokeWidth := 1/3minStrokeWidth;

    % this value corresponds to particular dashing algorithm and is subject to change whenever this algorithm changes
    minDashStrokeLength := 3minStrokeWidth;

    dashStrokeWidthStep := 1/5minDashStrokeWidth;

    % all the shading algorithms need to know how close lines should be packed
    shadingDensity := 3maxShadingStrokeWidth;

    % here are some pens
    pen thinpen, thickpen, fatpen;

    thinpen := pencircle scaled minStrokeWidth;
    thickpen := pencircle scaled 3minStrokeWidth;
    fatpen := pencircle scaled 6minStrokeWidth;
enddef;

defineMinStrokeWidth(1/5pt);

% here we set global light direction

pair lightDirection, lightDirectionVector;
lightDirection := (-1/8pi, 1/8pi);
lightDirectionVector := (sin(xpart(lightDirection)), sin(ypart(lightDirection)));

boolean shadowsEnabled;
shadowsEnabled := false;

%
% To simplify further calculations we need subdivided original path
%

vardef pathSubdivideBase (expr p, subdivideStep, i) =
    save returnPath, sp;
    path returnPath, sp;
    returnPath := point i of p;
    if i<length(p):
      sp := subpath(i, i + subdivideStep) of p;
      returnPath := returnPath .. controls (postcontrol 0 of sp) and (precontrol 1 of sp) .. pathSubdivideBase (p, subdivideStep, i + subdivideStep);
    fi;
    if (i = 0) and (cycle p):
      (subpath(0, length(returnPath)-1) of returnPath)  .. controls (postcontrol length(returnPath)-1 of returnPath) and (precontrol length(returnPath) of returnPath) ..  cycle
    else:
      returnPath
    fi
enddef;

vardef offsetPathSubdivide (expr p) =
    pathSubdivideBase(p, 1/offsetPathSteps, 0)
enddef;

vardef pathSubdivide (expr p, n) =
    pathSubdivideBase(p, 1/n, 0)
enddef;

%
% This macro creates a template offset path to a straight line, so we can correct angles
% It might appear as if we need to calculate derivative of the function somehow, instead of mocking it
% but this function might be anything, function of coordinates of distance to some point etc.,
% so consider this a lazy way to do the right thing.
%
% either offsetPathTime or offsetPathLength are intended to be used as arguments. offsetPathTime is for time and offsetPathLength is for distance
%

vardef offsetPathTemplate (expr p, i) (text offsetFunction) =
    save returnPath, offsetPathTime, offsetPathLength, instantDirection, nextDirection;
    numeric offsetPathTime, offsetPathLength, currentAngle;
    pair instantDirection, nextDirection;
    path returnPath;
    if (i <= length(p)):
        offsetPathTime := i;
    else:
        offsetPathTime := length(p);
    fi;
    if (arclength(p) > 0):
        offsetPathLength := arclength(subpath (0, i) of p)/arclength(p);
    else:
        offsetPathLength := 0;
    fi;
    returnPath := (arclength(subpath (0, i) of p), offsetFunction);
    if (i < length(p)):
        % this thing is glitchy, but should be more accurate
        %if (arclength(subpath (0, i) of p) < arclength(subpath (0, i + 1/4) of p)):
            % offsetPathTime := i + 1/4;
            % offsetPathLength := arclength(subpath (0, i + 1/4) of p)/arclength(p);
            % instantDirection := unitvector((arclength(subpath (0, i + 1/4) of p), offsetFunction) - point 0 of returnPath);
            % offsetPathTime := i + 1;
            % offsetPathLength := arclength(subpath (0, i + 1) of p)/arclength(p);
            % nextDirection := (arclength(subpath (0, i + 1) of p), offsetFunction);
            % offsetPathTime := i + 3/4;
            % offsetPathLength := arclength(subpath (0, i + 3/4) of p)/arclength(p);
            % nextDirection := unitvector(nextDirection - (arclength(subpath (0, i + 3/4) of p), offsetFunction));
            % returnPath := returnPath{instantDirection} .. {nextDirection}offsetPathTemplate(p, i + 1)(offsetFunction);
        %    returnPath := returnPath -- offsetPathTemplate(p, i + 1)(offsetFunction);
        %else:
            returnPath := returnPath -- offsetPathTemplate(p, i + 1)(offsetFunction);
        %fi;
    fi;
    returnPath
enddef;

%
% This macro creates offset path p based on previously built template q, instead of function itself
% It is loosely based on something called Tiller-Hanson heuristic as described here:
% http://math.stackexchange.com/questions/465782/control-points-of-offset-bezier-curve
%

vardef offsetPathGenerate (expr p, q, i) =
    save returnPath, c, d, pl, ps;
    path returnPath, pl[];
    pair c[], d[];
    c1 := precontrol i of p;
    c2 := point i of p;
    c3 := postcontrol i of p;
    if abs(c1-c2) = 0:
        c1 := c2 shifted (c2-c3);
    fi;
    if abs(c3-c2) = 0:
        c3 := c2 shifted (c2-c1);
    fi;
    if (abs(c1-c2) > 0) and (abs(c2-c3) > 0):
        d1 := unitvector(c1-c2) rotated -90;
        d2 := unitvector(c2-c3) rotated -90;
        pl1 := (unitvector(c2-c1)--unitvector(c1-c2))
            scaled arclength(subpath (i - 1/2, i + 1/2) of p)
            shifted (point i of p shifted (d1 scaled ypart(point i of q)));
        pl2 := (unitvector(c2-c3)--unitvector(c3-c2))
            scaled arclength(subpath (i - 1/2, i + 1/2) of p)
            shifted (point i of p shifted (d2 scaled ypart(point i of q)));
        if (abs(angle(d1) - angle(d2)) > 2) and (xpart(pl1 intersectiontimes pl2) > 0):
            c4 := pl1 intersectionpoint pl2;
        else:
            c4 := c2 shifted (d1 scaled ypart(point i of q));
        fi;
        returnPath := c4;
    else:
        returnPath := c2 shifted (unitvector( (point i-1 of p) - (point i+1 of p) rotated -90) scaled ypart (point i of q));
    fi;
    if i < length(p):
        path ps;
        ps := subpath (i, i + 1) of p;
        c1 := point 0 of ps;
        c2 := postcontrol 0 of ps;
        c3 := precontrol 1 of ps;
        c4 := point 1 of ps;
        c5 := point 0 of returnPath;
        if (abs(c3-c4)>0)
            and (abs(c1-c2)>0)
            and (abs(c1-c4)>0)
            and (abs(direction i of q) > 0):
            c6 := c4 shifted (unitvector(c4 - c3) rotated 90 scaled ypart(point i + 1 of q));
            c7 := (c2 - c1) scaled (abs(c5-c6)/abs(c1-c4)) rotated angle(direction i of q) shifted c5;
            c8 := (c3 - c4) scaled (abs(c5-c6)/abs(c1-c4)) rotated angle(direction i + 1 of q) shifted c6;
            returnPath := returnPath .. controls c7 and c8 .. offsetPathGenerate (p, q, i + 1);
        else:
            returnPath := returnPath -- offsetPathGenerate (p, q, i + 1);
        fi;
    fi;
    returnPath
enddef;

%
% Frontend for offsetPathGenerate and offsetPathTemplate
%

vardef offsetPath (expr p)(text offsetFunction) =
    offsetPathGenerate (p, offsetPathTemplate(p, 0)(offsetFunction), 0)
enddef;

%
% Brush macro. It draws line with brush of variable width.
% For parts thicker than minStrokeWidth it uses offsetPath functions'
% results, for thiner parts it draws dashed lines of fixed width
%

def brushGenerate (expr p, q, i) =
begingroup
    save w, bp, bt, t;
    numeric w[], t[];
    path bp[], bt;
    bt := q;
    w0 := (ypart(urcorner(bt)));
    w1 := (ypart(lrcorner(bt)));
    t := cutPathTime(bt, minStrokeWidth);
    if ((w0 > minStrokeWidth)
        and (w1 < minStrokeWidth)
        and (t > 0)
        and (t < length(p))
        and (arclength(p) > minDashStrokeLength)
        and (i < 10)):
        brushGenerate (subpath (0, t) of p, subpath (0, t) of q, i + 1);
        brushGenerate (subpath (t, length(p)) of p, subpath (t, length(q)) of q, i + 1);
    elseif (arclength(p) > 0):
        if (w0 > 99/100minStrokeWidth)
            and (w1 > 99/100minStrokeWidth):
            bp1 := offsetPathGenerate (p, q yscaled 1/2, 0);
            bp2 := offsetPathGenerate (p, q yscaled -1/2, 0);
            fill bp1 -- reverse(bp2) -- cycle;
        elseif (w0 < 101/100minStrokeWidth) and (w1 < 101/100minStrokeWidth):
            thinBrushGenerate (p, q, 0)
        fi;
    fi;
endgroup
enddef;

%
% macro for thin lines which are actually dashed
%

def thinBrushGenerate (expr p, q, i) =
begingroup
    save w, bp, bt, t, h, linecap;
    numeric w[], t[];
    path bp[], bt;
    bt := q;
    w0 := (ypart(urcorner(bt)));
    w1 := (ypart(lrcorner(bt)));
    w2 := floor((1/2(w0 + w1))/dashStrokeWidthStep)*dashStrokeWidthStep;
    t := cutPathTime(bt, w2);
    bp1 := subpath (0, t) of p;
    bp2 := subpath (t, length(p)) of p;
    if (((w0 - w1) > dashStrokeWidthStep) and (i < 15))
        and ((arclength(bp1) > minDashStrokeLength)
        or (arclength(bp2) > minDashStrokeLength)):
        thinBrushGenerate (bp1, subpath (0, t) of q, i + 1);
        thinBrushGenerate (bp2, subpath (t, length(q)) of q, i + 1);
    else:
        linecap := butt;
        if (w2 > minStrokeWidth):
            w2 := minStrokeWidth;
        fi;
        if (w2 >= minDashStrokeWidth) and (arclength(p) > 0):
            draw p withpen thinpen dashed thinBrushPattern(w2, arclength(p));
        fi;
    fi;
endgroup
enddef;

%
% this macro returns path as a shaded edge
%

vardef shadedEdge (expr p) =
    image(
        brushGenerate (p,
            offsetPathTemplate (p, 0) (
                1/2minStrokeWidth + 2*minStrokeWidth
                * angleToLightness(
                    sphereAngleToAbsoulteAngle(
                        (angleRad(direction offsetPathTime of p), 1/2)
                    ), 0, point offsetPathTime of p
                )
            ), 0);
    )
enddef;

%
% Whenever we have brush thinner than minStrokeWidth we call this dash pattern macro
%

vardef thinBrushPattern (expr w, l) =
    save d;
    numeric d[];
    d0 := w;
    if d0 > minStrokeWidth: d0 := minStrokeWidth; fi;
    % d1 is a result of some arbitrary function of line width
    % we do not use simple linear function because minimal dash length
    % also shouldn't be less than minStrokeWidth.
    % After we get d1 other measurements are calculated,
    % so filled area per unit length remains adequate and dashes are aligned
    % with segments
    d1 := (1/2minDashStrokeLength) + (((d0/minStrokeWidth)**2)*1/2minDashStrokeLength);
    d1 := d1 + 1/2uniformdeviate(d1);
    d2 := (minStrokeWidth - d0)*(d1/d0);
    d3 := round(l/(d2 + d1));
    if (d3 < 1): d3 := 1; fi;
    d4 := (l/d3)/(d2 + d1);
    d1 := d1*d4;
    d2 := d2*d4;
    if (uniformdeviate(2) > 1):
        dashpattern (on d1 off 2d2)
    else:
        dashpattern (off 2d2 on d1)
    fi
enddef;

%
% macro that actually draws line of variable width
%

vardef brush (expr p) (text offsetFunction) =
    image(
        brushGenerate (p, offsetPathTemplate(p, 0)(offsetFunction), 0);
    )
enddef;

%
% This macro generates tube between paths p and q, of variable width d
% Tube is subdivided into segments in such a way that within every segment
% we need 2**n lines to generate even fill
%

def tubeGenerate (expr p, q, d, i) =
begingroup
    save w, bw, k, t, tubeWidth, sp, currentPath, currentTubePath, currentDepth;
    numeric w[], bw[], t, currentDepth;
    path tubeWidth, sp, currentPath, currentTubePath;
    tubeWidth := d yscaled 2;
    w0 := (ypart(urcorner(tubeWidth))) - 1/1000;
    w1 := (ypart(lrcorner(tubeWidth))) + 1/1000;
    w2 := ceiling(log(w0/shadingDensity, 2));
    w3 := ceiling(log(w1/shadingDensity, 2));
    if ((w2 > w3) and (i<20)):
        t := cutPathTime(tubeWidth, shadingDensity*(2**(w2-1)));
        tubeGenerate (subpath (0, t) of p, subpath (0, t) of q, subpath (0, t) of d, i + 1);
        tubeGenerate (subpath (t, length(p)) of p, subpath (t, length(q)) of q, subpath (t, length(d)) of d, i + 1);
    else:
        if (arclength(p) > 0) and (arclength(q) > 0):
            bw1 := 2**w2;
            currentTubePath := interpath (1/2, q, p);
            for k := 0 upto bw1:
                currentPath := interpath (k/bw1, q, p);
                angleOnTube := arccos(((k/bw1)*2) - 1);
                currentDepth := -abs((1-sin(angleOnTube))*w0);
                if shadowsEnabled:
                    currentPath := shadowCut(currentPath, currentDepth);
                fi;
                brushGenerate (currentPath,
                offsetPathTemplate(currentPath, 0)(
                maxShadingStrokeWidth
                if odd (k): * 1/2(2abs(ypart(point offsetPathTime of tubeWidth)/bw1) - shadingDensity) fi
                * orderFade(xpart(unitvector(direction offsetPathTime of tubeWidth yscaled 1/2cos(angleOnTube))), k)
                * angleToLightness(
                    tubeAngleToAbsoulteAngle((
                        angleOnTube,
                        angleRad(direction offsetPathTime of currentTubePath),
                        angleRad(direction offsetPathTime of tubeWidth yscaled 1/2)
                        )), currentDepth, point offsetPathTime of currentPath)
                ), 0);
            endfor;
        fi;
    fi;
endgroup
enddef;

%
% This macro is analogous to tubeGenerate, but draws transverse strokes
% result is somewhat suboptimal for now, but in simple cases it works ok
%

def tubeGenerateAlt (expr p, q, d) =
begingroup
    save spth, lpth, currentPath, pos, t, pthdir, corr, o, l, i, j, k, tubeAngle, pathAngle, scorr, dt;
    numeric l[];
    path spth, lpth, currentPath;
    pos := 0;
    j := 0;
    forever:
        dt := (xpart(point pos of d) + 1/2shadingDensity);
        scorr := cosd(angle(direction xpart(d intersectiontimes ((dt, ypart(lrcorner(d))) -- (dt, ypart(urcorner(d))))) of d));
        t1 := arctime ((arclength(subpath(0, pos) of p)) + shadingDensity/scorr) of p;
        t2 := arctime ((arclength(subpath(0, pos) of q)) + shadingDensity/scorr) of q;
        if (arclength(subpath(pos, t1) of p) < arclength(subpath(pos, t1) of q)):
            pthdir := -1;
            t3 := t1;
        else:
            pthdir := 1;
            t3 := t2;
        fi;
        corr := round(arclength(subpath(pos, t3) of if pthdir = 1: p else: q fi)/(shadingDensity/scorr));
        if (corr < 1): corr := 1; fi;
        corr := (arclength(subpath(pos, t3) of if pthdir = 1: p else: q fi) - (corr*(shadingDensity/scorr)))/corr;
        t3 := arctime (arclength(subpath(0, t3) of if pthdir = 1: q else: p fi) - 1/3corr) of if pthdir = 1: q else: p fi;
        spth := subpath(pos, t3) of if pthdir = 1: q else: p fi;
        lpth := subpath(pos, t3) of if pthdir = 1: p else: q fi;
        tubeAngle := angleRad(direction 1/2[pos, t3] of d);
        pathAngle := angleRad(direction 1/2 of interpath (1/2, spth, lpth));
        pos := t3;
        l1 := round(arclength(lpth)/(shadingDensity/scorr));
        if (l1 < 1): l1 := 1; fi;
        l2 := arclength(lpth)/(l1*(shadingDensity/scorr));
        for i := 0 upto l1 - 1:
            j := j + 1;
            k := i*(arclength(lpth)/l1);
            currentPath := point (arctime k of lpth) of spth -- point (arctime k of lpth) of lpth;
            currentPath := offsetPathSubdivide(currentPath);
            brushGenerate (
                currentPath,
                offsetPathTemplate(currentPath, 0)(
                    maxShadingStrokeWidth
                    * orderFade(offsetPathLength[1/l1, l2], j)
                    * angleToLightness(
                    tubeAngleToAbsoulteAngle((
                        arccos(pthdir*((offsetPathLength*2)-1)),
                        pathAngle,
                        tubeAngle)
                    ), -2(1/2arclength(currentPath))+sqrt(1 - (2offsetPathLength - 1)**2)*(1/2arclength(currentPath)), point offsetPathTime of currentPath)
                )
            , 0);
        endfor;
    exitif pos >= length(p);
    endfor;
endgroup
enddef;

%
% This macro converts some measurements of point on tube to absolute angle.
% Since there are three such measurements, macro gets them as as a single
% argument of "color" type, in case it will eventually appear as a result
% of some other macro.
%

vardef tubeAngleToAbsoulteAngle (expr p) =
    save a;
    numeric a[];
    a1 := bluepart(p) + 1/2pi;
    a2 := arccos(cos(redpart(p))*sin(a1));
    a3 := greenpart(p) + 1/2pi;
    a4 := arccos((cos(a1) * cos(a3) - cos(a2) * sin(a3))*(99/100));
    a5 := arccos((cos(a1) * sin(a3) + cos(a2) * cos(a3))*(99/100));
    (a5, a4)
enddef;

%
% frontends to simplify tube drawing. tubeOutline variable changes on every call
% of any tube frontend function and can be used afterwards.
%

path tubeOutline;
boolean drawTubeEnds;
drawTubeEnds := true;

vardef tube.l (expr p)(text offsetFunction)=
    save q;
    path q[];
    q0 := offsetPathSubdivide(p);
    q1 := offsetPathTemplate(q0, 0)(offsetFunction);
    q2 := offsetPathGenerate (q0, q1, 0);
    q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
    tubeOutline := q3--reverse(q2)--cycle;
    image(
        tubeGenerate (q2, q3, q1, 0);
        if (cycle p) or (not drawTubeEnds):
            draw q2 withpen thinpen;
            draw q3 withpen thinpen;
        else:
            draw q2--reverse(q3)--cycle withpen thinpen;
        fi;
    )
enddef;

vardef tube.t (expr p)(text offsetFunction)=
    save q;
    path q[];
    q0 := offsetPathSubdivide(p);
    q1 := offsetPathTemplate(q0, 0)(offsetFunction);
    q2 := offsetPathGenerate (q0, q1, 0);
    q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
    tubeOutline := q3--reverse(q2)--cycle;
    image(
        tubeGenerateAlt (q2, q3, q1);
        if (cycle p) or (not drawTubeEnds):
            draw q2 withpen thinpen;
            draw q3 withpen thinpen;
        else:
            draw q2--reverse(q3)--cycle withpen thinpen;
        fi;
    )
enddef;

vardef tube.e (expr p)(text offsetFunction)=
    save q;
    path q[];
    q0 := offsetPathSubdivide(p);
    q1 := offsetPathTemplate(q0, 0)(offsetFunction);
    q2 := offsetPathGenerate (q0, q1, 0);
    q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
    tubeOutline := q3--reverse(q2)--cycle;
    if not drawTubeEnds:
        image(
            draw q2 withpen thinpen;
            draw q3 withpen thinpen;
            )
    else:
        tubeOutline := q3--reverse(q2)--cycle;
        tubeOutline
    fi
enddef;

%
% Sphere can be used as a cap for a tube, so it has same 2**n lines.
%

vardef sphere.c (expr d) =
    save currentCircle, origCircle, currentRadius, currentDepth, order, circleThickness;
    path currentCircle, origCircle;
    numeric currentRadius, currentDepth, order;
    origCircle := fullcircle;
    order := 2**ceiling(log((1/2d)/shadingDensity, 2));
    image(
        draw fullcircle scaled d withpen thinpen;
        for i := 1 upto order:
        currentRadius := i/order;
        currentCircle := origCircle scaled (currentRadius*d) rotated uniformdeviate (1/4pi);
        if odd(i):
            circleThickness := maxShadingStrokeWidth * ((abs(d - (shadingDensity*order)))/order);
        else:
            circleThickness := maxShadingStrokeWidth;
        fi;
        currentDepth:= -(1-sqrt(1-currentRadius**2))*(1/2d);
        if shadowsEnabled:
            currentCircle := shadowCut(currentCircle, currentDepth);
        fi;
        brushGenerate (currentCircle,
            offsetPathTemplate (currentCircle, 0) (
                circleThickness
                * angleToLightness(
                    sphereAngleToAbsoulteAngle(
                        (angleRad(direction offsetPathTime of currentCircle), currentRadius)
                    ), currentDepth, point offsetPathTime of currentCircle
                )
            ), 0);
        endfor;
    )
enddef;

%
% Alternative sphere macro. It's all about latitudinal strokes.
% The idea is: when we have a sphere with evenly distributed parallel strokes
% we know how their density rises towards edge in a projection,
% so all we need to do is to fade lines correspondingly
%

vardef sphere.l (expr d, lat) =
    save p, a, x, y, sphlat, latrad, n, c, currentPath, nline, tlat;
    path p[], currentPath, currentArc;
    sphlat := 0;
    nline := 0;
    latrad := (2pi*lat/360);
    n := ceiling((pi*1/2d)/shadingDensity);
    if (cosd(lat) <> 0): tlat := (sind(lat)/cosd(lat)); fi;
    image(
        draw fullcircle scaled d withpen thinpen;
        p0 := fullcircle rotated 90;
        for nline := 1 upto n-1:
            sphlat := nline*(pi/n);
            if (sphlat + latrad < pi) and (sphlat + latrad > 0):
                if (cosd(lat) <> 0):
                    if (sin(sphlat) <> 0):
                        x := tlat*(cos(sphlat)/sin(sphlat));
                    else:
                        x := 0;
                    fi;
                else:
                    if ((sphlat > 1/2pi) and (lat > 0)) or ((sphlat < 1/2pi) and (lat < 0)):
                        x := -2;
                    else:
                        x := 2;
                    fi;
                fi;
                if (abs(x) <= 1):
                    y := arcsin(x);
                    p1 := subpath(6 + 8y/2pi, 2 - 8y/2pi) of p0;
                else:
                    p1 := p0;
                fi;
                if (x > -1) and (arclength(p1) > 0):
                    currentPath := (p1 scaled (d*sin(sphlat)) yscaled sind(lat)) shifted (0, 1/2d*cos(sphlat)*cosd(lat));
                    currentPath := offsetPathSubdivide(currentPath);
                    brushGenerate(currentPath,
                        offsetPathTemplate(currentPath, 0)(
                        maxShadingStrokeWidth * orderFade(
                            sqrt(1 -
                                abs(
                                    ypart(point offsetPathTime of currentPath)/(1/2d),
                                    1 - abs(
                                            1 - abs(
                                                    xpart(point offsetPathTime of currentPath)
                                                        /(1/2d)
                                                    )
                                            )**abs(sind(lat))
                                    )**2)
                        , nline)
                        * angleToLightness(
                            sphereAngleToAbsoulteAngle((
                                (
                                if (abs(point offsetPathTime of currentPath) > 0):
                                    angleRad(point offsetPathTime of currentPath)
                                else:
                                    0
                                fi
                                 + 1/2pi), 2abs(point offsetPathTime of currentPath)/(d+1))
                            ), 0, point offsetPathTime of currentPath)
                        ), 0);
                fi;
            fi;
       endfor;
    )
enddef;

vardef orderFade (expr v, n)=
    save o;
    if (v > 1/256):
        o := 2**ceiling(log(1/v, 2));
        if ((n mod 1/2o) = 0):
            if ((n mod o) = 0):
                1
            else:
                (v*o) - 1
            fi
        else:
            0
        fi
    else:
        0
    fi
enddef;

%
% This one converts point location on sphere to absolute angle
%

vardef sphereAngleToAbsoulteAngle (expr p) =
    save a;
    numeric a[];
    a1 := xpart(p) - 1/2pi;
    a2 := arcsin(ypart(p));
    a3 := arccos(sin(a2)*cos(a1));
    a4 := pi - arccos(sin(a2)*sin(a1));
    (a3, a4)
enddef;

%
% Once we get two angles at some point of some surface, we can compute light intensity there.
%

vardef angleToLightness (expr p, d, q) =
    save returnValue, shiftedShadowPath;
    path shiftedShadowPath;
    if shadowsEnabled:
        for i := 0 step 1 until numberOfShadows:
            shiftedShadowPath := shadowPath[i] shifted (lightDirectionVector scaled (d-shadowDepth[i]));
            if q isInside shiftedShadowPath:
                returnValue := 1;
            fi;
        endfor;
    fi;
    if not known returnValue:
        returnValue := (cos(xpart(p) + xpart(lightDirection))++cos(ypart(p) - ypart(lightDirection)));
        returnValue := angleToLightnessPP(returnValue);
    fi;
    if returnValue > 1:
        1
    else:
        returnValue
    fi
enddef;

vardef angleToLightnessPP (expr v) =
    v**3
enddef;

% Shadows are global

path shadowPath[];
numeric shadowDepth[];

% Shadows either require high path resolution, or some points
% on a path in just the right place for shadows.
% This macro adds such points.

vardef shadowCut (expr pathToCut, currentDepth)=
    save shiftedShadowPath, pathShadowIntersection, pathShadowCut, currentPath;
    path shiftedShadowPath, currentPath;
    pair pathShadowIntersection;
    numeric pathShadowCut;
    currentPath := pathToCut;
    for j := 0 step 1 until numberOfShadows:
        shiftedShadowPath := shadowPath[j] shifted (lightDirectionVector scaled (currentDepth - shadowDepth[j]));
        forever:
            pathShadowIntersection := shiftedShadowPath firstIntersectionTimes currentPath;
            pathShadowCut := ypart(pathShadowIntersection);
            if (pathShadowCut > 1/10) and (pathShadowCut < length(currentPath) - 1/10):
                currentPath := (subpath (0, pathShadowCut - 1/20) of currentPath) .. (subpath (pathShadowCut + 1/20, length(currentPath)) of currentPath);
            fi;
            shiftedShadowPath := subpath (xpart(pathShadowIntersection) + 1/5, length(shiftedShadowPath)) of shiftedShadowPath;
            exitif (pathShadowCut = -1);
        endfor;
    endfor;
    currentPath
enddef;

%
% Several macros rely on cutting offset path template at given height.
% Taking cutting points closer to the middle gives better results, and that's
% just what this macro tries to do.
%

vardef cutPathTime (expr p, h) =
    save cutTime, d;
    numeric cutTime[], d[];
    d1 := xpart(urcorner(p));
    d2 := xpart(ulcorner(p));
    if (d2 < d1):
        d3 := 1/2(d1 + d2);
        cutTime1 := ypart(((d3, h) -- (d1, h)) firstIntersectionTimes p);
        cutTime2 := ypart(((d3, h) -- (d2, h)) firstIntersectionTimes p);
        d4 := xpart (point cutTime1 of p);
        d5 := xpart (point cutTime2 of p);
        if abs(d4-d3) < abs(d5-d3):
            cutTime3 := cutTime1
        else:
            cutTime3 := cutTime2
        fi;
    else:
        cutTime3 := -1;
    fi;
    cutTime3
enddef;

%
% This macro calculates ray angle after refraction. It takes raw angles (one of ray — p and one of surface — q)
% and refraction indices ratio. Whether ray comes from opticaly denser material is determined by direction of q
% relative to that of p
%

vardef refractionAngle (expr p, q, n) =
    save a;
    numeric a[];
    a0 := p - q;
    if (sin(a0) < 0):
        a1 := cos(a0 + pi) * n;
        a2 := pi;
    else:
        a1 := cos(a0) / n;
        a2 := 0;
    fi;
    if abs(a1) <= 1:
        a3 := arccos(a1) + q + a2;
    else:
        a3 := -1000;
    fi;
    a3
enddef;

%
% Same thing for reflection angle, just in case
%

vardef reflectionAngle (expr p, q) =
    (2pi - p + 2q)
enddef;

%
% This macro returns path of ray 'sa' (which can actually be any path, but only ray from next to last to last point
% will count) refracted with coef. n through some shape p; if ray can't be refracted and, therefore, totally reflected,
% it will contunue as reflected from that point. i is total number of refractions to compute;
%

vardef refractionPathR (expr sa, p, n, i, mn) =
    save ray, resultRay, d, s, a, iT;
    path ray, resultRay;
    pair s, iT;
    numeric d[], a;
    s := point (length(sa) - 1) of sa;
    a := angleRad((point (length(sa)) of sa)-(point (length(sa) - 1) of sa));
    ray := (s shifted (-dirRad(a) scaled 2)) -- s -- (s shifted (dirRad(a) scaled (abs(llcorner(p)-(urcorner(p))) + abs(s-(center(p))))));
    if (i > 0): ray := subpath (1 + 1/1000, 2) of ray; fi;
    iT := ray firstIntersectionTimes p;
    d1 := xpart(iT);
    d2 := ypart(iT);
    d3 := a;
    d4 := angleRad(direction d2 of p);
    if (n > 0):
        d5 := refractionAngle(d3, d4, n);
        if (d5 < -100) and (d2 >= 0):
            d5 := reflectionAngle(d3, d4);
        fi;
    else:
        d5 := reflectionAngle(d3, d4);
    fi;
    if (d1 >= 0) and (i < mn) and (d5 > -100):
        resultRay := (subpath (0, length(sa) - 1) of sa) -- refractionPathR(point d2 of p -- (point d2 of p shifted dirRad(d5)), p, n, i + 1, mn);
    else:
        if (d5 > -100) or (d1 < 0):
            resultRay := subpath (0, 1/2) of ray;
        else:
            resultRay := subpath (0, d1) of ray;
        fi;
    fi;
    resultRay
enddef;

vardef refractionPath (expr sa, p, n) =
    refractionPathR(sa, p, n, 0, 10)
enddef;

%
% These macros are for isolines. cLine draws continuous line and is called by isoLines.
% For now they are only used to draw wood texture, but can be used elsewhere
%

%
% isoLines goes through i by j matrix of nodes (xy), looking for square, that has some of it's
% angles below zero and some - above, when found, it calls cLine, that tries to build segment of
% isoline, that happen to go through abovementioned square. Thickness of line is
% controlled by values in v array.
% All squares with lines already drawn through are ignored.
%

vardef isoLines (suffix xy)(expr cs, l, s) =
    save xxyy, i, j, c, v, sqB, iL, lvl;
    numeric xxyy[][], c[], v[], sqB, sqbM;
    lvl := l;
    path iL;
    image(
        for i := 0 step 1 until xpart(cs) - 1:
            for j := 0 step 1 until ypart(cs) - 1:
                if (unknown xxyy[i][j]):
                    c1 := xy[i][j]+lvl;
                    c2 := xy[i][j+1]+lvl;
                    c3 := xy[i+1][j]+lvl;
                    c4 := xy[i+1][j+1]+lvl;
                    sqB := 0;
                    sqBm := 0;
                    if (abs(sign(c1)+sign(c2)+sign(c3)+sign(c4)) < 4):
                        iL := cLine (xy)((i, j), (0, 0), 0, cs) scaled s;
                        brushGenerate (reverse(iL),
                        offsetPathTemplate(iL, 0)(
                        1/16minStrokeWidth
                            /(1/64 + 2(
                                if (offsetPathTime < length(iL) - 1):
                                    (offsetPathTime - floor(offsetPathTime))
                                        [v[floor(sqB + offsetPathTime)],
                                        v[ceiling(sqB + offsetPathTime)]]
                                else:
                                    1
                                fi
                                ))
                        )
                        , 0);
                    fi;
                fi;
            endfor;
        endfor;
        draw (0,0);
    )
enddef;

% cLine tries to generate continouos segment of an isoline

vardef cLine (suffix xy)(expr ij, dr, st, cs) =
    save p, d, dd, n, i, j, k, outputPath, sqS, cp, dp, nd;
    pair p[], d[], dd[], cp[], dp[];
    path outputPath;
    i := xpart(ij);
    j := ypart(ij);
    sqS := 0;
    if (i >= 0) and (i <= xpart(cs)-1) and (j >= 0) and (j <= ypart(cs)-1):
        n := 0;
        c1 := xy[i][j] + lvl; d1:= (i, j);
        c2 := xy[i][j+1] + lvl; d2:= (i, j+1);
        c3 := xy[i+1][j] + lvl; d3:= (i+1, j);
        c4 := xy[i+1][j+1] + lvl; d4:= (i+1, j+1);
        cp1 := (1, 2); dp1 := (-1, 0);
        cp2 := (1, 3); dp2 := (0, -1);
        cp3 := (2, 4); dp3 := (0, 1);
        cp4 := (3, 4); dp4 := (1, 0);
        for k := 1 upto 4:
            c5 := c[xpart(cp[k])]; d5 := d[xpart(cp[k])];
            c6 := c[ypart(cp[k])]; d6 := d[ypart(cp[k])];
            if (sign(c5)) <> (sign(c6)):
                n := n + 1;
                p[n] := (abs(-c5/(c6-c5)))[d5, d6];
                dd[n] := dp[k];
            fi;
        endfor;
        sqS := max(c1, c2, c3, c4) - min(c1, c2, c3, c4);
        if (unknown xxyy[i][j]):
            xxyy[i][j] := 1;
            if (dr = (0, 0)):
                outputPath := cLine (xy)(ij shifted dd2, dd2, st + 1,cs) -- p1 -- p2 -- cLine (xy)(ij shifted dd1, dd1, st - 1,cs);
            else:
                nd := 0;
                if (unknown(xxyy[i + xpart(dd1)][j + ypart(dd1)])):
                    nd := 1;
                elseif (unknown(xxyy[i + xpart(dd2)][j + ypart(dd2)])):
                    nd := 2;
                fi;
                if nd > 0:
                    outputPath := cLine (xy)(ij shifted dd[nd], dd[nd], st + sign(st),cs);
                    p3 := p[nd];
                    if (st > 0):
                        outputPath := outputPath -- p3;
                    else:
                        outputPath := p3 -- outputPath;
                    fi;
                else:
                    outputPath := 1/2[p1, p2];
                fi;
            fi;
        else:
            outputPath := 1/2[p1, p2];
        fi;
    else:
        outputPath := (i, j);
        xxyy[i][j] := 1;
    fi;
    if (st < sqB): sqB := st; fi;
    if (st > sqBm): sqBm := st; fi;
    v[st] := sqS;
    outputPath
enddef;

%
%
%
% In following section are gathered all the things for some commonly used
% real life objects
%
%
%

%
% Though there's a decent library to deal with geography for mp already
% (http://melusine.eu.org/lab/bmp/a_mp-geo), here's some basic globe-drawing
% routine for simple cases, note that latitude starts from the pole,
% not from the equator (for convenience sake)
% Below some landmasses are defined
%

path landmass[];
landmass1 := (206, 122.33)--(211.07, 116)--(213.3, 109.94)--(218.57, 106.03)--(218.38, 97.36)--(220.28, 91.28)--(229.75, 78.07)--(221.41, 78.29)--(220.78, 76.52)--(218.07, 74.48)--(213.8, 66.08)--(213.38, 62.04)--(222.31, 77.1)--(233.88, 72.27)--(237.79, 68.59)--(234.88, 64.69)--(229.83, 65.57)--(228.98, 64.73)--(227.37, 59.82)--(250.57, 68.12)--(254.63, 80.83)--(257.07, 80.93)--(257.38, 80.52)--(258.64, 75.5)--(266.4, 68.48)--(269.56, 67.49)--(271.88, 70.43)--(272.67, 74.49)--(275.36, 72.94)--(276.87, 78.6)--(276.68, 79.04)--(276.11, 79.28)--(276.3, 80.22)--(276.75, 79.96)--(276.56, 82.38)--(277.05, 82.04)--(280.5, 86.44)--(277.25, 85.56)--(276.55, 88.03)--(279.47, 92.77)--(283.29, 92.25)--(282.68, 90.91)--(283.74, 90.4)--(282.53, 89.58)--(283.03, 88.6)--(278.44, 80.08)--(279.15, 76.64)--(281.08, 78.25)--(282.29, 80.21)--(285.35, 79.72)--(288, 77.83)--(284.21, 71.22)--(287.94, 68.57)--(288, 68.6)--(288.74, 69.82)--(300.09, 61.89)--(300.86, 59.94)--(299.36, 59.63)--(297.64, 55.13)--(301.24, 52.55)--(296.1, 51.5)--(300.45, 49.51)--(299.83, 50.75)--(299.84, 50.82)--(299.44, 51.42)--(303.59, 50.57)--(302.72, 51.9)--(302.96, 52.12)--(304.97, 52.87)--(304.12, 55.13)--(307.89, 53.38)--(306.37, 50.11)--(308.65, 47.92)--(315.01, 45.12)--(319.69, 40.31)--(320.43, 44.25)--(321.66, 44.31)--(323.19, 41.66)--(320.37, 35.59)--(318.47, 37.21)--(315.99, 36.32)--(313.68, 35.16)--(320.43, 31.11)--(332.73, 30.38)--(338.5, 28.24)--(340.91, 28.61)--(334.92, 32.27)--(335, 39.2)--(340.58, 35.32)--(341.69, 32.15)--(340.43, 31.93)--(344.49, 29.68)--(352.49, 28.33)--(355.9, 25.35)--(358.67, 24.01)--(366.1, 25.61)--(368.78, 23.99)--(319.11, 17.34)--(309.82, 19)--(308.23, 18.4)--(307.69, 16.74)--(297.49, 16.63)--(290.61, 13.26)--(285.38, 13.37)--(284.06, 12.79)--(258.59, 16.61)--(260.79, 18.13)--(254.13, 18.01)--(253.53, 17.04)--(252.25, 17.02)--(252.44, 18.56)--(253.69, 19.64)--(251.71, 20.89)--(249.66, 16.97)--(245.54, 19.39)--(236.64, 19.73)--(239.08, 21)--(237.57, 21.46)--(232.4, 21.62)--(232.29, 21.34)--(225.16, 22.27)--(221.46, 21.23)--(218.52, 25.09)--(216.81, 24.69)--(214.76, 24.93)--(214.95, 25.52)--(213.66, 25.25)--(211.67, 23.33)--(215.44, 23.49)--(217.75, 21.65)--(200.52, 19.57)--(194.37, 21.1)--(186.19, 26.3)--(183.33, 30.4)--(187.61, 31.42)--(191.44, 33.88)--(194.61, 33.54)--(197.17, 30.74)--(196.08, 28.46)--(196.04, 27.66)--(203.54, 24.58)--(203.45, 24.88)--(200.38, 27.18)--(200.91, 27.54)--(200.05, 29.69)--(199.62, 29.91)--(201.03, 30.25)--(207.36, 29.93)--(205.2, 31.05)--(199.88, 30.97)--(199.94, 31.44)--(200.26, 32.2)--(202.19, 31.76)--(202.85, 32.2)--(199.62, 32.83)--(199.15, 34.61)--(189.46, 35.87)--(189.93, 35.46)--(191.12, 35.08)--(190.83, 34.56)--(188.1, 33.45)--(186.87, 34.75)--(187.11, 36.02)--(176.39, 40.19)--(176.65, 41.24)--(173.41, 42.02)--(176.82, 43.77)--(169.68, 46.56)--(169.15, 53.05)--(171.1, 53.62)--(173.12, 53.39)--(178.7, 51.26)--(183.17, 46.73)--(186.38, 46.75)--(192.72, 49.52)--(191.46, 52.64)--(193.74, 52.83)--(196.74, 50.32)--(190.71, 44.65)--(191.74, 44.4)--(198.11, 50.06)--(198.89, 52.03)--(200.95, 53.75)--(202.49, 51.99)--(201.15, 49.3)--(204.15, 49.28)--(206.54, 53.44)--(214.39, 53.25)--(211.18, 58.75)--(198.36, 57.7)--(197.88, 59.47)--(188.5, 55.87)--(189.63, 53.18)--(189.49, 52.79)--(173.31, 54.75)--(168.56, 58.21)--(161.34, 69.75)--(160.58, 75.18)--(161.25, 77.58)--(162.08, 79.09)--(163.71, 80.23)--(165.04, 82.46)--(168.88, 84.86)--(182.72, 83.77)--(184.88, 85.79)--(187.22, 85.99)--(186.79, 90.34)--(190.56, 95.97)--(190.23, 105.47)--(193.05, 115.74)--(196.18, 121.46)--(196.92, 124.65)--(206, 122.33)--(206, 122.33);
landmass2 := (111.44, 45.06)--(113.41, 44.75)--(111.77, 46)--(111.77, 46.07)--(118.69, 43.98)--(118.13, 42.88)--(116.49, 43.6)--(114.48, 42.7)--(114.1, 43.65)--(114.04, 41.9)--(113.28, 42.04)--(108.57, 42.18)--(114.57, 39.81)--(120.91, 38.84)--(119.04, 41.38)--(119.53, 41.59)--(122.9, 42.64)--(121.94, 42.77)--(121.82, 43.31)--(124.3, 42.48)--(125.29, 42.37)--(125.59, 41.84)--(125.41, 41.3)--(124.75, 41.38)--(122.58, 40.38)--(122.97, 39.95)--(121.71, 40.06)--(123.02, 38.38)--(121.65, 38.53)--(120.78, 35.69)--(116.8, 33.48)--(114.09, 29.59)--(110.59, 31.42)--(108.79, 28.81)--(104.18, 27.54)--(99.54, 29.42)--(100.85, 30.15)--(100.61, 31.83)--(100.51, 34.6)--(98.7, 35.56)--(99.11, 36.37)--(99.33, 38.41)--(96.3, 36.78)--(85.98, 32.83)--(83.79, 29.73)--(86.02, 28)--(87.63, 26.53)--(92.02, 23.6)--(94.53, 23.9)--(94.57, 23.59)--(95.6, 23.75)--(96.08, 21.63)--(96.05, 20.47)--(99.61, 19.73)--(103.5, 21.33)--(105.9, 22.76)--(103.75, 23.87)--(104.54, 24.37)--(101.78, 25.83)--(112.52, 27.74)--(113.4, 27.33)--(113.39, 27.23)--(110.6, 24.25)--(110.62, 24.18)--(111.27, 23.6)--(116.34, 23.81)--(117.17, 23.3)--(110.5, 21.34)--(111.78, 20.87)--(110.82, 20.4)--(111.3, 20.21)--(109.74, 19.84)--(110.11, 19.43)--(102.09, 17.29)--(97.38, 16.64)--(92.88, 17.67)--(92.21, 18.01)--(91.83, 17.28)--(89.16, 18.82)--(92.76, 20.05)--(93.22, 20.96)--(92.06, 21.98)--(91.69, 22.39)--(88.11, 21.59)--(87.79, 20.91)--(86.11, 20.22)--(86.94, 19.77)--(84.28, 18.1)--(84.81, 17.32)--(85.92, 16.37)--(82.62, 16.82)--(82.26, 18.46)--(82.22, 20.63)--(80.29, 21.42)--(73.81, 21.72)--(73.19, 21.56)--(73.02, 21.15)--(75.97, 21.21)--(75.92, 20.34)--(77.6, 20.64)--(73.05, 17.2)--(70.79, 18.11)--(67.81, 17.27)--(64.31, 17.23)--(54.27, 15.93)--(52.31, 18.03)--(60.06, 17.29)--(60.43, 18.73)--(59.79, 19.06)--(65.44, 20.05)--(71.86, 20.7)--(72.16, 20.95)--(69.43, 21.73)--(70.4, 21.96)--(70.06, 22.49)--(69.48, 22.4)--(63.3, 21.97)--(48.4, 19.77)--(41.64, 20.99)--(22.72, 18.59)--(11.06, 21.67)--(16.58, 23.75)--(14.57, 23.75)--(10.29, 24.54)--(17.36, 25.3)--(17.42, 26.18)--(12.61, 29.54)--(15.96, 29.89)--(15.52, 31.43)--(20.94, 31.31)--(13.31, 35.43)--(16.05, 35.66)--(19.1, 35.11)--(18.12, 34.75)--(27.83, 28.87)--(28.89, 30.18)--(33.87, 29.92)--(33.36, 30.35)--(38.31, 30.44)--(42.27, 33.16)--(42.87, 32.94)--(47.84, 35.37)--(50.85, 39.13)--(53.79, 42.3)--(54.39, 50.26)--(64.16, 61.59)--(63.13, 61.47)--(62.78, 61.95)--(64.93, 63.33)--(66.24, 65.62)--(67.78, 65.49)--(65.67, 61.75)--(65.09, 58.99)--(66.42, 61.44)--(68.81, 63.42)--(72.94, 69.36)--(81.5, 74.4)--(83.61, 73.92)--(85.99, 75.53)--(90.7, 76.75)--(93.55, 80.26)--(95.61, 82.43)--(96.7, 82.3)--(98.47, 82.54)--(101.05, 86.23)--(98.22, 93.14)--(100.55, 101.04)--(102.97, 105.27)--(107.45, 108.16)--(104.04, 132.27)--(104.08, 133.7)--(103.49, 134.62)--(102.5, 136.82)--(104.04, 136.98)--(103.44, 141.15)--(104.17, 143.63)--(108.08, 144.9)--(110.27, 145.35)--(111.35, 145.04)--(113.34, 144.63)--(109.31, 140.79)--(112.69, 137.21)--(111.47, 135.36)--(113.17, 133.67)--(113.34, 130.92)--(116.56, 129.1)--(119.97, 124.37)--(128.41, 119.87)--(133.19, 114.17)--(136.37, 113.08)--(138.56, 109.76)--(141.63, 100.78)--(139.94, 93.61)--(133.56, 91.17)--(129.89, 90.92)--(128.12, 89.29)--(123.75, 83.93)--(119.97, 83.01)--(117.24, 81.38)--(117.85, 80.79)--(116.9, 80.06)--(117.65, 79.02)--(114.24, 79.23)--(110.12, 78.93)--(108.35, 77.69)--(102.27, 80.15)--(102.6, 80.45)--(101.42, 81.66)--(96.3, 80.94)--(95.6, 75.16)--(91.88, 73.8)--(89.69, 73.89)--(91.19, 69.61)--(91.08, 68.3)--(87.73, 69.96)--(81.32, 69.32)--(81.63, 61.96)--(88.41, 60.66)--(88.78, 61.23)--(92.41, 60.31)--(95.93, 65.23)--(96.7, 65.47)--(97.12, 65.14)--(97.12, 59.81)--(100.34, 56.62)--(103.22, 54.85)--(104.21, 50.99)--(106.28, 48.84)--(108.51, 48.83)--(108.23, 48.05)--(111.68, 45.41);
landmass3 := (309.58, 101.89)--(307.85, 104.82)--(304.23, 104.36)--(301.98, 106.89)--(301.81, 107.2)--(301.39, 106.32)--(297.9, 109.91)--(292.61, 112.27)--(292.42, 116.24)--(291.76, 116.34)--(293.22, 123.3)--(295.54, 125.57)--(300.79, 123.84)--(313.31, 124.74)--(314.35, 125.13)--(314.72, 125.92)--(316.53, 125.74)--(318.45, 127.71)--(324.06, 128.78)--(326.88, 127.94)--(328.82, 125.64)--(331.64, 120.19)--(331.26, 115.24)--(328.34, 111.83)--(327.46, 109.78)--(327.32, 109.75)--(323.91, 106.24)--(320.57, 100.41)--(318.09, 106.52)--(315.29, 105.19)--(314.65, 104.27)--(314.4, 103.64)--(314.38, 101.88)--(314.02, 100.8)--(310.93, 100.72)--(310, 101.21)--(309.58, 101.89);
landmass4 := (360, 173.94)--(347.31, 173.02)--(337.83, 170.31)--(340.03, 168.66)--(345.63, 168.61)--(346.01, 167.92)--(341.09, 166.89)--(341.61, 165.5)--(343.88, 164.64)--(343.24, 163.51)--(349.37, 161.91)--(322.58, 157.73)--(323.11, 157.14)--(263.4, 156.39)--(263.26, 156.59)--(263.82, 157.03)--(245.18, 163.09)--(245.85, 157.68)--(234.93, 156.8)--(226.52, 156.65)--(194.69, 160.02)--(194.23, 160.12)--(182.27, 160.22)--(175.88, 161.21)--(175.09, 160.92)--(174.87, 161.24)--(171.99, 160.65)--(165.8, 161.33)--(163.91, 162.6)--(161.68, 163.73)--(141.54, 169.39)--(118.58, 172.13)--(116.78, 171.69)--(102.46, 169.67)--(94.78, 168.49)--(97.74, 167.88)--(101.28, 166.75)--(117.86, 164.33)--(118.52, 163.02)--(117.24, 161.46)--(117.41, 160.81)--(114.93, 158.64)--(113.38, 158.53)--(113.67, 158.17)--(112.94, 157.45)--(115.93, 156.83)--(115.81, 156.34)--(116.18, 155.88)--(116.84, 155.67)--(119.7, 154.63)--(119.77, 154.11)--(121.16, 153.99)--(121.76, 153.53)--(116.74, 154)--(113.84, 154.79)--(110.65, 157.28)--(111.18, 157.79)--(111.19, 159.12)--(104.73, 163.13)--(104.3, 163)--(90.27, 162.69)--(86.46, 162.59)--(74.77, 162.74)--(78.14, 164.63)--(64.48, 164.84)--(65.31, 164.46)--(50.04, 164.22)--(50.29, 164.61)--(32.44, 165.76)--(29.52, 166.6)--(27.21, 166.74)--(27.17, 166.97)--(22.41, 166.97)--(23.06, 168.33)--(21.43, 168.63)--(29.78, 169.97)--(27.58, 170.36)--(29.1, 170.81)--(23.15, 171.94)--(24.93, 172.46)--(17.69, 173.06)--(13.37, 172.69)--(3.71, 172.63)--(13.68, 173.98)--(0, 174.21);
landmass5 := (124.62, 19.08)--(123.98, 19.56)--(126.36, 20.09)--(127.24, 20.59)--(124.98, 23.19)--(130.77, 29.28)--(135.8, 28.99)--(137.84, 25.04)--(141.86, 24.34)--(146.13, 22.18)--(157, 19.51)--(155.91, 17.98)--(155.55, 16.8)--(159.25, 15.48)--(158.44, 14.93)--(159.9, 14.05)--(157.97, 12.46)--(159.52, 10.77)--(159.19, 10.3)--(167.06, 8.42)--(159.95, 8.2)--(156.76, 8.73)--(153.02, 7.87)--(131.44, 7.07)--(130.82, 7.37)--(127.12, 7.44)--(116.94, 8.32)--(111.03, 9.65)--(105.32, 11.75)--(107.03, 12.86)--(108.98, 13.43)--(112.23, 14.12)--(119.83, 14.46)--(121.54, 15.67)--(120.54, 15.91)--(122.91, 16.69)--(121.82, 17.23)--(124.62, 19.08);
landmass6 := (307.49, 56.47)--(307.06, 57.11)--(308.22, 57.5)--(310.39, 56.79)--(310.75, 57.43)--(312.59, 56.96)--(313.38, 56.17)--(316.84, 55.24)--(317.14, 55.51)--(319.46, 54.34)--(320.21, 51.88)--(320.32, 48.77)--(319.72, 48.29)--(319.35, 47.51)--(322.01, 46.93)--(323.56, 45.58)--(319.79, 44.82)--(319.05, 44.6)--(318.2, 46.06)--(317.67, 48.01)--(318.7, 48.63)--(315.73, 52.34)--(311.83, 54.71)--(307.49, 56.47);
landmass7 := (172.44, 33.8)--(171.76, 34.44)--(174.73, 35.22)--(173.52, 37.33)--(172.83, 38.17)--(172.56, 39.98)--(179.32, 38.52)--(178.63, 37.06)--(175.74, 33.85)--(176.19, 30.59)--(172.04, 32.2)--(171.52, 33.36)--(172.44, 33.8);
landmass8 := (222.04, 111.1)--(224.53, 115.35)--(228.6, 106.45)--(226.81, 103.35)--(222.04, 111.1);

%
% This macro draws contures for a landmass on globe centered on lon,lat
%

vardef drawLandMass (expr p, lon, lat) =
    save i, j, k, l, horizon, currentPoint, horizonTimes, outHorizon, inHorizon, visibleContours, pathNumber, horizonArc, arcTimes, resultPath;
    path resultPath, visibleContours[], horizon, horizonArc;
    pair currentPoint, horizonTimes[];
    numeric pathNumber, outHorizon, arcTimes[];
    horizon := fullcircle scaled 2;
    pathNumber := 0;
    outHorizon := -1;
    inHorizon := -1;

    % In the following loop visible segments of landmass and points of
    % horizon-crossing are calculated
    % visibleContours are just what they are called and horizonTimes are
    % times on horizon circle where visible segment should cross it
    for i := 0 upto length(p):
    currentPoint := pointOnGlobe (point i of p, lon, lat);
    if (horizonOnGlobe (point i of p, lon, lat) < 0):
        if (unknown visibleContours[pathNumber]):
            visibleContours[pathNumber] := currentPoint;
            if (i > 0):
                outHorizon := xpart(horizon intersectiontimes ((0,0) -- (findHorizonPoint (subpath(i-1, i) of p, lon, lat, 0) scaled 5)));
                if (outHorizon < inHorizon): outHorizon := outHorizon + 8; fi;
                horizonTimes[pathNumber - 1] := (inHorizon, outHorizon);
            fi;
        else:
            visibleContours[pathNumber] := visibleContours[pathNumber] -- currentPoint;
        fi;
    else:
        if (known visibleContours[pathNumber]):
            pathNumber := pathNumber + 1;
            inHorizon := xpart(horizon intersectiontimes ((0,0) -- (findHorizonPoint (subpath(i, i-1) of p, lon, lat, 0) scaled 5)));
        fi;
    fi;
    endfor;
    if (unknown visibleContours0):
        resultPath := (1,0);
    else:
        if (unknown visibleContours[pathNumber]): pathNumber := pathNumber - 1; fi;
        if (unknown horizonTimes[-1]):
            if (pathNumber > 0):
                visibleContours0 := visibleContours[pathNumber] -- visibleContours0;
            fi;
            pathNumber := pathNumber - 1;
        else:
            if (ypart(horizonTimes[-1]) < inHorizon):
                horizonTimes[pathNumber] := (inHorizon, ypart(horizonTimes[-1]) + 8);
            else:
                horizonTimes[pathNumber] := (inHorizon, ypart(horizonTimes[-1]));
            fi;
        fi;
        % In these loops horizon arcs directions should be handled
        % The idea is that when we have path with no self-intersections arcs should
        % not cross one another, these conflicts are resolved here
        % It's important to note, that horizon-time detecting algorithm is
        % not absolutely precise for now, so at times in will work incorrect.
        for i := 0 upto pathNumber - 1:
            for j := i + 1 upto pathNumber:
                l := 0;
                for k := -8, 0, 8:
                if (xpart(horizonTimes[j]) > xpart(horizonTimes[i]) + k) and (xpart(horizonTimes[j]) < ypart(horizonTimes[i]) + k): l := l + 1; fi;
                if (xpart(horizonTimes[i]) > xpart(horizonTimes[j]) + k) and (xpart(horizonTimes[i]) < ypart(horizonTimes[j]) + k): l := l + 1; fi;
            endfor;
            if (l > 1): horizonTimes[j] := (xpart(horizonTimes[j]) + 8, ypart(horizonTimes[j])); fi;
            endfor;
        endfor;

        % In the following loop previously calculated segments of a landmass and
        % arcs of the horizon are sewed together in order
        resultPath := visibleContours0
        for i := 1 upto pathNumber + 1:
            if (known horizonTimes[i-1]): -- (subpath horizonTimes[i-1] of horizon) fi
            if (i <= pathNumber): -- visibleContours[i] fi
        endfor
    fi;
    resultPath -- cycle
enddef;

% This thing just converts coordinates on globe rotated by lon, lat to screen coordinates

vardef pointOnGlobe (expr p, lon, lat) =
    (cosd(lon + xpart(p)) * sind(ypart(p)),
        cosd(ypart(p)) * cosd(lat)
        + sind(lon + xpart(p)) * sind(ypart(p)) * sind(lat))
enddef;

% This one is needed to check if point on globe is in view

vardef horizonOnGlobe (expr p, lon, lat) =
    (sind(lon + xpart(p)) * cosd(lat) * sind(ypart(p))) - (cosd(ypart(p)) * sind(lat))
enddef;

% This macro calculates horizon crossing point with given precision (recursion depth).
% Likely, this could be done analytically, though.

vardef findHorizonPoint (expr p, lon, lat, i) =
    save selecthalf, returnpoint;
    pair selecthalf, returnpoint;
    if (horizonOnGlobe (point 1/2 of p, lon, lat) < 0):
        selecthalf := (0, 1/2);
    else:
        selecthalf := (1/2, 1);
    fi;
    if (i < 5):
        returnpoint := findHorizonPoint (subpath selecthalf of p, lon, lat, i + 1)
    else:
        returnpoint := pointOnGlobe (point 1/2 of p, lon, lat);
    fi;
    returnpoint
enddef;

vardef globe (expr s, lon, lat) =
    save i, p, lm;
    picture p[];
    path lm;
    begingroup
        save angleToLightnessPP;
        vardef angleToLightnessPP (expr v) =
            1/2(v**3)
        enddef;
        p1 := image(draw sphere.l(2s, lat));
        vardef angleToLightnessPP (expr v) =
            if (abs(cos(sphlat)) > 7/8 + uniformdeviate (1/20)):
                1/4(v**2)
            else:
                1/3(v**2) + 2/3
            fi
        enddef;
        p2 := image(draw sphere.l(2s, lat));
    endgroup;
    image(
        draw fullcircle scaled 2s withpen thinpen;
        for i := 1 upto 8:
            lm := drawLandMass(landmass[i], lon + 90, lat) scaled s;
            p3 := p2;
            clip p3 to lm;
            draw p3;
            thinBrushGenerate (lm,
                offsetPathTemplate (lm, 0) (
                    2/3minStrokeWidth + 1/3minStrokeWidth
                    * angleToLightness(
                        sphereAngleToAbsoulteAngle(
                            (angleRad(point offsetPathTime of lm) + 1/4pi, abs(point offsetPathTime of lm)/2s)
                        ), 0, point offsetPathTime of lm
                    )
                ), 0);
            p1 := p1 maskedWith lm;
        endfor;
        draw p1;
    )
enddef;

%
% This macro draws an eye pointed in the direction a (in degrees)
% Eye is opened at random angle and pupil is scaled randomly by design
% Scaling below some level, dependent on minStrokeWidth, simplifies image
%

eyescale = 1/2cm;

vardef eye (expr a) =
    save s, eyelids, pupil, eyeball, eyelash, loopstep, p, o;
    path eyelids[], pupil[], eyelash;
    pair p[];
    picture eyeball;
    numeric s, loopstep;
    o := 10 + (15/(1 + 2**(3/2normaldeviate)));
    s := eyescale;
    p1 := (-3/4s, 0);
    pupil1 := ((subpath (-2, 2) of fullcircle xscaled 3/5) .. (subpath (3, 5) of fullcircle xscaled 2/5) .. cycle) scaled 3/5s;
    pupil2 := fullcircle scaled (1/3s + uniformdeviate(1/5s)) xscaled 1/3;
    p2 := ((p1 -- ((1/2s, 0) rotatedabout (p1, o - 5))) intersectionpoint (subpath (0, 4) of pupil1));
    eyelids1 := (p1 shifted (0, -1/16s)){dir(1/3o)} .. {dir(0)}p2;
    eyelids2 := p1 {dir(-1/3o)} .. {dir(0)}((1/6s, 0) rotatedabout (p1, -2/3o - 5));
    eyelids2 := subpath(xpart(eyelids2 intersectiontimes eyelids1), length(eyelids2)) of eyelids2;
    eyelids3 := (p1){dir(2/3o)} .. tension 3/2 .. {dir(o-1/3o)}p2 rotatedabout (p1, 1/3o + 7);
    eyelids3 := subpath (1/8, length(eyelids3)) of eyelids3;
    eyelids4 := (p1 shifted (0, -1/16s)) .. {dir(1/4o - 2/3o)}((1/6s, -1/6s) rotatedabout (p1, -2/3o - 5));
    eyelids4 := subpath (1/2, length(eyelids4)) of eyelids4;
    loopstep := length(eyelids1)/20;
    if (arclength(subpath(0, loopstep) of eyelids1) < 5minStrokeWidth):
        loopstep := arctime (5minStrokeWidth) of eyelids1;
    fi;
    eyeball := image(
        if (5loopstep <= 1):
        draw pupil1 withpen thinpen;
        fill pupil2;
            for i := 0 step 5loopstep until length pupil1:
                draw brush ((point i of pupil1) -- (point i + 6 of pupil2 scaled 5/6 yscaled 1/2))(cos(offsetPathLength*1/2pi)*2minStrokeWidth);
            endfor;
        else:
        fill pupil1;
        fi;
    );
    clip eyeball to (eyelids1{(1, 0)} .. (s, 0) .. {-1, 0}reverse(eyelids2) -- cycle);
    eyeball := eyeball maskedWith ((fullcircle scaled (1/4s) xscaled 1/2 rotated 2 shifted (1/12s, 0) rotatedabout (p1, 1/3o + 2)));
    image(
        draw brush (eyelids1 .. tension 2.5 .. reverse (eyelids3))((1-offsetPathLength)*2minStrokeWidth);
        draw brush (eyelids2)((offsetPathLength)*2minStrokeWidth);
        draw brush (eyelids4)(sin(offsetPathLength*pi)*minStrokeWidth);
        draw eyeball;
        for i := length(eyelids1) step -loopstep until 0:
            eyelash := (point i of eyelids1) {dir(angle(direction i of eyelids1) - 60 + 50*(i/length(eyelids1)))}
            .. (point i of eyelids1) shifted (1/16s + (i/length(eyelids1))*1/4s, (i/length(eyelids1))*1/5s);
            if (arclength(eyelash) > 2/3minDashStrokeLength):
                draw brush (eyelash shifted ((-1/32s, uniformdeviate(1/12s)) scaled ((length(eyelids1)-i)/length(eyelids1))) )(minStrokeWidth + (1-offsetPathLength)*minStrokeWidth);
            fi;
        endfor;
        for i := length(eyelids2) step -3/2loopstep until 0:
            eyelash := (point i of eyelids2) {dir(angle(direction i of eyelids2) + 20 - 40*(i/length(eyelids2)))}
            .. (point i of eyelids2) shifted (1/16s + (i/length(eyelids2))**2*1/7s, 1/16s - (i/length(eyelids2))*1/5s);
            if (arclength(eyelash) > minDashStrokeLength):
                draw brush (eyelash shifted (-1/32s, -uniformdeviate(1/24s)))(minStrokeWidth + (1-offsetPathLength)*minStrokeWidth);
            fi;
        endfor;
    ) if cosd(a) < 0: yscaled -1 rotated (a) else: rotated a fi
enddef;

%
% This macro draws solid surface
%

vardef solidSurface (expr p) =
    save q, s, d, stripes;
    path q, s;
    picture stripes;
    q := offsetPath(p) (-1/4cm);
    s := p -- reverse(q) -- cycle;
    image(
        draw solid (s, 45, 0);
        draw p withpen thinpen;
    )
enddef;

vardef solid (expr p, a, t) =
    save stripes, stripeskind, d, i, j, c;
    picture stripes, stripeskind;
    pair c;
    stripes := image(
        d1 := abs(ulcorner(p rotated (90 - a)) - urcorner(p rotated (90 - a)));
        d2 := abs(ulcorner(p rotated (90 - a)) - llcorner(p rotated (90 - a)));
        stripeskind := dashpattern (on 1mm);
        c := 1/2[ulcorner(p rotated (90 - a)), lrcorner(p rotated (90 - a))] rotated (a - 90);
        for i:= 0 step (3/2shadingDensity)/d1 until 1:
            if (t = 1):
                j := round(i*d1/(3/2shadingDensity));
                if (j mod 4) = 0:
                    stripeskind := dashpattern (on 8shadingDensity off 4shadingDensity);
                fi;
                if ((j mod 4) = 1) or ((j mod 4) = 3):
                    stripeskind := dashpattern (off 1shadingDensity on 6shadingDensity off 5shadingDensity);
                fi;
                if (j mod 4) = 2:
                    stripeskind := dashpattern (on 0 off 12shadingDensity);
                fi;
            fi;
            draw ((dir(a) scaled 1/2d2) -- (dir(a + 180) scaled 1/2d2)) shifted c shifted i[dir(a + 90) scaled 1/2d1, dir(a -90) scaled 1/2d1] withpen thinpen
            dashed stripeskind;
        endfor;
    );
    clip stripes to p;
    stripes
enddef;

%
% Returns a picture of shaded gradient inside shape p at an angle a
%

vardef gradientShade (expr p, a) =
    save stripes, stripeshd, d, i, j, s;
    picture stripes;
    path s;
    stripes := image(
        d1 := abs(ulcorner(p rotated (90 - a)) - urcorner(p rotated (90 - a)));
        d2 := abs(ulcorner(p rotated (90 - a)) - llcorner(p rotated (90 - a)));
        for i:= 0 step (shadingDensity)/d1 until 1:
            s := ((dir(a) scaled 1/2d2) -- (dir(a + 180) scaled 1/2d2)) shifted 1/2[ulcorner(p), lrcorner(p)] shifted i[dir(a + 90) scaled 1/2d1, dir(a -90) scaled 1/2d1];
            stripeshd := 1/4 + 3/4i;
            draw brush(s)(minStrokeWidth*stripeshd);
        endfor;
    );
    clip stripes to p;
    stripes
enddef;

%
% This one draws a spring between points p and q with n steps
% if stretched more than possible, displayed as a straight line
% if compressed too much, displayed as having less steps
%

springwidth := 1/8cm;

vardef spring (expr p, q, n) =
    save sp, ss, t, x, springstep, springcoef, springsegment;
    transform t;
    path ss[];
    pair sp;
    picture springsegment;
    springstep := (arclength(p--q) - 2springwidth)/(n+1);
    if (springstep < 6minStrokeWidth): springstep := arclength(p--q)/round(arclength(p--q)/6minStrokeWidth); fi;
    if (springstep < (springwidth*pi)):
        springcoef := (1-(springstep/(springwidth*pi)));
    else:
        springcoef := 0;
    fi;
    image(
        for i := 0 step 30 until 360:
            sp := ((cosd(i - 90), sind(i - 90)) scaled springwidth xscaled 1/4 yscaled springcoef) shifted (springstep*(i/360) - 1/2springstep, 0);
            if (i = 0):
                ss1 := sp;
            else:
                ss1 := ss1 -- sp;
            fi;
        endfor;
        ss2 := subpath (0, 6) of ss1;
        ss3 := subpath (6, 12) of ss1;
        ss4 := subpath (0, ypart(ss2 shifted (-3minStrokeWidth, 0) intersectiontimes ss3)) of ss3;
        x := ypart(ss2 shifted (3minStrokeWidth, 0) intersectiontimes ss3);
        if (x > 0):
            ss5 := subpath (x, length(ss3)) of ss3;
        else:
            ss5 := point length(ss3) of ss3;
        fi;
        if (xpart(llcorner(ss4)) - 3minStrokeWidth < xpart(urcorner(ss2 shifted (-springstep, 0)))):
            x := ypart((subpath (3, 6) of ss2 shifted (-springstep + 3minStrokeWidth, 0)) intersectiontimes ss4);
            if (x > 0):
                ss6 := subpath (0, x) of ss4;
            else:
                ss6 := point 0 of ss4;
            fi;
            x := ypart((subpath (0, 3) of ss2 shifted (-springstep + 3minStrokeWidth, 0)) intersectiontimes ss4);
            if (x > 0):
                ss7 := subpath (x, length(ss4)) of ss4;
            else:
                ss7 := point length(ss4) of ss4;
            fi;
        fi;
        springsegment := image(
            draw brush (ss2)(minStrokeWidth + sin(offsetPathLength*pi)*minStrokeWidth);
            if (unknown(ss6)):
                if (arclength(ss4) > minStrokeWidth): draw ss4 withpen thinpen; fi;
            else:
                if (arclength(ss6) > minStrokeWidth): draw ss6 withpen thinpen; fi
                if (arclength(ss7) > minStrokeWidth): draw ss7 withpen thinpen; fi
            fi;
                if (arclength(ss5) > minStrokeWidth): draw ss5 withpen thinpen; fi;
        );
        ss8 := (ss2 shifted (-2minStrokeWidth, 0)) rotated angle(q-p) shifted ((springwidth + 1/2springstep)/arclength(p--q))[p, q];
        for i := springwidth + 1/2springstep step springstep until arclength(p--q) - springwidth - 1/2springstep + 1:
            t := identity rotated angle(q-p) shifted (i/arclength(p--q))[p, q];
            draw springsegment transformed t;
            if (i <= springwidth + 1/2springstep + 2/3springwidth):
                ss9 := ss3 transformed t;
                ss10 := subpath (
                    xpart(ss9 intersectiontimes (subpath (0, 3) of ss8)),
                    xpart(ss9 intersectiontimes (subpath (3, 6) of ss8))
                ) of ss9;
                if (arclength(ss10) > minStrokeWidth): draw ss10 withpen thinpen; fi;
            fi;
        endfor;
        draw brush (((springwidth)/arclength(p--q))[p, q] shifted (dir(angle(p-q) + 90)*springwidth * springcoef){(p-q)} .. {(p-q)}p)(minStrokeWidth);
        draw brush (((springwidth)/arclength(p--q))[q, p] shifted (dir(angle(p-q) + 90)*springwidth * springcoef){(q-p)} .. {(q-p)}q)(minStrokeWidth);
    )
enddef;

%
% This macro draws some kind of weight. Not very nice one at the moment
%

vardef weight.h (expr h) =
    save auricle, q, r;
    path q[];
    auricle.d := 2mm;
    auricle.t := 2shadingDensity;
    r := 2/5(h-auricle.d);
    image(
        q0 := offsetPathSubdivide((0, -h) -- (0, -auricle.d - 1/6h));
        q1 := offsetPathTemplate(q0, 0)(r-(offsetPathLength*(1/8r)));
        q2 := offsetPathGenerate (q0, q1, 0);
        q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
        tubeGenerate (q2, q3, q1, 0);
        draw reverse(q2) -- q3 withpen thinpen;
        q0 := offsetPathSubdivide((0, -auricle.d - 1/6h) -- (0, -auricle.d));
        q1 := offsetPathTemplate(q0, 0)(2/8r + 5/8r*(sqrt(1-offsetPathLength**2)));
        q2 := offsetPathGenerate (q0, q1, 0);
        q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
        tubeGenerateAlt (q2, q3, q1);
        draw q3 -- reverse(q2) withpen thinpen;
        q5 := offsetPathSubdivide(point 0 of q3 -- point 0 of q2);
        q6 := tube.e((0,0) -- (0, -3/2auricle.t))(1/2auricle.t);
        draw image(
            q4 := (((0, -1/2) {dir(90)} .. (1/2, 1/2) .. (0, 1) .. {dir(-90)}(-1/2, 1/4)) shifted (0, -1)) scaled 2/3auricle.d;
            draw shadedEdge(tube.e(q4) (1/4auricle.t)) shifted (0, -1/2auricle.t);
        ) maskedWith (q3 -- reverse(q2) -- (q2 yscaled 0 shifted (0, -h)) -- (reverse(q3) yscaled 0 shifted (0, -h)) -- cycle)
          maskedWith q6;
        draw shadedEdge(q6);
        thinBrushGenerate (q5,
            offsetPathTemplate (q5, 0) (
                minDashStrokeWidth + minStrokeWidth
                * angleToLightness(
                        (arccos(1 - offsetPathLength*2), 1/2pi)
                        , 0, point offsetPathTime of q5
                )
            ), 0);
    )
enddef;

vardef weight.s (expr h) =
    save q,r;
    path q[];
    r := 2/5h;
    image(
        q0 := offsetPathSubdivide((0, 0) -- (0, h-2/3r));
        q1 := offsetPathTemplate(q0, 0)(r);
        q2 := offsetPathGenerate (q0, q1, 0);
        q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
        tubeGenerate (q2, q3, q1, 0);
        draw reverse(q2)--q3 withpen thinpen;
        q0 := offsetPathSubdivide((0, h-2/3r) -- (0, h - 1/8r));
        q1 := offsetPathTemplate(q0, 0)(r-sqrt(1- (1- offsetPathLength*2)**2)*1/3r - 1/6r*offsetPathLength);
        q2 := offsetPathGenerate (q0, q1, 0);
        q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
        tubeGenerateAlt (q2, q3, q1);
        draw q2 withpen thinpen;
        draw q3 withpen thinpen;
        q0 := offsetPathSubdivide((0, h-1/8r) -- (0, h));
        q1 := offsetPathTemplate(q0, 0)((r-1/6r)+sqrt(1- (1- offsetPathLength*2)**2)*1/16r);
        q2 := offsetPathGenerate (q0, q1, 0);
        q3 := offsetPathGenerate (q0, q1 yscaled -1, 0);
        tubeGenerateAlt (q2, q3, q1);
        draw q2 --reverse(q3) withpen thinpen;
    )
enddef;

%
% This macro makes a lens-shaped clockwise path with radii
% r = (left radius, right radius), thickness t and diameter d
%

vardef lens (expr r, t, d, s) =
    save p, q, m, c;
    pair c[];
    path p[], q[];
    if (xpart(r) = infinity):
        p1 := (0, d) -- (0, -d);
    else:
        p1 := subpath (2, 6) of fullcircle scaled 2xpart(r);
    fi;
    if (ypart(r) = infinity):
        p2 := (0, d) -- (0, -d);
    else:
        p2 := subpath (-2, 2) of fullcircle scaled 2ypart(r);
    fi;
    q1 := (min(xpart(ulcorner(p1)), xpart(ulcorner(p2))) - 1, -1/2d)--(max(xpart(urcorner(p1)), xpart(urcorner(p2))) + 1,-1/2d);
    q2 := q1 shifted (0, d);
    q3 := q1 shifted (0, 1/2d);
    c1 := p1 intersectiontimes q1;
    c2 := p1 intersectiontimes q2;
    c3 := p2 intersectiontimes q2;
    c4 := p2 intersectiontimes q1;
    if (xpart(c1) > 0):
        p1 := subpath (xpart(c1), xpart(c2)) of p1;
    fi;
    if (xpart(c3) > 0):
        p2 := subpath (xpart(c3), xpart(c4)) of p2;
    fi;
    p1 := p1 shifted (-xpart(point xpart(p1 intersectiontimes q3) of p1), 0);
    p2 := p2 shifted (-xpart(point xpart(p2 intersectiontimes q3) of p2) + t, 0);
    reverse(p1--p2--cycle) scaled s
enddef;

%
% This one returns a picture of a pulley with diameter d and it's support rotated
% at angle a. pulleyOutline path changes every time
%

path pulleyOutline;
numeric pulleySupportSize;
pulleySupportSize := 2/3;

vardef pulley (expr d, a) =
    save pw, p, r;
    picture pw;
    path p[];
    r1 := 3/5d;
    r2 := 1/6d;
    image(
        p0 := fullcircle scaled d;
        p1 := (subpath (3, 9) of fullcircle) scaled r1;
        p0 := subpath (
            xpart(p0 intersectiontimes ((point 0 of p1) -- (point 0 of p1 shifted (0, d)))),
            8 + xpart(p0 intersectiontimes ((point 0 of reverse(p1)) -- (point 0 of reverse(p1) shifted (0, d)))))
            of p0;
        p0 := ((xpart(point 0 of reverse(p0)), pulleySupportSize*d) -- (xpart(point 0 of p0), pulleySupportSize*d) -- p0 -- cycle) rotated a;
        pulleyOutline := p0;
        p1 := (p1 --  (xpart(point 0 of reverse(p1)), pulleySupportSize*d) --  (xpart(point 0 of p1), pulleySupportSize*d) -- cycle) rotated a;
        pw := pulleyWheel(d) maskedWith p1;
        draw pw;
        draw p1 withpen thinpen;
        draw shadedEdge(reverse(fullcircle) scaled r2);
    )
enddef;

vardef pulleyWheel (expr d) =
    save pw, r, i;
    picture pw;
    r1 := 7/9d;
    r2 := 8/9d;
    r3 := 3/5d;
    r4 := 1/8d;
    if (r2-r1) > shadingDensity:
        pw := image(
            for i := r3 step 2shadingDensity until r2:
            if (i <= r1) or (i >= r2):
                thinBrushGenerate (fullcircle scaled i,
                    offsetPathTemplate (fullcircle scaled i, 0) (
                        2/3minStrokeWidth + minStrokeWidth
                        * angleToLightness(
                            sphereAngleToAbsoulteAngle(
                                (angleRad(direction offsetPathTime of fullcircle), i/4d)
                            ), 0, point offsetPathTime of fullcircle scaled i
                        )
                    ), 0);
            else:
                thinBrushGenerate (fullcircle scaled i,
                    offsetPathTemplate (fullcircle scaled i, 0) (
                        1/4minStrokeWidth + minStrokeWidth
                        * angleToLightness(
                            sphereAngleToAbsoulteAngle(
                                (angleRad(direction offsetPathTime of fullcircle) + pi, 1/2)
                            ), 0, point offsetPathTime of fullcircle scaled i
                        )
                    ), 0);
            fi;
            endfor;
            draw brush (fullcircle scaled r1)(minStrokeWidth);
            draw brush (fullcircle scaled r2)(minStrokeWidth);
            draw fullcircle scaled d withpen thinpen;
            draw fullcircle scaled r3 withpen thinpen;
            draw shadedEdge(reverse(fullcircle) scaled r4);
        );
    else:
        pw := image(
            draw shadedEdge (reverse(fullcircle) scaled r1);
            draw fullcircle scaled d withpen thinpen;
            draw fullcircle scaled r4 withpen thickpen;
        )
    fi;
    pw
enddef;

%
% This macro draws a wheel
%

vardef wheel (expr d, a) =
    save pc, p, r, i;
    picture pc[];
    path p[];
    r1 := 2/8d;
    r2 := d-6minStrokeWidth;
    r3 := 7/8d-2shadingDensity;
    if r1 > 3shadingDensity:
        pc1 := image(
            for i := r1 step 2shadingDensity until r3:
                thinBrushGenerate (fullcircle scaled i,
                    offsetPathTemplate (fullcircle scaled i, 0) (
                        2/3minStrokeWidth + minStrokeWidth
                        * angleToLightness(
                            sphereAngleToAbsoulteAngle(
                                (angleRad(direction offsetPathTime of fullcircle) + pi, i/4d)
                            ), 0, point offsetPathTime of fullcircle scaled i
                        )
                    ), 0);
            endfor;
            draw sphere.c(r1);
            draw shadedEdge (reverse(fullcircle) scaled r3);
        );
    else:
        pc1 := image(
            draw shadedEdge (fullcircle scaled d);
            draw shadedEdge (fullcircle scaled r1);
            draw shadedEdge (reverse(fullcircle) scaled r2);
        );
    fi;
    pc2 := image(fill fullcircle scaled d;) maskedWith (fullcircle scaled r2);
    pc3 := image(
        p1 := reverse((1/3d, 1/4d) -- (-1/3d, 1/4d) -- (-1/2d, 1/2d) --  (1/2d, 1/2d) -- cycle) rotated a;
        draw p1 withpen thinpen;
        draw gradientShade(p1, 180);
    );
    pc3 := pc3 maskedWith (fullcircle scaled d);
    image(
        draw pc1;
        draw pc2;
        draw pc3;
    )
enddef;

%
% These macros are for drawing wood texture. A bunch of wood-related global
% variables are also here.
%

woodBlockRes := 1/3mm;
woodBlockDetail := 1/5;
woodBlockYRdensity := 1/24;
woodKnotAngle := 1/3pi;
woodKnotRadius := 1/8cm;
woodKnotDensity := 2cm;

% wField returns a value on a scalar field, that is surface of year ring

vardef wField (suffix wk)(expr i, j, cs, nwk)=
    save x, y, csx, csy, ba, a, r, outputValue, k, bd;
    csx := xpart(cs);
    csy := ypart(cs);
    x := i*woodBlockDetail;
    y := j*woodBlockDetail;
    bd := 1/2(woodKnotRadius/woodBlockRes)*woodBlockDetail;
    outputValue := 0;
    for k := 0 upto nwk:
        r := (abs(((x, y) shifted -wk[k]) yscaled (sin(woodKnotAngle))));
        a := angleRad((x, y) shifted -wk[k]);
        if (r >= 2bd) and (1/2r-bd < 8):
            outputValue := outputValue + ((sqrt(1/2r-bd)/(3**(1/2r-bd)))*(sin(woodKnotAngle)*(1/2sin(-a)) + 1)*(1/3 + 2/3abs(cos(a))))**2;
        elseif (r < 2bd):
            outputValue := outputValue - 10sqrt(1-(r/2bd)**4);
        fi;
        outputValue := outputValue + 1/64cos(2pi*1/30r);
    endfor;
    outputValue := outputValue - (i*woodBlockYRdensity)/5 + 1/32sin(pi*i/xpart(cs) + 4pi*j/ypart(cs));
    outputValue
enddef;

% woodBlock generates coordinates of knots, calls wField to
% generate matrix of heights (one for all years, that's simplification, of course)
% and then calls isoLines for each year ring (shifting values in matrix by woodBlockYRdensity)

vardef woodBlock (expr w, l) =
    save wood, wKnot, nwKnot, p, q, i, j, k, cl, tr, wS, lS;
    numeric wood[][];
    pair wKnot[];
    path q;
    picture p;
    if (l > w):
        wS := round(w/woodBlockRes);
        lS := round(l/woodBlockRes);
    else:
        wS := round(l/woodBlockRes);
        lS := round(w/woodBlockRes);
    fi;
    image(
        p := image(
            i := -1;
            j := 0;
            forever:
                wKnot[-1] := (uniformdeviate(wS*woodBlockDetail + woodKnotRadius*woodBlockDetail/woodBlockRes), uniformdeviate(lS*woodBlockDetail + woodKnotRadius*woodBlockDetail/woodBlockRes)) shifted (-1/2woodKnotRadius*woodBlockDetail/woodBlockRes, -1/2woodKnotRadius*woodBlockDetail/woodBlockRes);
                cl := 0;
                if (i > -1):
                    for k := 0 step 1 until i:
                        if (woodBlockRes*abs(wKnot[k]-wKnot[-1])/woodBlockDetail) < woodKnotDensity:
                            cl := 1;
                        fi;
                    endfor;
                fi;
                if cl > 0:
                    j := j + 1;
                else:
                    i := i + 1;
                    wKnot[i] := wKnot[-1];
                    for tr := 2woodKnotRadius step -8minStrokeWidth until 2minStrokeWidth:
                        draw brush(
                        ((fullcircle scaled tr yscaled (1/sin(woodKnotAngle))) shifted (woodBlockRes*wKnot[i]/woodBlockDetail))
                        )(
                        minStrokeWidth*(1/2+abs(sin(woodKnotAngle))*abs(sin(angleRad(point offsetPathTime of fullcircle))))
                        );
                    endfor;
                fi;
            exitif (j >= 10) or (i >= 1/2((w/cm)*(l*cm))/(woodKnotDensity/cm));
            endfor;
            nwKnot := i;
            for i := 0 step 1 until wS:
                k := uniformdeviate(1/8woodBlockYRdensity);
                for j := 0 step 1 until lS:
                    wood[i][j] := wField (wKnot)(i, j, (wS, lS), nwKnot) + k;
                endfor;
            endfor;
            for i := -wS/(80woodBlockYRdensity) - 2 upto wS/(80woodBlockYRdensity) + 2:
                draw isoLines(wood)((wS, lS), woodBlockYRdensity*i + uniformdeviate(1/8woodBlockYRdensity), woodBlockRes);
            endfor;
        );
        q := (0, 0) -- (w, 0) -- (w, l) -- (0, l) -- cycle;
        if (w > l): q := q xscaled -1 rotated -90; fi;
        clip p to q;
        draw p;
        draw q withpen thinpen;
    ) if (l < w): xscaled -1 rotated -90 fi
enddef;

% woodenThing fits a woodBlock into thingOutline at a given woodAngle

vardef woodenThing (expr thingOutline, woodAngle) =
    save shiftedThing, thingOrigin, thingWoodBlock;
    path shiftedThing;
    pair thingOrigin;
    picture thingWoodBlock;
    shiftedThing := thingOutline rotated -woodAngle;
    thingOrigin := llcorner(shiftedThing);
    shiftedThing := shiftedThing shifted -thingOrigin;
    thingWoodBlock := woodBlock(xpart(urcorner(shiftedThing)), ypart(urcorner(shiftedThing)));
    clip thingWoodBlock to shiftedThing;
    thingWoodBlock := (thingWoodBlock shifted thingOrigin) rotated woodAngle;
    image(
        draw thingOutline withpen thinpen;
        draw thingWoodBlock;
        )
enddef;

%
% This part is related to knots
%

% lists are only used in knots so far.
% The following two macros are taken from byrne.mp

vardef appendList@#(suffix listName)(expr valueToAdd, whereToAdd, omitDuplicates) =
    save v, valueExists;
    string v;
    boolean valueExists;
    valueExists := false;
    if str @# = "":
        if not string listName:
            string listName;
        fi;
    else:
        if not string listName0:
            string listName[];
        fi;
    fi;
    if unknown listName@#:
        listName@# := "";
    fi;
    if omitDuplicates:
        for i=scantokens(listName@#):
            if (i = valueToAdd):
                valueExists := true;
            fi;
        endfor;
    fi;
    if not valueExists:
        if string valueToAdd:
            v := valueToAdd;
        else:
            v := decimal(valueToAdd);
        fi;
        if length(listName@#) = 0:
            listName@# := v;
        else:
            if (whereToAdd = 1):
                listName@# := listName@# & ", " & v;
            else:
                listName@# := v & ", " & listName@#;
            fi;
        fi;
    fi;
enddef;

vardef sortList (expr listToSort, ascending) =
    save nPre, nPost, pivot, isSorted, lastValue, preList, postList, rv;
    numeric nPre, nPost, pivot;
    boolean isSorted;
    string preList, postList, rv;
    nPre := 0;
    nPost := 0;
    isSorted := true;
    if ascending:
        lastValue := -infinity;
    else:
        lastValue := infinity;
    fi;
    for i=scantokens(listToSort):
        if (unknown pivot):
            pivot := i;
        fi;
        if ((i < pivot) and ascending) or ((i > pivot) and not ascending):
            appendList (preList, i, -1, false);
            nPre := nPre + 1;
        else:
            appendList (postList, i, -1, false);
            nPost := nPost + 1;
        fi;
        if ((lastValue > i) and ascending) or ((lastValue < i) and not ascending):
            isSorted := false;
        fi;
        lastValue := i;
    endfor;
    if isSorted:
        rv := listToSort;
    else:
        if nPre > 1:
            preList := sortList(preList, ascending);
        fi;
        if nPre > 0:
            preList := preList & ", ";
        else:
            preList := "";
        fi;
        if nPost > 1:
            postList := sortList(postList, ascending);
        fi;
        rv := preList & postList;
    fi;
    rv
enddef;


% When looking for intersections, knot is browsed with knotStepSize step.
% Affects nothing interesting.
numeric knotStepSize;
knotStepSize := 1/8;

vardef knotFromStrands (suffix knotName) =
    save slidingSegment, timeToAdd, pathSegments, intTimes, tSegWidth, tSegStyle, numberOfSegments, segmentWidth, totalNumberOfSegments, intersections, intersectionsList, layerContents, layersList, b, e, n, layerContents, segmentPicture;
    save shadowsEnabled, allShadowPaths, totalNumberOfShadows, numberOfShadows, shadowPath, tmpShadows;
    boolean shadowsEnabled;
    path shadowPath[], allShadowPaths[];
    numeric timeToAdd, numberOfShadows, totalNumberOfShadows;
    totalNumberOfShadows := -1;
    tmpShadows := -1;
    path inspectedPath, slidingSegment, pathSegments[];
    pair intTimes[];
    numeric intersections[], numberOfSegments[], segmentWidth[], totalNumberOfSegments, tSegWidth, b, e, n;
    picture layerPicture[];
    string layerContents[], segmentStyle[], tSegStyle;
    totalNumberOfSegments := 0;
    for sNa := 1 step 1 until knotName.nStrands:
        inspectedPath := knotName.strandPath[sNa];
        tSegWidth := knotName.strandWidth[sNa];
        tSegStyle := knotName.strandStyle[sNa];
        for sNb := 1 step 1 until knotName.nStrands:
            for i := -knotStepSize step knotStepSize until length(knotName.strandPath[sNb]):
                slidingSegment := subpath (i, i + 2knotStepSize) of knotName.strandPath[sNb];
                intTimes0 := (inspectedPath firstIntersectionTimes slidingSegment);
                intTimes1 := (reverse(inspectedPath) firstIntersectionTimes slidingSegment);
                if (sNb = sNa):
                    if (xpart(intTimes0) >= i)
                        and (xpart(intTimes0) <= i + 2knotStepSize):
                        intTimes0 := (-1, -1);
                    fi;
                    if ((length(inspectedPath) - xpart(intTimes1)) >= i)
                        and ((length(inspectedPath) - xpart(intTimes1)) <= i + 2knotStepSize):
                        intTimes1 := (-1, -1);
                    fi;
                    if (i+knotStepSize >= length(inspectedPath)):
                        if (xpart(intTimes0) <= knotStepSize)
                            or (xpart(intTimes0) = length(inspectedPath)):
                            intTimes0 := (-1, -1);
                        fi;
                        if ((length(inspectedPath) - xpart(intTimes1)) <= knotStepSize)
                            or (xpart(intTimes1) = 0):
                            intTimes1 := (-1, -1);
                        fi;
                    fi;
                    if (i-knotStepSize <= length(inspectedPath)):
                        if (xpart(intTimes0) >= (length(inspectedPath) - knotStepSize))
                            or (xpart(intTimes0) = 0):
                            intTimes0 := (-1, -1);
                        fi;
                        if ((length(inspectedPath) - xpart(intTimes1)) >= (length(inspectedPath) - knotStepSize))
                            or (xpart(intTimes1) = length(inspectedPath)):
                            intTimes1 := (-1, -1);
                        fi;
                    fi;
                fi;
                timeToAdd := -1;
                if ((ypart(intTimes0) > 0) and (ypart(intTimes0) < length(slidingSegment)))
                    and ((xpart(intTimes0) >= 0) and (xpart(intTimes0) <= length(inspectedPath)))
                    and ((sNb <> sNa) or ((xpart(intTimes0) < i) or (xpart(intTimes0) > i + 1))):
                    timeToAdd := xpart(intTimes0);
                elseif (sNb = sNa):
                    if ((ypart(intTimes1) > 0) and (ypart(intTimes1) < length(slidingSegment)))
                        and ((xpart(intTimes1) >= 0) and (xpart(intTimes1) <= length(inspectedPath)))
                        and ((length(inspectedPath) - xpart(intTimes1) < i) or (length(inspectedPath) - xpart(intTimes1) > i + 1)):
                        timeToAdd := length(inspectedPath) - xpart(intTimes1);
                    fi;
                fi;
                if (timeToAdd >= 0):
                    if (timeToAdd = length(inspectedPath)):
                        timeToAdd := 0;
                    fi;
                    appendList[sNa](intersectionsList, round(timeToAdd*10)/10, 1, true);
                fi;
            endfor;
        endfor;
        if known intersectionsList[sNa]:
            numberOfSegments[sNa] := 0;
            for i := scantokens(sortList(intersectionsList[sNa], true)):
                numberOfSegments[sNa] := numberOfSegments[sNa] + 1;
                intersections[numberOfSegments[sNa]] := i;
            endfor;
            intersections[0] := 0;
            if (not cycle knotName.strandPath[sNa]):
                intersections[numberOfSegments[sNa] + 1] := length(knotName.strandPath[sNa]);
            fi;
            for i := 1 step 1 until numberOfSegments[sNa]:
                totalNumberOfSegments := totalNumberOfSegments + 1;
                if (i > 1):
                    b := 1/2[intersections[i-1], intersections[i]];
                else:
                    if (not cycle knotName.strandPath[sNa]):
                        b := 0;
                    else:
                        b := 1/2[intersections[numberOfSegments[sNa]] - length(knotName.strandPath[sNa]), intersections[i]];
                    fi;
                fi;
                if (i < numberOfSegments[sNa]):
                    e := 1/2[intersections[i], intersections[i+1]];
                else:
                    if (not cycle knotName.strandPath[sNa]):
                        e := length(inspectedPath);
                    else:
                        e := 1/2[intersections[i], intersections[1] + length(knotName.strandPath[sNa])];
                    fi;
                fi;
                pathSegments[totalNumberOfSegments] := subpath (b, e) of inspectedPath;
                if (length(pathSegments[totalNumberOfSegments])<=2):
                    pathSegments[totalNumberOfSegments] := pathSubdivide(pathSegments[totalNumberOfSegments], 2);
                fi;
                segmentWidth[totalNumberOfSegments] := tSegWidth;
                segmentStyle[totalNumberOfSegments] := tSegStyle;
            endfor;
        else:
            totalNumberOfSegments := totalNumberOfSegments + 1;
            numberOfSegments[sNa] := 1;
            pathSegments[totalNumberOfSegments] := inspectedPath;
            segmentWidth[totalNumberOfSegments] := tSegWidth;
            segmentStyle[totalNumberOfSegments] := tSegStyle;
        fi;
        n := 0;
        for i := scantokens(knotName.intLayers[sNa]):
            n := n + 1;
            if (n <= numberOfSegments[sNa]):
                appendList[i](layerContents, totalNumberOfSegments - numberOfSegments[sNa] + n, 1, true);
                appendList(layersList, i, 1, true);
            fi;
        endfor;
        if n > 0:
            if n < numberOfSegments[sNa]:
                for i := n + 1 step 1 until numberOfSegments[sNa]:
                    appendList0(layerContents, totalNumberOfSegments - numberOfSegments[sNa] + i, 1, true);
                endfor;
                appendList(layersList, 0, 1, true);
            fi;
        else:
            for i := 1 step 1 until numberOfSegments[sNa]:
                appendList0(layerContents, totalNumberOfSegments - numberOfSegments[sNa] + i, 1, true);
            endfor;
            appendList(layersList, 0, 1, true);
        fi;
    endfor;
    image(
        for i := scantokens(sortList(layersList, false)):
            layerPicture[i] := image(
                for j := scantokens(layerContents[i]):
                    numberOfShadows := -1;
                    shadowsEnabled := false;
                    for k := 0 step 1 until totalNumberOfShadows:
                        if xpart((subpath (1/10, length(pathSegments[j]) - 1/10) of pathSegments[j])
                            intersectiontimes allShadowPaths[k]) > 0:
                            shadowsEnabled := true;
                            numberOfShadows := numberOfShadows + 1;
                            shadowPath[numberOfShadows] := allShadowPaths[k];
                            shadowDepth[numberOfShadows] := 3/2segmentWidth[j];
                        fi;
                    endfor;
                    save drawTubeEnds;
                    boolean drawTubeEnds;
                    drawTubeEnds := false;
                    draw tube.scantokens(segmentStyle[j])(pathSegments[j])(segmentWidth[j]) if segmentStyle[j] = "e": withpen thickpen fi;
                    tmpShadows := tmpShadows + 1;
                    allShadowPaths[tmpShadows] := tubeOutline;
                endfor;
            );
            for j := 0 step 1 until totalNumberOfShadows:
                layerPicture[i] := layerPicture[i] maskedWith allShadowPaths[j];
            endfor;
            totalNumberOfShadows := tmpShadows;
        endfor;
        for i := scantokens(sortList(layersList, true)):
            draw layerPicture[i];
        endfor;
    )
enddef;

vardef addStrandToKnot (suffix knotName) (expr p, w, s, intersectionLayers) =
    save n;
    if not known knotName.nStrands:
        numeric knotName.nStrands;
        knotName.nStrands := 0;
    fi;
    if not path knotName.strandPath0:
        path knotName.strandPath[];
    fi;
    if not numeric knotName.strandWidth0:
        numeric knotName.strandWidth[];
    fi;
    if not string knotName.strandStyle0:
        string knotName.strandStyle[];
    fi;
    if not string knotName.intLayers0:
        string knotName.intLayers[];
    fi;
    knotName.nStrands := knotName.nStrands + 1;
    n := knotName.nStrands;
    knotName.strandPath[n] := p;
    knotName.strandWidth[n] := w;
    knotName.strandStyle[n] := s;
    knotName.intLayers[n] := intersectionLayers;
enddef;
