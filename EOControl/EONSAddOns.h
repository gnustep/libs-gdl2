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

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>


@class NSArray;


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


#endif /* __EONSAddOns_h__ */
