#!/usr/bin/perl -w
#
# graph-slicer.pl
#
# Copyright (c) 2009, 2017 Matt Evans
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ------------------------------------------------------------------------------
# Version 1.0, 12th August 2017
#
# This program generates an SVG on stdout which provides outlines of slices of a
# 3D graph/surface, suitable for laser cutting.
#
# There are lots of improvements that could be made; for starters, taking
# command-line options for the many tunable parameters (at the very least an
# output filename).  The number of slices is currently best determined through
# (simple) trial and error, but could be automated given a desired output area
# and slice XY size.
#

use SVG;
use strict;
use POSIX;

my $PI = 3.1415926;

################################################################################
#################### Tunable variables #########################################
################################################################################

# Graph coordinate space:
my $xmin = -5;
my $xmax = 5;
my $ymin = -5;
my $ymax = 5;
my $funcMin = -2;
my $funcMax = 2;

# The graph function itself:
sub myFunc
{
    my $x = shift;
    my $y = shift;
    my $r = sqrt(($x*$x)+($y*$y));

    return cos($r**1.6)*(1+(cos($PI*($r/sqrt(50)))));
}

# Output page setup:
# 
# 210 * X
# 297 * Y
# 	A4: X=1 Y=1
# 	A3: X=2 Y=1
# 	A2: X=2 Y=2
my $pgWidth = 210*5;
my $pgHeight = 297*1;

# Slices; determine this empirically given page size and
# graphWidth/graphHeight/gapX/gapY.  Also, balance this against material
# thickness ($slices * thickness should roughly equal $graphWidth).
#
# For starters, 240 fills 5x A4 sheets with 50x30mm slices.
my $slices = 240;

# Slice output dimensions
my $graphWidth = 50;
my $graphHeight = 30;		# Total, including base
my $graphHeightBase = 10;	# Base guaranteed free from cutouts
my $graphHeightTop = $graphHeight - $graphHeightBase;
my $graphDepth = $graphWidth;

# Resolution, in number of samples.  Much more than 2 per mm seems overkill for
# cutting paper etc.
my $graphXres = 100;

# Spacing between slices:
my $gapX = 1.5;
my $gapY = 1.5;

# Hole dimensions and position:
my $holeFromEdge = 5;
my $holeRad = 1;

# Slice ID notch dimensions
my $idNotchDepth = 1.5;
my $idNotchWidth = 1.5;

################################################################################
################################################################################

# Misc non-configuration constants:

# Inkscape seems to assume 90dpi.  I thought that SVG inherits units from the
# declared document dimensions (which are output in mm, below), yet without a
# scale transform it just doesn't seem to line up.  Generate the correct scale
# here, so that one unit equals 1mm:
my $unitsPerMm = 90 / 25.4;

# Number of bits required for the slice ID notches:
my $slicesBits = ceil(log($slices)/log(2));

################################################################################

# create an SVG object
my $svg= SVG->new(width=>$pgWidth."mm",height=>$pgHeight."mm");

sub drawGraph
{
    my $gNum = shift;
    my $ypos = shift;
    my $originX = shift;
    my $originY = shift;

    my @xv = ();
    my @yv = ();

    my $point = 0;

    my $yscale = ($graphHeightTop/($funcMax - $funcMin));

    my $maxZ = 0;

    $xv[$point] = $originX;
    $yv[$point] = $originY;
    $point++;
    my $pointZ;
    for (my $i = 0; $i <= $graphWidth; $i += ($graphWidth/$graphXres))
    {
        my $x = (($i/$graphWidth)*($xmax-$xmin))+$xmin;


        $pointZ = $graphHeightBase + (($graphHeightTop/(-$funcMin/$funcMax-$funcMin))+(myFunc($x, $ypos) * $yscale));
        $xv[$point] = $originX + $i;
        $yv[$point] = $originY + $pointZ;
        $point++;
        if ($pointZ > $maxZ)
        {
            $maxZ = $pointZ;
        }
    }
    # Connect back to start
    $xv[$point] = $originX+$graphWidth;
    $yv[$point] = $originY+$pointZ;
    $point++;
    $xv[$point] = $originX+$graphWidth;
    $yv[$point] = $originY;
    $point++;

    ################################################################################
    # Add slice ID notches for gNum, for order/identification (roughly centered):
    my $nCur = $originX+($graphWidth+($slicesBits * $idNotchWidth))/2;
    $xv[$point] = $nCur;
    $yv[$point] = $originY;
    $point++;

    $xv[$point] = $nCur;
    $yv[$point] = $originY+(1.5*$idNotchDepth);
    $point++;
    $nCur 	= $nCur-$idNotchWidth;

    $xv[$point] = $nCur;
    $yv[$point] = $originY+(1.5*$idNotchDepth);
    $point++;

    $xv[$point] = $nCur;
    $yv[$point] = $originY;
    $point++;
    $nCur 	= $nCur-$idNotchWidth;

    my $lastBit = 0;
    my $lastX = $nCur;
    for (my $bit = 0; $bit < $slicesBits; $bit++) {
	my $cBit = ($gNum & (1 << $bit)) ? 1 : 0;

	if ($cBit == 0 && $lastBit == 1) {
	    $xv[$point] = $lastX;
	    $yv[$point] = $originY+$idNotchDepth;
	    $point++;

	    $xv[$point] = $nCur;
	    $yv[$point] = $originY;
	    $point++;		
	} elsif ($cBit == 1 && $lastBit == 0) {
	    $xv[$point] = $lastX;
	    $yv[$point] = $originY;
	    $point++;

	    $xv[$point] = $nCur;
	    $yv[$point] = $originY+$idNotchDepth;
	    $point++;
	}
	$nCur = $nCur - $idNotchWidth;

	$lastBit = $cBit;
	$lastX = $nCur;
    }
    if ($lastBit == 1) {
	$xv[$point] = $nCur;
	$yv[$point] = $originY+$idNotchDepth;
	$point++;
    }
    $xv[$point] = $nCur;
    $yv[$point] = $originY;
    $point++;
    ################################################################################

    # Finally, close path:
    $xv[$point] = $originX;
    $yv[$point] = $originY;
    $point++;

    my $mGroup=$svg->group(
        id    => "group_$gNum",
        style => { stroke=>'red', 'fill-opacity'=>0, 'stroke-width'=>'0.1' },
        transform => "scale($unitsPerMm)"
        );

    my $points = $mGroup->get_path(
        x => \@xv,
        y => \@yv,
        -type   => 'polyline',
        -closed => 'false'
        );

    # Alignment/mounting holes:
    my $rcirc = $mGroup->circle(id=>"cr".$gNum,
				cx=>($originX+$holeFromEdge), cy=>($originY+$holeFromEdge), r=>$holeRad
	);

    my $lcirc = $mGroup->circle(id=>"cl".$gNum,
				cx=>($originX+$graphWidth-$holeFromEdge), cy=>($originY+$holeFromEdge), r=>$holeRad
	);

    my $tag = $mGroup->polyline(
        %$points,
        id    => "pline_$gNum"
        );

    return $maxZ;
}


my $px;
my $py;
my $grNum = 0;
my $y = $ymin;
my $ystep = ($ymax - $ymin)/($slices-1);
my $maxZ = 0;

for ($px = 0; ($px+$graphWidth < $pgWidth) && ($grNum < $slices); $px += ($graphWidth + $gapX))
{
    $maxZ = 0;
    # This loop is slightly conservative.  It generates a vertical column of
    # slice outlines, stopping when there isn't enough space for the worst-case
    # graph size ($graphHeight).  However, most slices will be smaller than
    # this, so some material is wasted here.  A better version will evaluate the
    # function to get a real "next slice height" and decide to loop based on
    # that.
    for ($py = 0; (($py + $graphHeight) < $pgHeight) && ($grNum < $slices); $py += ($maxZ + $gapY))
    {
        my $z;
        $maxZ = drawGraph($grNum, $y, $px, $py);
        $grNum++;
	# This Y is in the graph's coordinate space.  Move on to next slice in
	# that space:
        $y += $ystep;
    }
}

# Finally, render the SVG object.  Implicitly use svg namespace:
print $svg->xmlify;
