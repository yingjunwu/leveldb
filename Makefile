# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

#-----------------------------------------------
# Uncomment exactly one of the lines labelled (A), (B), and (C) below
# to switch between compilation modes.

# (A) Production use (optimized mode)
# OPT ?= -O2 -DNDEBUG
# (B) Debug mode, w/ full line-level debugging symbols
OPT ?= -g2
# (C) Profiling mode: opt, but w/debugging symbols
# OPT ?= -O2 -g2 -DNDEBUG
#-----------------------------------------------

# detect what platform we're building on
$(shell CC="$(CC)" CXX="$(CXX)" TARGET_OS="$(TARGET_OS)" \
    ./build_detect_platform build_config.mk ./)
# this file is generated by the previous line to set build flags and sources
include build_config.mk

TESTS = \
	db/autocompact_test \
	db/c_test \
	db/corruption_test \
	db/db_test \
	db/dbformat_test \
	db/fault_injection_test \
	db/filename_test \
	db/log_test \
	db/recovery_test \
	db/skiplist_test \
	db/version_edit_test \
	db/version_set_test \
	db/write_batch_test \
	helpers/memenv/memenv_test \
	issues/issue178_test \
	issues/issue200_test \
	table/filter_block_test \
	table/table_test \
	util/arena_test \
	util/bloom_test \
	util/cache_test \
	util/coding_test \
	util/crc32c_test \
	util/env_posix_test \
	util/env_test \
	util/hash_test

UTILS = \
	db/db_bench \
	db/leveldbutil \
	db/my_program

# Put the object files in a subdirectory, but the application at the top of the object dir.
PROGNAMES := $(notdir $(TESTS) $(UTILS))

# On Linux may need libkyotocabinet-dev for dependency.
BENCHMARKS = \
	doc/bench/db_bench_sqlite3 \
	doc/bench/db_bench_tree_db

CFLAGS += -I. -I./include $(PLATFORM_CCFLAGS) $(OPT)
CXXFLAGS += -I. -I./include $(PLATFORM_CXXFLAGS) $(OPT)

LDFLAGS += $(PLATFORM_LDFLAGS)
LIBS += $(PLATFORM_LIBS)

SIMULATOR_OUTDIR=out-ios-x86
DEVICE_OUTDIR=out-ios-arm

ifeq ($(PLATFORM), IOS)
# Note: iOS should probably be using libtool, not ar.
AR=xcrun ar
SIMULATORSDK=$(shell xcrun -sdk iphonesimulator --show-sdk-path)
DEVICESDK=$(shell xcrun -sdk iphoneos --show-sdk-path)
DEVICE_CFLAGS = -isysroot "$(DEVICESDK)" -arch armv6 -arch armv7 -arch armv7s -arch arm64
SIMULATOR_CFLAGS = -isysroot "$(SIMULATORSDK)" -arch i686 -arch x86_64
STATIC_OUTDIR=out-ios-universal
else
STATIC_OUTDIR=out-static
SHARED_OUTDIR=out-shared
STATIC_PROGRAMS := $(addprefix $(STATIC_OUTDIR)/, $(PROGNAMES))
SHARED_PROGRAMS := $(addprefix $(SHARED_OUTDIR)/, db_bench c_test)
endif

STATIC_LIBOBJECTS := $(addprefix $(STATIC_OUTDIR)/, $(SOURCES:.cc=.o))
STATIC_MEMENVOBJECTS := $(addprefix $(STATIC_OUTDIR)/, $(MEMENV_SOURCES:.cc=.o))

DEVICE_LIBOBJECTS := $(addprefix $(DEVICE_OUTDIR)/, $(SOURCES:.cc=.o))
DEVICE_MEMENVOBJECTS := $(addprefix $(DEVICE_OUTDIR)/, $(MEMENV_SOURCES:.cc=.o))

SIMULATOR_LIBOBJECTS := $(addprefix $(SIMULATOR_OUTDIR)/, $(SOURCES:.cc=.o))
SIMULATOR_MEMENVOBJECTS := $(addprefix $(SIMULATOR_OUTDIR)/, $(MEMENV_SOURCES:.cc=.o))

SHARED_LIBOBJECTS := $(addprefix $(SHARED_OUTDIR)/, $(SOURCES:.cc=.o))
SHARED_MEMENVOBJECTS := $(addprefix $(SHARED_OUTDIR)/, $(MEMENV_SOURCES:.cc=.o))

TESTUTIL := $(STATIC_OUTDIR)/util/testutil.o
TESTHARNESS := $(STATIC_OUTDIR)/util/testharness.o $(TESTUTIL)
TEST_STATIC_OBJS := $(STATIC_OUTDIR)/port/port_posix.o $(STATIC_OUTDIR)/util/crc32c.o $(STATIC_OUTDIR)/util/histogram.o

STATIC_TESTOBJS := $(addprefix $(STATIC_OUTDIR)/, $(addsuffix .o, $(TESTS)))
STATIC_UTILOBJS := $(addprefix $(STATIC_OUTDIR)/, $(addsuffix .o, $(UTILS)))
STATIC_ALLOBJS := $(STATIC_LIBOBJECTS) $(STATIC_MEMENVOBJECTS) $(STATIC_TESTOBJS) $(STATIC_UTILOBJS) $(TESTHARNESS)
DEVICE_ALLOBJS := $(DEVICE_LIBOBJECTS) $(DEVICE_MEMENVOBJECTS)
SIMULATOR_ALLOBJS := $(SIMULATOR_LIBOBJECTS) $(SIMULATOR_MEMENVOBJECTS)

default: all

# Should we build shared libraries?
ifneq ($(PLATFORM_SHARED_EXT),)

# Many leveldb test apps use non-exported API's. Only build a subset for testing.
SHARED_ALLOBJS := $(SHARED_LIBOBJECTS) $(SHARED_MEMENVOBJECTS) $(TESTHARNESS)
SHARED_CXXFLAGS += -DLEVELDB_SHARED_LIBRARY
SHARED_BUILD_CXXFLAGS += $(SHARED_CXXFLAGS) -DLEVELDB_COMPILE_LIBRARY

ifneq ($(PLATFORM_SHARED_VERSIONED),true)
SHARED_LIB1 = libleveldb.$(PLATFORM_SHARED_EXT)
SHARED_LIB2 = $(SHARED_LIB1)
SHARED_LIB3 = $(SHARED_LIB1)
SHARED_LIBS = $(SHARED_LIB1)
SHARED_MEMENVLIB = $(SHARED_OUTDIR)/libmemenv.a
else
# Update db.h if you change these.
SHARED_VERSION_MAJOR = 1
SHARED_VERSION_MINOR = 20
SHARED_LIB1 = libleveldb.$(PLATFORM_SHARED_EXT)
SHARED_LIB2 = $(SHARED_LIB1).$(SHARED_VERSION_MAJOR)
SHARED_LIB3 = $(SHARED_LIB1).$(SHARED_VERSION_MAJOR).$(SHARED_VERSION_MINOR)
SHARED_LIBS = $(SHARED_OUTDIR)/$(SHARED_LIB1) $(SHARED_OUTDIR)/$(SHARED_LIB2) $(SHARED_OUTDIR)/$(SHARED_LIB3)
$(SHARED_OUTDIR)/$(SHARED_LIB1): $(SHARED_OUTDIR)/$(SHARED_LIB3)
	ln -fs $(SHARED_LIB3) $(SHARED_OUTDIR)/$(SHARED_LIB1)
$(SHARED_OUTDIR)/$(SHARED_LIB2): $(SHARED_OUTDIR)/$(SHARED_LIB3)
	ln -fs $(SHARED_LIB3) $(SHARED_OUTDIR)/$(SHARED_LIB2)
SHARED_MEMENVLIB = $(SHARED_OUTDIR)/libmemenv.a
endif

$(SHARED_OUTDIR)/$(SHARED_LIB3): $(SHARED_LIBOBJECTS)
	$(CXX) $(LDFLAGS) $(PLATFORM_SHARED_LDFLAGS)$(SHARED_LIB2) $(SHARED_LIBOBJECTS) -o $(SHARED_OUTDIR)/$(SHARED_LIB3) $(LIBS)

endif  # PLATFORM_SHARED_EXT

all: $(SHARED_LIBS) $(SHARED_PROGRAMS) $(STATIC_OUTDIR)/libleveldb.a $(STATIC_OUTDIR)/libmemenv.a $(STATIC_PROGRAMS)

check: $(STATIC_PROGRAMS)
	for t in $(notdir $(TESTS)); do echo "***** Running $$t"; $(STATIC_OUTDIR)/$$t || exit 1; done

clean:
	-rm -rf out-static out-shared out-ios-x86 out-ios-arm out-ios-universal
	-rm -f build_config.mk
	-rm -rf ios-x86 ios-arm

$(STATIC_OUTDIR):
	mkdir $@

$(STATIC_OUTDIR)/db: | $(STATIC_OUTDIR)
	mkdir $@

$(STATIC_OUTDIR)/helpers/memenv: | $(STATIC_OUTDIR)
	mkdir -p $@

$(STATIC_OUTDIR)/port: | $(STATIC_OUTDIR)
	mkdir $@

$(STATIC_OUTDIR)/table: | $(STATIC_OUTDIR)
	mkdir $@

$(STATIC_OUTDIR)/util: | $(STATIC_OUTDIR)
	mkdir $@

.PHONY: STATIC_OBJDIRS
STATIC_OBJDIRS: \
	$(STATIC_OUTDIR)/db \
	$(STATIC_OUTDIR)/port \
	$(STATIC_OUTDIR)/table \
	$(STATIC_OUTDIR)/util \
	$(STATIC_OUTDIR)/helpers/memenv

$(SHARED_OUTDIR):
	mkdir $@

$(SHARED_OUTDIR)/db: | $(SHARED_OUTDIR)
	mkdir $@

$(SHARED_OUTDIR)/helpers/memenv: | $(SHARED_OUTDIR)
	mkdir -p $@

$(SHARED_OUTDIR)/port: | $(SHARED_OUTDIR)
	mkdir $@

$(SHARED_OUTDIR)/table: | $(SHARED_OUTDIR)
	mkdir $@

$(SHARED_OUTDIR)/util: | $(SHARED_OUTDIR)
	mkdir $@

.PHONY: SHARED_OBJDIRS
SHARED_OBJDIRS: \
	$(SHARED_OUTDIR)/db \
	$(SHARED_OUTDIR)/port \
	$(SHARED_OUTDIR)/table \
	$(SHARED_OUTDIR)/util \
	$(SHARED_OUTDIR)/helpers/memenv

$(DEVICE_OUTDIR):
	mkdir $@

$(DEVICE_OUTDIR)/db: | $(DEVICE_OUTDIR)
	mkdir $@

$(DEVICE_OUTDIR)/helpers/memenv: | $(DEVICE_OUTDIR)
	mkdir -p $@

$(DEVICE_OUTDIR)/port: | $(DEVICE_OUTDIR)
	mkdir $@

$(DEVICE_OUTDIR)/table: | $(DEVICE_OUTDIR)
	mkdir $@

$(DEVICE_OUTDIR)/util: | $(DEVICE_OUTDIR)
	mkdir $@

.PHONY: DEVICE_OBJDIRS
DEVICE_OBJDIRS: \
	$(DEVICE_OUTDIR)/db \
	$(DEVICE_OUTDIR)/port \
	$(DEVICE_OUTDIR)/table \
	$(DEVICE_OUTDIR)/util \
	$(DEVICE_OUTDIR)/helpers/memenv

$(SIMULATOR_OUTDIR):
	mkdir $@

$(SIMULATOR_OUTDIR)/db: | $(SIMULATOR_OUTDIR)
	mkdir $@

$(SIMULATOR_OUTDIR)/helpers/memenv: | $(SIMULATOR_OUTDIR)
	mkdir -p $@

$(SIMULATOR_OUTDIR)/port: | $(SIMULATOR_OUTDIR)
	mkdir $@

$(SIMULATOR_OUTDIR)/table: | $(SIMULATOR_OUTDIR)
	mkdir $@

$(SIMULATOR_OUTDIR)/util: | $(SIMULATOR_OUTDIR)
	mkdir $@

.PHONY: SIMULATOR_OBJDIRS
SIMULATOR_OBJDIRS: \
	$(SIMULATOR_OUTDIR)/db \
	$(SIMULATOR_OUTDIR)/port \
	$(SIMULATOR_OUTDIR)/table \
	$(SIMULATOR_OUTDIR)/util \
	$(SIMULATOR_OUTDIR)/helpers/memenv

$(STATIC_ALLOBJS): | STATIC_OBJDIRS
$(DEVICE_ALLOBJS): | DEVICE_OBJDIRS
$(SIMULATOR_ALLOBJS): | SIMULATOR_OBJDIRS
$(SHARED_ALLOBJS): | SHARED_OBJDIRS

ifeq ($(PLATFORM), IOS)
$(DEVICE_OUTDIR)/libleveldb.a: $(DEVICE_LIBOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(DEVICE_LIBOBJECTS)

$(SIMULATOR_OUTDIR)/libleveldb.a: $(SIMULATOR_LIBOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(SIMULATOR_LIBOBJECTS)

$(DEVICE_OUTDIR)/libmemenv.a: $(DEVICE_MEMENVOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(DEVICE_MEMENVOBJECTS)

$(SIMULATOR_OUTDIR)/libmemenv.a: $(SIMULATOR_MEMENVOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(SIMULATOR_MEMENVOBJECTS)

# For iOS, create universal object libraries to be used on both the simulator and
# a device.
$(STATIC_OUTDIR)/libleveldb.a: $(STATIC_OUTDIR) $(DEVICE_OUTDIR)/libleveldb.a $(SIMULATOR_OUTDIR)/libleveldb.a
	lipo -create $(DEVICE_OUTDIR)/libleveldb.a $(SIMULATOR_OUTDIR)/libleveldb.a -output $@

$(STATIC_OUTDIR)/libmemenv.a: $(STATIC_OUTDIR) $(DEVICE_OUTDIR)/libmemenv.a $(SIMULATOR_OUTDIR)/libmemenv.a
	lipo -create $(DEVICE_OUTDIR)/libmemenv.a $(SIMULATOR_OUTDIR)/libmemenv.a -output $@
else
$(STATIC_OUTDIR)/libleveldb.a:$(STATIC_LIBOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(STATIC_LIBOBJECTS)

$(STATIC_OUTDIR)/libmemenv.a:$(STATIC_MEMENVOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(STATIC_MEMENVOBJECTS)
endif

$(SHARED_MEMENVLIB):$(SHARED_MEMENVOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(SHARED_MEMENVOBJECTS)

$(STATIC_OUTDIR)/db_bench:db/db_bench.cc $(STATIC_LIBOBJECTS) $(TESTUTIL)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/db_bench.cc $(STATIC_LIBOBJECTS) $(TESTUTIL) -o $@ $(LIBS)

$(STATIC_OUTDIR)/db_bench_sqlite3:doc/bench/db_bench_sqlite3.cc $(STATIC_LIBOBJECTS) $(TESTUTIL)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) doc/bench/db_bench_sqlite3.cc $(STATIC_LIBOBJECTS) $(TESTUTIL) -o $@ -lsqlite3 $(LIBS)

$(STATIC_OUTDIR)/db_bench_tree_db:doc/bench/db_bench_tree_db.cc $(STATIC_LIBOBJECTS) $(TESTUTIL)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) doc/bench/db_bench_tree_db.cc $(STATIC_LIBOBJECTS) $(TESTUTIL) -o $@ -lkyotocabinet $(LIBS)

$(STATIC_OUTDIR)/leveldbutil:db/leveldbutil.cc $(STATIC_LIBOBJECTS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/leveldbutil.cc $(STATIC_LIBOBJECTS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/my_program:db/my_program.cc $(STATIC_LIBOBJECTS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/my_program.cc $(STATIC_LIBOBJECTS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/arena_test:util/arena_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/arena_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/autocompact_test:db/autocompact_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/autocompact_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/bloom_test:util/bloom_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/bloom_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/c_test:$(STATIC_OUTDIR)/db/c_test.o $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(STATIC_OUTDIR)/db/c_test.o $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/cache_test:util/cache_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/cache_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/coding_test:util/coding_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/coding_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/corruption_test:db/corruption_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/corruption_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/crc32c_test:util/crc32c_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/crc32c_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/db_test:db/db_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/db_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/dbformat_test:db/dbformat_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/dbformat_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/env_posix_test:util/env_posix_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/env_posix_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/env_test:util/env_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/env_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/fault_injection_test:db/fault_injection_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/fault_injection_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/filename_test:db/filename_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/filename_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/filter_block_test:table/filter_block_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) table/filter_block_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/hash_test:util/hash_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) util/hash_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/issue178_test:issues/issue178_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) issues/issue178_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/issue200_test:issues/issue200_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) issues/issue200_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/log_test:db/log_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/log_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/recovery_test:db/recovery_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/recovery_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/table_test:table/table_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) table/table_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/skiplist_test:db/skiplist_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/skiplist_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/version_edit_test:db/version_edit_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/version_edit_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/version_set_test:db/version_set_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/version_set_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/write_batch_test:db/write_batch_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) db/write_batch_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/memenv_test:$(STATIC_OUTDIR)/helpers/memenv/memenv_test.o $(STATIC_OUTDIR)/libmemenv.a $(STATIC_OUTDIR)/libleveldb.a $(TESTHARNESS)
	$(XCRUN) $(CXX) $(LDFLAGS) $(STATIC_OUTDIR)/helpers/memenv/memenv_test.o $(STATIC_OUTDIR)/libmemenv.a $(STATIC_OUTDIR)/libleveldb.a $(TESTHARNESS) -o $@ $(LIBS)

$(SHARED_OUTDIR)/db_bench:$(SHARED_OUTDIR)/db/db_bench.o $(SHARED_LIBS) $(TESTUTIL) $(TEST_STATIC_OBJS)
	$(XCRUN) $(CXX) $(LDFLAGS) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) $(SHARED_CXXFLAGS) $(SHARED_OUTDIR)/db/db_bench.o $(TESTUTIL) $(TEST_STATIC_OBJS) $(SHARED_OUTDIR)/$(SHARED_LIB3) -o $@ $(LIBS)

$(SHARED_OUTDIR)/c_test:$(SHARED_OUTDIR)/db/c_test.o $(SHARED_LIBS) $(TESTUTIL) $(TEST_STATIC_OBJS)
	$(XCRUN) $(CXX) $(LDFLAGS) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) $(SHARED_CXXFLAGS) $(SHARED_OUTDIR)/db/c_test.o $(TESTUTIL) $(TEST_STATIC_OBJS) $(SHARED_OUTDIR)/$(SHARED_LIB3) -o $@ $(LIBS)

.PHONY: run-shared-db_bench
run-shared-db_bench: $(SHARED_OUTDIR)/db_bench
	LD_LIBRARY_PATH=$(SHARED_OUTDIR) $(SHARED_OUTDIR)/db_bench

.PHONY: run-shared-c_test
run-shared-c_test: $(SHARED_OUTDIR)/c_test
	LD_LIBRARY_PATH=$(SHARED_OUTDIR) $(SHARED_OUTDIR)/c_test

$(SIMULATOR_OUTDIR)/%.o: %.cc
	xcrun -sdk iphonesimulator $(CXX) $(CXXFLAGS) $(SIMULATOR_CFLAGS) -c $< -o $@

$(DEVICE_OUTDIR)/%.o: %.cc
	xcrun -sdk iphoneos $(CXX) $(CXXFLAGS) $(DEVICE_CFLAGS) -c $< -o $@

$(SIMULATOR_OUTDIR)/%.o: %.c
	xcrun -sdk iphonesimulator $(CC) $(CFLAGS) $(SIMULATOR_CFLAGS) -c $< -o $@

$(DEVICE_OUTDIR)/%.o: %.c
	xcrun -sdk iphoneos $(CC) $(CFLAGS) $(DEVICE_CFLAGS) -c $< -o $@

$(STATIC_OUTDIR)/%.o: %.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(STATIC_OUTDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(SHARED_OUTDIR)/%.o: %.cc
	$(CXX) $(CXXFLAGS) $(SHARED_BUILD_CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) -c $< -o $@

$(SHARED_OUTDIR)/%.o: %.c
	$(CC) $(CFLAGS) $(SHARED_BUILD_CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) -c $< -o $@
