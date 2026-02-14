ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

include $(MKFILES_ROOT)/qmacros.mk

NAME=libunwind
QNX_PROJECT_ROOT ?= $(shell readlink -f $(PROJECT_ROOT)/../../../$(NAME))

#install into stage
QNX_BASE:=$(notdir $(shell readlink -f $(QNX_HOST)/../../../))
INSTALL_ROOT_nto = /usr/local/stage/
$(NAME)_INSTALL_ROOT ?= $(INSTALL_ROOT_nto)/$(NAME)/$(QNX_BASE)

PREFIX ?= /usr/local

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = $(NAME)_all
.PHONY: $(NAME)_all install clean

CFLAGS += $(FLAGS) -I$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/include -D_QNX_SOURCE -O3 -fPIC 
CXXFLAGS += $(CFLAGS)
LDFLAGS += -Wl,--build-id=md5 

include $(MKFILES_ROOT)/qtargets.mk

#Setup pkg-config dir
#export PKG_CONFIG_PATH=
#PKG_CONFIG_LIBDIR_IN = $($(NAME)_INSTALL_DIR)/lib/pkgconfig:$($(NAME)_INSTALL_DIR)/share/pkgconfig
#PKG_CONFIG_TARGET_IN = $(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/lib/pkgconfig:$(QNX_TARGET)/$(CPUVARDIR)/$(PREFIX)/share/pkgconfig:$(INSTALL_ROOT_$(OS))/$(CPUVARDIR)/$(PREFIX)/lib/pkgconfig
#export PKG_CONFIG_LIBDIR = $(PKG_CONFIG_LIBDIR_IN):$(PKG_CONFIG_TARGET_IN)

#Config toolchain for qnx
CONFIGURE_CMD = $(QNX_PROJECT_ROOT)/configure 
CONFIGURE_ARGS = --host=$(CPU)-pc-$(OS) \
		 --prefix=$($(NAME)_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX) \
                 --srcdir=$(QNX_PROJECT_ROOT) \
		 --disable-tests
CONFIGURE_ENVS = CFLAGS="$(CFLAGS)" \
                 CXXFLAGS="$(CXXFLAGS)" \
                 LDFLAGS="$(LDFLAGS)" \
		 CC="qcc -Vgcc_$(OS)$(CPUVARDIR)" \
		 CXX="${QNX_HOST}/usr/bin/q++ -Vgcc_$(OS)$(CPUVARDIR)" \
		 AR="${QNX_HOST}/usr/bin/$(OS)$(CPU)-ar" \
		 AS="${QNX_HOST}/usr/bin/qcc -Vgcc_$(OS)$(CPUVARDIR)" \
                 RANDLIB="${QNX_HOST}/usr/bin/$(OS)$(CPU)-ranlib" 

CCCC:=$(CPU)
KKKK:=$(CPUVARDIR)

MAKE_ARGS ?= -j $(firstword $(JLEVEL) 4)

$(CONFIGURE_CMD):
	@cd $(QNX_PROJECT_ROOT) && autoreconf -i

build/config.status: $(CONFIGURE_CMD)
	@mkdir -p build
	@cd build && $(CONFIGURE_CMD) $(CONFIGURE_ARGS) $(CONFIGURE_ENVS)

$(NAME)_all: build/config.status
	@cd build && make $(MAKE_ARGS)

TARGET_INSTALL=@cd build && make install $(MAKE_ARGS)
EXTRA_ICLEAN=-rf build
