# (C)2004-2013 AMX Mod X Development Team
# Makefile written by David "BAILOPAN" Anderson

###########################################
### EDIT THESE PATHS FOR YOUR OWN SETUP ###
###########################################

HLSDK   = ../amxmodx/hlsdk-bu
MM_ROOT = ../amxmodx/metamod-bu/metamod

#####################################
### EDIT BELOW FOR OTHER PROJECTS ###
#####################################

PROJECT = orpheu

OBJECTS = public/sdk/amxxmodule.cpp orpheu.cpp memoryUtil.cpp memoryStructureManager.cpp functionStructuresManager.cpp functionVirtualManager.cpp functionManager.cpp function.cpp filesManager.cpp hooker.cpp jansson/dump.c jansson/error.c jansson/hashtable.c jansson/hashtable_seed.c jansson/load.c jansson/memory.c jansson/pack_unpack.c jansson/strbuffer.c jansson/strconv.c jansson/utf.c jansson/value.c global.cpp librariesManager.cpp typeHandlerManager.cpp configManager.cpp structHandler.cpp typeHandlerImplementations/boolHandler.cpp typeHandlerImplementations/byteHandler.cpp typeHandlerImplementations/longHandler.cpp typeHandlerImplementations/CBaseEntityHandler.cpp typeHandlerImplementations/charPtrHandler.cpp typeHandlerImplementations/edict_sPtrHandler.cpp typeHandlerImplementations/floatHandler.cpp typeHandlerImplementations/VectorHandler.cpp typeHandlerImplementations/CMBaseMonsterHandler.cpp typeHandlerImplementations/entvarHandler.cpp typeHandlerImplementations/short.cpp typeHandlerImplementations/charArrHandler.cpp typeHandlerImplementations/VectorPointerHandler.cpp typeHandlerImplementations/charHandler.cpp


##############################################
### CONFIGURE ANY OTHER FLAGS/OPTIONS HERE ###
##############################################

C_OPT_FLAGS     = -DNDEBUG -O2 -fomit-frame-pointer -pipe -mmmx -msse -msse2 -march=i686 -mtune=generic
C_DEBUG_FLAGS   = -D_DEBUG -DDEBUG -g -ggdb3
C_GCC4_FLAGS    = -fvisibility=hidden
CPP_GCC4_FLAGS  = -fvisibility-inlines-hidden
CPP             = gcc
CPP_OSX         = clang

LINK =

INCLUDE =   -I. -Isdk -Iincludes -Ijansson \
			-Ipublic -Ipublic/sdk -Ipublic/amtl \
			-I$(HLSDK) -I$(HLSDK)/public -I$(HLSDK)/common -I$(HLSDK)/dlls -I$(HLSDK)/engine -I$(HLSDK)/game_shared -I$(HLSDK)/pm_shared \
			-I$(MM_ROOT)

################################################
### DO NOT EDIT BELOW HERE FOR MOST PROJECTS ###
################################################

OS := "$(shell uname -s)"

ifeq "$(OS)" "Darwin"
	CPP = $(CPP_OSX)
	LIB_EXT = dylib
	LIB_SUFFIX = _amxx
	CFLAGS += -DOSX -D_OSX -DPOSIX
	LINK += -dynamiclib -lstdc++ -mmacosx-version-min=10.5 -arch=i386
else
	LIB_EXT = so
	LIB_SUFFIX = _amxx_i386
	CFLAGS += -DLINUX -D_LINUX -DPOSIX
	LINK += -shared
endif

LINK += -m32 -lm -ldl

CFLAGS += -DORPHEU_BUILD -DORPHEU_USE_VERSIONLIB -DPAWN_CELL_SIZE=32 -DJIT -DASM32 -DHAVE_STDINT_H -fno-strict-aliasing -m32 -Wall -Werror -Wno-uninitialized -Wno-unused -Wno-switch
CPPFLAGS += -Wno-invalid-offsetof -fno-exceptions -fno-rtti -std=c++11

BINARY = $(PROJECT)$(LIB_SUFFIX).$(LIB_EXT)

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS += $(C_DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS += $(C_OPT_FLAGS)
	LINK += -s
endif

IS_CLANG := $(shell $(CPP) --version | head -1 | grep clang > /dev/null && echo "1" || echo "0")

ifeq "$(IS_CLANG)" "1"
	CPP_MAJOR := $(shell $(CPP) --version | grep clang | sed "s/.*version \([0-9]\)*\.[0-9]*.*/\1/")
	CPP_MINOR := $(shell $(CPP) --version | grep clang | sed "s/.*version [0-9]*\.\([0-9]\)*.*/\1/")
else
	CPP_MAJOR := $(shell $(CPP) -dumpversion >&1 | cut -b1)
	CPP_MINOR := $(shell $(CPP) -dumpversion >&1 | cut -b3)
endif

# Clang || GCC >= 4
ifeq "$(shell expr $(IS_CLANG) \| $(CPP_MAJOR) \>= 4)" "1"
	CFLAGS += $(C_GCC4_FLAGS)
	CPPFLAGS += $(CPP_GCC4_FLAGS)
endif

ifeq "$(IS_CLANG)" "1"
	CFLAGS += -Wno-logical-op-parentheses
else
	CFLAGS += -Wno-parentheses
endif

# Clang >= 3 || GCC >= 4.7
ifeq "$(shell expr $(IS_CLANG) \& $(CPP_MAJOR) \>= 3 \| $(CPP_MAJOR) \>= 4 \& $(CPP_MINOR) \>= 7)" "1"
	CFLAGS += -Wno-delete-non-virtual-dtor
endif

# OS is Linux and not using clang
ifeq "$(shell expr $(OS) \= Linux \& $(IS_CLANG) \= 0)" "1"
	LINK += -static-libgcc
endif

# OS is Linux and using clang
ifeq "$(shell expr $(OS) \= Linux \& $(IS_CLANG) \= 1)" "1"
	LINK += -lgcc_eh
endif

OBJ_BIN := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)
OBJ_BIN := $(OBJ_BIN:%.c=$(BIN_DIR)/%.o)

# This will break if we include other Makefiles, but is fine for now. It allows
#  us to make a copy of this file that uses altered paths (ie. Makefile.mine)
#  or other changes without mucking up the original.
MAKEFILE_NAME := $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

$(BIN_DIR)/%.o: %.c
	$(CPP) $(INCLUDE) $(CFLAGS) -o $@ -c $<
    
all:
	mkdir -p $(BIN_DIR)
	mkdir -p $(BIN_DIR)/public/sdk
	mkdir -p $(BIN_DIR)/typeHandlerImplementations
	mkdir -p $(BIN_DIR)/jansson
	$(MAKE) -f $(MAKEFILE_NAME) $(PROJECT)

$(PROJECT): $(OBJ_BIN)
	$(CPP) $(INCLUDE) $(OBJ_BIN) $(LINK) -o $(BIN_DIR)/$(BINARY)

debug:
	$(MAKE) -f $(MAKEFILE_NAME) all DEBUG=true

default: all

clean:
	rm -rf $(BIN_DIR)/*.o
	rm -rf $(BIN_DIR)/public/sdk/*.o
	rm -rf $(BIN_DIR)/typeHandlerImplementations/*.o
	rm -rf $(BIN_DIR)/jansson/*.o
	rm -f $(BIN_DIR)/$(BINARY)
