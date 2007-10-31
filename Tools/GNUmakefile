#
#  Tools makefile for GNUstep Database Library.
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


include $(GNUSTEP_MAKEFILES)/common.make

include ../Version
include ../common.make

# The library to be compiled
TOOL_NAME=gdlgsdoc eoutil

# The C source files to be compiled
gdlgsdoc_C_FILES = 

# The Objective-C source files to be compiled
gdlgsdoc_OBJC_FILES = \
EOAttribute+GSDoc.m \
EOEntity+GSDoc.m \
EOJoin+GSDoc.m \
EOModel+GSDoc.m \
EORelationship+GSDoc.m \
gsdoc-model.m \
NSArray+GSDoc.m \
NSDictionary+GSDoc.m \

gdlgsdoc_HEADER_FILES_DIR = .
#gdlgsdoc_HEADER_FILES_INSTALL_DIR = 

gdlgsdoc_HEADER_FILES = \
EOAttribute+GSDoc.h \
EOEntity+GSDoc.h \
EOJoin+GSDoc.h \
EOModel+GSDoc.h \
EORelationship+GSDoc.h \
NSArray+GSDoc.h \
NSDictionary+GSDoc.h \

gdl2gsdoc_AUTOGSDOC_HEADERS = $(gdlgsdoc_HEADER_FILES)
gdl2gsdoc_AUTOGSDOC_SOURCE = $(gdlgsdoc_OBJC_FILES)
DOCUMENT_NAME = gdl2gsdoc
gdl2gsdoc_HEADER_FILES_DIR = $(HEADER_DIR)
gdl2gsdoc_AGSDOC_FILES = gdl2gsdoc.gsdoc $(gdl2gsdoc_AUTOGSDOC_HEADERS) 
#$(gdl2gsdoc_AUTOGSDOC_SOURCE)
gdl2gsdoc_AGSDOC_FLAGS = \
	-Declared gdlgsdoc \
	-Project gdl2gsdoc \
	-Up gdl2gsdoc \
	$(GDL2_AGSDOC_FLAGS)


eoutil_OBJC_FILES = eoutil.m

eoutil_HEADER_FILES = 


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/ctool.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif


-include Makefile.postamble
