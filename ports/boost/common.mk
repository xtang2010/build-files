ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

NAME=boost
QNX_PROJECT_ROOT ?= $(shell readlink -f $(PROJECT_ROOT)/../../../$(NAME))

#choose release or debug
BOOST_VARIANT ?= release

#where to install Boost:
#$(INSTALL_ROOT_$(OS)) is pointing to $QNX_TARGET
#by default, unless it was manually re-routed to
#a staging area by setting both INSTALL_ROOT_nto
#and USE_INSTALL_ROOT
BOOST_INSTALL_ROOT ?= $(shell readlink -f $(QNX_PROJECT_ROOT)/../stage)

#A prefix path to use **on the target**. This is
#different from INSTALL_ROOT, which refers to a
#installation destination **on the host machine**.
#This prefix path may be exposed to the source code,
#the linker, or package discovery config files (.pc,
#CMake config modules, etc.). Default is /usr/local
PREFIX ?= /usr/local

BOOST_CPP_VERSION_FLAG ?= -std=c++11

ifneq ($(wildcard $(QNX_TARGET)/usr/include/python3.11),)
	PYTHON_VERSION = 3.11
	PYTHON_USER_CONFIG=user-config-python311.jam
else
	PYTHON_VERSION = 3.8
	PYTHON_USER_CONFIG=user-config-python38.jam
endif

#B2_MODULES = --without-mpi --without-graph_parallel
B2_EXTRA_OPTS ?=

# list of flags passed to the b2 command which are shared by all target architectures
B2_OPTIONS = -q -d2 \
             ${B2_MODULES} \
             --build-type=minimal target-os=qnxnto toolset=qcc \
             --prefix=$(BOOST_INSTALL_ROOT)/$(PREFIX) --includedir=$(BOOST_INSTALL_ROOT)/$(PREFIX)/include \
             --libdir=$(BOOST_INSTALL_ROOT)/$(CPUVARDIR)/$(PREFIX)/lib \
             --user-config=$(PROJECT_ROOT)/$(PYTHON_USER_CONFIG) \
             runtime-link=shared link=shared variant=$(BOOST_VARIANT) define=BOOST_SYSTEM_NO_DEPRECATED \
             ${B2_EXTRA_OPTS}

FLAGS   += -g
LDFLAGS += -Wl,--build-id=md5 -lang-c++ -lsocket

FLAGS   +=  $(BOOST_CPP_VERSION_FLAG) -D_QNX_SOURCE -Vgcc_nto$(CCVER) -Wno-ignored-attributes -I$(PROJECT_ROOT)/libs/predef/include/boost/predef/other
# not sure who need this
#FLAGS   +=  -DBOOST_NO_CXX98_FUNCTION_BASE 
# libs/graph need this otherwise will fail
FLAGS   +=  -DBOOST_NO_CXX17_HDR_MEMORY_RESOURCE 
# libs/process will use SA_RESTART will QNX do not support
FLAGS   +=  -DSA_RESTART=0
LDFLAGS += -Vgcc_nto$(CCVER)

#override 'all' target to bypass the default QNX build system
ALL_DEPENDENCIES = $(NAME)_all

include $(MKFILES_ROOT)/qtargets.mk

ifndef NO_TARGET_OVERRIDE

BUILD_DIR = $(PWD)/build

$(QNX_PROJECT_ROOT)/b2:
	$(CP_HOST) $(PROJECT_ROOT)/$(PYTHON_USER_CONFIG) $(QNX_PROJECT_ROOT)/user-config.jam
	cd $(QNX_PROJECT_ROOT) && ./bootstrap.sh --with-python-version=$(PYTHON_VERSION)

B2_CMD = export CPUVARDIR=$(CPUVARDIR) && \
		export CCVER=$(CCVER) && \
		cd $(QNX_PROJECT_ROOT) && ./b2 $(B2_OPTIONS) --build-dir=$(BUILD_DIR) cflags="$(FLAGS)" linkflags="$(LDFLAGS)"

B2_CMD_TEST = export CPUVARDIR=$(CPUVARDIR) && \
		export CCVER=$(CCVER) && \
		$(QNX_PROJECT_ROOT)/b2 $(B2_OPTIONS) --build-dir=$(BUILD_DIR) cflags="$(FLAGS)" linkflags="$(LDFLAGS)"

$(NAME)_all: $(QNX_PROJECT_ROOT)/b2
	@mkdir -p build
	$(B2_CMD) install
	$(ADD_USAGE_TO_LIBS)

TARGET_INSTALL=
EXTRA_ICLEAN=-rf build

test.%: $(QNX_PROJECT_ROOT)/b2
	cd $(QNX_PROJECT_ROOT)/libs/$(subst test.,,$@)/test && \
	$(B2_CMD_TEST) testing.execute=off

endif
