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

static char rcsId[] = "$Id$";

#import <EOControl/EOControl.h>
#import <EOControl/EOSortOrdering.h>
#import <EOControl/EOKeyValueCoding.h>


@implementation EOSortOrdering

+ (EOSortOrdering *)sortOrderingWithKey: (NSString *)key
			       selector: (SEL)selector
{
  return [[[self alloc] initWithKey: key
			selector: selector] 
           autorelease];
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(SEL) at: _selector];
  [coder encodeObject: _key];
}

- (id)initWithCoder: (NSCoder *)coder
{
  self = [super init];

  [coder decodeValueOfObjCType: @encode(SEL) at: &_selector];
  _key = [[coder decodeObject] retain];

  return self;
}

- initWithKey: (NSString *)key selector: (SEL)selector
{
  self = [super init];

  ASSIGN(_key, key);
  _selector = selector;

  return self;
}

- (NSString *)key
{
  return _key;
}

- (SEL)selector
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

- (void) encodeWithKeyValueArchiver: (EOKeyValueUnarchiver*)archiver
{
  [self notImplemented: _cmd];
}

@end


@implementation NSArray (EOKeyBasedSorting)

- (NSArray *)sortedArrayUsingKeyOrderArray: (NSArray *)orderArray
{
  // A fast-coding way
  //TODO a better way (see sortUsingKeyOrderArray:)

  if ([self count] <= 1) 
    return self;
  else
    {
      NSMutableArray *sortedArray = [[self mutableCopy] autorelease];

      [sortedArray sortUsingKeyOrderArray: orderArray];

      // make array immutable but don't copy as mutable arrays copy deep
      return [NSArray arrayWithArray: sortedArray];
    }
}

@end


@implementation NSMutableArray (EOKeyBasedSorting)

- (void)_sortUsingKeyOrder: (EOSortOrdering *)order
		 fromIndex: (int)index
		     count: (int)count
{
  /* Shell sort algorithm taken from SortingInAction - a NeXT example */
#define STRIDE_FACTOR 3	// good value for stride factor is not well-understood
                        // 3 is a fairly good choice (Sedgewick)
  unsigned	c, d, stride;
  BOOL		found;
#ifdef	GSWARN
  BOOL		badComparison = NO;
#endif
  NSString *orderKey;
  SEL       orderSel;
  int       type;
  EONull   *null = (EONull *)[EONull null];

  orderKey = [order key];
  orderSel = [order selector];

  type = 1;

  if (sel_eq(orderSel, EOCompareAscending))
    type = 1;
  else if (sel_eq(orderSel, EOCompareDescending))
    type = 2;
  else if (sel_eq(orderSel, EOCompareCaseInsensitiveAscending))
    type = 3;
  else if (sel_eq(orderSel, EOCompareCaseInsensitiveDescending))
    type = 4;

  stride = 1;
  while (stride <= count)
    {
      stride = stride * STRIDE_FACTOR + 1;
    }
    
  while (stride > (STRIDE_FACTOR - 1))
    {
      // loop to sort for each value of stride
      stride = stride / STRIDE_FACTOR;

      for (c = stride; c < count; c++)
	{
	  found = NO;
	  if (stride > c)
	    {
	      break;
	    }

	  d = c - stride + index;
	  while (!found)	/* move to left until correct place */
	    {
	      id		 a = [self objectAtIndex: d + stride];
	      id		 b = [self objectAtIndex: d];
	      id                 aValue = [a valueForKey: orderKey];
	      id                 bValue = [b valueForKey: orderKey];
	      NSComparisonResult r;

	      if (aValue == nil)
		aValue = null;
	      else if (bValue == nil)
		{
		  bValue = aValue;
		  aValue = null;
		}

	      switch (type)
		{
		default:
		case 1:
		  r = [aValue compareAscending: bValue];
		  break;
		case 2:
		  r = [aValue compareDescending: bValue];
		  break;
		case 3:
		  r = [aValue compareCaseInsensitiveAscending: bValue];
		  break;
		case 4:
		  r = [aValue compareCaseInsensitiveDescending: bValue];
		  break;
		}

	      if (aValue == null && bValue != nil && bValue != null)
		r = ~r+1;

	      if (r < 0)
		{
#ifdef	GSWARN
		  if (r != NSOrderedAscending)
		    {
		      badComparison = YES;
		    }
#endif
		  IF_NO_GC(RETAIN(a));
		  [self replaceObjectAtIndex: d + stride withObject: b];
		  [self replaceObjectAtIndex: d withObject: a];
		  RELEASE(a);
		  if ((stride + index) > d)
		    {
		      break;
		    }
		  d -= stride;		// jump by stride factor
		}
	      else
		{
#ifdef	GSWARN
		  if (r != NSOrderedDescending && r != NSOrderedSame)
		    {
		      badComparison = YES;
		    }
#endif
		  found = YES;
		}
	    }
	}
    }
#ifdef	GSWARN
  if (badComparison == YES)
    {
      NSWarnMLog(@"Detected bad return value from comparison", 0);
    }
#endif
}

- (void)sortUsingKeyOrderArray: (NSArray *)orderArray
{
  int count = [self count];

  if (count > 1) 
    {
      EOSortOrdering *order;
      NSEnumerator   *orderEnum;
      //NSString *key;
      
      orderEnum = [orderArray objectEnumerator];
      if ((order = [orderEnum nextObject]))
        {
          //id a, b;
          
          [self _sortUsingKeyOrder: order
                fromIndex: 0
                count: [self count]];
#if 0
          key = [order key];
          
          a = [[self objectAtIndex: i] valueForKey: key];
          
          for (i = index; i < (count - 1); i++)
            {
              b = [[self objectAtIndex: i + 1] valueForKey: key];

              if ([a compare: b] == NSOrderedSame)
                {
                  start = i;
                }

              a = b;
            }
#endif
        }
    }
}

@end


@implementation NSObject (EOSortOrderingComparison)

- (NSComparisonResult)compareAscending: (id)other
{
  return [self compare: other];
}

- (NSComparisonResult)compareDescending: (id)other
{
  NSComparisonResult result = [self compare: other];

  return (~result + 1);
}

- (NSComparisonResult)compareCaseInsensitiveAscending: (id)other
{
  return [self compare: other];
}

- (NSComparisonResult)compareCaseInsensitiveDescending: (id)other
{
  NSComparisonResult result = [self compare: other];

  return (~result + 1);
}

@end


@implementation EONull (EOSortOrderingComparison)

- (NSComparisonResult)compareAscending: (id)other
{
  if (other == nil || self == other)
    return NSOrderedSame;

  return NSOrderedAscending;
}

- (NSComparisonResult)compareDescending: (id)other
{
  if (other == nil || self == other)
    return NSOrderedSame;

  return NSOrderedDescending;
}

- (NSComparisonResult)compareCaseInsensitiveAscending: (id)other
{
  if (other == nil || self == other)
    return NSOrderedSame;

  return NSOrderedAscending;
}

- (NSComparisonResult)compareCaseInsensitiveDescending: (id)other
{
  if (other == nil || self == other)
    return NSOrderedSame;

  return NSOrderedDescending;
}

@end


@implementation NSString (EOSortOrderingComparison)

- (NSComparisonResult)compareCaseInsensitiveAscending: (id)other
{
  return [self caseInsensitiveCompare: other];
}

- (NSComparisonResult)compareCaseInsensitiveDescending: (id)other
{
  NSComparisonResult result = [self caseInsensitiveCompare: other];

  return (~result + 1);
}

@end
