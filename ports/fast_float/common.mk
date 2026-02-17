ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

include $(MKFILES_ROOT)/qmacros.mk

NAME=fast_float
QNX_PROJECT_ROOT ?= $(shell readlink -f $(PROJECT_ROOT)/../../../$(NAME))

#install into stage
QNX_BASE:=$(shell readlink -f $(QNX_HOST)/../../../)
INSTALL_ROOT_nto = /usr/local/stage
$(NAME)_INSTALL_ROOT ?= $(INSTALL_ROOT_nto)/$(NAME)/$(notdir $(QNX_BASE))

PREFIX ?= /usr/local

#choose Release or Debug
CMAKE_BUILD_TYPE ?= RelWithDebInfo

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(NAME)_all install clean

include $(MKFILES_ROOT)/qtargets.mk

#CMake env
CMAKE_FIND_ROOT_PATH := $(QNX_TARGET);$(QNX_TARGET)/$(CPUVARDIR);$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)
CMAKE_MODULE_PATH := $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/cmake;$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/lib/cmake

CFLAGS += $(FLAGS) -I$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/include \
                   -D_QNX_SOURCE

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPU) \
             -DCMAKE_INSTALL_PREFIX=$($(NAME)_INSTALL_ROOT)/$(PREFIX) \
             -DCMAKE_INSTALL_LIBDIR=$($(NAME)_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib \
             -DCMAKE_INSTALL_BINDIR=$($(NAME)_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/bin \
             -DCMAKE_FIND_ROOT_PATH="$(CMAKE_FIND_ROOT_PATH)" \
             -DCMAKE_MODULE_PATH="$(CMAKE_MODULE_PATH)" \
             -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
             -DEXTRA_CMAKE_C_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_CXX_FLAGS="$(CFLAGS)" \
             -DEXTRA_CMAKE_LINKER_FLAGS="$(LDFLAGS)" \
             $(CMAKE_MODULE_EXTRA)

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 4)

$(NAME)_all: 
	@mkdir -p build
	cd build && cmake $(CMAKE_ARGS) $(QNX_PROJECT_ROOT) 
	cd build && make all $(MAKE_ARGS)

TARGET_INSTALL=@cd build && make VERBOSE=1 install $(MAKE_ARGS)
EXTRA_ICLEAN=-rf build
