#
#  DBModeler makefile for GNUstep Database Library.
#  
#  Copyright (C) 2005,2006 Free Software Foundation, Inc.
#
#  Author: Matt Rice <ratmice@yahoo.com>
#
#  This file is part of the GNUstep Database Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

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

$(APP_NAME)_RESOURCE_FILES =			\
	Resources/Key_On.tiff			\
	Resources/ClassProperty_On.tiff 	\
	Resources/ModelDrag.tiff		\
	Resources/SQLGenerator.gorm		\
	Resources/Info-gnustep.plist    	\
	Resources/Key_Header.tiff		\
	Resources/Locking_On.tiff		\
	Resources/Locking_Header.tiff		\
	Resources/ClassProperty_Header.tiff	\
	Resources/Preferences.gorm		\
	Resources/ConsistencyResults.gorm	\
	Resources/DBModeler.tiff

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
	ModelerTableEmbedibleEditor.m	\
	SQLGenerator.m			\
	ConsistencyResults.m		\
	Preferences.m			\
	ConsistencyChecker.m

include $(GNUSTEP_MAKEFILES)/application.make
