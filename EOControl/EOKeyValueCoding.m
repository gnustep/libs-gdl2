/** 
   EOKeyValueCoding.m <title>EOKeyValueCoding</title>

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: November 1996

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@oxymium.net>
   Date: January 2002

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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSHashTable.h>
#include <Foundation/NSException.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSDecimalNumber.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <gnustep/base/GSCategories.h>

#include <ctype.h>

#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>
#include <EOControl/EONull.h>

#include <ctype.h>


/*
 *  EOKeyValueCodingAdditions implementation
 */

@implementation NSObject (EOKVCPAdditions2)

+ (void) flushClassKeyBindings
{
}

/** if key is a bidirectional rel, use addObject:toBothSidesOfRelationship otherwise call  takeValue:forKey: **/
- (void)smartTakeValue: (id)anObject 
                forKey: (NSString *)aKey
{
  [self takeValue: anObject
        forKey: aKey];
}

- (void)smartTakeValue: (id)anObject 
            forKeyPath: (NSString *)aKeyPath
{
  NSRange r = [aKeyPath rangeOfString: @"."];

  if (r.length == 0)
    {
      [self smartTakeValue: anObject 
            forKey: aKeyPath];
    }
  else
    {
      NSString *key = [aKeyPath substringToIndex: r.location];
      NSString *path = [aKeyPath substringFromIndex: NSMaxRange(r)];

      [[self valueForKey: key] smartTakeValue: anObject 
                               forKeyPath: path];
    }
}

- (void)takeStoredValue: value 
             forKeyPath: (NSString *)key
{
  NSArray *pathArray;
  NSString *path;
  id obj = self;
  int i, count;

  EOFLOGObjectFnStartCond(@"EOKVC");

  pathArray = [key componentsSeparatedByString:@"."];
  count = [pathArray count];

  for (i = 0; i < (count - 1); i++)
    {
      path = [pathArray objectAtIndex: i];
      obj = [obj valueForKey: path];
    }

  path = [pathArray lastObject];
  [obj takeStoredValue: value forKey: path];

  EOFLOGObjectFnStopCond(@"EOKVC");
}

- (id)storedValueForKeyPath: (NSString *)key
{
  NSArray *pathArray = nil;
  NSString *path;
  id obj = self;
  int i, count;
  EOFLOGObjectFnStartCond(@"EOKVC");
  pathArray = [key componentsSeparatedByString:@"."];
  count = [pathArray count];

  for(i=0; i < (count-1); i++)
    {
      path = [pathArray objectAtIndex:i];
      obj = [obj valueForKey:path];
    }

  path = [pathArray lastObject];
  obj=[obj storedValueForKey:path];
  EOFLOGObjectFnStopCond(@"EOKVC");
  return obj;
}

#if !FOUNDATION_HAS_KVC
- (void)takeStoredValuesFromDictionary: (NSDictionary *)dictionary
{
  NSEnumerator *keyEnum;
  id key;
  id val;
  EONull *null;
  
  EOFLOGObjectFnStartCond(@"EOKVC");

  keyEnum = [dictionary keyEnumerator];

  null = (EONull *)[EONull null];

  while ((key = [keyEnum nextObject]))
    {
      val = [dictionary objectForKey: key];
      
      if (val == null)
	val = nil;
      
      [self takeStoredValue: val forKey: key];
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
}
#endif /* !FOUNDATION_HAS_KVC */

- (NSDictionary *)storedValuesForKeyPaths: (NSArray *)keyPaths
{
  NSDictionary *values = nil;
  int i, n;
  NSMutableArray *newKeyPaths = nil;
  NSMutableArray *newVals = nil;
  EONull *null;

  EOFLOGObjectFnStartCond(@"EOKVC");

  n = [keyPaths count];

  newKeyPaths = [[[NSMutableArray alloc] initWithCapacity: n] 
			      autorelease];
  newVals = [[[NSMutableArray alloc] initWithCapacity: n] 
			      autorelease];
  null = (EONull *)[EONull null];

  for (i = 0; i < n; i++)
    {
      id keyPath = [keyPaths objectAtIndex: i];
      id val = nil;

      NS_DURING //DEBUG Only ?
        {
          val = [self storedValueForKeyPath: keyPath];
        }
      NS_HANDLER
        {
          NSLog(@"EXCEPTION %@", localException);
          NSDebugMLog(@"EXCEPTION %@", localException);              
          [localException raise];
        }
      NS_ENDHANDLER;
        
      if (val == nil)
	val = null;
      
      [newKeyPaths addObject: keyPath];
      [newVals addObject: val];
    }
  
  values = [NSDictionary dictionaryWithObjects: newVals
			 forKeys: newKeyPaths];
  EOFLOGObjectFnStopCond(@"EOKVC");

  return values;
}

- (NSDictionary *)valuesForKeyPaths: (NSArray *)keyPaths
{
  NSDictionary *values = nil;
  int i;
  int n;
  NSMutableArray *newKeyPaths;
  NSMutableArray *newVals;
  EONull *null;

  EOFLOGObjectFnStartCond(@"EOKVC");

  n = [keyPaths count];
  newKeyPaths = [[[NSMutableArray alloc] initWithCapacity: n]
		  autorelease];
  newVals = [[[NSMutableArray alloc] initWithCapacity: n]
	      autorelease];
  null = (EONull *)[EONull null];

  for (i = 0; i < n; i++)
    {
      id keyPath = [keyPaths objectAtIndex: i];
      id val = nil;

      NS_DURING //DEBUG Only ?
        {
          val = [self valueForKeyPath: keyPath];
        }
      NS_HANDLER
        {
          NSLog(@"EXCEPTION %@", localException);
          NSDebugMLog(@"EXCEPTION %@",localException);              
          [localException raise];
        }
      NS_ENDHANDLER;

      if (val == nil)
	val = null;

      [newKeyPaths addObject: keyPath];
      [newVals addObject: val];
    }
  
  values = [NSDictionary dictionaryWithObjects: newVals
			 forKeys: newKeyPaths];

  EOFLOGObjectFnStopCond(@"EOKVC");

  return values;
}

@end

@implementation NSArray (EOKeyValueCoding)

- (id)valueForKey: (NSString *)key
{
  id result = nil;
  const char *str;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@",
  //                      key);

  str=[key cString];

  if (str && *str == '@')
    {
      if ([key length] > 1)
        {
          if ([key isEqualToString: @"@count"]) //the only known case because we haven't implemented custom operators
            result = [super valueForKey: @"count"];
          else // for unknwon case: call computeXXForKey:nil
            {
              NSMutableString *selString = [NSMutableString stringWithCapacity:10];
              SEL computeSelector;
              char l = str[1];
              
              if (islower(l))
                l = toupper(l);
              
              [selString appendString: @"compute"];
              [selString appendString: [NSString stringWithCString: &l
						 length: 1]];
              [selString appendString: [NSString stringWithCString: &str[2]]];
              [selString appendString: @"ForKey:"];

              computeSelector = NSSelectorFromString(selString);
              result = [self performSelector: computeSelector
			     withObject: nil];
            }
        }
    }
  else if ([key isEqualToString: @"count"]) //Special case: Apple Doc is wrong; here we return -count
    {
      static BOOL warnedCount = NO;
      if (warnedCount == NO)
        {
          warnedCount = YES;
          NSWarnLog(@"use of special 'count' key may works differently with only foundation base", "");
        }
      result = [super valueForKey: key];
    }
  else
    {
      result = [self resultsOfPerformingSelector: @selector(valueForKey:)
		     withObject: key
		     defaultResult: [EONull null]];
    }

  EOFLOGObjectFnStopCond(@"EOKVC");

  return result;
}

- (id)valueForKeyPath: (NSString *)keyPath
{
  id result = nil;
  const char *str;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPath=%@",
  //                      keyPath);

  str = [keyPath cString];

  if (str && *str == '@')
    {
      if ([keyPath length] > 1)
        {
	  NSMutableString *selString = [NSMutableString stringWithCapacity: 10];
          NSArray *pathArray = [keyPath componentsSeparatedByString: @"."];
	  NSString *fn = [pathArray objectAtIndex:0];
	  NSString *key = nil;
	  SEL computeSelector;
	  char l;

	  str = [fn cString];
	  l = str[1];
                            
	  if (islower(l))
	    l = toupper(l);
              
	  [selString appendString: @"compute"];
	  [selString appendString: [NSString stringWithCString: &l
					     length: 1]];
	  [selString appendString: [NSString stringWithCString: &str[2]]];
	  [selString appendString: @"ForKey:"];

	  computeSelector = NSSelectorFromString(selString);

	  if ([pathArray count] > 1)
	    {
	      key = [pathArray objectAtIndex: 1];

	      result = [self performSelector: computeSelector
			     withObject: key];
	    }
	  else
	    result = [self performSelector: computeSelector
			   withObject: @""];

	  if (result && [pathArray count] > 2)
	    {
	      NSArray *rightKeyPathArray
		= [pathArray subarrayWithRange:
			       NSMakeRange(2, [pathArray count] - 2)];
	      NSString *rightKeyPath
		= [rightKeyPathArray componentsJoinedByString: @"."];

	      result = [result valueForKeyPath: rightKeyPath];
	    }
	}
    }
  else if ([keyPath isEqualToString: @"count"]) //Special case: Apple Doc is wrong; here we return -count
    {
      static BOOL warnedCount = NO;
      if (warnedCount == NO)
        {
          warnedCount = YES;
          NSWarnLog(@"use of special 'count' key may works differently with only foundation base", "");
        }
      result = [super valueForKeyPath: keyPath];
    }
  else 
    result = [self resultsOfPerformingSelector: @selector(valueForKeyPath:)
		   withObject: keyPath
		   defaultResult: [EONull null]];

  EOFLOGObjectFnStopCond(@"EOKVC");

  return result;
}

- (id)computeSumForKey: (NSString *)key
{
  NSEnumerator *arrayEnum;
  NSDecimalNumber *item, *ret;

  EOFLOGObjectFnStartCond(@"EOKVC");

  arrayEnum = [self objectEnumerator];
  ret = [NSDecimalNumber zero];

  while ((item = [arrayEnum nextObject]))
    [ret decimalNumberByAdding: [item valueForKey:key]];
        
  EOFLOGObjectFnStopCond(@"EOKVC");

  return ret;
}

- (id)computeAvgForKey: (NSString *)key
{
  NSEnumerator *arrayEnum;
  NSDecimalNumber *item, *ret;

  EOFLOGObjectFnStartCond(@"EOKVC");

  arrayEnum = [self objectEnumerator];
  ret = [NSDecimalNumber zero];

  while ((item = [arrayEnum nextObject]))
    [ret decimalNumberByAdding: [item valueForKey:key]];

  ret = [ret decimalNumberByDividingBy:
	       [NSDecimalNumber decimalNumberWithMantissa: [self count]
				exponent: 0
				isNegative:NO]];

  EOFLOGObjectFnStopCond(@"EOKVC");

  return ret;
}

- (id)computeCountForKey: (NSString *)key
{
  id ret;

  EOFLOGObjectFnStartCond(@"EOKVC");

  ret = [NSNumber numberWithInt: [self count]];

  EOFLOGObjectFnStopCond(@"EOKVC");

  return ret;
}

- (id)computeMaxForKey: (NSString *)key
{
  NSEnumerator *arrayEnum;
  NSDecimalNumber *item, *max;
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOKVC");

  arrayEnum = [self objectEnumerator];

  item = [arrayEnum nextObject];
  value = [item valueForKey:key];
  max = value;

  if (item != nil)
    {
      while ((item = [arrayEnum nextObject]))
	{
          value = [item valueForKey:key];
	  if ([max compare: value] == NSOrderedAscending)
	    max = value;
	}
    }

  EOFLOGObjectFnStopCond(@"EOKVC");

  return max;
}

- (id)computeMinForKey: (NSString *)key
{
  NSEnumerator *arrayEnum;
  NSDecimalNumber *item, *min;
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOKVC");

  arrayEnum = [self objectEnumerator];
  item = [arrayEnum nextObject];
  value = [item valueForKey:key];
  min = value;

  if (item != nil)
    {
      while ((item = [arrayEnum nextObject]))
	{
          value = [item valueForKey:key];
	  if ([min compare: value] == NSOrderedDescending)
	    min = value;
	}
    }

  EOFLOGObjectFnStopCond(@"EOKVC");

  return min;
}

@end


@implementation NSDictionary (EOKeyValueCoding)

#if !FOUNDATION_HAS_KVC
- (id)valueForKey:(NSString *)key
{
  id value;

  EOFLOGObjectFnStartCond(@"EOKVC");
  EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@",
                        key);

  value = [self objectForKey: key];

  if (!value)
    {
      if ([key isEqualToString: @"allValues"])
        {
          static BOOL warnedAllValues = NO;
          if (warnedAllValues == NO)
            {
              warnedAllValues = YES;
              NSWarnLog(@"use of special 'allValues' key works differently with only foundation base", "");
            }

          value = [self allValues];
        }
      else if ([key isEqualToString: @"allKeys"])
        {
          static BOOL warnedAllKeys = NO;
          if (warnedAllKeys == NO)
            {
              warnedAllKeys = YES;
              NSWarnLog(@"use of special 'allKeys' key works differently with only foundation base", "");
            }

          value = [self allKeys];
        }
      else if ([key isEqualToString: @"count"])
        {
          static BOOL warnedCount = NO;
          if (warnedCount == NO)
            {
              warnedCount = YES;
              NSWarnLog(@"use of special 'count' key works differently with only foundation base", "");
            }

          value = [NSNumber numberWithInt: [self count]];
        }
    }

  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@ value: %p (class %@)",
  //                      key, value, [value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}

- (id)storedValueForKey: (NSString *)key
{
  id value;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@",
  //                      key);

  value = [self objectForKey: key];

  if (!value)
    {
      if ([key isEqualToString: @"allValues"])
        value = [self allValues];
      else if ([key isEqualToString: @"allKeys"])
        value = [self allKeys];
      else if ([key isEqualToString: @"count"])
        value = [NSNumber numberWithInt: [self count]];
    }

  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@ value: %p (class=%@)",
  //                      key, value, [value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}
#endif /* !FOUNDATION_HAS_KVC */ //MG

- (id)valueForKeyPath: (NSString*)keyPath
{
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPath=\"%@\"",
  //                      keyPath);

  if ([keyPath hasPrefix: @"'"]) //user defined composed key 
    {
      NSMutableArray *keyPathArray = [[[[keyPath stringByDeletingPrefix: @"'"]
					 componentsSeparatedByString: @"."]
					mutableCopy] autorelease];
      NSMutableString *key = [NSMutableString string];

      //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

      while ([keyPathArray count] > 0)
        {
          id tmpKey;

          //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

          tmpKey = [keyPathArray objectAtIndex: 0];
          //EOFLOGObjectLevelArgs(@"EOKVC", @"tmpKey=%@", tmpKey);

          [keyPathArray removeObjectAtIndex: 0];

          if ([key length] > 0)
            [key appendString: @"."];
          if ([tmpKey hasSuffix: @"'"])
            {
              tmpKey = [tmpKey stringByDeletingSuffix: @"'"];
              [key appendString: tmpKey];
              break;
            }
          else
	    [key appendString: tmpKey];

          //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);
        }

      //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);

      value = [self valueForKey: key];

      //EOFLOGObjectLevelArgs(@"EOKVC",@"key=%@ tmpValue: %p (class=%@)",
      //             key,value,[value class]);

      if (value && [keyPathArray count] > 0)
        {
          NSString *rightKeyPath = [keyPathArray
				     componentsJoinedByString: @"."];

          //EOFLOGObjectLevelArgs(@"EOKVC", @"rightKeyPath=%@",
          //                      rightKeyPath);

          value = [value valueForKeyPath: rightKeyPath];
        }
    }
  else
    {
      //return super valueForKeyPath:keyPath only if there's no object for entire key keyPath
      value = [self objectForKey: keyPath];

      EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ tmpValue: %p (class=%@)",
                   keyPath,value,[value class]);

      /*  if([value isEqual:[EONull null]] == YES) //???
          value=nil;
          else */

      if (!value)
        value = [super valueForKeyPath: keyPath];
    }

  //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ value: %p (class=%@)",
  //             keyPath,value,[value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}
//MG #endif /* !FOUNDATION_HAS_KVC */

- (id)storedValueForKeyPath: (NSString*)keyPath
{
  id value = nil;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=\"%@\"",
  //                      keyPath);

  if ([keyPath hasPrefix: @"'"]) //user defined composed key 
    {
      NSMutableArray *keyPathArray = [[[[keyPath stringByDeletingPrefix: @"'"]
					 componentsSeparatedByString: @"."]
					mutableCopy] autorelease];
      NSMutableString *key = [NSMutableString string];

      //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

      while ([keyPathArray count] > 0)
        {
          id tmpKey;

          //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

          tmpKey = [keyPathArray objectAtIndex: 0];
          //EOFLOGObjectLevelArgs(@"EOKVC", @"tmpKey=%@", tmpKey);

          [keyPathArray removeObjectAtIndex: 0];

          if ([key length] > 0)
            [key appendString: @"."];
          if ([tmpKey hasSuffix: @"'"])
            {
              tmpKey = [tmpKey stringByDeletingSuffix: @"'"];
              [key appendString: tmpKey];
              break;
            }
          else
	    [key appendString: tmpKey];

          //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);
        }

      //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);

      value = [self storedValueForKey: key];

      //EOFLOGObjectLevelArgs(@"EOKVC",@"key=%@ tmpValue: %p (class=%@)",
      //             key,value,[value class]);

      if (value && [keyPathArray count] > 0)
        {
          NSString *rightKeyPath = [keyPathArray
				     componentsJoinedByString: @"."];

          EOFLOGObjectLevelArgs(@"EOKVC", @"rightKeyPath=%@",
				rightKeyPath);

          value = [value storedValueForKeyPath: rightKeyPath];
        }
    }
  else
    {
      //return super valueForKeyPath:keyPath only if there's no object for entire key keyPath
      value = [self objectForKey: keyPath];

      //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ tmpValue: %p (class=%@)",
      //             keyPath,value,[value class]);

      /*  if([value isEqual:[EONull null]] == YES) //???
          value=nil;
          else */

      if (!value)
        value = [super storedValueForKeyPath: keyPath];
    }

  //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ value: %p (class=%@)",
  //             keyPath,value,[value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}

@end


@interface NSMutableDictionary(EOKeyValueCodingPrivate)
- (void)takeValue: (id)value
       forKeyPath: (NSString *)keyPath
          isSmart: (BOOL)smartFlag;
@end

@implementation NSMutableDictionary (EOKeyValueCoding)

#if !FOUNDATION_HAS_KVC
- (void)takeValue: (id)value 
           forKey: (NSString *)key
{
  EOFLOGObjectFnStartCond(@"EOKVC");

  if (value)
    [self setObject: value 
          forKey: key];
  else
    [self removeObjectForKey: key];

  EOFLOGObjectFnStopCond(@"EOKVC");
}

- (void)takeStoredValue: (id)value 
                 forKey: (NSString *)key
{
  EOFLOGObjectFnStartCond(@"EOKVC");

  if (value)
    [self setObject: value 
          forKey: key];
  else
    [self removeObjectForKey: key];

  EOFLOGObjectFnStopCond(@"EOKVC");
}
#endif /* !FOUNDATION_HAS_KVC */

- (void)smartTakeValue: (id)value 
            forKeyPath: (NSString*)keyPath
{
  [self takeValue:value
        forKeyPath:keyPath
        isSmart:YES];
}

#if !FOUNDATION_HAS_KVC
- (void)takeValue: (id)value
       forKeyPath: (NSString *)keyPath
{
  [self takeValue:value
        forKeyPath:keyPath
        isSmart:NO];
}
#endif /* !FOUNDATION_HAS_KVC */

- (void)takeValue: (id)value
       forKeyPath: (NSString *)keyPath
          isSmart: (BOOL)smartFlag
{
  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPath=\"%@\"",
  //                      keyPath);

  if ([keyPath hasPrefix: @"'"]) //user defined composed key 
    {
      NSMutableArray *keyPathArray = [[[[keyPath stringByDeletingPrefix: @"'"]
					 componentsSeparatedByString: @"."]
					mutableCopy] autorelease];
      NSMutableString *key = [NSMutableString string];

      //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

      while ([keyPathArray count] > 0)
        {
          id tmpKey;

          //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

          tmpKey = RETAIN([keyPathArray objectAtIndex: 0]);
          //EOFLOGObjectLevelArgs(@"EOKVC", @"tmpKey=%@", tmpKey);

          [keyPathArray removeObjectAtIndex: 0];

          if ([key length] > 0)
            [key appendString: @"."];
          if ([tmpKey hasSuffix: @"'"])
            {
              ASSIGN(tmpKey, [tmpKey stringByDeletingSuffix: @"'"]);
              [key appendString: tmpKey];
              break;
            }
          else
	    [key appendString: tmpKey];

          RELEASE(tmpKey);

          //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);
        }

      //EOFLOGObjectLevelArgs(@"EOKVC",@"key=%@",key);
      //EOFLOGObjectLevelArgs(@"EOKVC",@"left keyPathArray=\"%@\"",
      //             keyPathArray);

      if ([keyPathArray count] > 0)
        {
          id obj = [self objectForKey: key];

          if (obj)
            {
              NSString *rightKeyPath = [keyPathArray
					 componentsJoinedByString: @"."];

              //EOFLOGObjectLevelArgs(@"EOKVC",@"rightKeyPath=\"%@\"",
              //             rightKeyPath);

              if (smartFlag)
                [obj smartTakeValue: value
		     forKeyPath: rightKeyPath];
              else
                [obj takeValue: value
		     forKeyPath: rightKeyPath];
            }
        }
      else
        {
          if (value)
            [self setObject: value 
                  forKey: key];
          else
            [self removeObjectForKey: key];
        }
    }
  else
    {
      if (value)
        [self setObject: value 
              forKey: keyPath];
      else
        [self removeObjectForKey: keyPath];
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
}

- (void)takeStoredValue: (id)value 
             forKeyPath: (NSString *)keyPath
{
  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=\"%@\"",
  //             keyPath);

  if ([keyPath hasPrefix: @"'"]) //user defined composed key 
    {
      NSMutableArray *keyPathArray = [[[[keyPath stringByDeletingPrefix: @"'"]
					 componentsSeparatedByString: @"."]
					mutableCopy] autorelease];
      NSMutableString *key = [NSMutableString string];

      //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

      while ([keyPathArray count] > 0)
        {
          id tmpKey;

          //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

          tmpKey = [keyPathArray objectAtIndex: 0];
          //EOFLOGObjectLevelArgs(@"EOKVC", @"tmpKey=%@", tmpKey);

          [keyPathArray removeObjectAtIndex: 0];

          if ([key length] > 0)
            [key appendString: @"."];

          if ([tmpKey hasSuffix: @"'"])
            {
              tmpKey = [tmpKey stringByDeletingSuffix: @"'"];
              [key appendString: tmpKey];
              break;
            }
          else
	    [key appendString: tmpKey];

          //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);
        }

      //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@", key);
      //EOFLOGObjectLevelArgs(@"EOKVC",@"left keyPathArray=\"%@\"",
      //             keyPathArray);

      if ([keyPathArray count] > 0)
        {
          id obj = [self objectForKey: key];

          if (obj)
            {
              NSString *rightKeyPath = [keyPathArray
					 componentsJoinedByString: @"."];

              //EOFLOGObjectLevelArgs(@"EOKVC",@"rightKeyPath=\"%@\"",
              //             rightKeyPath);

              [obj  takeStoredValue: value
                    forKeyPath: rightKeyPath];
            }
        }
      else
        {
          if (value)
            [self setObject: value 
                  forKey: key];
          else
            [self removeObjectForKey: key];
        }
    }
  else
    {
      if (value)
        [self setObject: value 
              forKey: keyPath];
      else
        [self removeObjectForKey: keyPath];
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
}

@end
