# dungeon

A C-language port of Dungeon 2.7s (original MIT Zork plus changes by @ianlancetaylor), with the goal of being able to both compile and run on an Intel 8088+ PCs and clones.

## Target environments
* IBM PC Portable (5155)
  * Intel 8088 CPU @ 4.77 MHz
  * No coprocessor
  * 512 kB RAM
  * IBM PC-DOS 5.01
* Development Tools
  * Borland C++ 2.0

This code began as a copy of the f2c-generated C port of Dungeon 2.7s, the 03-11-1991 port of Dungeon 2.7a done by [Ian Lance Taylor](https://github.com/ianlancetaylor), with contributing work by Jonathan Mark and Volker Blasius, availble from [ifarchive.org](https://www.ifarchive.org/if-archive/games/source/dungn27s.zip).

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

## Manifest
| File Name    | Description                                                              |
| -------------|--------------------------------------------------------------------------|
| README.md    | Some revision history notes, this shipping list, and general information |
| Makefile     | Makefile for gcc and *nix systems                                        |
| Makefile.BCC | Makefile for MS-DOS and Borland C++                                      |
| Makefile.MSC | Makefile for MS-DOS and Microsoft C                                      |
| actors.c     | character processors                                                     |
| ballop.c     | balloon processor                                                        |
| clockr.c     | clock event processors                                                   |
| demons.c     | demon processors                                                         |
| dgame.c      | main routine                                                             |
| dinit.c      | initialization routine                                                   |
| dmain.c      | program root                                                             |
| dso1.c       | overlaid subroutines, part 1                                             |
| dso2.c       | overlaid subroutines, part 2                                             |
| dso3.c       | overlaid subroutines, part 3                                             |
| dso4.c       | overlaid subroutines, part 4                                             |
| dso5.c       | overlaid subroutines, part 5                                             |
| dso6.c       | overlaid subroutines, part 6                                             |
| dso7.c       | overlaid subroutines, part 7                                             |
| dsub.c       | resident subroutines                                                     |
| dtextc.uu1   | data base, part 1 [uuencoded binary]                                     |
| dtextc.uu2   | data base, part 2 [uuencoded binary]                                     |
| dtextc.uu3   | data base, part 3 [uuencoded binary]                                     |
| dtextc.uu4   | data base, part 4 [uuencoded binary]                                     |
| dungeon.6    | *nix man page                                                            |
| dverb1.c     | auxiliary verbs, part 1                                                  |
| dverb2.c     | auxiliary verbs, part 2                                                  |
| funcs.h      | header file with function prototypes                                     |
| gdt.c        | game debugging tool                                                      |
| lightp.c     | light processors                                                         |
| local.c      | hooks for local definition                                               |
| nobjs.c      | new objects                                                              |
| np.c         | parser, part 0                                                           |
| np1.c        | parser, part 1                                                           |
| np2.c        | parser, part 2                                                           |
| np3.c        | parser, part 3                                                           |
| nrooms.c     | new room processors                                                      |
| objcts.c     | principal objects                                                        |
| parse.h      | header file for parsing routines                                         |
| rooms.c      | room processors                                                          |
| sobjs.c      | simple objects                                                           |
| supp.c       | support routines and more processing                                     |
| sverbs.c     | simple verbs                                                             |
| vars.h       | header file with variable definitions                                    |
| UUDECODE.ASM | source for David S. Peterson's uudecode MS-DOS utility                   |
| UUDECODE.COM | binary for David S. Peterson's uudecode MS-DOS utility                   |
| verbs.c      | principal verbs                                                          |
| villns.c     | villain processors                                                       |

## From the Original README

### Ian Lance Taylor (11-mar-91)

This is a source file distribution for the game dungeon as implemented in C.  It is based on the game dungeon as distributed on a DECUS tape, circa 1980.  It has been converted from the original DEC FORTRAN to f77 to C.  See the file "History" for some revision history and credit to those whose efforts have made this possible.

Take a look at the Makefile.  It should be fine for most systems, although you may want to change BINDIR and LIBDIR.  On SCO UNIX see the note at the definition of CFLAGS.  Makefile.MSC should work for MS-DOS using Microsoft C.  It was contributed by Jonathan Mark (uunet!microsoft!jonm).

To compile and link dungeon, type make.  To install it in BINDIR and LIBDIR, type make install.

There are two functions in local.c that you may want to write for your system.  The first controls when the game can be played, and can be used to disallow play during business hours, for example.  The second controls who is allowed to invoke the game debugging tool; note that this will only be available at all if you uncomment the GDTFLAG line in the Makefile.  The comments in local.c explain what to do.

All files in the distribution kit are ASCII.  The files dtextc.uu1, dtextc.uu2, dtextc.uu3, dtextc.uu4 are parts of a uuencoded binary file named dtextc.dat.  The Makefile will create the binary file automatically on a UNIX system; elsewhere you will have to stick the four files together in numerical order and run the resulting large file through uudecode.  I can't help you find uudecode, though.

The binary file dtextc.dat holds the text strings and initialization information for the game.  The strings are encrypted to prevent easy cheating; if you want to do further work on the program, or translate the strings, Ian Taylor (address below) has a program to convert this file back and forth from a human-readable form.

This has been compiled and tested on a DECstation 3100 running Ultrix 4.0, a VAXstation GPX running Ultrix 3.1, an 80386 box running SCO Unix 3.2.2, an 8800 running Ultrix, a Sun box running SUN OS 4 release 4, and an 80386 PC running MS-DOS.

I consider my changes to be in the public domain, as did previous contributors (see the History file for more detail).  The original source, however, is copyright.

Ian Lance Taylor
[ian@airs.com](mailto:ian@airs.com) or uunet!airs!ian
11 March 1991

### Volker Blasius (11-jul-93)
I supplied a new file Makefile.BCC for Borland C++ (tested with version 3.1). While working on this, I discovered that I had to change function main in dmain.c from 'returning void' to 'returning int' - bcc doesn't accept `void main(...)` in ANSI mode.

[Volker Blasius](mailto:Volker.Blasius@gmd.de), 11jul93

## History of the C Implementation of Dungeon

This version of dungeon has been modified from FORTRAN to C.  The
original was written in DEC FORTRAN, translated from MDL.  It was then
translated to f77 for UN*X systems, from which it was translated to C.
The C translation was done with the help of f2c, the FORTRAN to C
translator written by David Gay (AT&T Bell Labs), Stu Feldman
(Bellcore), Mark Maimone (Carnegie-Mellon University), and Norm
Schryer (AT&T Bell Labs).

### I. From the original documentation...

```
To:	Dungeon Players
From:	"The Translator"
Subj:	Game Information
Date:	8-OCT-80


This is the first (and last) source release of the PDP-11 version of 
Dungeon.

Please note that Dungeon has been superceded by the game ZORK(tm).
The following is an extract from the new product announcement for
ZORK in the September, 1980 issue of the RT-11 SIG newsletter:

  "'ZORK:  The Great Underground Empire - Part I' ...was developed
   by the original authors based on their ZORK (Dungeon) game for
   the PDP-10.  It features a greatly improved parser;  command
   input and transcript output files;  SAVEs to any device and
   file name;  and adaptation to different terminal types,
   including a status line on VT100s.  Note:  this is not the
   FORTRAN version that has been available through DECUS.  This
   version has been completely rewritten to run efficiently on
   small machines - up to 10 times as fast as the DECUS version.

   ...ZORK runs under RT-ll, HT-ll, or RSTS/E and requires as
   little as 20K words of memory and a single floppy disk drive.
   The game package, consisting of an RX01-format diskette and
   an instruction booklet, is available from Infocom, Inc.,
   P.O. Box 120, Kendall Station, Cambridge, Ma. 02142."

ZORK(tm) is a trademark of Infocom, Inc.  It is available for several
popular personal computers as well as for the PDP-ll.


SUMMARY
-------

		    Welcome to Dungeon!

   Dungeon is a game of adventure, danger, and low cunning.  In it
you will explore some of the most amazing territory ever seen by mortal
man.  Hardened adventurers have run screaming from the terrors contained
within.

   In Dungeon, the intrepid explorer delves into the forgotten secrets
of a lost labyrinth deep in the bowels of the earth, searching for
vast treasures long hidden from prying eyes, treasures guarded by
fearsome monsters and diabolical traps!

   No DECsystem should be without one!

   Dungeon was created at the Programming Technology Division of the MIT
Laboratory for Computer Science by Tim Anderson, Marc Blank, Bruce
Daniels, and Dave Lebling.  It was inspired by the Adventure game of
Crowther and Woods, and the Dungeons and Dragons game of Gygax
and Arneson.  The original version was written in MDL (alias MUDDLE).
The current version was translated from MDL into FORTRAN IV by
a somewhat paranoid DEC engineer who prefers to remain anonymous.

   On-line information may be obtained with the commands HELP and INFO.
```

### II. DEC FORTRAN to f77 Conversion (17-nov-81)

The conversion from DEC FORTRAN to Unix f77 was done by Randy
Dietrich, Lynn Cochran and Sig Peterson.  Much hacking was done to get
it to fit in the limited address space of a PDP-11/44 (split I/D).
Suffice it to say that by leaving out the debugging package and not
linking in the f77 i/o library they managed to get it to run.

### III. PDP to VAX (dec-85)

Based on the work of Randy, Lynn and Sig, Bill Randle folded in the
full save/restore functions and the game debugging package (gdt) into
the pdp version to create a Vax/Unix version.  This version also uses
f77 i/o, thus eliminating the extra speak and listen processes needed
on the pdp.

### IV. Cleanup I (11-dec-86)

John Gilmore (hoptoad!gnu) cleaned up the source files by moving
most of the common declarations into include files and added
comments from the original (FORTRAN or MDL?) source.  His efforts
are greatly appreciated.

### V. Cleanup II (9-feb-87)

Bill Randle (billr@tekred.tek.com) added the pdp dependencies back
into the Vax source files with #ifdefs in order to have just one
set of sources.  Previously, there were two sets of source: one for
the pdp and one for the Vax.  In addition, a shell escape of the
form !cmd was added and the wizard can enter the gdt without having
to recompile the source.  Finally, a man page was generated, based
on the dungeon.doc file.

### VI. f77 to C (11-mar-91)

Ian Lance Taylor (ian@airs.com or uunet!airs!ian) used the f2c
translator to generate C source code.  The resulting code was modified
to remove the FORTRAN I/O library, to add simple more processing, and
to change the format of the database file.  Andre Srinivasan
(andre@cs.pitt.edu) help test it.  Jonathan Mark
(uunet!microsoft!jonm) made it work under MS-DOS and Microsoft C.

### VII. This fork (19-feb-19)

Dan FitzGerald (daniel.j.fitzgerald@gmail.com) corrected some errors
in the Borland C++ makefile and created a new github repository as a
means of distributing their fix.  They decided to then use this fork
as a way of hosting Dungeon C code garunteed to build on their IBM
PC Portable (IBM 5155).  The README and HISTORY files were moved
into the README.md file.  The UNIX makefile was rewritten and tested
on a modern laptop running GCC 5.4.0 20160609, and then on the 5155
running Minix 2.0.2 and its' built in cc compiler.
