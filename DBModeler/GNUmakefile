#
#  DBModeler makefile for GNUstep Database Library.
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

include $(GNUSTEP_MAKEFILES)/common.make
include ../common.make

APP_NAME = DBModeler

DBModeler_NEEDS_GUI = yes
DBModeler_SUBPROJECTS=Inspectors

ifeq ($(GUI_LIB),apple)
DBModeler_APPLICATION_ICON = DBModeler.icns
else
DBModeler_APPLICATION_ICON = DBModeler.tiff
endif

ADDITIONAL_INCLUDE_DIRS+=-I../
ADDITIONAL_NATIVE_LIB_DIRS+=../EOAccess ../EOControl ../EOInterface ../EOModeler
ADDITIONAL_NATIVE_LIBS += EOAccess EOControl EOInterface EOModeler Renaissance

$(APP_NAME)_RESOURCE_FILES =			\
	Resources/ModelDrag.tiff		\
	Resources/SQLGenerator.gorm		\
	Resources/Info-gnustep.plist    	\
	Resources/Key_Diagram.tiff		\
	Resources/Key_Header.tiff		\
	Resources/Key_On.tiff			\
	Resources/Locking_Diagram.tiff		\
	Resources/Locking_Header.tiff		\
	Resources/Locking_On.tiff		\
	Resources/ClassProperty_Diagram.tiff	\
	Resources/ClassProperty_Header.tiff	\
	Resources/ClassProperty_On.tiff 	\
	Resources/Preferences.gorm		\
	Resources/ConsistencyResults.gorm	\
	Resources/DBModeler.tiff		\
	Resources/DBModeler.icns		\
	Resources/AllowsNull_On.tiff		\
	Resources/AllowsNull_Header.tiff	\
	Resources/Menu-Cocoa.gsmarkup	\
	Resources/Menu-GNUstep.gsmarkup

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
	ConsistencyChecker.m		\
	DiagramView.m			\
	AttributeCell.m			\
	NSView+Additions.m		\
	EntityView.m			\
	DiagramEditor.m

include $(GNUSTEP_MAKEFILES)/application.make
