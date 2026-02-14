ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

NAME=glog

QNX_PROJECT_ROOT=$(PRODUCT_ROOT)/../../$(NAME)
#install into stage
QNX_BASE:=$(notdir $(shell readlink -f $(QNX_HOST)/../../../))
INSTALL_ROOT_nto = /usr/local/stage/$(QNX_BASE)

PREFIX ?= usr/local

#$(INSTALL_ROOT_$(OS)) is pointing to $QNX_TARGET
#by default, unless it was manually re-routed to
#a staging area by setting both INSTALL_ROOT_nto
#and USE_INSTALL_ROOT
INSTALL_ROOT ?= $(INSTALL_ROOT_$(OS))

#choose Release or Debug
CMAKE_BUILD_TYPE ?= Debug

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(NAME)_all install check clean test

CFLAGS += $(FLAGS)

include $(MKFILES_ROOT)/qtargets.mk

CFLAGS += -I$(INSTALL_ROOT)/$(PREFIX)/include

BUILD_TESTING ?= OFF

#Search paths for all of CMake's find_* functions --
#headers, libraries, etc.
#
#$(QNX_TARGET): for architecture-agnostic files shipped with SDP (e.g. headers)
#$(QNX_TARGET)/$(CPUVARDIR): for architecture-specific files in SDP
#$(INSTALL_ROOT)/$(CPUVARDIR): any packages that may have been installed in the staging area
CMAKE_FIND_ROOT_PATH := $(QNX_TARGET);$(QNX_TARGET)/$(CPUVARDIR);$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)

#Path to CMake modules; These are CMake files installed by other packages
#for downstreams to discover them automatically. We support discovering
#CMake-based packages from inside SDP or in the staging area.
#Note that CMake modules can automatically detect the prefix they are
#installed in.
CMAKE_MODULE_PATH := $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/cmake;$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/lib/cmake

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_INSTALL_PREFIX="$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)" \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
             -DEXTRA_CMAKE_C_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_CXX_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_ASM_FLAGS="$(FLAGS)" \
             -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
             -DCMAKE_DEBUG_POSTFIX="" \
             -Dgflags_DIR=$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib/cmake/gflags \
             -DGTest_DIR=$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib/cmake/GTest \
             -DBUILD_TESTING=$(BUILD_TESTING)

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 1)

ifndef NO_TARGET_OVERRIDE
$(NAME)_all:
	@mkdir -p build
	@cd build && cmake $(CMAKE_ARGS) $(QNX_PROJECT_ROOT)
	@cd build && make VERBOSE=1 all $(MAKE_ARGS)

install check: $(NAME)_all
	@echo Installing...
	@cd build && make VERBOSE=1 install $(MAKE_ARGS)
	@cp ../run_tests.sh $(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/bin/$(NAME)_tests
	@echo Done

clean iclean spotless:
	rm -fr build

uninstall:
endif
