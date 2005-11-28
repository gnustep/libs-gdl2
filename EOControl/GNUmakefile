#
#  EOControl makefile for GNUstep Database Library.
#  
#  Copyright (C) 1997,2002,2003,2004,2005 Free Software Foundation, Inc.
#
#  Written by:	Scott Christley <scottc@net-community.com>
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

include ../Version

# The library to be compiled
LIBRARY_NAME=libgnustep-db2control

# The C source files to be compiled
libgnustep-db2control_C_FILES = 

# The Objective-C source files to be compiled
libgnustep-db2control_OBJC_FILES = \
EOSortOrdering.m \
EOFetchSpecification.m \
EOGenericRecord.m \
EOClassDescription.m \
EOKeyValueCoding.m \
EOKeyValueArchiver.m \
EOQualifier.m \
EOKeyValueQualifier.m \
EOKeyComparisonQualifier.m \
EOAndQualifier.m \
EOOrQualifier.m \
EONotQualifier.m \
EONull.m \
EOObjectStore.m \
EOObjectStoreCoordinator.m \
EOFaultHandler.m \
EOFault.m \
EOGlobalID.m \
EOKeyGlobalID.m \
EOObserver.m \
EOEditingContext.m \
EOSharedEditingContext.m \
EODataSource.m \
EODetailDataSource.m \
EOUndoManager.m \
EOMutableKnownKeyDictionary.m \
EONSAddOns.m \
EOCheapArray.m \
EOArrayDataSource.m \
EODebug.m \
EOPrivate.m

libgnustep-db2control_HEADER_FILES_DIR = .
libgnustep-db2control_HEADER_FILES_INSTALL_DIR = /EOControl

libgnustep-db2control_HEADER_FILES = \
EOSortOrdering.h \
EOFetchSpecification.h \
EOGenericRecord.h \
EOClassDescription.h \
EOKeyValueCoding.h \
EOKeyValueArchiver.h \
EOQualifier.h \
EONull.h \
EOObjectStore.h \
EOObjectStoreCoordinator.h \
EOFault.h \
EOGlobalID.h \
EOKeyGlobalID.h \
EOObserver.h \
EOEditingContext.h \
EOSharedEditingContext.h \
EODataSource.h \
EODetailDataSource.h \
EOArrayDataSource.h \
EODebug.h \
EONSAddOns.h \
EODefines.h \
EODeprecated.h \
EOControl.h

DOCUMENT_NAME = EOControl
EOControl_AUTOGSDOC_HEADERS = $(libgnustep-db2control_HEADER_FILES)
EOControl_AUTOGSDOC_SOURCE = $(libgnustep-db2control_OBJC_FILES)
EOControl_HEADER_FILES_DIR = $(HEADER_DIR)
EOControl_AGSDOC_FILES = EOControl.gsdoc $(EOControl_AUTOGSDOC_HEADERS) 
#$(EOControl_AUTOGSDOC_SOURCE)
EOControl_AGSDOC_FLAGS = \
	-Declared EOControl \
	-Standards YES \
	-SystemProjects System \
	-Project EOControl \
	-WordMap '{\
	FOUNDATION_EXPORT=extern;FOUNDATION_STATIC_INLINE="";\
	GS_GEOM_SCOPE=extern;GS_GEOM_ATTR="";\
	GS_EXPORT=extern;GS_DECLARE="";\
	GS_RANGE_SCOPE=extern;GS_RANGE_ATTR="";\
	GS_ZONE_SCOPE=extern;GS_ZONE_ATTR="";\
	}' -Up EOControl

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif

-include Makefile.postamble
