include $(GNUSTEP_MAKEFILES)/common.make
include ../gdl2.make

PALETTE_NAME=GDL2
GDL2_PRINCIPAL_CLASS = GDL2Palette

SUBPROJECTS+=../EOModeler ../EOInterface
include $(GNUSTEP_MAKEFILES)/aggregate.make

ADDITIONAL_LIB_DIRS+=-L../EOAccess/$(GNUSTEP_OBJ_DIR) \
	-L../EOControl/$(GNUSTEP_OBJ_DIR)

ifeq ($(FOUNDATION_LIB),apple)
  ADDITIONAL_INCLUDE_DIRS+=-F../EOModeler -F../EOInterface
  ADDITIONAL_LIB_DIRS+=-F../EOModeler -F../EOInterface
  PALETTE_LIBS +=-framework gnustep-db2modeler -framework EOInterface
else
  ADDITIONAL_INCLUDE_DIRS+=-I../
  ADDITIONAL_LIB_DIRS+=-L../EOModeler/$(GNUSTEP_OBJ_DIR) \
-L../EOInterface/$(GNUSTEP_OBJ_DIR)
  PALETTE_LIBS+=-lgnustep-db2modeler -lEOInterface
endif


PALETTE_LIBS+=$(AUXILIARY_TOOL_LIBS)

GDL2_RESOURCE_FILES=GDL2Palette.tiff GDL2ConnectionInspector.gorm palette.table

GDL2_OBJC_FILES=		\
	Palette.m		\
	ResourceManager.m	\
	ConnectionInspector.m	\
	IB+Categories.m		\
	Foundation+Categories.m \
	KeyWrapper.m


include $(GNUSTEP_MAKEFILES)/palette.make
