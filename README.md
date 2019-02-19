# dungeon

A C-language port of Dungeon 2.7a (original MIT Zork), with the goal of being able to both compile and run on an Intel 8088+ PCs and clones.

## Target environments
* IBM PC Portable (5155)
  * Intel 8088 CPU @ 4.77 MHz
  * No coprocessor
  * 512 kB RAM
  * IBM PC-DOS 5.01
* Development Tools
  * Borland C++ 2.0

This code began as a copy of the f2c-generated C port of Dungeon 2.7s, the 03-11-1991 port of Dungeon 2.7a done by Ian Lance Taylor ian@airs.com, with contributing work by Jonathan Mark and Volker Blasius, availble from ifarchive.org at https://www.ifarchive.org/if-archive/games/source/dungn27s.zip.

## Build Instructions

This source has been verified to build on the envirnonments listed above.  No other prerequisites should be required; to begin, simply clone the repo or download and unzip the archive.

### Borland C++

To build:
```
make -fmakefile.bcc
```

To clean:
```
make -fmakefile.bcc clean
```

## Copyright and License

This code includes a copy of This site was built using [David S. Peterson's](mailto:dspeter1@eos.ncsu.edu) UUDECODE utility for 8088 assembler and a DOS binary.  This is copyrighted software and distributed under the following conditions:

```
;----------------------------------------------------------------------------
; UUDECODE program, version 1.1
;
; Copyright 1995, David S. Peterson
;
; This program may be used and distributed freely as long as this copyright
; notice is not removed.  Feel free to use sections of code from this program
; as part of your own programs, but please leave this file intact.  I am
; reasonably certain that this program doesn't have any major bugs, but its
; use is at your own risk.  If you find any bugs in this program, or have any
; questions or comments, please feel free to send me some email or write me a
; letter.  My email address is:
;
;    dspeter1@eos.ncsu.edu
;
; and my mailing address is:
;
;    David S. Peterson
;    3717 Williamsborough Ct.
;    Raleigh, NC 27609
;    USA
;
; If you like this program, feel free to send me a postcard from your home
; town.
;----------------------------------------------------------------------------
```
