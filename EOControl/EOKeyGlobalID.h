/* -*-objc-*-
   EOKeyGlobalID.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

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

#ifndef __EOKeyGlobalID_h__
#define __EOKeyGlobalID_h__

#include <EOControl/EOGlobalID.h>


@interface EOKeyGlobalID : EOGlobalID <NSCoding>
{
  unsigned short _keyCount;
  NSString *_entityName;  
  id *_keyValues;
}

+ (id)globalIDWithEntityName: (NSString *)entityName
                        keys: (id *)keys 
                    keyCount: (unsigned)count
                        zone: (NSZone *)zone;

- (NSString *)entityName;

- (id *)keyValues;

- (unsigned)keyCount;
- (NSArray *)keyValuesArray;

- (BOOL)isEqual: (id)other;
- (unsigned)hash;

- (void)encodeWithCoder: (NSCoder *)coder;
- (id)initWithCoder: (NSCoder *)decoder;

- (BOOL)isFinal;
- (NSString *)description;
- (BOOL)areKeysAllNulls;

@end

#endif
