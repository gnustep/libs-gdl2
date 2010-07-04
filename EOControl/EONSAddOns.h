/* -*-objc-*-
   EONSAddOns.h

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#ifndef __EONSAddOns_h__
#define __EONSAddOns_h__

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>

/**
 * This define is experimental.  Expect it to be replaced.
 */
#define GDL2_BUFFER(ID, SIZE, TYPE) \
  unsigned ID##_size = (SIZE); \
  TYPE ID##_obuf[(ID##_size) <= GS_MAX_OBJECTS_FROM_STACK ? (ID##_size) : 0]; \
  TYPE *ID##_base = ((ID##_size) <= GS_MAX_OBJECTS_FROM_STACK) ? ID##_obuf \
    : ( TYPE *)GSAutoreleasedBuffer((ID##_size) * sizeof( TYPE )); \
  TYPE *ID = ID##_base;


GDL2CONTROL_EXPORT BOOL
GSUseStrictWO451Compatibility(NSString *key);

GDL2CONTROL_EXPORT void
GDL2_Activate(Class sup, Class cls);

@interface NSObject (NSObjectPerformingSelector)
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                   withEachObjectInArray: (NSArray *)array;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                   withEachObjectInArray: (NSArray *)array
                           defaultResult: (id)defaultResult;
@end

@interface NSArray (NSArrayPerformingSelector)
- (id)firstObject;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                           defaultResult: (id)defaultResult;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                              withObject: (id)obj1;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                              withObject: (id)obj1
                           defaultResult: (id)defaultResult;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                              withObject: (id)obj1
                              withObject: (id)obj2;
- (NSArray *)resultsOfPerformingSelector: (SEL)sel
                              withObject: (id)obj1
                              withObject: (id)obj2
                           defaultResult: (id)defaultResult;
- (NSArray *)arrayExcludingObjectsInArray: (NSArray *)array;
- (NSArray *)arrayExcludingObject: (id)object;
- (NSArray *)arrayByReplacingObject: (id)object1
                         withObject: (id)object2;
- (BOOL)containsIdenticalObjectsWithArray: (NSArray *)array;

@end

@interface NSObject (EOCompareOnName)
- (NSComparisonResult)eoCompareOnName: (id)object;
@end

@interface NSString (YorYes)
- (BOOL)isYorYES;
@end

@interface NSString (VersionParsing)
- (int)parsedFirstVersionSubstring;
@end

@interface NSString (Extensions)
- (NSString *)initialCapitalizedString;
@end

//Ayers: Review
/* Do not rely on these.  */
@interface NSString (StringToNumber)
-(unsigned int)unsignedIntValue;
-(short)shortValue;
-(unsigned short)unsignedShortValue;
-(long)longValue;
-(unsigned long)unsignedLongValue;
-(long long)longLongValue;
-(unsigned long long)unsignedLongLongValue;
@end

@interface NSObject (PerformSelect3)
/**
 * Causes the receiver to execute the method implementation corresponding
 * to selector and returns the result.<br />
 * The method must be one which takes three arguments and returns an object.
 * <br />Raises NSInvalidArgumentException if given a null selector.
 */
- (id)performSelector: (SEL)selector
           withObject: (id)object1
           withObject: (id)object2
           withObject: (id)object3;

@end
@interface NSMutableDictionary (EOAdditions)

/**
 * Creates an autoreleased mutable dictionary based on otherDictionary
 * but only with keys from the keys array.
 */

+ (NSMutableDictionary*) dictionaryWithDictionary:(NSDictionary *)otherDictionary
                                             keys:(NSArray*)keys;

/**
 * replaces the current keys with the new ones without changing the contents
 * only keys from currentKeys are left in the receiver.
 */

- (void) translateFromKeys:(NSArray *) currentKeys
                    toKeys:(NSArray *) newKeys;

@end
@interface NSDictionary (EOAdditions)

/**
 * return YES if any EONull is into receiver.
 * otherwise return NO.
 */

- (BOOL) containsAnyNullObject;

/**
 * creates an new dictionary with EONull for the keys
 */

+ (NSDictionary*) dictionaryWithNullValuesForKeys:(NSArray*) keys;

@end

#endif /* __EONSAddOns_h__ */
