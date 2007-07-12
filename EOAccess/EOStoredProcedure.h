/* -*-objc-*-
   EOStoredProcedure.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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

#ifndef __EOStoredProcedure_h__
#define __EOStoredProcedure_h__

#include <EOAccess/EOPropertyListEncoding.h>


@class NSDictionary;

@class EOModel;
@class EOAttribute;
@class EOStoredProcedure;


@interface EOStoredProcedure : NSObject <EOPropertyListEncoding>
{
  NSString *_name;
  NSString *_externalName;
  NSDictionary *_userInfo;
  NSDictionary *_internalInfo;

  /* Garbage collectable objects */
  EOModel *_model;
  NSArray *_arguments;
}

+ (EOStoredProcedure *)storedProcedureWithPropertyList: (NSDictionary *)propertyList 
                                                 owner: (id)owner;

- (EOStoredProcedure *)initWithName: (NSString *)name;

- (NSString *)name;

- (NSString *)externalName;

- (EOModel *)model;

- (NSArray *)arguments;

- (NSDictionary *)userInfo;

- (void)setName: (NSString *)name;
- (void)setExternalName: (NSString *)name;
- (void)setArguments: (NSArray *)arguments;
- (void)setUserInfo: (NSDictionary *)dictionary;

@end

@interface EOStoredProcedure (EOModelBeautifier)

- (void)beautifyName;

@end

#endif
