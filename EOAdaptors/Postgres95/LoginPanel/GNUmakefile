# -*-Makefile-*-
#  GNUmakefile
#
#  Copyright (C) 2004 Free Software Foundation, Inc.
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
#  along with the GNUstep Database Library; see the file COPYING. If not, 
#  write to the Free Software Foundation, Inc., 
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME=LoginPanel
LoginPanel_OBJC_FILES = Postgres95LoginPanel.m
LoginPanel_PRINCIPAL_CLASS = Postgres95LoginPanel
ADDITIONAL_INCLUDE_DIRS = -I..
LoginPanel_COPY_INTO_DIR = ../Postgres95EOAdaptor.framework/Resources

include ../config.mak

-include Makefile.preamble

-include GNUmakefile.local

ifeq ($(GUI_MAKE_LOADED),yes)
  include $(GNUSTEP_MAKEFILES)/bundle.make
else
  ifeq ($(GUI_LIB),apple)
      include $(GNUSTEP_MAKEFILES)/bundle.make
  else
       guiNotInstalled:
	@echo Skipping login panel compilation. GNUstep gui not installed. 
  endif
endif

-include Makefile.postamble
