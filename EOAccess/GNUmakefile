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

include ../Version
include ../common.make

# The library to be compiled
NATIVE_LIBRARY_NAME=EOAccess

EOAccess_NEEDS_GUI = NO

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
EOSchemaGeneration.m \
EOSchemaSynchronization.m \
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
EOSchemaSynchronization.h \
EOSchemaGeneration.h \
EOUtilities.h \
EODefines.h \
EODeprecated.h \
EOAccess.h


DOCUMENT_NAME = EOAccess

# autogsdoc scan the source files corresponding to the headers
EOAccess_AGSDOC_FILES = EOAccess.gsdoc \
	$(EOAccess_HEADER_FILES) \
	$(EOAccess_OBJC_FILES)

EOAccess_AGSDOC_FLAGS = \
	-Declared EOAccess \
	-Project EOAccess \
	-Up EOAccess \
	$(GDL2_AGSDOC_FLAGS)


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/native-library.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif


-include Makefile.postamble
