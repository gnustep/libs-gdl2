/** 
   EOPrivate.m <title>EOPrivate: various definitions</title>

   Copyright (C) 2005 Free Software Foundation, Inc.

   Date: Jan 2005

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

#include <Foundation/Foundation.h>
#define GSI_ARRAY_TYPES GSUNION_OBJ
#define GSI_ARRAY_NO_RETAIN 1
#define GSI_ARRAY_NO_RELEASE 1
#include <GNUstepBase/GSIArray.h>

#ifndef GNUSTEP
#include <GNUstepBase/Additions.h>
#endif

#include <EOControl/EOEditingContext.h>
#include <EOControl/EOFault.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EONull.h>

#include "EOPrivate.h"

// ==== Classes ====
Class GDL2_NSArrayClass=Nil;
Class GDL2_NSMutableArrayClass=Nil;
Class GDL2_NSDictionaryClass=Nil;
Class GDL2_NSMutableDictionaryClass=Nil;
Class GDL2_NSStringClass=Nil;
Class GDL2_NSNumberClass=Nil;
Class GDL2_NSDecimalNumberClass=Nil;
Class GDL2_NSCalendarDateClass=Nil;
Class GDL2_NSDateClass=Nil;
Class GDL2_NSAutoreleasePoolClass=Nil;
Class GDL2_NSDataClass=Nil;
Class GDL2_EOFaultClass=Nil;
Class GDL2_MKKDClass=Nil;
Class GDL2_EOMKKDInitializerClass=Nil;
Class GDL2_EOEditingContextClass=Nil;

// ==== IMPs ====
IMP GDL2_NSAutoreleasePool_newIMP=NULL;
IMP GDL2_NSNumber_allocWithZoneIMP=NULL;
IMP GDL2_NSDecimalNumber_allocWithZoneIMP=NULL;
IMP GDL2_NSString_allocWithZoneIMP=NULL;
IMP GDL2_NSCalendarDate_allocWithZoneIMP=NULL;
IMP GDL2_NSData_allocWithZoneIMP=NULL;
IMP GDL2_NSMutableArray_allocWithZoneIMP=NULL;
IMP GDL2_NSMutableDictionary_allocWithZoneIMP=NULL;

IMP GDL2_NSData_dataWithBytes_lengthIMP=NULL;

IMP GDL2_NSString_stringWithCString_lengthIMP=NULL;
IMP GDL2_NSString_stringWithCStringIMP=NULL;
GDL2IMP_NSStringEncoding GDL2_NSString_defaultCStringEncodingIMP=NULL;

IMP GDL2_MKKD_objectForKeyIMP=NULL;
IMP GDL2_MKKD_setObjectForKeyIMP=NULL;
IMP GDL2_MKKD_removeObjectForKeyIMP=NULL;
GDL2IMP_BOOL GDL2_MKKD_hasKeyIMP=NULL;
GDL2IMP_UINT GDL2_MKKD_indexForKeyIMP=NULL;
GDL2IMP_UINT GDL2_EOMKKDInitializer_indexForKeyIMP=NULL;

IMP GDL2_EOEditingContext_recordObjectGlobalIDIMP=NULL;
IMP GDL2_EOEditingContext_objectForGlobalIDIMP=NULL;
IMP GDL2_EOEditingContext_globalIDForObjectIMP=NULL;

IMP GDL2_NSMutableArray_arrayWithCapacityIMP=NULL;
IMP GDL2_NSMutableArray_arrayWithArrayIMP=NULL;
IMP GDL2_NSMutableArray_arrayIMP=NULL;
IMP GDL2_NSArray_arrayIMP=NULL;

IMP GDL2_NSMutableDictionary_dictionaryWithCapacityIMP=NULL;

// ==== Constants ====
NSNumber* GDL2_NSNumberBool_Yes=nil;
NSNumber* GDL2_NSNumberBool_No=nil;

EONull* GDL2_EONull=nil;
NSArray* GDL2_NSArray=nil;

// ==== Private Variables ====
static NSRecursiveLock *GDL2_Lock=nil;

// ==== Init Method ====
void GDL2_PrivateInit()
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized = YES;

      GDL2_Lock = [NSRecursiveLock new];

      // ==== Classes ====
      GDL2_NSArrayClass=[NSArray class];
      GDL2_NSMutableArrayClass=[NSMutableArray class];
      GDL2_NSDictionaryClass=[NSDictionary class];
      GDL2_NSMutableDictionaryClass=[NSMutableDictionary class];
      GDL2_NSStringClass=[NSString class];
      GDL2_NSNumberClass=[NSNumber class];
      GDL2_NSDecimalNumberClass=[NSDecimalNumber class];
      GDL2_NSCalendarDateClass=[NSCalendarDate class];
      GDL2_NSDateClass = [NSDate class];
      GDL2_NSAutoreleasePoolClass = [NSAutoreleasePool class];
      GDL2_NSDataClass = [NSData class];
      GDL2_EOFaultClass = [EOFault class];
      GDL2_MKKDClass = [EOMutableKnownKeyDictionary class];
      GDL2_EOMKKDInitializerClass = [EOMKKDInitializer class];
      GDL2_EOEditingContextClass = [EOEditingContext class];

      // ==== IMPs ====
      GDL2_NSAutoreleasePool_newIMP=
        [GDL2_NSAutoreleasePoolClass methodForSelector:@selector(new)];

      GDL2_NSNumber_allocWithZoneIMP=
        [GDL2_NSNumberClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSDecimalNumber_allocWithZoneIMP=
        [GDL2_NSDecimalNumberClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSString_allocWithZoneIMP=
        [GDL2_NSStringClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSCalendarDate_allocWithZoneIMP=
        [GDL2_NSCalendarDateClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSData_allocWithZoneIMP=
        [GDL2_NSDataClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSMutableArray_allocWithZoneIMP=
        [GDL2_NSMutableArrayClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSMutableDictionary_allocWithZoneIMP=
        [GDL2_NSMutableDictionaryClass methodForSelector:@selector(allocWithZone:)];

      GDL2_NSData_dataWithBytes_lengthIMP=
        [GDL2_NSDataClass methodForSelector:@selector(dataWithBytes:length:)];

      GDL2_NSString_stringWithCString_lengthIMP=
        [GDL2_NSStringClass methodForSelector:@selector(stringWithCString:length:)];

      GDL2_NSString_stringWithCStringIMP=
        [GDL2_NSStringClass methodForSelector:@selector(stringWithCString:)];

      GDL2_NSString_defaultCStringEncodingIMP=
        (GDL2IMP_NSStringEncoding)[GDL2_NSStringClass methodForSelector:@selector(defaultCStringEncoding)];

      GDL2_MKKD_objectForKeyIMP=[GDL2_MKKDClass instanceMethodForSelector:@selector(objectForKey:)];
      GDL2_MKKD_setObjectForKeyIMP=[GDL2_MKKDClass instanceMethodForSelector:@selector(setObject:forKey:)];
      GDL2_MKKD_removeObjectForKeyIMP=[GDL2_MKKDClass instanceMethodForSelector:@selector(removeObjectForKey:)];
      GDL2_MKKD_hasKeyIMP=(GDL2IMP_BOOL)[GDL2_MKKDClass instanceMethodForSelector:@selector(hasKey:)];
      GDL2_MKKD_indexForKeyIMP=(GDL2IMP_UINT)[GDL2_MKKDClass instanceMethodForSelector:@selector(indexForKey:)];
      GDL2_EOMKKDInitializer_indexForKeyIMP=(GDL2IMP_UINT)[GDL2_EOMKKDInitializerClass instanceMethodForSelector:@selector(indexForKey:)];

      GDL2_EOEditingContext_recordObjectGlobalIDIMP=[GDL2_EOEditingContextClass instanceMethodForSelector:@selector(recordObject:globalID:)];
      GDL2_EOEditingContext_objectForGlobalIDIMP=[GDL2_EOEditingContextClass instanceMethodForSelector:@selector(objectForGlobalID:)];
      GDL2_EOEditingContext_globalIDForObjectIMP=[GDL2_EOEditingContextClass instanceMethodForSelector:@selector(globalIDForObject:)];

      GDL2_NSMutableArray_arrayWithCapacityIMP=[GDL2_NSMutableArrayClass 
                                                methodForSelector:@selector(arrayWithCapacity:)];

      GDL2_NSMutableArray_arrayWithArrayIMP=[GDL2_NSMutableArrayClass 
                                             methodForSelector:@selector(arrayWithArray:)];

      GDL2_NSMutableArray_arrayIMP=[GDL2_NSMutableArrayClass 
                                    methodForSelector:@selector(array)];

      GDL2_NSArray_arrayIMP=[GDL2_NSArrayClass 
                             methodForSelector:@selector(array)];

      GDL2_NSMutableDictionary_dictionaryWithCapacityIMP=[GDL2_NSMutableDictionaryClass 
                                    methodForSelector:@selector(dictionaryWithCapacity:)];

      // ==== Constants ====
      ASSIGN(GDL2_NSNumberBool_Yes,[GDL2_NSNumberClass numberWithBool:YES]);
      ASSIGN(GDL2_NSNumberBool_No,[GDL2_NSNumberClass numberWithBool:NO]);

      ASSIGN(GDL2_EONull,[EONull null]);
      ASSIGN(GDL2_NSArray,[NSArray array]);

    };
}

void
GDL2_AssignAtomicallyIfNil (id *address,id value)
{
  GDL2_PrivateInit();
  [GDL2_Lock lock];
  if (address && *address == nil)
    {
      *address = value;
    }
  [GDL2_Lock unlock];
}

/* EOMultipleKnownKeyDictionary */

id
EOMKKD_objectForKeyWithImpPtr(NSDictionary* mkkd,
			      IMP* impPtr,
			      NSString* key)
{
  if (mkkd)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(mkkd)==GDL2_MKKDClass
              && GDL2_MKKD_objectForKeyIMP)
            imp=GDL2_MKKD_objectForKeyIMP;
          else
            imp=[mkkd methodForSelector:@selector(objectForKey:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(mkkd,@selector(objectForKey:),key);
    }
  else
    return nil;
};

void
EOMKKD_setObjectForKeyWithImpPtr(NSDictionary* mkkd,
				 IMP* impPtr,
				 id anObject,
				 NSString* key)
{
  if (mkkd)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(mkkd)==GDL2_MKKDClass
              && GDL2_MKKD_setObjectForKeyIMP)
            imp=GDL2_MKKD_setObjectForKeyIMP;
          else
            imp=[mkkd methodForSelector:@selector(setObject:forKey:)];
          if (impPtr)
            *impPtr=imp;
        }
      (*imp)(mkkd,@selector(setObject:forKey:),anObject,key);
    };
};

void
EOMKKD_removeObjectForKeyWithImpPtr(NSDictionary* mkkd,
				    IMP* impPtr,
				    NSString* key)
{
  if (mkkd)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(mkkd)==GDL2_MKKDClass
              && GDL2_MKKD_removeObjectForKeyIMP)
            imp=GDL2_MKKD_removeObjectForKeyIMP;
          else
            imp=[mkkd methodForSelector:@selector(removeObjectForKey:)];
          if (impPtr)
            *impPtr=imp;
        }
      (*imp)(mkkd,@selector(removeObjectForKey:),key);
    };
};

BOOL 
EOMKKD_hasKeyWithImpPtr(NSDictionary* mkkd,
			GDL2IMP_BOOL* impPtr,
			NSString* key)
{
  if (mkkd)
    {
      GDL2IMP_BOOL imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(mkkd)==GDL2_MKKDClass
              && GDL2_MKKD_hasKeyIMP)
            imp=GDL2_MKKD_hasKeyIMP;
          else
            imp=(GDL2IMP_BOOL)[mkkd methodForSelector:@selector(hasKey:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(mkkd,@selector(hasKey:),key);
    }
  else
    return NO;
};

NSUInteger 
EOMKKD_indexForKeyWithImpPtr(EOMutableKnownKeyDictionary* mkkd,
			     GDL2IMP_UINT* impPtr,
			     NSString* key)
{
  if (mkkd)
    {
      GDL2IMP_UINT imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(mkkd)==GDL2_MKKDClass
              && GDL2_MKKD_indexForKeyIMP)
            imp=GDL2_MKKD_indexForKeyIMP;
          else
            imp=(GDL2IMP_UINT)[mkkd methodForSelector:@selector(indexForKey:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(mkkd,@selector(indexForKey:),key);
    }
  else
    return 0;
};

NSUInteger EOMKKDInitializer_indexForKeyWithImpPtr(EOMKKDInitializer* mkkdInit,
					GDL2IMP_UINT* impPtr,
					NSString* key)
{
  if (mkkdInit)
    {
      GDL2IMP_UINT imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(mkkdInit)==GDL2_EOMKKDInitializerClass
              && GDL2_EOMKKDInitializer_indexForKeyIMP)
            imp=GDL2_EOMKKDInitializer_indexForKeyIMP;
          else
            imp=(GDL2IMP_UINT)[mkkdInit methodForSelector:@selector(indexForKey:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(mkkdInit,@selector(indexForKey:),key);
    }
  else
    return 0;
};

/* EOEditingContext */

id
EOEditingContext_objectForGlobalIDWithImpPtr(EOEditingContext *edContext,
					     IMP              *impPtr,
					     EOGlobalID       *gid)
{
  if (edContext)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(edContext)==GDL2_EOEditingContextClass
              && GDL2_EOEditingContext_objectForGlobalIDIMP)
            imp=GDL2_EOEditingContext_objectForGlobalIDIMP;
          else
            imp=[edContext methodForSelector:@selector(objectForGlobalID:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(edContext,@selector(objectForGlobalID:),gid);
    }
  else
    return nil;
};

EOGlobalID *
EOEditingContext_globalIDForObjectWithImpPtr(EOEditingContext *edContext,
					     IMP              *impPtr,
					     id object)
{
  if (edContext)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(edContext)==GDL2_EOEditingContextClass
              && GDL2_EOEditingContext_globalIDForObjectIMP)
            imp=GDL2_EOEditingContext_globalIDForObjectIMP;
          else
            imp=[edContext methodForSelector:@selector(globalIDForObject:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(edContext,@selector(globalIDForObject:),object);
    }
  else
    return nil;
};

id
EOEditingContext_recordObjectGlobalIDWithImpPtr(EOEditingContext  *edContext,
						IMP               *impPtr,
						id                 object,
						EOGlobalID        *gid)
{
  if (edContext)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(edContext)==GDL2_EOEditingContextClass
              && GDL2_EOEditingContext_recordObjectGlobalIDIMP)
            imp=GDL2_EOEditingContext_recordObjectGlobalIDIMP;
          else
            imp=[edContext methodForSelector:@selector(recordObject:globalID:)];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(edContext,@selector(recordObject:globalID:),object,gid);
    }
  else
    return nil;
};

void EOHashAddTable(NSHashTable *to, NSHashTable *from)
{
  NSHashEnumerator hEnum;
  void *content;

  hEnum = NSEnumerateHashTable (from);
  while ((content = NSNextHashEnumeratorItem (&hEnum)))
    {
      NSHashInsert(to, content);
    }
  NSEndHashTableEnumeration(&hEnum);
}

static SEL eqSel;

@interface GDL2NonRetainingMutableArray (PrivateExceptions)
- (void) _raiseRangeExceptionWithIndex:(NSUInteger) index from:(SEL)selector;
@end

/**
 *  A mutable array which does not retain its objects,
 *  the caller must remove the object before it is deallocated. 
 */
@implementation GDL2NonRetainingMutableArray

+ (void) initialize
{
 eqSel = NSSelectorFromString(@"isEqual:"); 
}

- (void) dealloc
{
  GSIArrayEmpty(_contents);
  NSZoneFree([self zone], _contents);
  [super dealloc];
}

- (id) init
{
  self = [self initWithCapacity:0];
  return self;
}

- (id) copyWithZone:(NSZone *)zone
{
  return [self mutableCopyWithZone:zone];
}

- (id) mutableCopyWithZone:(NSZone *)zone
{
  return [[GDL2NonRetainingMutableArray allocWithZone:zone] initWithArray:self copyItems:NO];
}

/* designated initializer */
- (id) initWithCapacity:(NSUInteger)capacity
{
  self = [super init];
  _contents = NSZoneMalloc([self zone], sizeof(GSIArray_t));
  _contents = GSIArrayInitWithZoneAndCapacity(_contents, [self zone], capacity);
  return self; 
}

- (id) initWithObjects:(const id[])objects count:(NSUInteger)count
{
  NSUInteger i;
  self = [self initWithCapacity:count];
  for (i = 0; i < count; i++)
    GSIArrayAddItem(_contents, (GSIArrayItem)objects[i]);
  return self;
}

/* These are *this* subclasses responsibility */
- (NSUInteger) count
{
  return GSIArrayCount(_contents);
}

- (id) objectAtIndex:(NSUInteger) index
{
  if (index >= GSIArrayCount(_contents))
    [self _raiseRangeExceptionWithIndex:index from:_cmd];

  return GSIArrayItemAtIndex(_contents, index).obj;
}

- (void) addObject:(id)object
{
  if (object == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Attempt to add nil to an array"];
      return;
    }

  GSIArrayAddItem(_contents, (GSIArrayItem)object);
}

- (void) replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
  if (object == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Attempt to add nil to an array"];
      return;
    }
  else if (index >= GSIArrayCount(_contents))
    {
      [self _raiseRangeExceptionWithIndex:index from:_cmd];
      return;
    }
   
  GSIArraySetItemAtIndex(_contents, (GSIArrayItem)object, index);
}

- (void) insertObject:(id)object atIndex:(NSUInteger)index
{
  if (object == nil)
    {
      [NSException raise: NSInvalidArgumentException
  		  format: @"Attempt to add nil to an array"];
      return;
    }
  else if (index >= GSIArrayCount(_contents))
    {
      [self _raiseRangeExceptionWithIndex:index from:_cmd];
    }
  
  GSIArrayInsertItem(_contents, (GSIArrayItem)object, index);
}

- (void) removeObjectAtIndex:(NSUInteger)index
{
  if (index >= GSIArrayCount(_contents))
    {
      [self _raiseRangeExceptionWithIndex:index from:_cmd];
    }
  GSIArrayRemoveItemAtIndex(_contents, index);
}

- (void) removeAllObjects
{
  GSIArrayRemoveAllItems(_contents);
}

/* might as well also implement because we can do it faster */
- (id) lastObject
{
  return GSIArrayLastItem(_contents).obj;
}

- (id) firstObject
{
  if (GSIArrayCount(_contents) == 0)
    return nil;
  return GSIArrayItemAtIndex(_contents, 0).obj;
}

/* not only make it faster but work around for old buggy implementations of
 * NSArray in gnustep with an extra release */
- (void) removeObject:(id)anObject
{
  int index = GSIArrayCount(_contents);
  BOOL (*eq)(id,SEL,id) 
    = (BOOL (*)(id, SEL, id))[anObject methodForSelector:eqSel];
  
  /* iterate backwards, so that all objects equal to 'anObject'
   * can safely be removed from the array while iterating. */
  while (index-- > 0)
    {
      if ((*eq)(anObject, eqSel, GSIArrayItemAtIndex(_contents, index).obj))
        {
	  GSIArrayRemoveItemAtIndex(_contents, index);
	}
    }
}

/* private methods. */
- (void) _raiseRangeExceptionWithIndex: (NSUInteger)index from: (SEL)sel
{
  NSDictionary *info;
  NSException  *exception;
  NSString     *reason;
  NSUInteger     count = GSIArrayCount(_contents);

  info = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithUnsignedInteger: index], @"Index",
    [NSNumber numberWithUnsignedInteger: count], @"Count",
    self, @"Array", nil, nil];

  reason = [NSString stringWithFormat: @"Index %"PRIuPTR" is out of range %"PRIuPTR" (in '%@')",    index, count, NSStringFromSelector(sel)];

  exception = [NSException exceptionWithName: NSRangeException
                                      reason: reason
                                    userInfo: info];
  [exception raise];
}

@end


BOOL
GDL2_isLegalDBName(NSString* name)
{
  static NSCharacterSet *illegalSet = nil;
  NSRange range;
  
  if (illegalSet == nil)
    {
      NSMutableCharacterSet *mutableSet;
      illegalSet = [NSCharacterSet alphanumericCharacterSet];
      mutableSet = AUTORELEASE([illegalSet mutableCopy]);
      [mutableSet addCharactersInString:@"_-"];
      illegalSet = RETAIN([mutableSet invertedSet]);
    }

  if (![name length])
    { 
      return NO;
    }
  range = [name rangeOfCharacterFromSet: illegalSet];
  return (range.location == NSNotFound) ? YES : NO;
}
