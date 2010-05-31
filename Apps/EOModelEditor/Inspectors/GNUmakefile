#
#  DBModeler/Inspectors makefile for GNUstep Database Library.
#  
#  Copyright (C) 2005,2006 Free Software Foundation, Inc.
#
#  Author: Matt Rice  <ratmice@gmail.com>
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

include ../../../common.make
include $(GNUSTEP_MAKEFILES)/common.make
SUBPROJECT_NAME=Inspectors

ADDITIONAL_INCLUDE_DIRS+=-I../../

Inspectors_NEEDS_GUI=yes
Inspectors_HAS_RESOURCE_BUNDLE=yes

Inspectors_RESOURCE_FILES+=	\
    RelationshipInspector.gsmarkup	\
    RelationshipInspector.tiff \
    EntityInspector.tiff \
    AdvancedRelationshipInspector.tiff \
    AttributeInspector.tiff \
    AdvancedAttributeInspector.tiff \
    AdvancedEntityInspector.tiff \
    StoredProcedureInspector.tiff \
    ConnectionDictionaryInspector.tiff  \
    UserInfoInspector.tiff


Inspectors_OBJC_FILES+=RelationshipInspector.m

Inspectors_RESOURCE_FILES+=AttributeInspector.gsmarkup \
      AdvancedRelationshipInspector.gsmarkup \
      AdvancedEntityInspector.gsmarkup \
      EntityInspector.gsmarkup \
      AdvancedAttributeInspector.gsmarkup \
      StoredProcedureInspector.gsmarkup \
      ConnectionDictionaryInspector.gsmarkup \
      UserInfoInspector.gsmarkup \
      EntityStoredProcedureInspector.gsmarkup
      
Inspectors_OBJC_FILES+=AttributeInspector.m

Inspectors_OBJC_FILES+=AdvancedEntityInspector.m \
    AdvancedRelationshipInspector.m \
    EntityInspector.m \
    AdvancedAttributeInspector.m \
    StoredProcedureInspector.m \
    ConnectionDictionaryInspector.m \
    UserInfoInspector.m \
    EntityStoredProcedureInspector.m

include $(GNUSTEP_MAKEFILES)/subproject.make
