ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

NAME=zstd

QNX_PROJECT_ROOT ?= $(PRODUCT_ROOT)/../../$(NAME)

#install into stage
QNX_BASE:=$(notdir $(shell readlink -f $(QNX_HOST)/../../../))
#INSTALL_ROOT_nto:=/usr/local/stage/$(QNX_BASE)
$(NAME)_INSTALL_ROOT=/usr/local/stage/$(NAME)

#$(INSTALL_ROOT_$(OS)) is pointing to $QNX_TARGET
#by default, unless it was manually re-routed to
#a staging area by setting both INSTALL_ROOT_nto
#and USE_INSTALL_ROOT
INSTALL_ROOT ?= $(INSTALL_ROOT_$(OS))

#A prefix path to use **on the target**. This is
#different from INSTALL_ROOT, which refers to a
#installation destination **on the host machine**.
#This prefix path may be exposed to the source code,
#the linker, or package discovery config files (.pc,
#CMake config modules, etc.). Default is /usr/local
PREFIX ?= /usr/local

BUILD_TESTING ?= OFF

#choose Release or Debug
CMAKE_BUILD_TYPE ?= Release

ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(NAME)_all install clean

CFLAGS += $(FLAGS)

#Define _QNX_SOURCE for LLVM libc++ on QNX 7
CFLAGS += -D_QNX_SOURCE -O3 -fPIC
LDFLAGS += -Wl,--build-id=md5

include $(MKFILES_ROOT)/qtargets.mk

BUILD_TESTING ?= OFF

#Search paths for all of CMake's find_* functions --
#headers, libraries, etc.
#
#$(QNX_TARGET): for architecture-agnostic files shipped with SDP (e.g. headers)
#$(QNX_TARGET)/$(CPUVARDIR): for architecture-specific files in SDP
#$(INSTALL_ROOT)/$(CPUVARDIR): any packages that may have been installed in the staging area
CMAKE_FIND_ROOT_PATH := $(QNX_TARGET);$(QNX_TARGET)/$(CPUVARDIR);$(INSTALL_ROOT)/$(CPUVARDIR)

#Path to CMake modules; These are CMake files installed by other packages
#for downstreams to discover them automatically. We support discovering
#CMake-based packages from inside SDP or in the staging area.
#Note that CMake modules can automatically detect the prefix they are
#installed in.
CMAKE_MODULE_PATH := $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/cmake;$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib/cmake

#Headers from INSTALL_ROOT need to be made available by default
#because CMake and pkg-config do not necessary add it automatically
#if the include path is "default"
CFLAGS += -I$(INSTALL_ROOT)/$(PREFIX)/include -I$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/include

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_SYSTEM_PROCESSOR_ENDIAN=$(CPUVARDIR) \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
	     -DCPU=$(CPU) \
             -DEXTRA_CMAKE_ASM_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_C_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_CXX_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
             -DCMAKE_CXX_COMPILER_TARGET=gcc_nto$(CPUVARDIR) \
             -DCMAKE_C_COMPILER_TARGET=gcc_nto$(CPUVARDIR) \
             -DCMAKE_INSTALL_PREFIX="$(INSTALL_ROOT)/$(PREFIX)" \
             -DCMAKE_INSTALL_LIBDIR="$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib" \
             -DCMAKE_MODULE_PATH="$(CMAKE_MODULE_PATH)" \
             -DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE)

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 1) DESTDIR=$($(NAME)_INSTALL_ROOT)
BUILDDIR ?= build_$(QNX_BASE)

$(NAME)_all:
	@mkdir -p $(BUILDDIR)
	@cd $(BUILDDIR) && cmake $(CMAKE_ARGS) $(QNX_PROJECT_ROOT)/build/cmake
	@cd $(BUILDDIR) && make VERBOSE=1 all $(MAKE_ARGS)

TARGET_INSTALL=@cd $(BUILDDIR) && make VERBOSE=1 install $(MAKE_ARGS)
EXTRA_ICLEAN=-rf $(BUILDDIR) 

clean_all:
	rm -rf $($(NAME)_INSTALL_ROOT) build_*
