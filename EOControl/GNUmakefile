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
include ../Version

# The library to be compiled
NATIVE_LIBRARY_NAME=EOControl

EOControl_NEEDS_GUI = no

# The C source files to be compiled
EOControl_C_FILES = 

# The Objective-C source files to be compiled
EOControl_OBJC_FILES = \
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
EOMultiReaderLock.m \
EOAggregateEvent.m \
EOEvent.m \
EOEventCenter.m \
EODebug.m \
EOPrivate.m

EOControl_HEADER_FILES_DIR = .
EOControl_HEADER_FILES_INSTALL_DIR = /EOControl

EOControl_HEADER_FILES = \
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
EOMultiReaderLock.h \
EOAggregateEvent.h \
EOEvent.h \
EOEventCenter.h \
EODebug.h \
EONSAddOns.h \
EODefines.h \
EODeprecated.h \
EOControl.h

DOCUMENT_NAME = EOControl

EOControl_AGSDOC_FILES = EOControl.gsdoc \
	$(EOControl_HEADER_FILES) \
	$(EOControl_OBJC_FILES)

EOControl_AGSDOC_FLAGS = \
	-Declared EOControl \
	-Project EOControl \
	-Up EOControl \
	$(GDL2_AGSDOC_FLAGS)

-include Makefile.preamble
-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/native-library.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif

-include Makefile.postamble
