/* 
   EOKeyValueCodingBase.h

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

#ifndef __EOKeyValueCoding_h__
#define __EOKeyValueCoding_h__

#if !FOUNDATION_HAS_KVC
#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

@class NSDictionary;



@interface NSObject (EOKeyValueCodingPrimitives)

- (id)valueForKey: (NSString *)key;
- (id)storedValueForKey: (NSString *)key;
- (void)takeValue: (id)value forKey: (NSString *)key;
- (void)takeStoredValue: (id)value forKey: (NSString *)key;
+ (BOOL)accessInstanceVariablesDirectly;
+ (BOOL)useStoredAccessor;

@end

@interface NSObject (EOKVCPAdditions)

- (id)valueForKeyPath: (NSString *)key;
- (void)takeValue: value forKeyPath: (NSString *)key;
- (NSDictionary *)valuesForKeys: (NSArray *)keys;
- (void)takeValuesFromDictionary: (NSDictionary *)dictionary;

@end

@interface NSObject (EOKeyValueCodingException)

- (id)handleQueryWithUnboundKey: (NSString *)key;
- (void)handleTakeValue: (id)value forUnboundKey: (NSString *)key;

- (void)unableToSetNilForKey: (NSString *)key;

@end

@interface NSObject (EOKeyValueCodingCacheControl)

+ (void)flushAllKeyBindings;

@end


#endif

#endif /* __EOKeyValueCodingBase_h__ */
