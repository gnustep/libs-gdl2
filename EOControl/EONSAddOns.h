/* 
   EONSAddOns.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#ifndef __EONSAddOns_h__
#define __EONSAddOns_h__

#ifndef NeXT_Foundation_LIBRARY
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

@class NSLock;
@class NSRecursiveLock;

GDL2CONTROL_EXPORT BOOL
GSUseStrictWO451Compatibility(NSString *key);

GDL2CONTROL_EXPORT NSLock *
GDL2GlobalLock();

GDL2CONTROL_EXPORT NSRecursiveLock *
GDL2GlobalRecursiveLock();

@interface NSObject (NSObjectPerformingSelector)
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                  withEachObjectInArray: (NSArray*)array;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                  withEachObjectInArray: (NSArray*)array
                          defaultResult: (id)defaultResult;
@end

@interface NSArray (NSArrayPerformingSelector)
- (id)firstObject;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                          defaultResult: (id)defaultResult;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1
                          defaultResult: (id)defaultResult;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1
                             withObject: (id)obj2;
- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1
                             withObject: (id)obj2
                          defaultResult: (id)defaultResult;
- (NSArray*)arrayExcludingObjectsInArray: (NSArray*)array;
- (NSArray*)arrayExcludingObject: (id)object;
- (NSArray*)arrayByReplacingObject: (id)object1
                        withObject: (id)object2;
- (BOOL)containsIdenticalObjectsWithArray: (NSArray*)array;

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
 * to aSelector and returns the result.<br />
 * The method must be one which takes three arguments and returns an object.
 * <br />Raises NSInvalidArgumentException if given a null selector.
 */
- (id) performSelector: (SEL)aSelector
            withObject: (id) object1
            withObject: (id) object2
            withObject: (id) object3;

@end
#endif /* __EONSAddOns_h__ */
