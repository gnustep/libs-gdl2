#
#  EOModeler makefile for GNUstep Database Library.
#  
#  Copyright (C) 2001 Free Software Foundation, Inc.
#
#  Written by: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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

include $(GNUSTEP_MAKEFILES)/common.make

include ../Version

# The library to be compiled
LIBRARY_NAME=libgnustep-db2modeler

ifeq ((FOUNDATION_LIB),gnu)
libgnustep-db2modeler_LIBRARIES_DEPEND_UPON = -lgnustep-base
else
libgnustep-db2modeler_LIBRARIES_DEPEND_UPON = -lgnustep-baseadd
endif

# The C source files to be compiled
libgnustep-db2modeler_C_FILES = 

# The Objective-C source files to be compiled
libgnustep-db2modeler_OBJC_FILES = EOModelExtensions.m

libgnustep-db2modeler_HEADER_FILES_DIR = .
libgnustep-db2modeler_HEADER_FILES_INSTALL_DIR = /EOModeler

libgnustep-db2modeler_HEADER_FILES = EOModelExtensions.h


-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/library.make

-include Makefile.postamble
