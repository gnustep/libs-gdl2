# configure.in for GDL2 library
# Process this file with autoconf to produce a configure script.
#
#   Copyright (C) 2002,2004,2005 Free Software Foundation, Inc.
#
#   Written by: Mirko Viviani <mirko.viviani@gmail.com>
#
#   This file is part of the GDL2 library.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Library General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#   
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Library General Public License for more details.
#
#   You should have received a copy of the GNU Library General Public
#   License along with this library; 
#   If not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA

builtin(include, config/postgres.m4)dnl
builtin(include, config/sqlite3.m4)dnl
AC_INIT

if test -z "$GNUSTEP_SYSTEM_ROOT"; then
  AC_MSG_ERROR([You must run the GNUstep initialization script first!])
fi

AC_CONFIG_HEADER(config.h)


#--------------------------------------------------------------------
# Check for Postgres database
#--------------------------------------------------------------------

AM_PATH_PGSQL(enable_pgsql=yes, enable_pgsql=no)
if test $enable_pgsql = yes; then
  EOADAPTORS="$EOADAPTORS PostgreSQLAdaptor"
  AC_CONFIG_FILES([EOAdaptors/PostgreSQLAdaptor/GNUmakefile EOAdaptors/PostgreSQLAdaptor/config.mak])

  HAVE_PGSQL=1
#  AC_DEFINE(HAVE_LIBXML,1,
#           [Define if libxml available])
else
  HAVE_PGSQL=0
fi

#--------------------------------------------------------------------
# Check for SQLite3 database 
#--------------------------------------------------------------------
AM_PATH_SQLITE3(enable_sqlite3=yes, enable_sqlite3=no)
if test $enable_sqlite3 = yes; then
  EOADAPTORS="$EOADAPTORS SQLiteAdaptor"
  AC_CONFIG_FILES([EOAdaptors/SQLiteAdaptor/GNUmakefile])
  HAVE_SQLITE3=1
else
  HAVE_SQLITE3=0
fi


AC_SUBST(EOADAPTORS)

# FIXME: Once we have a generic reliable way to test-link GNUstep projects
#        this should be replaced with that technique.
AC_ARG_ENABLE(gorm-palette,
	[  --disable-gorm-palette to disable building gorm palette], ,
	enable_gorm_palette=yes)
GUI_SUBPROJECTS=""
if test "$enable_gorm_palette" = "yes"; then
  GUI_SUBPROJECTS="$GUI_SUBPROJECTS GDL2Palette"
fi
AC_SUBST(GUI_SUBPROJECTS)

#--------------------------------------------------------------------
# Record the version
#--------------------------------------------------------------------
AC_MSG_CHECKING(for the version of GDL2 we are compiling)
if test -f "Version"; then
  . ./Version
fi
AC_MSG_RESULT($VERSION)
AC_SUBST(VERSION)
AC_SUBST(MAJOR_VERSION)
AC_SUBST(MINOR_VERSION)
AC_SUBST(SUBMINOR_VERSION)
AC_SUBST(GCC_VERSION)

#--------------------------------------------------------------------
# Write the Makefiles
#--------------------------------------------------------------------
AC_CONFIG_FILES([gdl2.make GNUmakefile EOAdaptors/GNUmakefile])
AC_OUTPUT
