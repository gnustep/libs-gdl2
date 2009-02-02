#
#  GDL2Palette makefile for GNUstep Database Library.
#  
#  Copyright (C) 2005,2006 Free Software Foundation, Inc.
#
#  Written by:	Matt Rice <ratmice@gmail.com>
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


include ../common.make
include $(GNUSTEP_MAKEFILES)/common.make

PALETTE_NAME=GDL2
GDL2_NEEDS_GUI = yes
GDL2_PRINCIPAL_CLASS = GDL2Palette

ADDITIONAL_INCLUDE_DIRS+=-I../
ADDITIONAL_NATIVE_LIB_DIRS+=../EOAccess/ ../EOControl/ ../EOInterface ../EOModeler
ADDITIONAL_NATIVE_LIBS+=EOAccess EOControl EOInterface EOModeler 

GDL2_RESOURCE_FILES=		\
GDL2Palette.tiff		\
GDL2ConnectionInspector.gorm	\
GDL2DisplayGroupInspector.gorm	\
palette.table 


GDL2_OBJC_FILES=		\
	Palette.m		\
	ResourceManager.m	\
	ConnectionInspector.m	\
	IB+Categories.m		\
	Foundation+Categories.m \
	KeyWrapper.m		\
	DisplayGroupInspector.m

PALETTE_LIBS=$(ADDITIONAL_OBJC_LIBS) -lGorm

include $(GNUSTEP_MAKEFILES)/palette.make
