#
#  EOModeler makefile for GNUstep Database Library.
#  
#  Copyright (C) 2001,2002,2003,2004,2005 Free Software Foundation, Inc.
#
#  Written by: Mirko Viviani <mirko.viviani@gmail.com>
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
NATIVE_LIBRARY_NAME=EOModeler

# The C source files to be compiled
EOModeler_C_FILES = 

# The Objective-C source files to be compiled
EOModeler_OBJC_FILES =		\
EOModelExtensions.m		   	\
EOMInspector.m				\
EOModelExtensions.m			\
EOModelerDocument.m			\
EOMInspectorController.m		\
EOModelerApp.m				\
EOModelerEditor.m			


EOModeler_HEADER_FILES_DIR = .
EOModeler_HEADER_FILES_INSTALL_DIR = /EOModeler

EOModeler_HEADER_FILES =	\
EOModelExtensions.h			\
EOMInspector.h				\
EOModelExtensions.h			\
EOModelerDocument.h			\
EOMInspectorController.h		\
EOModelerApp.h				\
EOModelerEditor.h			\
EODefines.h

-include Makefile.preamble
include ../common.make

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/native-library.make

-include Makefile.postamble
