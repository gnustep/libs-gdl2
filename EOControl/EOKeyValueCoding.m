/** 
   EOKeyValueCoding.m <title>EOKeyValueCoding</title>

   Copyright (C) 1996-2002, 2003 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: November 1996

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@oxymium.net>
   Date: January 2002

   Author: David Ayers <d.ayers@inode.at>
   Date: February 2003


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

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>
#include <EOControl/EONull.h>

#include <GNUstepBase/GSObjCRuntime.h>

#include "EOPrivate.h"

static BOOL    strictWO;
static BOOL initialized=NO;

static inline void
initialize(void)
{
  if (!initialized)
    {
      initialized=YES;
      strictWO = GSUseStrictWO451Compatibility(nil);
      GDL2PrivInit();
    }
}

/* This macro is only used locally in defined places so for the sake
   of efficiency, we don't use the do {} while (0) pattern.  */
#define INITIALIZE if (!initialized) initialize();


@implementation NSObject (_EOKeyValueCodingCompatibility)

- (void)GDL2KVCNSObjectICategoryID
{
}

+ (void)load
{
  GDL2_ActivateCategory("NSObject",
			@selector(GDL2KVCNSObjectICategoryID), YES);
}

- (void) unableToSetNilForKey: (NSString *)key
{
  [self unableToSetNullForKey: key];
}

/* See EODeprecated.h. */
+ (void) flushClassKeyBindings
{
}

/* See header file for documentation. */
+ (void) flushAllKeyBindings
{
}

/* See header file for documentation. */
- (void) unableToSetNullForKey: (NSString *)key
{
  [NSException raise: NSInvalidArgumentException
	       format: @"%@ -- %@ 0x%x: Given nil value to set for key \"%@\"",
	       NSStringFromSelector(_cmd), NSStringFromClass([self class]), 
	       self, key];
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


@implementation NSArray (EOKeyValueCoding)

- (void)GDL2KVCNSArrayICategoryID
{
}

+ (void)load
{
  GDL2_ActivateCategory("NSArray",
			@selector(GDL2KVCNSArrayICategoryID), YES);
}

/**
 * EOKeyValueCoding protocol<br/>
 * This overrides NSObjects implementation of this method.
 * Generally this method returns an array of objects
 * returned by invoking [NSObject-valueForKey:]
 * for each item in the receiver, substituting EONull for nil.
 * Keys formated like "@function.someKey" are resolved by invoking
 * [NSArray-computeFuncionWithKey:] "someKey" on the receiver.
 * If the key is omitted, the function will be called with nil.
 * The following functions are supported by default:
 * <list>
 *  <item>@sum   -> -computeSumForKey:</item>
 *  <item>@avg   -> -computeAvgForKey:</item>
 *  <item>@max   -> -computeMaxForKey:</item>
 *  <item>@min   -> -computeMinForKey:</item>
 *  <item>@count -> -computeCountForKey:</item>
 * </list>
 * Computational components generally expect a key to be passed to
 * the function.  This is not mandatory in which case 'nil' will be supplied.
 * (i.e. you may use "@myFuncWhichCanHandleNil" as a key.)
 * As a special case the key "count" does not actually invoke
 * computeCountForKey: on receiver but returns the number of objects of 
 * the receiver.<br/>
 * There is no special handling of EONull.  Therefore expect exceptions
 * on EONull not responding to decimalValue and compare: when the are
 * used with this mechanism. 
 */
- (id)valueForKey: (NSString *)key
{
  id result;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");
  if ([key isEqualToString: @"count"] || [key isEqualToString: @"@count"])
    {
      result = [NSDecimalNumber numberWithUnsignedInt: [self count]];
    }
  else if ([key hasPrefix:@"@"])
    {
      NSString *selStr;
      NSString *attrStr;
      SEL       sel;
      NSRange   r;

      r = [key rangeOfString:@"."];
      if (r.location == NSNotFound)
	{
	  r.length   = [key length] - 1; /* set length of key (w/o @) */
	  r.location = 1;                /* remove leading '@' */
	  attrStr = nil;
	}
      else
	{
	  r.length  = r.location - 1;    /* set length of key (w/o @) */
	  r.location = 1;                /* remove leading '@' */
                                         /* skip located '.' */
	  attrStr = [key substringFromIndex: NSMaxRange(r) + 1];
	}

      selStr = [NSString stringWithFormat: @"compute%@ForKey:",
		   [[key substringWithRange: r] initialCapitalizedString]];
      sel = NSSelectorFromString(selStr);
      NSAssert2(sel!=NULL,@"Invalid computational key: '%@' Selector: '%@'",
                key,
                selStr);

      result = [self performSelector: sel
		     withObject: attrStr];
    }
  else
    {
      result = [self resultsOfPerformingSelector: @selector(valueForKey:)
		     withObject: key
		     defaultResult: GDL2EONull];
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
  return result;
}

/**
 * EOKeyValueCoding protocol<br/>
 * Returns the object returned by invoking [NSObject-valueForKeyPath:]
 * on the object returned by invoking [NSObject-valueForKey:]
 * on the receiver with the first key component supplied by the key path,
 * with rest of the key path.<br/>
 * If the first component starts with "@", the first component includes the key
 * of the computational key component and as the form "@function.key".
 * If there is only one key component, this method invokes 
 * [NSObject-valueForKey:] in the receiver with that component.
 * Unlike the reference implementation GDL2 allows you to continue the keyPath
 * in a meaningful way after @count but the path must then contain a key as
 * the computational key structure implies.
 * (i.e. you may use "@count.self.decimalValue") The actual key "self" is
 * in fact ignored during the computation, but the formal structure must be
 * maintained.<br/>
 * It should be mentioned that the reference implementation
 * would return the result of "@count" independent
 * of any additional key paths, even if they were meaningless like
 * "@count.bla.strange".  GDL2 will raise, if the object returned by
 * valueForKey:@"count.bla" (which generally is an NSDecimalNumber) raises on
 * valueForKey:@"strange".
 */
- (id)valueForKeyPath: (NSString *)keyPath
{
  NSRange   r;
  id        result;

  EOFLOGObjectFnStartCond(@"EOKVC");
  r = [keyPath rangeOfString: @"."];
  if ([keyPath hasPrefix: @"@"] == YES
      && [keyPath isEqualToString: @"@count"] == NO
      && r.location != NSNotFound)
    {
      NSRange rr;
      unsigned length;

      length = [keyPath length];

      rr.location = NSMaxRange(r);
      rr.length   = length - rr.location;
      r = [keyPath rangeOfString: @"." 
		   options: 0
		   range: rr];
    }
    
  if (r.length == 0)
    {
      result = [self valueForKey: keyPath];
    }
  else
    {
      NSString *key  = [keyPath substringToIndex: r.location];
      NSString *path = [keyPath substringFromIndex: NSMaxRange(r)];

      result = [[self valueForKey: key] valueForKeyPath: path];
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
  return result;
}

/**
 * Iterates over the objects of the receiver send each object valueForKey:
 * with the parameter.  The decimalValue of the returned object is accumalted.
 * An empty array returns NSDecimalNumber 0.
 */
- (id)computeSumForKey: (NSString *)key
{
  NSDecimalNumber *ret=nil;
  NSDecimal        result, left, right;
  NSRoundingMode   mode;
  unsigned int     count;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");

  mode = [[NSDecimalNumber defaultBehavior] roundingMode];
  count = [self count];
  NSDecimalFromComponents(&result, 0, 0, NO);

  if (count>0)
    {
      unsigned int i=0;
      IMP oaiIMP = [self methodForSelector: @selector(objectAtIndex:)];
      for (i=0; i<count; i++)
        {
          left = result;
          right = [[GDL2ObjectAtIndexWithImp(self,oaiIMP,i) valueForKey: key] decimalValue];
          NSDecimalAdd(&result, &left, &right, mode);
        }
    };
        
  ret = [NSDecimalNumber decimalNumberWithDecimal: result];
  EOFLOGObjectFnStopCond(@"EOKVC");
  return ret;
}

/**
 * Iterates over the objects of the receiver send each object valueForKey:
 * with the parameter.  The decimalValue of the returned object is accumalted
 * and then divided by number of objects contained by the receiver as returned
 * by [NSArray-coung].  An empty array returns NSDecimalNumber 0.
 */
- (id)computeAvgForKey: (NSString *)key
{
  NSDecimalNumber *ret = nil;
  NSDecimal        result, left, right;
  NSRoundingMode   mode;
  unsigned int     count = 0;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");
  mode = [[NSDecimalNumber defaultBehavior] roundingMode];
  count = [self count];
  NSDecimalFromComponents(&result, 0, 0, NO);

  if (count>0)
    {
      unsigned int i=0;
      IMP oaiIMP = [self methodForSelector: @selector(objectAtIndex:)];
      
      for (i=0; i<count; i++)
        {
          left = result;
          right = [[GDL2ObjectAtIndexWithImp(self,oaiIMP,i) valueForKey: key] decimalValue];
          NSDecimalAdd(&result, &left, &right, mode);
        }
    };

  left  = result;
  NSDecimalFromComponents(&right, (unsigned long long) count, 0, NO);

  NSDecimalDivide(&result, &left, &right, mode);
        
  ret = [NSDecimalNumber decimalNumberWithDecimal: result];
  EOFLOGObjectFnStopCond(@"EOKVC");
  return ret;
}

- (id)computeCountForKey: (NSString *)key
{
  id result;

  EOFLOGObjectFnStartCond(@"EOKVC");
  result = [NSDecimalNumber numberWithUnsignedInt: [self count]];

  EOFLOGObjectFnStopCond(@"EOKVC");
  return result;
}

- (id)computeMaxForKey: (NSString *)key
{
  id result=nil;
  id resultVal=nil;
  unsigned int count=0;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");
  count     = [self count];

  if (count > 0)
    {
      unsigned int i=0;
      id           current = nil;
      id	   currentVal = nil;
      IMP          oaiIMP = [self methodForSelector: @selector(objectAtIndex:)];

      for(i=0; i<count && (resultVal == nil || resultVal == GDL2EONull); i++)
	{
	  result    = GDL2ObjectAtIndexWithImp(self,oaiIMP,i);
	  resultVal = [result valueForKey: key];
	}          
      for (; i<count; i++)
	{
	  current    = GDL2ObjectAtIndexWithImp(self,oaiIMP,i);
	  currentVal = [current valueForKey: key];

	  if (currentVal == nil || currentVal == GDL2EONull)
            continue;
	  
	  if ([(NSObject *)resultVal compare: currentVal] == NSOrderedAscending)
	    {
	      result    = current;
	      resultVal = currentVal;
	    }
	}
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
  return result;
}

- (id)computeMinForKey: (NSString *)key
{
  id result=nil;
  id resultVal=nil;
  unsigned int   count = 0;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");
  count     = [self count];

  if (count > 0)
    {
      id current=nil;
      id currentVal=nil;
      unsigned int i = 0;
      IMP oaiIMP = [self methodForSelector: @selector(objectAtIndex:)];

      for(i=0; i<count && (resultVal == nil || resultVal == GDL2EONull); i++)
	{
	  result    = GDL2ObjectAtIndexWithImp(self,oaiIMP,i);
	  resultVal = [result valueForKey: key];
	}          
      for (; i<count; i++)
	{
	  current    = GDL2ObjectAtIndexWithImp(self,oaiIMP,i);
	  currentVal = [current valueForKey: key];

	  if (currentVal == nil || currentVal == GDL2EONull) continue;

	  if ([(NSObject *)resultVal compare: currentVal] == NSOrderedDescending)
	    {
	      result    = current;
	      resultVal = currentVal;
	    }
	}
    }

  EOFLOGObjectFnStopCond(@"EOKVC");
  return result;
}

@end


@implementation NSDictionary (EOKeyValueCoding)

- (void)GDL2KVCNSDictionaryICategoryID
{
}

+ (void)load
{
  GDL2_ActivateCategory("NSDictionary",
			@selector(GDL2KVCNSDictionaryICategoryID), YES);
}

/**
 * Returns the object stored in the dictionary for this key.
 * Unlike Foundation, this method may return objects for keys other than
 * those explicitly stored in the receiver.  These special keys are
 * 'count', 'allKeys' and 'allValues'.
 * We override the implementation to account for these
 * special keys.
 */
- (id)valueForKey: (NSString *)key
{
  id value;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@",
  //                      key);

  value = [self objectForKey: key];

  if (!value)
    {
      if ([key isEqualToString: @"allValues"])
	{
#ifndef GNUSTEP
          static BOOL warnedValuesKeys = NO;
          if (warnedValuesKeys == NO)
            {
              warnedValuesKeys = YES;
              NSWarnMLog(@"Foundation does not return a value for the special 'allValues' key", "");
            }
#endif
	  value = [self allValues];
	}
      else if ([key isEqualToString: @"allKeys"])
	{
#ifndef GNUSTEP
          static BOOL warnedAllKeys = NO;
          if (warnedAllKeys == NO)
            {
              warnedAllKeys = YES;
              NSWarnMLog(@"Foundation does not return a value for the special 'allKeys' key", "");
            }
#endif
	  value = [self allKeys];
	}
      else if ([key isEqualToString: @"count"])
	{
#ifndef GNUSTEP
          static BOOL warnedCount = NO;
          if (warnedCount == NO)
            {
              warnedCount = YES;
              NSWarnMLog(@"Foundation does not return a value for the special 'count' key", "");
            }
#endif
	  value = [NSNumber numberWithUnsignedInt: [self count]];
	}
    }

  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@ value: %p (class=%@)",
  //                      key, value, [value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}

/**
 * Returns the object stored in the dictionary for this key.
 * Unlike Foundation, this method may return objects for keys other than
 * those explicitly stored in the receiver.  These special keys are
 * 'count', 'allKeys' and 'allValues'.
 * We do not simply invoke [NSDictionary-valueForKey:]
 * to avoid recursions in subclasses that might implement
 * [NSDictionary-valueForKey:] by calling [NSDictionary-storedValueForKey:]
 */
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
	{
	  value = [self allValues];
	}
      else if ([key isEqualToString: @"allKeys"])
	{
	  value = [self allKeys];
	}
      else if ([key isEqualToString: @"count"])
	{
	  value = [NSNumber numberWithUnsignedInt: [self count]];
	}
    }

  //EOFLOGObjectLevelArgs(@"EOKVC", @"key=%@ value: %p (class=%@)",
  //                      key, value, [value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}

/**
 * First checks whether the entire keyPath is contained as a key
 * in the receiver before invoking super's implementation.
 * (The special quoted key handling will probably be moved
 * to a GSWDictionary subclass to be used by GSWDisplayGroup.)
 */
- (id)valueForKeyPath: (NSString*)keyPath
{
  id  value = nil;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPath=\"%@\"",
  //                      keyPath);

  if ([keyPath hasPrefix: @"'"] && strictWO == NO) //user defined composed key 
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
      /*
       * Return super valueForKeyPath: only 
       * if there's no object for entire key keyPath
       */
      value = [self objectForKey: keyPath];

      EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ tmpValue: %p (class=%@)",
                   keyPath,value,[value class]);

      if (!value)
        value = [super valueForKeyPath: keyPath];
    }

  //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ value: %p (class=%@)",
  //             keyPath,value,[value class]);
  EOFLOGObjectFnStopCond(@"EOKVC");

  return value;
}

/**
 * First checks whether the entire keyPath is contained as a key
 * in the receiver before invoking super's implementation.
 * (The special quoted key handling will probably be moved
 * to a GSWDictionary subclass to be used by GSWDisplayGroup.)
 */
- (id)storedValueForKeyPath: (NSString*)keyPath
{
  id value = nil;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=\"%@\"",
  //                      keyPath);

  if ([keyPath hasPrefix: @"'"] && strictWO == NO) //user defined composed key 
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
      /*
       * Return super valueForKeyPath: only 
       * if there's no object for entire key keyPath
       */
      value = [self objectForKey: keyPath];

      //EOFLOGObjectLevelArgs(@"EOKVC",@"keyPath=%@ tmpValue: %p (class=%@)",
      //             keyPath,value,[value class]);

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

@implementation NSMutableDictionary (EOKVCGNUstepExtensions)

- (void)GDL2KVCNSMutableDictionaryICategoryID
{
}

+ (void)load
{
  GDL2_ActivateCategory("NSMutableDictionary",
			@selector(GDL2KVCNSMutableDictionaryICategoryID), YES);
}

/**
 * Method to augment the NSKeyValueCoding implementation
 * to account for added functionality such as quoted key paths.
 * (The special quoted key handling will probably be moved
 * to a GSWDictionary subclass to be used by GSWDisplayGroup.
 * this method then becomes obsolete.)
 */
- (void)smartTakeValue: (id)value 
            forKeyPath: (NSString*)keyPath
{
  [self takeValue:value
        forKeyPath:keyPath
        isSmart:YES];
}

/**
 * Overrides gnustep-base and Foundations implementation
 * to account for added functionality such as quoted key paths.
 * (The special quoted key handling will probably be moved
 * to a GSWDictionary subclass to be used by GSWDisplayGroup.
 * this method then becomes obsolete.)
 */
- (void)takeValue: (id)value
       forKeyPath: (NSString *)keyPath
{
  [self takeValue:value
        forKeyPath:keyPath
        isSmart:NO];
}

/**
 * Support method to augment the NSKeyValueCoding implementation
 * to account for added functionality such as quoted key paths.
 * (The special quoted key handling will probably be moved
 * to a GSWDictionary subclass to be used by GSWDisplayGroup.
 * this method then becomes obsolete.)
 */
- (void)takeValue: (id)value
       forKeyPath: (NSString *)keyPath
          isSmart: (BOOL)smartFlag
{
  EOFLOGObjectFnStartCond(@"EOKVC");
  //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPath=\"%@\"",
  //                      keyPath);

  INITIALIZE;

  if ([keyPath hasPrefix: @"'"] && strictWO == NO) //user defined composed key 
    {
      NSMutableArray *keyPathArray = [[[[keyPath stringByDeletingPrefix: @"'"]
					 componentsSeparatedByString: @"."]
					mutableCopy] autorelease];
      NSMutableString *key = [NSMutableString string];

      unsigned keyPathArrayCount = [keyPathArray count];

      //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

      while (keyPathArrayCount > 0)
        {
          id tmpKey;

          //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

          tmpKey = RETAIN([keyPathArray objectAtIndex: 0]);
          //EOFLOGObjectLevelArgs(@"EOKVC", @"tmpKey=%@", tmpKey);

          [keyPathArray removeObjectAtIndex: 0];
          keyPathArrayCount--;

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

      if (keyPathArrayCount > 0)
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
      if (value == nil)
	{
	  [self removeObjectForKey: keyPath];
	}
      else
	{
	  [self setObject: value forKey: keyPath];
	}
     }

  EOFLOGObjectFnStopCond(@"EOKVC");
}

/**
 * Calls [NSMutableDictionary-setObject:forKey:] using the full keyPath
 * as a key, if the value is non nil.  Otherwise calls
 * [NSDictionary-removeObjectForKey:] with the full keyPath.
 * (The special quoted key handling will probably be moved
 * to a GSWDictionary subclass to be used by GSWDisplayGroup.)
 */
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

      int keyPathArrayCount=[keyPathArray count];

      //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

      while (keyPathArrayCount > 0)
        {
          id tmpKey;

          //EOFLOGObjectLevelArgs(@"EOKVC", @"keyPathArray=%@", keyPathArray);

          tmpKey = [keyPathArray objectAtIndex: 0];
          //EOFLOGObjectLevelArgs(@"EOKVC", @"tmpKey=%@", tmpKey);

          [keyPathArray removeObjectAtIndex: 0];
          keyPathArrayCount--;

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

      if (keyPathArrayCount > 0)
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

@implementation NSObject (EOKVCGNUstepExtensions)

/**
 * This is a GDL2 extension.  This convenience method iterates over
 * the supplied keyPaths and determines the corresponding values by invoking
 * valueForKeyPath: on the receiver.  The results are returned an NSDictionary
 * with the keyPaths as keys and the returned values as the dictionary's
 * values.  If valueForKeyPath: returns nil, it is replaced by the shared
 * EONull instance.
 */
- (NSDictionary *)valuesForKeyPaths: (NSArray *)keyPaths
{
  NSDictionary *values = nil;
  int i;
  int n;
  NSMutableArray *newKeyPaths;
  NSMutableArray *newVals;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");

  n = [keyPaths count];
  newKeyPaths = AUTORELEASE([[NSMutableArray alloc] initWithCapacity: n]);
  newVals = AUTORELEASE([[NSMutableArray alloc] initWithCapacity: n]);

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
          NSLog(@"KVC:%@ EXCEPTION %@",
		NSStringFromSelector(_cmd), localException);
          NSDebugMLog(@"KVC:%@ EXCEPTION %@",
		NSStringFromSelector(_cmd), localException);
          [localException raise];
        }
      NS_ENDHANDLER;

      if (val == nil)
	{
	  val = GDL2EONull;
	}

      [newKeyPaths addObject: keyPath];
      [newVals addObject: val];
    }
  
  values = [NSDictionary dictionaryWithObjects: newVals
			 forKeys: newKeyPaths];

  EOFLOGObjectFnStopCond(@"EOKVC");

  return values;
}

/**
 * This is a GDL2 extension.  This convenience method retrieves the object
 * obtained by invoking valueForKey: on each path component until the one
 * next to the last.  It then invokes takeStoredValue:forKey: on that object
 * with the last path component as the key.
 */
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

/**
 * This is a GDL2 extension.  This convenience method retrieves the object
 * obtained by invoking valueForKey: on each path component until the one
 * next to the last.  It then invokes storedValue:forKey: on that object
 * with the last path component as the key, returning the result.
 */
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

/**
 * This is a GDL2 extension.  This convenience method iterates over
 * the supplied keyPaths and determines the corresponding values by invoking
 * storedValueForKeyPath: on the receiver.  The results are returned an
 * NSDictionary with the keyPaths as keys and the returned values as the
 * dictionary's values.  If storedValueForKeyPath: returns nil, it is replaced
 * by the shared EONull instance.
 */
- (NSDictionary *)storedValuesForKeyPaths: (NSArray *)keyPaths
{
  NSDictionary *values = nil;
  int i, n;
  NSMutableArray *newKeyPaths = nil;
  NSMutableArray *newVals = nil;

  INITIALIZE;

  EOFLOGObjectFnStartCond(@"EOKVC");

  n = [keyPaths count];

  newKeyPaths = [[[NSMutableArray alloc] initWithCapacity: n] 
			      autorelease];
  newVals = [[[NSMutableArray alloc] initWithCapacity: n] 
			      autorelease];

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
	val = GDL2EONull;
      
      [newKeyPaths addObject: keyPath];
      [newVals addObject: val];
    }
  
  values = [NSDictionary dictionaryWithObjects: newVals
			 forKeys: newKeyPaths];
  EOFLOGObjectFnStopCond(@"EOKVC");

  return values;
}

/**
 * This is a GDL2 extension.  Simply invokes takeValue:forKey:.
 * This method provides a hook for EOGenericRecords KVC implementation,
 * which takes relationship definitions into account.
 */
- (void)smartTakeValue: (id)anObject 
                forKey: (NSString *)aKey
{
  [self takeValue: anObject
        forKey: aKey];
}

/**
 * This is a GDL2 extension.  This convenience method invokes
 * smartTakeValue:forKeyPath on the object returned by valueForKey: with
 * the first path component. 
 * obtained by invoking valueForKey: on each path component until the one
 * next to the last.  It then invokes storedValue:forKey: on that object
 * with the last path component as the key, returning the result.
 */
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


@end
