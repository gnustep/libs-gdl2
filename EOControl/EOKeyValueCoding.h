/* 
   EOKeyValueCoding.h

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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSKeyValueCoding.h>
#include <Foundation/NSDictionary.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>


@interface NSObject (EOKVCPAdditions2)
- (void)smartTakeValue: (id)anObject 
                forKey: (NSString *)aKey;
- (void)smartTakeValue: (id)anObject 
            forKeyPath: (NSString *)aKeyPath;
- (void)takeStoredValue: value 
             forKeyPath: (NSString *)key;
- (id)storedValueForKeyPath: (NSString *)key;
#if !FOUNDATION_HAS_KVC
- (void)takeStoredValuesFromDictionary: (NSDictionary *)dictionary;
#endif
- (NSDictionary *)valuesForKeyPaths: (NSArray *)keyPaths;
- (NSDictionary *)storedValuesForKeyPaths: (NSArray *)keyPaths;
@end

#if NeXT_Foundation_LIBRARY
@interface NSObject (MacOSXRevealed)
- (void)takeStoredValuesFromDictionary: (NSDictionary *)dictionary;
@end
#endif

@interface NSArray (EOKeyValueCoding)
- (id)valueForKey: (NSString *)key;
- (id)valueForKeyPath: (NSString *)keyPath;
- (id)computeSumForKey: (NSString *)key;
- (id)computeAvgForKey: (NSString *)key;
- (id)computeCountForKey: (NSString *)key;
- (id)computeMaxForKey: (NSString *)key;
- (id)computeMinForKey: (NSString *)key;
@end




#if !FOUNDATION_HAS_KVC
@interface NSDictionary (EOKeyValueCoding)
- (id)valueForKey: (NSString *)key;
@end


@interface NSMutableDictionary (EOKeyValueCoding)
- (void)takeValue: (id)value 
           forKey: (NSString*)key;
@end
#endif

GDL2CONTROL_EXPORT NSString *EOUnknownKeyException;
GDL2CONTROL_EXPORT NSString *EOTargetObjectUserInfoKey;
GDL2CONTROL_EXPORT NSString *EOUnknownUserInfoKey;

#endif /* __EOKeyValueCoding_h__ */
