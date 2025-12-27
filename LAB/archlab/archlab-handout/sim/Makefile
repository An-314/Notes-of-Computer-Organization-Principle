# Comment this out if you don't have Tcl/Tk on your system

#GUIMODE=-DHAS_GUI

# Modify the following line so that gcc can find the libtcl.so and
# libtk.so libraries on your system. You may need to use the -L option
# to tell gcc which directory to look in. Comment this out if you
# don't have Tcl/Tk.

TKLIBS=-L/usr/lib -ltk -ltcl

# Modify the following line so that gcc can find the tcl.h and tk.h
# header files on your system. Comment this out if you don't have
# Tcl/Tk.

TKINC=-isystem /usr/include/tcl8.5

##################################################
# You shouldn't need to modify anything below here
##################################################

# Use this rule (make all) to build the Y86-64 tools. The variables you've
# assigned to GUIMODE, TKLIBS, and TKINC will override the values that
# are currently assigned in seq/Makefile and pipe/Makefile.
COMPAT = -std=gnu11 -fcommon

.PHONY: parta parta-sum clean clean-parta clean-all

all:
	(cd misc; make all CFLAGS="-Wall -O1 -g $(COMPAT)" LCFLAGS="-O1 $(COMPAT)")
	(cd pipe; make all GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)" CFLAGS="-Wall -O2 $(COMPAT)")
	(cd seq;  make all GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)" CFLAGS="-Wall -O2 $(COMPAT)")
	(cd y86-code; make all CFLAGS="-Wall -O2 $(COMPAT)")

YAS:=misc/yas
YIS:=misc/yis
PARTA:=PartA

parta: parta-sum parta-rsum parta-copy

parta-sum: $(YAS) $(YIS)
	$(YAS) $(PARTA)/sum.ys
	$(YIS) $(PARTA)/sum.yo > $(PARTA)/sum.log

parta-rsum: $(YAS) $(YIS)
	$(YAS) $(PARTA)/rsum.ys
	$(YIS) $(PARTA)/rsum.yo > $(PARTA)/rsum.log

parta-copy: $(YAS) $(YIS)
	$(YAS) $(PARTA)/copy.ys
	$(YIS) $(PARTA)/copy.yo > $(PARTA)/copy.log

clean-parta:
	rm -f $(PARTA)/*.yo $(PARTA)/*.log

PARTB:=PartB

partb:
	mkdir -p $(PARTB)
	(cd seq; ./ssim -t ../y86-code/asumi.yo 2>&1 | tee ../$(PARTB)/asumi-ssim.log)
	(cd y86-code; make testssim 2>&1 | tee ../$(PARTB)/y86-testssim.log)
	(cd ptest; make SIM=../seq/ssim 2>&1 | tee ../$(PARTB)/ptest-ssim.log)
	(cd ptest; make SIM=../seq/ssim TFLAGS=-i 2>&1 | tee ../$(PARTB)/ptest-issim.log)

PARTC:=PartC

mkpipe:
	(make clean)
	(make)
	(cd pipe; make clean; make VERSION=full GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)" CFLAGS="-Wall -O2 $(COMPAT)")


partc:
	mkdir -p $(PARTC)
	(cd pipe; ../$(YAS) ncopy.ys 2>&1 | tee ../$(PARTC)/ncopy-yas.log)
	(cd pipe; ./check-len.pl < ncopy.yo 2>&1 | tee ../$(PARTC)/ncopy-len.log)
	(cd pipe; ../misc/yis sdriver.yo 2>&1 | tee ../$(PARTC)/sdriver-ypipe.log)
	(cd pipe; ./correctness.pl 2>&1 | tee ../$(PARTC)/pipe-correctness.log)
	(cd pipe; ./correctness.pl -p 2>&1 | tee ../$(PARTC)/pipe-pcorrectness.log)
	(cd pipe; ./benchmark.pl 2>&1 | tee ../$(PARTC)/pipe-benchmark.log)
clean:
	rm -f *~ core
	(cd misc; make clean)
	(cd pipe; make clean)
	(cd seq; make clean)
	(cd y86-code; make clean)
	(cd ptest; make clean)

clean-all: clean clean-partA