# -*-Makefile-*-
#  GNUmakefile
#
#  Copyright (C) 2004, 2005 Free Software Foundation, Inc.
#
#  Author: Matt Rice  <ratmice@yahoo.com>
#  Date: February 2004
#
#  This file is part of the GNUstep Database Library
#
#  The GNUstep Database Library is free software; you can redistribute it 
#  and/or modify it under the terms of the GNU Lesser General Public License 
#  as published by the Free Software Foundation; either version 2, 
#  or (at your option) any later version.
#
#  The GNUstep Database Library is distributed in the hope that it will be 
#  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License 
#  along with the GNUstep Database Library; see the file COPYING. 
#  If not, write to the Free Software Foundation, Inc., 
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 

# Install into the system root by default
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME=LoginPanel
ifneq ($(GUI_MAKE_LOADED),yes)
ifneq ($(GUI_LIB),apple)
BUNDLE_NAME=
endif
endif

LoginPanel_RESOURCE_FILES = postgreslogo.tif
LoginPanel_OBJC_FILES = PostgresLoginPanel.m
LoginPanel_PRINCIPAL_CLASS = PostgresLoginPanel

LoginPanel_INCLUDE_DIRS = -I.. -I../../..
LoginPanel_LIB_DIRS = \
	-L../../../EOControl/$(GNUSTEP_OBJ_DIR) \
	-L../../../EOAccess/$(GNUSTEP_OBJ_DIR)
LoginPanel_OBJC_LIBS = -lgnustep-db2control -lgnustep-db2

ifneq ($(FOUNDATION_LIB),gnu)
LoginPanel_OBJC_LIBS += -lgnustep-baseadd
endif

LoginPanel_COPY_INTO_DIR = ../PostgresEOAdaptor.framework/Resources

include ../config.mak

-include Makefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/bundle.make

-include Makefile.postamble

