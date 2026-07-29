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
