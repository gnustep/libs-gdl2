/** 
   EONSAddOns.m <title>EONSAddOns</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

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
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#include <GNUstepBase/GSObjCRuntime.h>
#endif
#include <GNUstepBase/Unicode.h>
#include <GNUstepBase/GSLock.h>

#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <limits.h>

#include "EOPrivate.h"

@class GDL2KVCNSObject;
@class GDL2KVCNSArray;
@class GDL2KVCNSDictionary;
@class GDL2KVCNSMutableDictionary;
@class GDL2CDNSObject;

static NSRecursiveLock *local_lock = nil;
static BOOL GSStrictWO451Flag = NO;

BOOL
GSUseStrictWO451Compatibility (NSString *key)
{
  static BOOL read = NO;
  if (read == NO)
    {
      [GS_INITIALIZED_LOCK(local_lock, GSLazyRecursiveLock) lock];

      NS_DURING
        if (read == NO)
          {
            NSUserDefaults *defaults;
            defaults = [NSUserDefaults standardUserDefaults];
            GSStrictWO451Flag
              = [defaults boolForKey: @"GSUseStrictWO451Compatibility"];
            read = YES;
          }
      NS_HANDLER
	[local_lock unlock];
        [localException raise];
      NS_ENDHANDLER

      [local_lock unlock];
    }
  return GSStrictWO451Flag;
}

void
GDL2_DumpMethodList(Class cls, SEL sel, BOOL isInstance)
{
/*
  void *iterator = 0;
  GSMethodList mList;
  
  fprintf(stderr,"List for :%s %s (inst:%d)\n",
	      GSNameFromClass(cls), GSNameFromSelector(sel), isInstance);
  while ((mList = GSMethodListForSelector(cls, sel,
					  &iterator, isInstance)))
    {
      GSMethod meth = GSMethodFromList(mList, sel, NO);
      IMP imp = meth->method_imp;

      fprintf(stderr,"List: %p Meth: %p Imp: %p\n",
	      mList, meth, imp);
    }
  fprintf(stderr,"List finished\n"); fflush(stderr);
*/
}

void
GDL2_Activate(Class sup, Class cls)
{
  GSObjCAddClassOverride(sup, cls);
}

void
GDL2_ActivateAll(void)
{
  /* EOKeyValueCoding */
  GDL2_Activate([NSObject class], [GDL2KVCNSObject class]);
  GDL2_Activate([NSArray class], [GDL2KVCNSArray class]);
  GDL2_Activate([NSDictionary class], [GDL2KVCNSDictionary class]);
  GDL2_Activate([NSMutableDictionary class], 
    [GDL2KVCNSMutableDictionary class]);

  /* EOClassDescription */
  GDL2_Activate([NSObject class], [GDL2CDNSObject class]);

}

@implementation NSObject (GDL2_Activate)
+(void)load
{
  GDL2_ActivateAll();
}
@end

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
      volatile id object = nil;

      results = [NSMutableArray array];

      //OPTIMIZE
      NS_DURING
        {
          for(i = 0; i < count; i++)
            {
              id result;

              object = [array objectAtIndex: i];
              result = [self performSelector: sel
			     withObject: (id)object];
              if (!result)
                result = defaultResult;

              NSAssert3(result,
                        @"%@: No result for object %@ resultOfPerformingSelector:\"%s\" withEachObjectInArray:",
                        self,
                        object,
                        sel_get_name(sel));

              [results addObject: result];
            }
        }
      NS_HANDLER
        {
          NSWarnLog(@"object %p %@ may not support %@",
                    object,
                    [object class],
                    NSStringFromSelector(sel));
          NSLog(@"%@ %@",localException,[localException userInfo]);
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
  volatile id object = nil;

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
  volatile id object = nil;

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
  volatile id object = nil;

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

- (NSArray *)arrayExcludingObject: (id)object
{
  //Verify: mutable/non mutable,..
  NSArray *result = nil;
  unsigned int selfCount = [self count];

  if (selfCount > 0 && object) //else return nil
    {
      int i;

      for (i = 0; i < selfCount; i++)
        {
          id object = [self objectAtIndex: i];

          if (object != object)
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

@interface NSObject (EOCOmpareOnNameSupport)
- (NSString *)name;
@end
@implementation NSObject (EOCompareOnName)

- (NSComparisonResult)eoCompareOnName: (id)object
{
  return [[self name] compare: [(NSObject *)object name]];
}

@end

@implementation NSString (YorYes)

- (BOOL)isYorYES
{
  return ([self isEqual: @"Y"] || [self isEqual: @"YES"]);
}

@end

@implementation NSString (VersionParsing)
- (int)parsedFirstVersionSubstring
{
  NSString       *shortVersion;
  NSScanner      *scanner;
  NSCharacterSet *characterSet;
  NSArray        *versionComponents;
  NSString       *component;
  int             count, i;
  int             version = 0;
  int             factor[] = { 10000, 100, 1 };

  scanner = [NSScanner scannerWithString: self];
  characterSet 
    = [NSCharacterSet characterSetWithCharactersInString: @"0123456789."];

  [scanner setCharactersToBeSkipped: [characterSet invertedSet]];
  [scanner scanCharactersFromSet: characterSet intoString: &shortVersion];

  versionComponents = [shortVersion componentsSeparatedByString:@"."];
  count = [versionComponents count];

  for (i = 0; (i < count) && (i < 3); i++)
    {
      component = [versionComponents objectAtIndex: i];
      version += [component intValue] * factor[i];
    }

  return version;
}
@end

@implementation NSString (Extensions)
- (NSString *)initialCapitalizedString
{
  unichar *chars;
  unsigned int length = [self length];

  chars = objc_malloc(length * sizeof(unichar));
  [self getCharacters: chars];
  chars[0]=uni_toupper(chars[0]);

  return AUTORELEASE([[NSString alloc] initWithCharactersNoCopy: chars
				       length: length
				       freeWhenDone: YES]);
}
@end

@implementation NSString (StringToNumber)
-(unsigned int)unsignedIntValue
{
  long v=atol([self lossyCString]);
  if (v<0 || v >UINT_MAX)
    {
      [NSException raise: NSInvalidArgumentException
                   format: @"%ld is not an unsigned int",v];
    };
  return (unsigned int)v;
};
-(short)shortValue
{
  int v=atoi([self lossyCString]);
  if (v<SHRT_MIN || v>SHRT_MAX)
    {
      [NSException raise: NSInvalidArgumentException
                   format: @"%d is not a short",v];
    };
  return (short)v;
};
-(unsigned short)unsignedShortValue
{
  int v=atoi([self lossyCString]);
  if (v<0 || v>USHRT_MAX)
    {
      [NSException raise: NSInvalidArgumentException
                   format: @"%d is not an unsigned short",v];
    };
  return (unsigned short)v;
};

-(long)longValue
{
  return atol([self lossyCString]);
};

-(unsigned long)unsignedLongValue
{
  long long v=atoll([self lossyCString]);
  if (v<0 || v>ULONG_MAX)
    {
      [NSException raise: NSInvalidArgumentException
                   format: @"%lld is not an unsigned long",v];
    };
  return (unsigned long)v;
};

-(long long)longLongValue
{
  long long v=atoll([self lossyCString]);
  return v;
};

-(unsigned long long)unsignedLongLongValue
{
  return strtoull([self lossyCString],NULL,10);
};

@end

@implementation NSObject (PerformSelect3)
//Ayers: Review (Do we really need this?)
/**
 * Causes the receiver to execute the method implementation corresponding
 * to aSelector and returns the result.<br />
 * The method must be one which takes three arguments and returns an object.
 * <br />Raises NSInvalidArgumentException if given a null selector.
 */
- (id) performSelector: (SEL)selector
            withObject: (id) object1
            withObject: (id) object2
            withObject: (id) object3
{
  IMP msg;

  if (selector == 0)
    [NSException raise: NSInvalidArgumentException
                format: @"%@ null selector given", NSStringFromSelector(_cmd)];
  
  msg = get_imp(GSObjCClass(self), selector);
  if (!msg)
    {
      [NSException raise: NSGenericException
                  format: @"invalid selector passed to %s", sel_get_name(_cmd)];
      return nil;
    }

  return (*msg)(self, selector, object1, object2, object3);
}

@end
