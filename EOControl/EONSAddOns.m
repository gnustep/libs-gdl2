/** 
   EONSAddOns.m <title>EONSAddOns</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#import <Foundation/Foundation.h>

#import <EOControl/EONSAddOns.h>


@implementation NSObject (NSObjectPerformingSelector)

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
		  withEachObjectInArray: (NSArray*)array
{
  return [self resultsOfPerformingSelector: sel
	       withEachObjectInArray: array
               defaultResult: nil];
}

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                  withEachObjectInArray: (NSArray*)array
                          defaultResult: (id)defaultResult
{
  NSMutableArray *results = nil;

  if (array)
    {
      int i, count = [array count];
      id object = nil;

      results = [NSMutableArray array];

      //OPTIMIZE
      NS_DURING
        {
          for(i = 0; i < count; i++)
            {
              id result;

              object = [array objectAtIndex: i];
              result = [self performSelector: sel
			     withObject: object];
              if (!result)
                result = defaultResult;

              NSAssert3(result,
                        @"%@: No result for object %@ resultOfPerformingSelector:\"%s\" withEachObjectInArray:",
                        self,
                        object,
                        sel_get_name(sel));

              [results addObject: result]; //TODO What to do if nil ??
            }
        }
      NS_HANDLER
        {
          NSWarnLog(@"object %p %@ may not support %@",
                    object,
                    [object class],
                    NSStringFromSelector(sel));
          NSLog(@"%@ (%@)",localException,[localException reason]);
          [localException raise];
        }
      NS_ENDHANDLER;
    }

  return results;
}

@end

@implementation NSArray (NSArrayPerformingSelector)

- (id)firstObject
{
  NSAssert1([self count] > 0, @"no object in %@", self);
  return [self objectAtIndex: 0];
}

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
{
  return [self resultsOfPerformingSelector: sel
               defaultResult: nil];
}

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                          defaultResult: (id)defaultResult
{
  NSMutableArray *results=[NSMutableArray array];
  int i, count = [self count];
  id object = nil;

  NSDebugMLLog(@"gsdb", @"self:%p (%@) results:%p (%@)",
	       self, [self class], results, [results class]);

  //OPTIMIZE
  NS_DURING
    {
      for(i = 0; i < count; i++)
        {
          id result;

          object = [self objectAtIndex: i];
          result = [object performSelector: sel];

          if (!result)
            result = defaultResult;

          NSAssert3(result,
                    @"%@: No result for object %@ resultOfPerformingSelector:\"%s\"",
                    self,
                    object,
                    sel_get_name(sel));

          [results addObject: result]; //TODO What to do if nil ??
        }
    }
  NS_HANDLER
    {
      NSWarnLog(@"object %p %@ may doesn't support %@",
                object,
                [object class],
                NSStringFromSelector(sel));

      NSLog(@"%@ (%@)", localException, [localException reason]);

      [localException raise];
    }
  NS_ENDHANDLER;

  NSDebugMLLog(@"gsdb", @"self:%p (%@) results:%p (%@)",
	       self, [self class], results, [results class]);

  return results;
}

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1
{
  return [self resultsOfPerformingSelector: sel
               withObject: obj1
               defaultResult: nil];
}

- (NSArray*)resultsOfPerformingSelector:(SEL)sel
                             withObject:(id)obj1
                          defaultResult:(id)defaultResult
{
  NSMutableArray *results = [NSMutableArray array];
  int i, count = [self count];
  id object = nil;

  //OPTIMIZE
  NS_DURING
    {
      for(i = 0; i < count; i++)
        {
          id result;

          object = [self objectAtIndex: i];
          result = [object performSelector: sel
			   withObject: obj1];

          if (!result)
            result = defaultResult;

          NSAssert3(result,
                    @"%@: No result for object %@ resultOfPerformingSelector:\"%s\"",
                    self,
                    object,
                    sel_get_name(sel));

          [results addObject: result]; //TODO What to do if nil ??
        }
    }
  NS_HANDLER
    {
      NSWarnLog(@"object %p %@ may doesn't support %@",
                object,
                [object class],
                NSStringFromSelector(sel));

      NSLog(@"%@ (%@)", localException, [localException reason]);

      [localException raise];
    }
  NS_ENDHANDLER;

  return results;
}

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1
                             withObject: (id)obj2
{
  return [self resultsOfPerformingSelector: sel
               withObject: obj1
               withObject: obj2
               defaultResult: nil];
}

- (NSArray*)resultsOfPerformingSelector: (SEL)sel
                             withObject: (id)obj1
                             withObject: (id)obj2
                          defaultResult: (id)defaultResult
{
  NSMutableArray *results = [NSMutableArray array];
  int i, count = [self count];
  id object = nil;

  //OPTIMIZE
  NS_DURING
    {
      for(i = 0; i < count; i++)
        {
          id result;

          object = [self objectAtIndex: i];
          result = [object performSelector: sel
			   withObject: obj1
			   withObject: obj2];

          if (!result)
            result = defaultResult;

          NSAssert3(result,
                    @"%@: No result for object %@ resultOfPerformingSelector:\"%s\"",
                    self,
                    object,
                    sel_get_name(sel));

          [results addObject: result]; //TODO What to do if nil ??
        }
    }
  NS_HANDLER
    {
      NSWarnLog(@"object %p %@ may doesn't support %@",
                object,
                [object class],
                NSStringFromSelector(sel));

      NSLog(@"%@ (%@)", localException, [localException reason]);

      [localException raise];
    }
  NS_ENDHANDLER;

  return results;
}

- (NSArray*)arrayExcludingObjectsInArray: (NSArray*)array
{
  //Verify: mutable/non mutable,..
  NSArray *result = nil;
  unsigned int selfCount = [self count];

  if (selfCount > 0) //else return nil
    {
      unsigned int arrayCount = [array count];

      if (arrayCount == 0) //Nothing to exclude ?
        result = self;
      else
        {
          int i;

          for (i = 0; i < selfCount; i++)
            {
              id object = [self objectAtIndex: i];
              int index = [array indexOfObjectIdenticalTo: object];

              if (index == NSNotFound)
                {
                  if (result)
                    [(NSMutableArray*)result addObject: object];
                  else
                    result = [NSMutableArray arrayWithObject: object];
                }
            }
        }
    }

  return result;
}

- (NSArray *)arrayExcludingObject: (id)anObject
{
  //Verify: mutable/non mutable,..
  NSArray *result = nil;
  unsigned int selfCount = [self count];

  if (selfCount > 0 && anObject) //else return nil
    {
      int i;

      for (i = 0; i < selfCount; i++)
        {
          id object = [self objectAtIndex: i];

          if (object != anObject)
            {
              if (result)
                [(NSMutableArray *)result addObject: object];
              else
                result = [NSMutableArray arrayWithObject: object];
            }
        }
    }

  return result;
}

- (NSArray*)arrayByReplacingObject: (id)object1
                        withObject: (id)object2
{
  NSArray *array = nil;
  int count;

  count = [self count];

  if (count > 0)
    {
      int i;
      id o = nil;
      NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity: count];

      for (i = 0; i < count; i++)
        {
          o = [self objectAtIndex: i];

          if ([o isEqual: object1])
            [tmpArray addObject: object2];
          else
            [tmpArray addObject: o];
        }

      array = [NSArray arrayWithArray: tmpArray];
    }
  else
    array = self;

  return array;
}

/** return YES if the 2 arrays contains exactly identical objects (compared by address) (i.e. only the order may change), NO otherwise
**/
- (BOOL)containsIdenticalObjectsWithArray: (NSArray *)array
{
  BOOL ret = NO;
  int selfCount = [self count];
  int arrayCount = [array count];

  if (selfCount == arrayCount)
    {
      BOOL foundInArray[arrayCount];
      int i, j;

      memset(foundInArray, 0, sizeof(BOOL) * arrayCount);
      ret = YES;

      for (i = 0; ret && i < selfCount; i++)
        {
          id selfObj = [self objectAtIndex: i];

          ret = NO;

          for (j = 0; j < arrayCount; j++)
            {
              id arrayObj = [array objectAtIndex: j];

              if (arrayObj == selfObj && !foundInArray[j])
                {
                  foundInArray[j] = YES;
                  ret = YES;

                  break;
                }
            }
        }
    }

  return ret;
}

@end

@implementation NSObject (EOCompareOnName)

- (NSComparisonResult)eoCompareOnName: (id)object
{
  return [[self name] compare: [object name]];
}

@end

@implementation NSString (YorYes)

- (BOOL)isYorYES
{
  return ([self isEqual: @"Y"] || [self isEqual: @"YES"]);
}

@end
