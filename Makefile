# Makefile for dungeon

# Where to install the program
BINDIR = /usr/games

# Where to install the data file
LIBDIR = /usr/games/lib

# Compiler to use
CC = cc

# Name of the dungeon executable
TARGET = dungeon

# Compilation flags
CFLAGS = -O0
# On SCO Unix Development System 3.2.2a, the const type qualifier does
# not work correctly when using cc.  The following line will cause it
# to not be used and should be uncommented.
# CFLAGS= -O -Dconst=

# Source files
CSRC1 =	actors.c ballop.c clockr.c demons.c dgame.c dinit.c dmain.c
CSRC2 =	dso1.c dso2.c dso3.c dso4.c dso5.c dso6.c dso7.c dsub.c dverb1.c
CSRC3 =	dverb2.c gdt.c lightp.c local.c nobjs.c np.c np1.c np2.c np3.c
CSRC4 =	nrooms.c objcts.c rooms.c sobjs.c supp.c sverbs.c verbs.c villns.c
CSRC = $(CSRC1) $(CSRC2) $(CSRC3) $(CSRC4)

# Header files
DEPS = funcs.h vars.h parse.h

# Object files
OBJS1 =	actors.o ballop.o clockr.o demons.o dgame.o dinit.o dmain.o
OBJS2 = dso1.o dso2.o dso3.o dso4.o dso5.o dso6.o dso7.o dsub.o dverb1.o
OBJS3 = dverb2.o gdt.o lightp.o local.o nobjs.o np.o np1.o np2.o np3.o
OBJS4 = nrooms.o objcts.o rooms.o sobjs.o supp.o sverbs.o verbs.o villns.o
OBJS = $(OBJS1) $(OBJS2) $(OBJS3) $(OBJS4)

##################################################################

# The dungeon program provides a "more" facility which tries to
# figure out how many rows the terminal has.  Several mechanisms are
# supported for determining this; the most common one has been left
# uncommented.  If you have trouble, especially when linking, you may
# have to select a different option.

# more option 1: use the termcap routines.  On some systems the LIBS
# variable may need to be set to -lcurses.  On some it may need to
# be /usr/lib/termcap.o.  These options are commented out below.
#LIBS = -ltermcap
#TERMFLAG =
# LIBS = -lcurses
# LIBS = /usr/lib/termcap.o

# more option 2: use the terminfo routines.  On some systems the LIBS
# variable needs to be -lcursesX, but probably all such systems support
# the termcap routines (option 1) anyhow.
# LIBS = -lcurses
# TERMFLAG = -DMORE_TERMINFO

# more option 3: assume all terminals have 24 rows
LIBS =
TERMFLAG = -DMORE_24

# more option 4: don't use the more facility at all
# LIBS =
# TERMFLAG = -DMORE_NONE

# End of more options

# Uncomment the following line if you want to have access to the game
# debugging tool.  This is invoked by typing "gdt".  It is not much
# use except for debugging.
# GDTFLAG = -DALLOW_GDT

##################################################################

all: $(TARGET)

$(TARGET): $(OBJS) dtextc.dat
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(LIBS)

dtextc.dat:
	cat dtextc.uu1 dtextc.uu2 dtextc.uu3 dtextc.uu4 | uudecode > dtextc.dat

dinit.o: dinit.c funcs.h vars.h
	$(CC) $(CFLAGS) $(GDTFLAG) -DTEXTFILE=\"dtextc.dat\" -c dinit.c

dgame.o: dgame.c funcs.h vars.h
	$(CC) $(CFLAGS) $(GDTFLAG) -c dgame.c

gdt.o: gdt.c funcs.h vars.h
	$(CC) $(CFLAGS) $(GDTFLAG) -c gdt.c

local.o: local.c funcs.h vars.h
	$(CC) $(CFLAGS) $(GDTFLAG) -c local.c

supp.o: supp.c funcs.h vars.h
	$(CC) $(CFLAGS) $(TERMFLAG) -c supp.c	

#%.o: %.c $(DEPS)
#	$(CC) -c -o $@ $< $(CFLAGS)

actors.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c actors.c 

ballop.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c ballop.c 

clockr.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c clockr.c 

demons.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c demons.c 

dmain.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dmain.c  

dso1.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso1.c   

dso2.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso2.c   

dso3.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso3.c   

dso4.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso4.c   

dso5.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso5.c   

dso6.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso6.c   

dso7.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dso7.c   

dsub.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dsub.c   

dverb1.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dverb1.c 

dverb2.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c dverb2.c 

lightp.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c lightp.c 

nobjs.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c nobjs.c  

np.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c np.c     

np1.o: funcs.h vars.h parse.h
	$(CC) $(CFLAGS) -c np1.c    

np2.o: funcs.h vars.h parse.h
	$(CC) $(CFLAGS) -c np2.c    

np3.o: funcs.h vars.h parse.h
	$(CC) $(CFLAGS) -c np3.c    

nrooms.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c nrooms.c 

objcts.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c objcts.c 

rooms.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c rooms.c  

sobjs.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c sobjs.c  

sverbs.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c sverbs.c 

verbs.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c verbs.c  

villns.o: funcs.h vars.h
	$(CC) $(CFLAGS) -c villns.c

.PHONY:clean
clean:
	rm -f $(OBJS) $(TARGET) dtextc.dat core dsave.dat *.o *~
