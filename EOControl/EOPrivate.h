/* -*-objc-*-
   EOPrivate.h

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Jan 2005

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOControl_EOPrivate_h__
#define __EOControl_EOPrivate_h__

#include <objc/runtime.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSHashTable.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EOEditingContext.h>
#include "EODefines.h"

@class NSNumber;
@class EONull;
@class EOMutableKnownKeyDictionary;
@class EOMKKDInitializer;
@class EOGlobalID;

typedef NSUInteger (*GDL2IMP_UINT)(id, SEL, ...);
typedef BOOL (*GDL2IMP_BOOL)(id, SEL, ...);
typedef NSStringEncoding (*GDL2IMP_NSStringEncoding)(id, SEL, ...);

// ==== Classes ====
GDL2CONTROL_EXPORT Class GDL2_NSArrayClass;
GDL2CONTROL_EXPORT Class GDL2_NSMutableArrayClass;
GDL2CONTROL_EXPORT Class GDL2_NSDictionaryClass;
GDL2CONTROL_EXPORT Class GDL2_NSMutableDictionaryClass;
GDL2CONTROL_EXPORT Class GDL2_NSStringClass;
GDL2CONTROL_EXPORT Class GDL2_NSNumberClass;
GDL2CONTROL_EXPORT Class GDL2_NSDecimalNumberClass;
GDL2CONTROL_EXPORT Class GDL2_NSCalendarDateClass;
GDL2CONTROL_EXPORT Class GDL2_NSDateClass;
GDL2CONTROL_EXPORT Class GDL2_NSAutoreleasePoolClass;
GDL2CONTROL_EXPORT Class GDL2_NSDataClass;
GDL2CONTROL_EXPORT Class GDL2_EOFaultClass;
GDL2CONTROL_EXPORT Class GDL2_MKKDClass;
GDL2CONTROL_EXPORT Class GDL2_EOMKKDInitializerClass;
GDL2CONTROL_EXPORT Class GDL2_EOEditingContextClass;

// ==== IMPs ====



// ==== Constants ====
GDL2CONTROL_EXPORT NSNumber* GDL2_NSNumberBool_Yes;
GDL2CONTROL_EXPORT NSNumber* GDL2_NSNumberBool_No;
GDL2CONTROL_EXPORT EONull* GDL2_EONull;
GDL2CONTROL_EXPORT NSArray* GDL2_NSArray;

// ==== Init Method ====
GDL2CONTROL_EXPORT void GDL2_PrivateInit();
GDL2CONTROL_EXPORT void GDL2_AssignAtomicallyIfNil (id *address,id value);

// ==== IMP Helpers ====

static inline BOOL
_isNilOrEONull(id obj) __attribute__ ((unused));
static inline BOOL
_isNilOrEONull(id obj)
{
  if (GDL2_EONull == nil) GDL2_PrivateInit();
  return (obj == nil || obj == GDL2_EONull) ? YES : NO;
}

//See also EOControl/EOFault.m
#define _isFault(v)	\
	(((v)==nil) ? NO : ((object_getClass((EOFault*)(v)) == GDL2_EOFaultClass) ? YES : NO))

// ---- +alloc/+allocWithZone: ----
#define GDL2_alloc(CLASS_NAME) \
	[GDL2_##CLASS_NAME##Class allocWithZone:NULL]

// ---- +allocWithZone: ----
#define GDL2_allocWithZone(CLASS_NAME,ALLOC_ZONE) \
	[GDL2_##CLASS_NAME##Class allocWithZone:ALLOC_ZONE]

// ---- NSMutableString appendString: ----
#define GDL2_AppendStringWithImp(string,methodIMP,aString) \
	[string appendString:aString]



// ---- NSMutableArray addObject: ----
#define GDL2_AddObjectWithImp(array,methodIMP,anObject) \
	[array addObject:anObject]



// ---- NSArray objectAtIndex: ----
#define GDL2_ObjectAtIndexWithImp(array,methodIMP,index) \
	[array objectAtIndex:index]



// ---- NSArray indexOfObjectIdenticalTo: ----
#define GDL2_IndexOfObjectIdenticalToWithImp(array,methodIMP,anObject) \
	[array indexOfObjectIdenticalTo:anObject]


// ---- NSArray lastObject ----
#define GDL2_LastObjectWithImp(array,methodIMP) \
	[array lastObject]



// ---- NSEnumerator nextObject ----
#define GDL2_NextObjectWithImp(enumerator,methodIMP) \
	[enumerator nextObject]



// ---- KVC storedValueForKey: ----
#define GDL2_StoredValueForKeyWithImp(object,methodIMP,value,key) \
	[object storedValueForKey:key]



// ---- KVC takeStoredValue:forKey: ----
#define GDL2_TakeStoredValueForKeyWithImp(object,methodIMP,value,key) \
	[object takeStoredValue:value forKey:key]



// ---- KVC valueForKey: ----
#define GDL2_ValueForKeyWithImp(object,methodIMP,value,key) \
	[object valueForKey:key]



// ---- KVC takeValue:forKey: ----
#define GDL2_TakeValueForKeyWithImp(object,methodIMP,value,key) \
	[object setValue:value forKey:key]



// ---- KVC validateValue:forKey: ----
#define GDL2_ValidateValueForKeyWithImp(object,methodIMP,valuePtr,key) \
	[object validateValue:valuePtr forKey:key]



// ---- Dictionary objectForKey: ----
#define GDL2_ObjectForKeyWithImp(object,methodIMP,value,key) \
	[object objectForKey:key]



// ---- Dictionary setObject:forKey: ----
#define GDL2_SetObjectForKeyWithImp(object,methodIMP,value,key) \
	[object setObject:value forKey:key]



// ---- NSString stringWithCString:length: ----
#define GDL2_StringWithCStringAndLength(cString,len)	\
	[NSString stringWithCString:cString length:len]

// ---- NSString stringWithCString: ----
#define GDL2_StringWithCString(cString)	\
	[NSString stringWithCString:cString]

// ---- NSString +defaultCStringEncoding ----
#define GDL2_StringDefaultCStringEncoding()	\
	[NSString defaultCStringEncoding]

// ---- NSAutoreleasePool +new ----
#define GDL2_NSAutoreleasePool_new() \
	[NSAutoreleasePool new]

// ---- NSData dataWithBytes:length: ----
#define GDL2_DataWithBytesAndLength(bytes,length)	\
	[NSData dataWithBytes:bytes length:length]

// ---- NSObject respondsToSelector: ----



// ==== EOMultipleKnownKeyDictionary ====

/** mkkkd can be a NSMutableKnownKey or another kind of dictionary **/








// ==== EOEditingContext ====






// ==== hash convienience functions ====

GDL2CONTROL_EXPORT void EOHashAddTable(NSHashTable *to, NSHashTable *from);


// ==== hash convienience functions ====

GDL2CONTROL_EXPORT BOOL GDL2_isLegalDBName(NSString *name);

// ==== Memory Management Utilities ====

@interface EOEditingContext (EOMemoryManagement)
+ (void)_objectDeallocated:(id)object;
@end

@interface EOObserverCenter(EOPrivate)
+ (void) _forgetObject:(id)object;
@end

@interface GDL2NonRetainingMutableArray : NSMutableArray
{
  void *_contents;
}
@end

#endif /* __EOControl_EOPrivate_h__ */
