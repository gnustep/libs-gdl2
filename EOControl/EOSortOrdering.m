/** 
   EOSortOrdering.m <title>EOSortOrdering</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSCoder.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSNull.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EOSortOrdering.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOKeyValueArchiver.h>
#include <EOControl/EODebug.h>

#define EONull NSNull

@implementation EOSortOrdering

/**
 * Returns an autoreleased EOSortOrdering initilaized with key and selector.  
 * The selector should take an id as an argument and return an 
 * NSComparisonResult value.  This method calls
 * [EOSortOrdering-initWithKey:selector:].
 */
+ (EOSortOrdering *) sortOrderingWithKey: (NSString *)key
				selector: (SEL)selector
{
  return AUTORELEASE([[self alloc] initWithKey: key
				   selector: selector]);
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(SEL) at: _selector];
  [coder encodeObject: _key];
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super init];

  [coder decodeValueOfObjCType: @encode(SEL) at: &_selector];
  _key = RETAIN([coder decodeObject]);

  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  if (NSShouldRetainWithZone(self, zone))
    {
      return RETAIN(self);
    }
  return [[[self class] allocWithZone: zone] 
	   initWithKey: _key selector: _selector];
}

/**<init />
 * Initializes the receiver with a copy of key and the selector.  The selector
 * should take an id as an argument and return an NSComparisonResult value.  
 */
- (id) initWithKey: (NSString *)key selector: (SEL)selector
{
  self = [super init];

  ASSIGNCOPY(_key, key);
  _selector = selector;

  return self;
}

/**
 * Returns the key of the receiver.
 */
- (NSString *) key
{
  return _key;
}

/**
 * Returns the selector of the receiver.  The selector should take an id as
 * an argument and return an NSComparisonResult value.  
 */
- (SEL) selector
{
  return _selector;
}

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver*)unarchiver
{
  EOFLOGObjectFnStartOrCond(@"EOSortOrdering");

  if ((self = [super init]))
    {
      NSString *selectorName;

      ASSIGN(_key, [unarchiver decodeObjectForKey: @"key"]);
      selectorName = [unarchiver decodeObjectForKey: @"selectorName"];

      if (selectorName)
	_selector = NSSelectorFromString(selectorName);
    }

  EOFLOGObjectFnStopOrCond(@"EOSortOrdering");

  return self;
}

- (void) encodeWithKeyValueArchiver: (EOKeyValueArchiver*)archiver
{
  [archiver encodeObject: _key forKey: @"key"];
  if (_selector)
    {
      [archiver encodeObject: NSStringFromSelector(_selector)
		forKey: @"selectorName"];
    }
}

/**
 * Returns a human readable representation of the receiver.
 */
- (NSString *) description
{
  return [NSString stringWithFormat:@"<%@ %p - %@ %@>",
		   NSStringFromClass(isa),
		   (void*)self,
		   _key,
		   NSStringFromSelector(_selector)];
}
@end


@implementation NSArray (EOKeyBasedSorting)

static NSComparisonResult 
compareUsingSortOrderings(id    left, 
			  id    right,
			  void* vpSortOrders)
{
  static EONull     *null = nil;
  NSArray           *sortOrders = (NSArray *)vpSortOrders;
  NSComparisonResult r = NSOrderedSame;
  unsigned int       i;
  unsigned int       sortOrdCnt = [sortOrders count];

  if (null == nil)
    {
      null = [EONull null];
    }

  /* Loop over all sort orderings until we have an ordering difference. */
  for (i=0; (r == NSOrderedSame) && (i < sortOrdCnt); i++)
    {
      EOSortOrdering *sortOrd  = [sortOrders objectAtIndex: i];
      NSString       *key      = [sortOrd key];
      SEL             compSel  = [sortOrd selector];
      id              leftVal  = [left  valueForKeyPath: key];
      id              rightVal = [right valueForKeyPath: key];
      BOOL            inverted = NO;
      NSComparisonResult (*imp)(id, SEL, id);

      /* Use EONull instead of nil. */
      leftVal  = (leftVal  != nil)?(leftVal) :(null);
      rightVal = (rightVal != nil)?(rightVal):(null);

      /* Insure that EONull is not the parameter for 
	 comparisons with other classes. */
      if (rightVal == null)
	{
	  rightVal = leftVal;
	  leftVal  = null;
	  inverted = YES;
	}

      imp = (NSComparisonResult (*)(id, SEL, id))
	[leftVal methodForSelector: compSel];
      NSCAssert3(imp!=NULL, 
		 @"Invalid comparison selector:%@ for object:<%@ 0x%x>",
		 NSStringFromSelector(compSel),
		 NSStringFromClass([leftVal class]),
		 leftVal);
      r = (*imp)(leftVal, compSel, rightVal);

      /* If we inverted the parameters, we must switch the result*/
      if (inverted == YES)
	{
	  r = ~r + 1;
	}
    }

  return r;
}


/**
 * Returns an array contaning the of the objects of the reveiver sorted 
 * according to the provided array of EOSortOrderings.
 */
- (NSArray *) sortedArrayUsingKeyOrderArray: (NSArray *)orderArray
{
  if ([self count] > 1)
    {
      return [self sortedArrayUsingFunction: compareUsingSortOrderings
		   context: orderArray];
    }
  else
    {
      return self;
    }
}

@end


@implementation NSMutableArray (EOKeyBasedSorting)

/**
 * Sorts the reveiver according to the provided array of EOSortOrderings.
 */
- (void) sortUsingKeyOrderArray: (NSArray *)orderArray
{
  if ([self count] > 1) 
    {
      [self sortUsingFunction: compareUsingSortOrderings
	    context: orderArray];
    }
}

@end

/*
  This declaration is needed by the compiler to state that 
  eventhough we know not all objects respond to -compare:,
  we want the compiler to generate code for the given
  prototype when calling -compare: in the following methods.
  We do not put this declaration in a header file to avoid
  the compiler seeing conflicting prototypes in user code.
 */
@interface NSObject (Comparison)
- (NSComparisonResult)compare: (id)other;
@end


@implementation NSObject (EOSortOrderingComparison)

/**
 * Default implementation of EOCompareAscending.
 * This implementation returns the result of compare:.  
 * Concrete classes should either override this method or compare: 
 * to return a meaningful NSComparisonResult. 
 */
- (NSComparisonResult) compareAscending: (id)other
{
  return [self compare: other];
}

/**
 * Default implementation of EOCompareDescending.
 * This implementation returns the inverted result of compare:. 
 * Concrete classes should either override this method or compare: 
 * to return a meaningful NSComparisonResult. 
 */
- (NSComparisonResult) compareDescending: (id)other
{
  NSComparisonResult result = [self compare: other];

  return (~result + 1);
}

/**
 * Default implementation of EOCompareCaseInsensitiveAscending.
 * This implementation returns the result of compare:. 
 * Concrete classes should either override this method or compare: 
 * to return a meaningful NSComparisonResult. 
 */
- (NSComparisonResult) compareCaseInsensitiveAscending: (id)other
{
  return [self compare: other];
}

/**
 * Default implementation of EOCompareCaseInsensitiveDescending.
 * This implementation returns the inverted result of compare:. 
 * Concrete classes should either override this method or compare: 
 * to return a meaningful NSComparisonResult. 
 */
- (NSComparisonResult) compareCaseInsensitiveDescending: (id)other
{
  NSComparisonResult result = [self compare: other];

  return (~result + 1);
}

@end


@implementation EONull (EOSortOrderingComparison)

/**
 * Implementation of EOCompareAscending for EONull.
 * When compared to another EONull, return NSOrderedSame.
 * Otherwise NSOrderdAscening.  This leads to EONulls to be at the begining
 * of arrays sorted with EOCompareAscending.
 */
- (NSComparisonResult) compareAscending: (id)other
{
  if (self == other)
    return NSOrderedSame;

  return NSOrderedAscending;
}

/**
 * Implementation of EOCompareDescending for EONull.
 * When compared to another EONull, return NSOrderedSame.
 * Otherwise NSOrderdDescening.  This leads to EONulls to be at the end
 * of arrays sorted with EOCompareDescending.
 */
- (NSComparisonResult) compareDescending: (id)other
{
  if (self == other)
    return NSOrderedSame;

  return NSOrderedDescending;
}

/**
 * Implementation of EOCompareCaseInsensativeAscending for EONull.
 * When compared to another EONull, return NSOrderedSame.
 * Otherwise NSOrderdAscening.  This leads to EONulls to be at the begining
 * of arrays sorted with EOCompareCaseInsensitiveAscending.
 */
- (NSComparisonResult) compareCaseInsensitiveAscending: (id)other
{
  if (self == other)
    return NSOrderedSame;

  return NSOrderedAscending;
}

/**
 * Implementation of EOCompareCaseInsensativeDescending for EONull.
 * When compared to another EONull, return NSOrderedSame.
 * Otherwise NSOrderdDescening.  This leads to EONulls to be at the end
 * of arrays sorted with EOCompareCaseInsensativeDescending.
 */
- (NSComparisonResult) compareCaseInsensitiveDescending: (id)other
{
  if (self == other)
    return NSOrderedSame;

  return NSOrderedDescending;
}

@end



@implementation NSString (EOSortOrderingComparison)

/**
 * Implementation of EOCompareCaseInsensativeDescending for NSString.
 * This method simply returns the result
 * of calling caseInsensitiveCompare:.
 */
- (NSComparisonResult) compareCaseInsensitiveAscending: (id)other
{
  return [self caseInsensitiveCompare: other];
}

/**
 * Implementation of EOCompareCaseInsensativeDescending for NSString.
 * This method simply returns the inverted result
 * of calling caseInsensitiveCompare:.
 */
- (NSComparisonResult) compareCaseInsensitiveDescending: (id)other
{
  NSComparisonResult result = [self caseInsensitiveCompare: other];

  return (~result + 1);
}

@end
