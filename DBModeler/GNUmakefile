include $(GNUSTEP_MAKEFILES)/common.make
include ../gdl2.make

SUBPROJECTS=../EOInterface ../EOModeler
include $(GNUSTEP_MAKEFILES)/aggregate.make

APP_NAME = DBModeler
DBModeler_SUBPROJECTS=Inspectors

ADDITIONAL_LIB_DIRS+=-L../EOAccess/$(GNUSTEP_OBJ_DIR)
ADDITIONAL_LIB_DIRS+=-L../EOControl/$(GNUSTEP_OBJ_DIR)

ifeq ($(FOUNDATION_LIB), apple)
ADDITIONAL_LIB_DIRS+= -F../EOModeler
ADDITIONAL_INCLUDE_DIRS+= -F../EOModeler
else
ADDITIONAL_INCLUDE_DIRS= -I..
ADDITIONAL_LIB_DIRS+=-L../EOInterface/$(GNUSTEP_OBJ_DIR) -L../EOModeler/$(GNUSTEP_OBJ_DIR)
endif

ADDITIONAL_NATIVE_LIBS += EOInterface gnustep-db2modeler

$(APP_NAME)_RESOURCE_FILES =		\
	Resources/Key_On.tiff		\
	Resources/ClassProperty_On.tiff \
	Resources/ModelDrag.tiff

$(APP_NAME)_OBJC_FILES =		\
	main.m				\
	Modeler.m			\
	AdaptorsPanel.m			\
	MainModelEditor.m		\
	ModelerEntityEditor.m		\
	DefaultColumnProvider.m		\
	KVDataSource.m			\
	ModelerAttributeEditor.m	\
	EOAdditions.m			\
	ModelerTableEmbedibleEditor.m	

include $(GNUSTEP_MAKEFILES)/application.make
