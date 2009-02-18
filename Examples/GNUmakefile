include ../common.make
include $(GNUSTEP_MAKEFILES)/common.make
include $(GNUSTEP_MAKEFILES)/Auxiliary/gdl2.make

SUBPROJECTS = Trading

ADDITIONAL_NATIVE_LIBS=EOAccess EOControl

# This is strictly for integration into the gdl2 build system
# If you are basing a gdl2 application off of these examples
# you won't need the following line in your GNUmakefiles.
ADDITIONAL_NATIVE_LIB_DIRS=../EOAccess ../EOControl

include GNUmakefile.eoexample
include GNUmakefile.connection
include GNUmakefile.eoexample2

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/tool.make
