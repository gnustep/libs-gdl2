# -*-makefile-*-
#  gdl2.EOControl.make
#
#  Makefile include segment which handles linking to the GNUstep
#  Database Library; requires the GNUstep makefile package.
#  
#  Copyright (C) 2009 Free Software Foundation, Inc.
#
#  Author: David Ayers  <ayers@fsfe.org>
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
#  License along with this library;
#  If not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

ifneq ($(GDL2_EOCONTROL_LOADED),yes)
include $(GNUSTEP_MAKEFILES)/Auxiliary/gdl2.make
GDL2_EOCONTROL_LOADED=yes
ADDITIONAL_NATIVE_LIBS+=EOControl
endif
