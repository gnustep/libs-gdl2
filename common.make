#
#  Common make commands for all GNUmakefile's in gdl2
#  
#  Copyright (C) 2006,2007,2008 Free Software Foundation, Inc.
#
#  Written by:	Matt Rice <ratmice@gmail.com>
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

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

GDL2_AGSDOC_FLAGS = \
	-WordMap '{ \
	RCS_ID = "//"; \
	GDL2CONTROL_EXPORT = extern; \
	GDL2ACCESS_EXPORT = extern; \
	GDL2INTERFACE_EXPORT = extern; \
	}'

ifeq ($(gcov),yes)
TEST_CFLAGS +=-ftest-coverage -fprofile-arcs
TEST_LDFLAGS +=-ftest-coverage -fprofile-arcs -lgcov
TEST_COVERAGE_LIBS+=-lgcov
endif

