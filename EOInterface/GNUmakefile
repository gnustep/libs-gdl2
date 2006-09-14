#
#  EOInterface makefile for GNUstep Database Library.
#  
#  Copyright (C) 2004,2005 Free Software Foundation, Inc.
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
#  License along with this library; see the file COPYING.LIB.
#  If not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The library to be compiled
NATIVE_LIBRARY_NAME=EOInterface

# The C source files to be compiled
EOInterface_C_FILES = 

# The Objective-C source files to be compiled
EOInterface_OBJC_FILES =	\
EOActionAssociation.m		\
EOActionCellAssociation.m	\
EOActionInsertionAssociation.m	\
EOAssociation.m			\
EOColumnAssociation.m		\
EOComboBoxAssociation.m		\
EOControlAssociation.m		\
EODetailSelectionAssociation.m	\
EODisplayGroup.m		\
EOGenericControlAssociation.m	\
EOMasterCopyAssociation.m	\
EOMasterDetailAssociation.m	\
EOMasterPeerAssociation.m	\
EOMatrixAssociation.m		\
EOPickTextAssociation.m		\
EOPopUpAssociation.m		\
EORadioMatrixAssociation.m	\
EORecursiveBrowserAssociation.m	\
EOTableViewAssociation.m	\
EOTextAssociation.m		\
NSImage+Additions.m		\
EOAspectConnector.m

EOInterface_HEADER_FILES =	\
EOActionAssociation.h		\
EOActionInsertionAssociation.h	\
EOAssociation.h			\
EOColumnAssociation.h		\
EOComboBoxAssociation.h		\
EOControlAssociation.h		\
EODetailSelectionAssociation.h	\
EODisplayGroup.h		\
EOInterface.h			\
EOMasterCopyAssociation.h	\
EOMasterDetailAssociation.h	\
EOMatrixAssociation.h		\
EOPickTextAssociation.h		\
EOPopUpAssociation.h		\
EORadioMatrixAssociation.h	\
EORecursiveBrowserAssociation.h	\
EOTextAssociation.h		\
EOAspectConnector.h		

EOInterface_AUTOGSDOC_HEADERS = $(EOInterface_HEADER_FILES)
EOInterface_AUTOGSDOC_SOURCE = $(EOInterface_OBJC_FILES)
DOCUMENT_NAME = EOInterface
EOInterface_HEADER_FILES_DIR = $(HEADER_DIR)
EOInterface_AGSDOC_FILES = EOInterface.gsdoc $(EOInterface_AUTOGSDOC_HEADERS) 
#$(EOInterface_AUTOGSDOC_SOURCE)
EOInterface_AGSDOC_FLAGS = \
	-Declared EOInterface \
	-Standards YES \
	-Project EOInterface \
	-WordMap '{\
	FOUNDATION_EXPORT=extern;FOUNDATION_STATIC_INLINE="";\
	GS_GEOM_SCOPE=extern;GS_GEOM_ATTR="";\
	GS_EXPORT=extern;GS_DECLARE="";\
	GS_RANGE_SCOPE=extern;GS_RANGE_ATTR="";\
	GS_ZONE_SCOPE=extern;GS_ZONE_ATTR="";\
	}' -Up EOInterface


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/native-library.make
# Only build the doc if doc=yes was passed on the command line
ifeq ($(doc),yes)
include $(GNUSTEP_MAKEFILES)/documentation.make
endif


-include Makefile.postamble
