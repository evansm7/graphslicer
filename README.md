# Graph Slicer
v1.0 12th August 2017

This script generates SVG outlines of vertical slices through a 3D function, which can then be cut out and stacked to form a 3D graph made of paper/cardboard/thin wood.

It is recommended to get a machine (such as a laser cutter) to do the dirty work, but it has been demonstrated that printing the slices and cutting them out by hand also works.  This works better if you don't get bored easily, and/or you choose to use fairly small number of slices.

The default configuration will generate 240 slices that are 50mm wide.  When used with 180gsm card (and packed tightly) this gives a cuboid approximately 50x50mm (and 30mm tall).

Each slice has mounting holes in consistent locations to leverage mechanical mounting techniques in order to generate a very straight stack to maximise end-user experience.  Each slice is also marked using a set of notches to show, in binary, the slice's sequence number.  This is very useful to re-order the slices when they get mixed up when removing them from the laser cutter, or fall on the floor, or blow away.


## Prerequisites
This perl program uses the SVG and POSIX perl modules.  (POSIX is probably already installed by your distribution but you might need to add a package such as libsvg-perl.)
 
## Usage
Running the program is super-simple, because it is a quick hack and doesn't even have any cruel command-line arguments.  ;-)

~~~
me:~$ ./graph-slicer.pl > amazing_graph.svg
~~~

Use the output to cut out the slices, and stack them in order.  The slices are ordered in columns top-to-bottom then left-to-right (and are numbered as such using the binary notches, mentioned above).


### Configuration

Various things to tinker with (by editing the variables in the script):

* The graphed function and coordinate space/scale (play around in Grapher.app (OS X) or Gnuplot to find something pleasing)
* The width/height of each slice
* The output page area
* The number of slices

The slice dimensions and number of slices will affect the number of slices that fit into the output area.  A simple attempt is made to pack the slices closer together rather than using a regular grid, to save material.

The script is dumb and works by walking through the output area in rows/columns, spaced by the given slice size.  If it reaches the requested number of slices before running out of space, it stops.  If it runs out of space before reaching the requested number of slices, it stops -- so tinkering with the values will be required for best results.

An obvious improvement would be to output a variable area given a requested number of slices, or a number of slices to fill a given area.  However, they are inter-dependent and this might need some iteration to converge on an ideal layout (changing the number of slices will change the area required for the slices, as they are "minimally packed").  The current packing algorithm is over-conservative and wastes a little material; it just walks columns and stops/wraps to the top again if there isn't enough space for the worst-case slice height.  (This could easily be improved by evaluating the graph function to get the exact height of the next slice and wrapping only if this doesn't fit.)

A harder improvement would be to optimally pack the slices.  This task is left to a second pass using smarter software (and authors) than this.


### Cutting advice
The default configuration outputs 240 slices across an area of 5x portrait A4 pages placed side-by-side (48 per page as 4 columns of 12).  As part of the laser cutting flow, I cut one A4 page at a time (by selecting groups of 4 columns in sequence).

I used 180gsm coloured card, which I measured at about 0.21mm per slice.  I chose 50mm wide and 240 slices to shoot for 50mm deep.

This took about 11 minutes per sheet (for 5 sheets) to cut.  Budget a couple of hours to make one of these!  (Assembly time will be significant.)

The default configuration generates 2mm holes, which look more elegant than 3mm holes on the 50mm-wide piece, but it is hard to find long 2mm bolts.  If you do wish to bolt the piece together, threaded rod might be worth investigating.  However, I used 2mm diameter wire instead and crimped the ends.


## Licence
    graph-slicer.pl is copyright (c) 2009, 2017 Matt Evans

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
