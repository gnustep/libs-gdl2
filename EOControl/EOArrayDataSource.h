/* -*-objc-*-
   EOArrayDataSource.h

   Copyright (C) 2003,2004,2005 Free Software Foundation, Inc.

   Author: Stephane Corthesy <stephane@sente.ch>
   Date: March 2003

   This file is part of the GNUstep Database Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   */

#ifndef __EOArrayDataSource_h__
#define __EOArrayDataSource_h__

#include <EOControl/EODataSource.h>

@class NSMutableArray;
@class NSArray;

@class EOEditingContext;
@class EOClassDescription;

@interface EOArrayDataSource : EODataSource <NSCoding>
{
  NSMutableArray        *_objects;
  EOEditingContext      *_context;
  EOClassDescription    *_classDescription;
}

- (id)initWithClassDescription: (EOClassDescription *)classDescription
		editingContext: (EOEditingContext *)context;

- (void)setArray: (NSArray *)array;

@end

#endif
