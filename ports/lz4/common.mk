ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

NAME=lz4

QNX_PROJECT_ROOT ?= $(PRODUCT_ROOT)/../../$(NAME)

#install into stage
QNX_BASE:=$(notdir $(shell readlink -f $(QNX_HOST)/../../../))
INSTALL_ROOT_nto = /usr/local/stage/$(QNX_BASE)
$(NAME)_INSTALL_ROOT = /usr/local/stage/$(NAME)

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

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(NAME)_all install clean

include $(MKFILES_ROOT)/qtargets.mk

#Headers from INSTALL_ROOT need to be made available by default
#because CMake and pkg-config do not necessary add it automatically
#if the include path is "default"
CFLAGS += -I$(INSTALL_ROOT)/$(PREFIX)/include
#LDFLAGS += -lsocket

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_INSTALL_PREFIX=$(INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX) \
             -DCMAKE_INSTALL_INCLUDEDIR=$(INSTALL_ROOT)/$(PREFIX)/include \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
             -DCMAKE_C_COMPILER_TARGET=gcc_nto$(CPUVARDIR) \
             -DCMAKE_CXX_COMPILER_TARGET=gcc_nto$(CPUVARDIR) \
             -DEXTRA_CMAKE_C_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_CXX_FLAGS="$(CXXFLAGS)" \
             -DEXTRA_CMAKE_ASM_FLAGS="$(FLAGS)" \
             -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
             -DEVENT__DISABLE_OPENSSL=ON \
	     -DEVENT__HAVE_SIGACTION=OFF

MAKE_ARGS = -j4 DESTDIR=$($(NAME)_INSTALL_ROOT)

$(NAME)_all:
	@mkdir -p build_$(QNX_BASE)
	@cd build_$(QNX_BASE) && cmake $(CMAKE_ARGS) $(QNX_PROJECT_ROOT)/build/cmake
	@cd build_$(QNX_BASE) && make VERBOSE=1 all $(MAKE_ARGS)

TARGET_INSTALL=@cd build_$(QNX_BASE) && make VERBOSE=1 install $(MAKE_ARGS)
EXTRA_ICLEAN=-rf build_$(QNX_BASE) 

clean_all:
	@rm -rf $($(NAME)_INSTALL_ROOT) build_*
	
