/* 
   EOStoredProcedure.h

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

#ifndef __EOStoredProcedure_h__
#define __EOStoredProcedure_h__

#import <Foundation/NSObject.h>
#import <gnustep/base/GCObject.h>

#import <EOAccess/EOPropertyListEncoding.h>


@class NSDictionary;

@class EOModel;
@class EOAttribute;
@class EOStoredProcedure;


@interface EOStoredProcedure : GCObject <EOPropertyListEncoding>
{
  NSString *_name;
  NSString *_externalName;
  NSDictionary *_userInfo;
  NSDictionary *_internalInfo;

  /* Garbage collectable objects */
  EOModel *_model;
  GCArray *_arguments;
}

+ (EOStoredProcedure *)storedProcedureWithPropertyList: (NSDictionary *)propertyList 
                                                 owner: (id)owner;

- (EOStoredProcedure *)initWithName:(NSString *)name;

- (NSString *)name;

- (NSString *)externalName;

- (EOModel *)model;

- (NSArray *)arguments;

- (NSDictionary *)userInfo;

- (void)setName:(NSString *)name;
- (void)setExternalName:(NSString *)name;
- (void)setArguments:(NSArray *)arguments;
- (void)setUserInfo:(NSDictionary *)dictionary;

@end

@interface EOStoredProcedure(EOModelBeautifier)

- (void)beautifyName;

@end

#endif
