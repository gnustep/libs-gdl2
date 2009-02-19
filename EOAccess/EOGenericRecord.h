/* -*-objc-*-
   EOGenericRecord.h

   Copyright (C) 2009 Free Software Foundation, Inc.

   Author: David Ayers
   Date: February 2009

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

#ifndef __EOAccess_EOGenericRecord_h__
#define __EOAccces_EOGenericRecord_h__

#include <EOControl/EOGenericRecord.h>

@class EOEntity;

@interface EOGenericRecord (EOAccessAdditions)
- (EOEntity *)entity;
@end

#endif /* __EOAccess_EOGenericRecord_h__ */
