/* -*-objc-*-
   EODefines.h

   Copyright (C) 2003,2004,2005 Free Software Foundation, Inc.

   Author: Stephane Corthesy <stephane@sente.ch>
   Date: Feb 2003

   This file is part of the GNUstep Database Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef __EOAccess_EODefines_h__
#define __EOAccess_EODefines_h__

#ifdef __cplusplus
extern "C" {
#endif

#ifdef GNUSTEP_WITH_DLL

#if BUILD_libEOAccess_DLL

# if defined(__MINGW32__)
  /* On Mingw, the compiler will export all symbols automatically, so
   * __declspec(dllexport) is not needed.
   */
#  define GDL2ACCESS_EXPORT  extern
#  define GDL2ACCESS_DECLARE
# else
#  define GDL2ACCESS_EXPORT  __declspec(dllexport)
#  define GDL2ACCESS_DECLARE __declspec(dllexport)
# endif
#else
#  define GDL2ACCESS_EXPORT  extern __declspec(dllimport)
#  define GDL2ACCESS_DECLARE __declspec(dllimport)
#endif

#else /* GNUSTEP_WITH[OUT]_DLL */

#  define GDL2ACCESS_EXPORT extern
#  define GDL2ACCESS_DECLARE

#endif

#ifdef __cplusplus
}
#endif

#endif /* __EOAccess_EODefines_h__ */
