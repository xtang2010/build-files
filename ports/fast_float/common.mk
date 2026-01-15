ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

include $(MKFILES_ROOT)/qmacros.mk

NAME=fast_float
QNX_PROJECT_ROOT ?= $(shell readlink -f $(PROJECT_ROOT)/../../../$(NAME))

#install into stage
INSTALL_ROOT_nto = $(shell readlink -f $(QNX_PROJECT_ROOT)/../stage)
FASTFLOAT_INSTALL_ROOT ?= $(INSTALL_ROOT_$(OS))/../stage_$(NAME)

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
#CMAKE_MODULE_EXTRA := -DDOUBLE_CONVERSION_INCLUDE_DIR=$(INSTALL_ROOT_$(OS))/$(PREFIX)/include \
                      -DDOUBLE_CONVERSION_LIBRARY=$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)$(PREFIX)/lib/

CFLAGS += $(FLAGS) -I$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/include \
                   -D_QNX_SOURCE
#LDFLAGS += -lgomp -lsocket -lc++

CMAKE_ARGS = -DCMAKE_TOOLCHAIN_FILE=$(PROJECT_ROOT)/qnx.nto.toolchain.cmake \
             -DCMAKE_SYSTEM_PROCESSOR=$(CPUVARDIR) \
             -DCPU=${CPU} \
             -DCMAKE_INSTALL_PREFIX=$(FASTFLOAT_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX) \
             -DCMAKE_INSTALL_INCLUDEDIR=$(FASTFLOAT_INSTALL_ROOT)/$(PREFIX)/include \
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
