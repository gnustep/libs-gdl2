/* 
   EOPropertyListEncoding.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __EOPropertyListEncoding_h__
#define __EOPropertyListEncoding_h__


#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif


@class NSDictionary;
@class NSMutableDictionary;


@protocol EOPropertyListEncoding

- initWithPropertyList: (NSDictionary *)propertyList owner: (id)owner;

- (void)awakeWithPropertyList: (NSDictionary *)propertyList;

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList;

@end

#endif /* __EOPropertyListEncoding_h__ */
