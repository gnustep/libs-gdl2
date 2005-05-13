include $(GNUSTEP_MAKEFILES)/common.make
include $(GNUSTEP_MAKEFILES)/Auxiliary/gdl2.make

PALETTE_NAME=GDL2
GDL2_PRINCIPAL_CLASS = GDL2Palette

ifeq ($(FOUNDATION_LIB),apple)
  ADDITIONAL_INCLUDE_DIRS += -F../EOModeler -F../EOInterface
  ADDITIONAL_LIB_DIRS += -F../EOModeler -F../EOInterface
else
  ADDITIONAL_INCLUDE_DIRS += -I../
  ADDITIONAL_LIB_DIRS += -L../EOModeler -L../EOInterface
endif

ADDITIONAL_NATIVE_LIBS+=EOModeler EOInterface
LDFLAGS+=-framework gnustep-db2modeler -framework EOInterface


ADDITIONAL_LIB_DIRS=			\
-L../EOAccess/$(GNUSTEP_OBJ_DIR)	\
-L../EOControl/$(GNUSTEP_OBJ_DIR)

ADDITIONAL_LDFLAGS+=-lgnustep-db2control -lgnustep-db2

GDL2_RESOURCE_FILES=GDL2Palette.tiff GDL2ConnectionInspector.gorm palette.table

GDL2_OBJC_FILES=		\
	Palette.m		\
	ResourceManager.m	\
	ConnectionInspector.m	\
	IB+Categories.m		\
	Foundation+Categories.m

include $(GNUSTEP_MAKEFILES)/palette.make
