# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Original Author: Shay Gal-on

# Make sure the default target is to simply build and run the benchmark.
RSTAMP = v1.0

.PHONY: run score
run: $(OUTFILE) rerun score

score:
	@echo "Check run1.log and run2.log for results."
	@echo "See readme.txt for run and reporting rules." 
	
OUTFLAG= -o
CC = gcc
PORT_CFLAGS = -O2
FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"
CFLAGS = $(PORT_CFLAGS) -DFLAGS_STR=\"$(FLAGS_STR)\"
#Flag: LFLAGS_END
#	Define any libraries needed for linking or other flags that should come at the end of the link line (e.g. linker scripts). 
#	Note: On certain platforms, the default clock_gettime implementation is supported but requires linking of librt.
LFLAGS_END += -lrt
# Port specific source files can be added here
# Flag: LOAD
#	Define this flag if you need to load to a target, as in a cross compile environment.

# Flag: RUN
#	Define this flag if running does not consist of simple invocation of the binary.
#	In a cross compile environment, you need to define this.

#For flashing and using a tera term macro, you could use
#LOAD = flash ADDR 
#RUN =  ttpmacro coremark.ttl

#For copying to target and executing via SSH connection, you could use
#LOAD = scp $(OUTFILE)  user@target:~
#RUN = ssh user@target -c  

#For native compilation and execution
LOAD = echo Loading done
RUN = 

OEXT = .o
EXE = .exe

# Flag: SEPARATE_COMPILE
# Define if you need to separate compilation from link stage. 
# In this case, you also need to define below how to create an object file, and how to link.
ifdef SEPARATE_COMPILE

LD		= gcc
OBJOUT 	= -o
LFLAGS 	=
OFLAG 	= -o
COUT 	= -c
# Flag: PORT_OBJS
# Port specific object files can be added here
PORT_OBJS = $(PORT_DIR)/core_portme$(OEXT)
PORT_CLEAN = *$(OEXT)

$(OPATH)%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@
	
endif

# Target: port_prebuild
# Generate any files that are needed before actual build starts.
# E.g. generate profile guidance files. Sample PGO generation for gcc enabled with PGO=1
#  - First, check if PGO was defined on the command line, if so, need to add -fprofile-use to compile line.
#  - Second, if PGO reference has not yet been generated, add a step to the prebuild that will build a profile-generate version and run it.
#  Note - Using REBUILD=1 
#
# Use make PGO=1 to invoke this sample processing.

ifdef PGO
 ifeq (,$(findstring $(PGO),gen))
  PGO_STAGE=build_pgo_gcc
  CFLAGS+=-fprofile-use
 endif
 PORT_CLEAN+=*.gcda *.gcno gmon.out
endif

.PHONY: port_prebuild
port_prebuild: $(PGO_STAGE)

.PHONY: build_pgo_gcc
build_pgo_gcc:
	$(MAKE) PGO=gen XCFLAGS="$(XCFLAGS) -fprofile-generate -DTOTAL_DATA_SIZE=1200" ITERATIONS=10 gen_pgo_data REBUILD=1
	
# Target: port_postbuild
# Generate any files that are needed after actual build end.
# E.g. change format to srec, bin, zip in order to be able to load into flash
.PHONY: port_postbuild
port_postbuild:

# Target: port_postrun
# 	Do platform specific after run stuff. 
#	E.g. reset the board, backup the logfiles etc.
.PHONY: port_postrun
port_postrun:

# Target: port_prerun
# 	Do platform specific after run stuff. 
#	E.g. reset the board, backup the logfiles etc.
.PHONY: port_prerun
port_prerun:

# Target: port_postload
# 	Do platform specific after load stuff. 
#	E.g. reset the reset power to the flash eraser
.PHONY: port_postload
port_postload:

# Target: port_preload
# 	Do platform specific before load stuff. 
#	E.g. reset the reset power to the flash eraser
.PHONY: port_preload
port_preload:

# FLAG: OPATH
# Path to the output folder. Default - current folder.
OPATH = ./
MKDIR = mkdir -p

# FLAG: PERL
# Define perl executable to calculate the geomean if running separate.
PERL=/usr/bin/perl

ifndef $(ITERATIONS)
ITERATIONS=0
endif
ifdef REBUILD
FORCE_REBUILD=force_rebuild
endif

CFLAGS += -DITERATIONS=$(ITERATIONS)

SRCS = *.c
OBJS = *.o
OUTNAME = coremark
OUTFILE = $(OPATH)$(OUTNAME)
LOUTCMD = $(OFLAG) $(OUTFILE) $(LFLAGS_END)
OUTCMD = $(OUTFLAG) $(OUTFILE) $(LFLAGS_END)

HEADERS = coremark.h 
CHECK_FILES = $(ORIG_SRCS) $(HEADERS)

$(OPATH):
	$(MKDIR) $(OPATH)

.PHONY: compile link

compile: $(OPATH) $(SRCS) $(HEADERS) 
	$(CC) $(CFLAGS) $(XCFLAGS) $(SRCS) $(OUTCMD)
link: compile 
	@echo "Link performed along with compile"


$(OUTFILE): $(SRCS) $(HEADERS) Makefile $(FORCE_REBUILD)
	$(MAKE) port_prebuild
	$(MAKE) link
	$(MAKE) port_postbuild

.PHONY: rerun
rerun: 
	$(MAKE) XCFLAGS="$(XCFLAGS) -DPERFORMANCE_RUN=1" load run1.log
	$(MAKE) XCFLAGS="$(XCFLAGS) -DVALIDATION_RUN=1" load run2.log

PARAM1=$(PORT_PARAMS) 0x0 0x0 0x66 $(ITERATIONS)
PARAM2=$(PORT_PARAMS) 0x3415 0x3415 0x66 $(ITERATIONS)
PARAM3=$(PORT_PARAMS) 8 8 8 $(ITERATIONS)

run1.log-PARAM=$(PARAM1) 7 1 2000
run2.log-PARAM=$(PARAM2) 7 1 2000 
run3.log-PARAM=$(PARAM3) 7 1 1200

run1.log run2.log run3.log: load
	$(MAKE) port_prerun
	# $(RUN) $(OUTFILE) $($(@)-PARAM) > $(OPATH)$@
	$(MAKE) port_postrun
	
.PHONY: gen_pgo_data
gen_pgo_data: run3.log

.PHONY: load
load: $(OUTFILE)
	$(MAKE) port_preload
	$(LOAD) $(OUTFILE)
	$(MAKE) port_postload

.PHONY: clean
clean:
	rm -f $(OUTFILE) $(OPATH)*.log *.info $(OPATH)index.html $(PORT_CLEAN)

.PHONY: force_rebuild
force_rebuild:
	echo "Forcing Rebuild"
	
.PHONY: check
check:
	md5sum -c coremark.md5 

ifdef ETC
# Targets related to testing and releasing CoreMark. Not part of the general release!
include Makefile.internal
endif	
