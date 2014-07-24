/** 
   EONSAddOns.m <title>EONSAddOns</title>

   Copyright (C) 2000-2002,2003,2004,2005,2006,2007,2010
   Free Software Foundation, Inc.

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
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif
#include <GNUstepBase/Unicode.h>
#include <GNUstepBase/GSLock.h>

#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <limits.h>
#include <assert.h>

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
      if (local_lock == nil)
	{
	  NSRecursiveLock *l = [GSLazyRecursiveLock new];
	  GDL2_AssignAtomicallyIfNil(&local_lock, l);
	}
      [local_lock lock];

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
  assert(sup!=Nil);
  assert(cls!=Nil);
  GSObjCAddClassOverride(sup, cls);
}

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
      IMP oaiIMP=NULL;
      NSUInteger count = [array count];
      results = [NSMutableArray array];
      if (count>0)
	{
	  NSUInteger i=0;
	  for(i = 0; i < count; i++)
	    {
	      id object = GDL2_ObjectAtIndexWithImpPtr(array,&oaiIMP,i);
	      id result = [self performSelector: sel
				withObject: object];
	      if (!result)
		result = defaultResult;
	      
	      NSAssert3(result,
			@"%@: No result for object %@ resultOfPerformingSelector:\"%s\" withEachObjectInArray:",
			self,
			object,
			sel_getName(sel));
	      
	      [results addObject: result];
	    }
	}
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
  NSUInteger count = [self count];

  if (count>0)
    {
      IMP oaiIMP=NULL;
      NSUInteger i =0;
      for(i = 0; i < count; i++)
	{
	  id object = GDL2_ObjectAtIndexWithImpPtr(self,&oaiIMP,i);
	  id result = [object performSelector: sel];
	  
	  if (!result)
	    result = defaultResult;
	  
	  NSAssert3(result,
		    @"%@: No result for object %@ resultOfPerformingSelector:\"%s\"",
		    self,
		    object,
		    sel_getName(sel));
	  
	  [results addObject: result];
	}
    }
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
  NSUInteger count = [self count];
  if (count>0)
    {
      IMP oaiIMP=NULL;
      NSUInteger i=0;
      for(i = 0; i < count; i++)
        {
	  id object = GDL2_ObjectAtIndexWithImpPtr(self,&oaiIMP,i);
          id result = [object performSelector: sel
			      withObject: obj1];

          if (!result)
            result = defaultResult;

          NSAssert3(result,
                    @"%@: No result for object %@ resultOfPerformingSelector:\"%s\"",
                    self,
                    object,
                    sel_getName(sel));

          [results addObject: result];
        }
    }

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
  NSUInteger count = [self count];

  if (count>0)
    {
      IMP oaiIMP=NULL;
      NSUInteger i=0;
      for(i = 0; i < count; i++)
        {
	  id object = GDL2_ObjectAtIndexWithImpPtr(self,&oaiIMP,i);
          id result = [object performSelector: sel
			      withObject: obj1
			      withObject: obj2];

          if (!result)
            result = defaultResult;

          NSAssert3(result,
                    @"%@: No result for object %@ resultOfPerformingSelector:\"%s\"",
                    self,
                    object,
                    sel_getName(sel));

          [results addObject: result];
        }
    }

  return results;
}

- (NSArray*)arrayExcludingObjectsInArray: (NSArray*)array
{
  //Verify: mutable/non mutable,..
  NSArray *result = nil;
  NSUInteger selfCount = [self count];

  if (selfCount > 0) //else return nil
    {
      NSUInteger arrayCount = [array count];

      if (arrayCount == 0) //Nothing to exclude ?
        result = self;
      else
        {
          NSUInteger i = 0;

          for (i = 0; i < selfCount; i++)
            {
              id object = [self objectAtIndex: i];
              NSUInteger index = [array indexOfObjectIdenticalTo: object];

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

- (NSArray *)arrayExcludingObject: (id)_object
{
  //Verify: mutable/non mutable,..
  NSArray *result = nil;
  NSUInteger selfCount = [self count];

  if (selfCount > 0 && _object) //else return nil
    {
      NSUInteger i=0;
      IMP oaiIMP=NULL;

      for (i = 0; i < selfCount; i++)
        {
          id object =  GDL2_ObjectAtIndexWithImpPtr(self,&oaiIMP,i);

          if (object != _object)
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
  NSUInteger count = [self count];

  if (count > 0)
    {
      IMP oaiIMP=NULL;
      NSUInteger i = 0;
      NSMutableArray* tmpArray = [NSMutableArray arrayWithCapacity: count];

      for (i = 0; i < count; i++)
        {
          id o = GDL2_ObjectAtIndexWithImpPtr(self,&oaiIMP,i);

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
  return ![NSArray diffOldArray:self
		   newArray:array
		   returnsRemovedValues:NULL
		   addedValues:NULL];
}

#define    EO_MAX_OBJECTS_FROM_STACK      64
/**
 * Macro to manage memory for chunks of code that need to work with
 * arrays of items.  Use this to start the block of code using
 * the array and EO_ENDITEMBUF() to end it.  The idea is to ensure that small
 * arrays are allocated on the stack (for speed), but large arrays are
 * allocated from the heap (to avoid stack overflow).
 */
#define EO_BEGINITEMBUF(P, S, T) { \
  T P ## _ibuf[(S) <= EO_MAX_OBJECTS_FROM_STACK ? (S) : 0]; \
  T *P ## _base = ((S) <= EO_MAX_OBJECTS_FROM_STACK) ? P ## _ibuf \
    : (T*)NSZoneMalloc(NSDefaultMallocZone(), (S) * sizeof(T)); \
  T *(P) = P ## _base;

/**
 * Macro to manage memory for chunks of code that need to work with
 * arrays of items.  Use EO_BEGINITEMBUF() to start the block of code using
 * the array and this macro to end it.
 */
#define EO_ENDITEMBUF(P) \
  if (P ## _base != P ## _ibuf) \
    NSZoneFree(NSDefaultMallocZone(), P ## _base); \
  }

/**
 * Macro to manage memory for chunks of code that need to work with
 * arrays of objects.  Use this to start the block of code using
 * the array and EO_ENDIDBUF() to end it.  The idea is to ensure that small
 * arrays are allocated on the stack (for speed), but large arrays are
 * allocated from the heap (to avoid stack overflow).
 */
#define EO_BEGINIDBUF(P, S) EO_BEGINITEMBUF(P, S, id)

/**
 * Macro to manage memory for chunks of code that need to work with
 * arrays of objects.  Use EO_BEGINIDBUF() to start the block of code using
 * the array and this macro to end it.
 */
#define EO_ENDIDBUF(P) EO_ENDITEMBUF(P)

//Returns YES if the 2 arrays don't contains exactly identical objects (compared by address) (i.e. only the order may change)
//Optimized for end addition/removing
+(BOOL)diffOldArray:(NSArray*)oldArray
	   newArray:(NSArray*)newArray
returnsRemovedValues:(NSArray**)removedValues
	addedValues:(NSArray**)addedValues
{
  BOOL isDiff=NO;
  if (removedValues!=NULL)
    *removedValues=nil;
  if (addedValues!=NULL)
    *addedValues=nil;
  if (oldArray==newArray)
    {
      //Same array: do nothing
      isDiff=NO;
    }
  else
    {
      NSUInteger oldArrayCount = [oldArray count];
      NSUInteger newArrayCount = [newArray count];
      if (oldArrayCount==0)
	{
	  if (newArrayCount==0) // oldArrayCount==0 && newArrayCount==0
	    {
	      //same are empty
	      isDiff=NO;
	    }
	  else // oldArrayCount==0 && newArrayCount>0
	    {
	      //No old array values
	      isDiff=YES;
	      if (addedValues!=NULL)
		{
		  if ([newArray isKindOfClass:GDL2_NSMutableArrayClass])
		    *addedValues=AUTORELEASE([newArray shallowCopy]);
		  else
		    *addedValues=AUTORELEASE(RETAIN(newArray));
		}
	    }
	}
      else if (newArrayCount==0) // oldArrayCount>0 && newArrayCount==0
	{
	  //no new array values
	  isDiff=YES;
	  if (removedValues!=NULL)
	    {
	      if ([oldArray isKindOfClass:GDL2_NSMutableArrayClass])
		*removedValues=AUTORELEASE([oldArray shallowCopy]);
	      else
		*removedValues=AUTORELEASE(RETAIN(oldArray));
	    }
	}
      else // oldArrayCount>0 && newArrayCount>0
	{
	  //Start deep work
	  NSUInteger minCount=(oldArrayCount<newArrayCount ? oldArrayCount : newArrayCount);
	  EO_BEGINIDBUF(oldObjects,oldArrayCount);
	  EO_BEGINIDBUF(newObjects,newArrayCount);
	  [oldArray getObjects: oldObjects];
	  [newArray getObjects: newObjects];

	  //Find for 1st diff
	  NSUInteger i=0;
	  NSUInteger start=minCount;
	  for(i=0;i<minCount;i++)
	    {
	      if (oldObjects[i]!=newObjects[i])
		{
		  start=i;
		  break;
		}
	    }
	  if (start==minCount
	      && oldArrayCount==newArrayCount)
	    {
	      //No diff found at the begining and same array size
	      isDiff=NO;
	    }
	  else
	    {
	      //NSLog(@"X DIFF ARRAY start at %d",start);
	      NSUInteger maxCount=(oldArrayCount>newArrayCount ? oldArrayCount : newArrayCount);
	      maxCount-=start;
	      EO_BEGINIDBUF(tmpObjects,maxCount);
	      
	      // Find removed values
	      NSUInteger oi=0;
	      NSUInteger ni=0;
	      i=0;
	      for(oi=start;oi<oldArrayCount;oi++)
		{
		  id o=oldObjects[oi];
		  for(ni=start;ni<newArrayCount && newObjects[ni]!=o;ni++);
		  NSCAssert(i<maxCount,@"Pb");
		  if (ni>=newArrayCount)//Not found ?
		    tmpObjects[i++]=o;
		}
	      if (i>0)
		{
		  isDiff=YES;
		  if (removedValues!=NULL)
		    {
		      *removedValues=[NSArray arrayWithObjects:tmpObjects
					      count:i];
		    }
		}

	      // Find added values
	      i=0;
	      for(ni=start;ni<newArrayCount;ni++)
		{
		  id n=newObjects[ni];
		  for(oi=start;oi<oldArrayCount && oldObjects[oi]!=n;oi++);
		  NSCAssert(i<maxCount,@"Pb");
		  if (oi>=oldArrayCount)//Not found ?
		    tmpObjects[i++]=n;
		}
	      if (i>0)
		{
		  isDiff=YES;
		  if (addedValues!=NULL)
		    {
		      *addedValues=[NSArray arrayWithObjects:tmpObjects
					    count:i];
		    }
		}
	      EO_ENDIDBUF(tmpObjects);
	    }
	  EO_ENDIDBUF(newObjects);
	  EO_ENDIDBUF(oldObjects);
	}
    }
  return isDiff;
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
  NSUInteger length = [self length];

  chars = NSZoneMalloc(NSDefaultMallocZone(),length * sizeof(unichar));
  [self getCharacters: chars];
  chars[0]=uni_toupper(chars[0]);

  
  // CHECKME: does this really free how we want it? -- dw
  
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

-(unsigned long long)unsignedLongLongValue
{
  return strtoull([self lossyCString],NULL,10);
};

@end

@implementation NSObject (PerformSelect3)

- (id) performSelector: (SEL)selector
	   withPointer: (void*) ptr
{
  IMP msg;

  if (selector == 0)
    [NSException raise: NSInvalidArgumentException
                format: @"%@ null selector given", NSStringFromSelector(_cmd)];
  
  msg = class_getMethodImplementation([self class], selector);
  if (!msg)
    {
      [NSException raise: NSGenericException
                  format: @"invalid selector passed to %s", sel_getName(_cmd)];
      return nil;
    }

  return (*msg)(self, selector, ptr);
}

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
  
  msg = class_getMethodImplementation([self class], selector);
  if (!msg)
    {
      [NSException raise: NSGenericException
                  format: @"invalid selector passed to %s", sel_getName(_cmd)];
      return nil;
    }

  return (*msg)(self, selector, object1, object2, object3);
}

@end

@implementation NSMutableDictionary (EOAdditions)

/**
 * Creates an autoreleased mutable dictionary based on otherDictionary
 * but only with keys from the keys array.
 */

+ (NSMutableDictionary *) dictionaryWithDictionary:(NSDictionary *)otherDictionary
                                              keys:(NSArray*)keys
{
  NSMutableDictionary* mDict=nil;
  if (keys==nil)
    {
      mDict=[NSMutableDictionary dictionary];
    }
  else
    {
      NSUInteger            keyCount = [keys count];
      if (keyCount==0)
	{
	  mDict=[NSMutableDictionary dictionary];
	}
      else
	{
	  IMP oaiIMP=NULL;
	  NSUInteger            i = 0;
	  mDict = [NSMutableDictionary dictionaryWithCapacity:keyCount];
      
	  for (; i < keyCount; i++)
	    {
	      NSString * key = GDL2_ObjectAtIndexWithImpPtr(keys,&oaiIMP,i);
	      id         value = [otherDictionary valueForKey:key];
	      
	      if (!value)
		value = GDL2_EONull;

	      [mDict setObject:value
		     forKey:key];
	    }
	}
    }
  return mDict;
}

// 	"translateFromKeys:toKeys:",

- (void) translateFromKeys:(NSArray *) currentKeys
                    toKeys:(NSArray *) newKeys
{
  NSUInteger       count = [currentKeys count];

  if (count != [newKeys count])
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"%s key arrays must contain equal number of keys", __PRETTY_FUNCTION__];
    }
  else
    {
      IMP oaiIMP=NULL;
      NSMutableArray* buffer = [NSMutableArray arrayWithCapacity:count];
      NSUInteger      i = 0;
      NSString       * nullPlaceholder = @"__EOAdditionsDummy__";
  
      for (i = 0; i < count; i++)
	{
	  id key = GDL2_ObjectAtIndexWithImpPtr(currentKeys,&oaiIMP,i);
	  id value = [self objectForKey:key];
	  
	  if (!value)
	    {
	      value = nullPlaceholder;
	      [buffer addObject:value];
	    }
	  else
	    {
	      [buffer addObject:value];
	      [self removeObjectForKey:key];
	    }
	}
  
      [self removeAllObjects];
      
      for (i = 0; i < count; i++)
	{
	  id value = [buffer objectAtIndex:i];
	  if(value != nullPlaceholder)
	    {
	      [self setObject:value 
		    forKey:[newKeys objectAtIndex:i]];
	    }
	}
    }
}

/**
 * Override self values with values from dict for keys
 */
-(void)overrideEntriesWithObjectsFromDictionary:(NSDictionary*)dict
					forKeys:(NSArray*)keys
{
  NSUInteger keysCount=[keys count];
  if (keysCount>0)
    {
      IMP oaiIMP=NULL;
      NSUInteger i=0;
      for(i=0;i<keysCount;i++)
        {
	  id key = GDL2_ObjectAtIndexWithImpPtr(keys,&oaiIMP,i);
	  id value = [dict objectForKey:key];
	  if (value != nil)
	    {
	      [self setObject:value
		    forKey:key];
	    }
        }
    }
}

@end

@implementation NSDictionary (EOAdditions)

- (BOOL) containsAnyNullObject
{
  NSArray    * values = [self allValues];
  NSUInteger   count = [values count];
  if (count>0)
    {
      IMP oaiIMP=NULL;
      NSUInteger   i = 0;
      for (; i < count; i++)
	{
	  if (GDL2_ObjectAtIndexWithImpPtr(values,&oaiIMP,i) == GDL2_EONull)
	    return YES;
	}
    }
  return NO;
}

+ (NSDictionary*) dictionaryWithNullValuesForKeys:(NSArray*) keys
{
  NSMutableDictionary * dict = nil;
  NSUInteger count = [keys count];

  if (count > 0)
    {
      IMP oaiIMP=NULL;
      NSUInteger i = 0;
      dict = [NSMutableDictionary dictionaryWithCapacity:count];
      for (i = 0; i < count; i++)
	{
	  NSString * key = GDL2_ObjectAtIndexWithImpPtr(keys,&oaiIMP,i);
	  [dict setObject:GDL2_EONull
		forKey: key];
	}    
    }
  return dict;
}

@end

@implementation NSString (EORelationshipPath)

- (NSString*) relationshipPathByDeletingFirstComponent
{
  NSRange r=[self rangeOfString:@"."];
  if (r.length==0)
    return nil;
  else
    return [self substringFromIndex:r.location+r.length];
}

- (NSString*) firstComponentFromRelationshipPath
{
  NSRange r=[self rangeOfString:@"."];
  if (r.length==0)
    return nil;
  else
    return [self substringToIndex:r.location];
}

- (NSString*) relationshipPathByDeletingLastComponent;
{
  NSRange r=[self rangeOfString:@"."
		  options:NSBackwardsSearch];
  if (r.length==0)
    return nil;
  else
    return [self substringToIndex:r.location];
}

- (NSString*) lastComponentFromRelationshipPath
{
  NSRange r=[self rangeOfString:@"."
		  options:NSBackwardsSearch];
  if (r.length==0)
    return nil;
  else
    return [self substringFromIndex:r.location+r.length];
}

- (BOOL) relationshipPathIsMultiHop
{
  NSRange r=[self rangeOfString:@"."];
  return (r.length>0 ? YES : NO);
}


@end

