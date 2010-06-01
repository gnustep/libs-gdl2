#
#  EOModelEditor makefile for GNUstep Database Library.
#  
#  Copyright (C) 2005,2006 Free Software Foundation, Inc.
#
#  Author: Matt Rice <ratmice@gmail.com>
#
#  This file is part of the GNUstep Database Library.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 3 of the License, or (at your option) any later version.
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

include ../../common.make
include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = EOModelEditor

EOModelEditor_NEEDS_GUI = yes
EOModelEditor_SUBPROJECTS=Inspectors

ifeq ($(GUI_LIB),apple)
EOModelEditor_APPLICATION_ICON = EOModelEditor.icns
else
EOModelEditor_APPLICATION_ICON = EOModelEditor.tiff
endif

ifneq ($(FOUNDATION_LIB),gnu)
ADDITIONAL_OBJC_LIBS += -lgnustep-baseadd
endif

ADDITIONAL_INCLUDE_DIRS+=-I../
ADDITIONAL_NATIVE_LIB_DIRS+=../EOAccess ../EOControl ../EOInterface ../EOModeler
ADDITIONAL_NATIVE_LIBS += EOAccess EOControl EOModeler Renaissance 

$(APP_NAME)_RESOURCE_FILES =			\
	Resources/ModelDrag.tiff		\
	Resources/SQLGenerator.gsmarkup	\
	Resources/EOMEDocument.gsmarkup	\
	Resources/EOModelEditorInfo.plist    	\
	Resources/Key_Diagram.tiff		\
	Resources/Key_Header.tiff		\
	Resources/toOne.tiff		\
	Resources/toMany.tiff		\
	Resources/Key_On.tiff			\
	Resources/gear.tiff			\
	Resources/Locking_Diagram.tiff		\
	Resources/Locking_Header.tiff		\
	Resources/Locking_On.tiff		\
	Resources/ClassProperty_Diagram.tiff	\
	Resources/ClassProperty_Header.tiff	\
	Resources/ClassProperty_On.tiff 	\
	Resources/Preferences.gorm		\
	Resources/EOModelEditor.tiff		\
	Resources/EOModelEditor.icns		\
	Resources/EOModel.icns		\
	Resources/AllowsNull_On.tiff		\
	Resources/dimple.tiff		\
	Resources/nodimple.tiff		\
	Resources/AllowsNull_Header.tiff	\
	Resources/Menu-Cocoa.gsmarkup	\
	Resources/Menu-GNUstep.gsmarkup \
	Resources/Credits.rtf \
	Resources/ConsistencyResults.gsmarkup \
  Resources/DataBrowser.gsmarkup

$(APP_NAME)_OBJC_FILES =		\
	main.m				\
  EOModelEditorApp.m \
  TableViewController.m \
  EOMEEOAccessAdditions.m \
  EOMEDocument.m \
	AdaptorsPanel.m			\
	EOAdditions.m			\
	SQLGenerator.m			\
	ConsistencyResults.m		\
	Preferences.m			\
	ConsistencyChecker.m		\
  CodeGenerator.m \
  DataBrowser.m

include $(GNUSTEP_MAKEFILES)/application.make
