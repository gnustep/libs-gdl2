#
#  EOInterface makefile for GNUstep Database Library.
#  
#  Copyright (C) 2004 Free Software Foundation, Inc.
#
#  Author: David Ayers  <d.ayers@inode.at>
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

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The library to be compiled
LIBRARY_NAME=EOInterface

# The C source files to be compiled
EOInterface_C_FILES = 

# The Objective-C source files to be compiled
EOInterface_OBJC_FILES = \
EOActionAssociation.m \
EOActionCellAssociation.m \
EOActionInsertionAssociation.m \
EOAssociation.m \
EOColumnAssociation.m \
EOComboBoxAssociation.m \
EOControlAssociation.m \
EODisplayGroup.m \
EOGenericControlAssociation.m \
EOTableViewAssociation.m \
NSImage+Additions.m

EOInterface_HEADER_FILES = \
EOActionAssociation.h \
EOActionInsertionAssociation.h \
EOAssociation.h \
EOColumnAssociation.h \
EOComboBoxAssociation.h \
EOControlAssociation.h \
EODisplayGroup.h \
EOInterface.h

gdl2_AUTOGSDOC_HEADERS = $(EOInterface_HEADER_FILES)
gdl2_AUTOGSDOC_SOURCE = $(EOInterface_OBJC_FILES)
DOCUMENT_NAME = gdl2
gdl2_HEADER_FILES_DIR = $(HEADER_DIR)
gdl2_AGSDOC_FILES = gdl2.gsdoc $(gdl2_AUTOGSDOC_HEADERS) 
#$(gdl2_AUTOGSDOC_SOURCE)
gdl2_AGSDOC_FLAGS = \
	-Declared EOInterface \
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
