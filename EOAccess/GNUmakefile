#
#  EOAccess makefile for GNUstep Database Library.
#  
#  Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.
#
#  Author: Mirko Viviani <mirko.viviani@gmail.com>
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


include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The library to be compiled
NATIVE_LIBRARY_NAME=EOAccess
# The C source files to be compiled
EOAccess_C_FILES = 

# The Objective-C source files to be compiled
EOAccess_OBJC_FILES = \
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
EOUtilities.m \
EOPrivate.m

EOAccess_HEADER_FILES_DIR = .

EOAccess_HEADER_FILES = \
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
EODefines.h \
EODeprecated.h \
EOAccess.h


DOCUMENT_NAME = EOAccess
EOAccess_AUTOGSDOC_HEADERS = $(EOAccess_HEADER_FILES)
EOAccess_AUTOGSDOC_SOURCE = $(EOAccess_OBJC_FILES)
EOAccess_HEADER_FILES_DIR = $(HEADER_DIR)
EOAccess_AGSDOC_FILES = EOAccess.gsdoc $(EOAccess_AUTOGSDOC_HEADERS) 
#$(EOAccess_AUTOGSDOC_SOURCE)
EOAccess_AGSDOC_FLAGS = \
	-Declared EOAccess \
	-Standards YES \
	-Project EOAccess \
	-WordMap '{\
	FOUNDATION_EXPORT=extern;FOUNDATION_STATIC_INLINE="";\
	GS_GEOM_SCOPE=extern;GS_GEOM_ATTR="";\
	GS_EXPORT=extern;GS_DECLARE="";\
	GS_RANGE_SCOPE=extern;GS_RANGE_ATTR="";\
	GS_ZONE_SCOPE=extern;GS_ZONE_ATTR="";\
	}' -Up EOAccess


-include Makefile.preamble
include ../common.make

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/native-library.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif


-include Makefile.postamble
