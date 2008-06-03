include ../common.make
include $(GNUSTEP_MAKEFILES)/common.make
include ../Version
include ../common.make

NATIVE_LIBRARY_NAME=Trading
TOOL_NAME=createTradingDB

Trading_RESOURCE_FILES=Trading.eomodeld
Trading_HAS_RESOURCE_BUNDLE=yes

Trading_OBJC_FILES=Trading.m TradingData.m
Trading_HEADER_FILES=Trading.h TradingData.h

createTradingDB_OBJC_FILES=create.m

ADDITIONAL_INCLUDE_DIRS+=-I..

ADDITIONAL_NATIVE_LIBS+=EOAccess EOControl Trading
ADDITIONAL_NATIVE_LIB_DIRS+=../EOAccess ../EOControl ../Trading

include $(GNUSTEP_MAKEFILES)/native-library.make
include $(GNUSTEP_MAKEFILES)/tool.make
