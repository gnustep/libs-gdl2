#
#  EOAccess makefile for GNUstep Database Library.
#  
#  Copyright (C) 2000-2002 Free Software Foundation, Inc.
#
#  Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

GNUSTEP_MAKEFILES = $(GNUSTEP_SYSTEM_ROOT)/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The library to be compiled
LIBRARY_NAME=libgnustep-db2

LIBRARIES_DEPEND_UPON=-lgnustep-base -lFoundationExt -lgnustep-db2control

# The C source files to be compiled
libgnustep-db2_C_FILES = 

# The Objective-C source files to be compiled
libgnustep-db2_OBJC_FILES = \
EOModelGroup.m \
EOModel.m \
EOEntity.m \
EOAttribute.m \
EORelationship.m \
EOJoin.m \
EOStoredProcedure.m \
EOExpressionArray.m \
EOAdaptor.m \
EOAdaptorContext.m \
EOAdaptorChannel.m \
EOAdaptorOperation.m \
EODatabaseOperation.m \
EOSQLExpression.m \
EOSQLQualifier.m \
EODatabase.m \
EODatabaseChannel.m \
EODatabaseContext.m \
EOAccessFault.m \
EODatabaseDataSource.m \
EOUtilities.m

libgnustep-db2_HEADER_FILES_DIR = .
libgnustep-db2_HEADER_FILES_INSTALL_DIR = /EOAccess

libgnustep-db2_HEADER_FILES = \
EOModelGroup.h \
EOModel.h \
EOEntity.h \
EOAttribute.h \
EORelationship.h \
EOJoin.h \
EOStoredProcedure.h \
EOAdaptor.h \
EOAdaptorContext.h \
EOAdaptorChannel.h \
EODatabaseOperation.h \
EOSQLExpression.h \
EOSQLQualifier.h \
EODatabase.h \
EODatabaseChannel.h \
EODatabaseContext.h \
EOAccessFault.h \
EOPropertyListEncoding.h \
EODatabaseDataSource.h \
EOSchemaGeneration.h \
EOUtilities.h \
EOAccess.h

gdl2_AUTOGSDOC_HEADERS = $(libgnustep-db2_HEADER_FILES)
gdl2_AUTOGSDOC_SOURCE = $(libgnustep-db2_OBJC_FILES)
DOCUMENT_NAME = gdl2
gdl2_HEADER_FILES_DIR = $(HEADER_DIR)
gdl2_AGSDOC_FILES = gdl2.gsdoc $(gdl2_AUTOGSDOC_HEADERS) 
#$(gdl2_AUTOGSDOC_SOURCE)
gdl2_AGSDOC_FLAGS = \
	-Declared EOAccess \
	-Standards YES \
	-Project gdl2 \
	-WordMap '{\
	FOUNDATION_EXPORT=extern;FOUNDATION_STATIC_INLINE="";\
	GS_GEOM_SCOPE=extern;GS_GEOM_ATTR="";\
	GS_EXPORT=extern;GS_DECLARE="";\
	GS_RANGE_SCOPE=extern;GS_RANGE_ATTR="";\
	GS_ZONE_SCOPE=extern;GS_ZONE_ATTR="";\
	}' -Up gdl2


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif


-include Makefile.postamble
