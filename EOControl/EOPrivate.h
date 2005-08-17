/* -*-objc-*-
   EOPrivate.h

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Jan 2005

   This file is part of the GNUstep Database Library.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef __EOControl_EOPrivate_h__
#define __EOControl_EOPrivate_h__

#include <Foundation/NSArray.h>
#include "EODefines.h"

@class NSNumber;
@class EONull;
@class EOMutableKnownKeyDictionary;
@class EOMKKDInitializer;
@class EOEditingContext;
@class EOGlobalID;

typedef unsigned int (*GDL2IMP_UINT)(id, SEL, ...);
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
GDL2CONTROL_EXPORT IMP GDL2_NSAutoreleasePool_newIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSNumber_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSDecimalNumber_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSString_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSCalendarDate_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSData_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSMutableArray_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSMutableDictionary_allocWithZoneIMP;

GDL2CONTROL_EXPORT IMP GDL2_NSData_dataWithBytes_lengthIMP;

GDL2CONTROL_EXPORT IMP GDL2_NSString_stringWithCString_lengthIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSString_stringWithCStringIMP;
GDL2CONTROL_EXPORT GDL2IMP_NSStringEncoding GDL2_NSString_defaultCStringEncodingIMP;

GDL2CONTROL_EXPORT IMP GDL2_MKKD_objectForKeyIMP;
GDL2CONTROL_EXPORT IMP GDL2_MKKD_setObjectForKeyIMP;
GDL2CONTROL_EXPORT IMP GDL2_MKKD_removeObjectForKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_BOOL GDL2_MKKD_hasKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_UINT GDL2_MKKD_indexForKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_UINT GDL2_EOMKKDInitializer_indexForKeyIMP;

GDL2CONTROL_EXPORT IMP GDL2_EOEditingContext_recordObjectGlobalIDIMP;
GDL2CONTROL_EXPORT IMP GDL2_EOEditingContext_objectForGlobalIDIMP;
GDL2CONTROL_EXPORT IMP GDL2_EOEditingContext_globalIDForObjectIMP;

GDL2CONTROL_EXPORT IMP GDL2_NSMutableArray_arrayWithCapacityIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSMutableArray_arrayWithArrayIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSMutableArray_arrayIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSArray_arrayIMP;
GDL2CONTROL_EXPORT IMP GDL2_NSMutableDictionary_dictionaryWithCapacityIMP;

// ==== Constants ====
GDL2CONTROL_EXPORT NSNumber* GDL2_NSNumberBool_Yes;
GDL2CONTROL_EXPORT NSNumber* GDL2_NSNumberBool_No;
GDL2CONTROL_EXPORT EONull* GDL2_EONull;
GDL2CONTROL_EXPORT NSArray* GDL2_NSArray;

// ==== Init Method ====
GDL2CONTROL_EXPORT void GDL2_PrivateInit();

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
	(((v)==nil) ? NO : ((((EOFault*)(v))->isa == GDL2_EOFaultClass) ? YES : NO))

// ---- +alloc/+allocWithZone: ----
#define GDL2_alloc(CLASS_NAME) \
	(*GDL2_##CLASS_NAME##_allocWithZoneIMP) \
	(GDL2_##CLASS_NAME##Class,@selector(allocWithZone:),NULL)

// ---- +allocWithZone: ----
#define GDL2_allocWithZone(CLASS_NAME,ALLOC_ZONE) \
	(*GDL2_##CLASS_NAME##_allocWithZoneIMP) \
	(GDL2_##CLASS_NAME##Class,@selector(allocWithZone:),ALLOC_ZONE)

// ---- NSMutableString appendString: ----
#define GDL2_AppendStringWithImp(string,methodIMP,aString) \
	(*(methodIMP))((string),@selector(appendString:),(aString))

static inline void GDL2_AppendStringWithImpPtr(NSMutableString* object,IMP* impPtr,NSString* string)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(appendString:)];
      (**impPtr)(object,@selector(appendString:),string);
    };
};

// ---- NSMutableArray addObject: ----
#define GDL2_AddObjectWithImp(array,methodIMP,anObject) \
	(*(methodIMP))((array),@selector(addObject:),(anObject))

static inline void GDL2_AddObjectWithImpPtr(id object,IMP* impPtr,id objectToAdd)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(addObject:)];
      (**impPtr)(object,@selector(addObject:),objectToAdd);
    };
};

// ---- NSArray objectAtIndex: ----
#define GDL2_ObjectAtIndexWithImp(array,methodIMP,index) \
	(*(methodIMP))((array),@selector(objectAtIndex:),(index))

static inline id GDL2_ObjectAtIndexWithImpPtr(id object,IMP* impPtr,int index)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(objectAtIndex:)];
      return (**impPtr)(object,@selector(objectAtIndex:),index);
    }
  else
    return nil;
};

// ---- NSArray indexOfObjectIdenticalTo: ----
#define GDL2_IndexOfObjectIdenticalToWithImp(array,methodIMP,anObject) \
	(*(methodIMP))((array),@selector(indexOfObjectIdenticalTo:),(anObject))


// ---- NSArray lastObject ----
#define GDL2_LastObjectWithImp(array,methodIMP) \
	(*(methodIMP))((array),@selector(lastObject))

static inline id GDL2_LastObjectWithImpPtr(id object,IMP* impPtr)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(lastObject)];
      return (**impPtr)(object,@selector(lastObject));
    }
  else
    return nil;
};

// ---- NSEnumerator nextObject ----
#define GDL2_NextObjectWithImp(enumerator,methodIMP) \
	(*(methodIMP))((enumerator),@selector(nextObject))

static inline id GDL2_NextObjectWithImpPtr(id object,IMP* impPtr)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(nextObject)];
      return (**impPtr)(object,@selector(nextObject));
    }
  else
    return nil;
};

// ---- KVC storedValueForKey: ----
#define GDL2_StoredValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),@selector(storedValueForKey:),value,key)

static inline id GDL2_StoredValueForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(storedValueForKey:)];
      return (**impPtr)(object,@selector(storedValueForKey:),key);
    }
  else
    return nil;
};

// ---- KVC takeStoredValue:forKey: ----
#define GDL2_TakeStoredValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),@selector(takeStoredValue:forKey:),value,key)

static inline void GDL2_TakeStoredValueForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(takeStoredValue:forKey:)];
      (**impPtr)(object,@selector(takeStoredValue:forKey:),value,key);
    };
};

// ---- KVC valueForKey: ----
#define GDL2_ValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),@selector(valueForKey:),value,key)

static inline id GDL2_ValueForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(valueForKey:)];
      return (**impPtr)(object,@selector(valueForKey:),key);
    }
  else
    return nil;
};

// ---- KVC takeValue:forKey: ----
#define GDL2_TakeValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),@selector(takeValue:forKey:),value,key)

static inline void GDL2_TakeValueForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(takeValue:forKey:)];
      (**impPtr)(object,@selector(takeValue:forKey:),value,key);
    };
};

// ---- KVC validateValue:forKey: ----
#define GDL2_ValidateValueForKeyWithImp(object,methodIMP,valuePtr,key) \
	(*methodIMP)((object),@selector(validateValue:forKey:),valuePtr,key)

static inline id GDL2_ValidateValueForKeyWithImpPtr(id object,IMP* impPtr,id* valuePtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(validateValue:forKey:)];
      return (**impPtr)(object,@selector(validateValue:forKey:),valuePtr,key);
    }
  else
    return nil;
};

// ---- Dictionary objectForKey: ----
#define GDL2_ObjectForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),@selector(objectForKey:),value,key)

static inline id GDL2_ObjectForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(objectForKey:)];
      return (**impPtr)(object,@selector(objectForKey:),key);
    }
  else
    return nil;
};

// ---- Dictionary setObject:forKey: ----
#define GDL2_SetObjectForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),@selector(setObject:forKey:),value,key)

static inline void GDL2_SetObjectForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:@selector(setObject:forKey:)];
      (**impPtr)(object,@selector(setObject:forKey:),value,key);
    }
};

// ---- NSString stringWithCString:length: ----
#define GDL2_StringWithCStringAndLength(cString,len)	\
	(*GDL2_NSString_stringWithCString_lengthIMP)(GDL2_NSStringClass,@selector(stringWithCString:length:),(const char*)(cString),(unsigned)(len))

// ---- NSString stringWithCString: ----
#define GDL2_StringWithCString(cString)	\
	(*GDL2_NSString_stringWithCStringIMP)(GDL2_NSStringClass,@selector(stringWithCString:),(const char*)(cString))

// ---- NSString +defaultCStringEncoding ----
#define GDL2_StringDefaultCStringEncoding()	\
	(*GDL2_NSString_defaultCStringEncodingIMP)(GDL2_NSStringClass,@selector(defaultCStringEncoding))

// ---- NSAutoreleasePool +new ----
#define GDL2_NSAutoreleasePool_new() \
	(*GDL2_NSAutoreleasePool_newIMP)(GDL2_NSAutoreleasePoolClass,@selector(new))

// ---- NSData dataWithBytes:length: ----
#define GDL2_DataWithBytesAndLength(bytes,length)	\
	(*GDL2_NSData_dataWithBytes_lengthIMP)(GDL2_NSDataClass,@selector(dataWithBytes:length:),(const void*)(bytes),(int)(length))

// ---- NSObject respondsToSelector: ----
static inline BOOL GDL2_RespondsToSelectorWithImpPtr(id object,GDL2IMP_BOOL* impPtr,SEL sel)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=(GDL2IMP_BOOL)[object methodForSelector:@selector(respondsToSelector:)];
      return (**impPtr)(object,@selector(respondsToSelector:),sel);
    }
  else
    return NO;
};


// ==== EOMultipleKnownKeyDictionary ====

/** mkkkd can be a NSMutableKnownKey or another kind of dictionary **/
GDL2CONTROL_EXPORT id EOMKKD_objectForKeyWithImpPtr(NSDictionary* mkkd,IMP* impPtr,NSString* key);
GDL2CONTROL_EXPORT void EOMKKD_setObjectForKeyWithImpPtr(NSDictionary* mkkd,IMP* impPtr,id anObject,NSString* key);
GDL2CONTROL_EXPORT void EOMKKD_removeObjectForKeyWithImpPtr(NSDictionary* mkkd,IMP* impPtr,NSString* key);
GDL2CONTROL_EXPORT BOOL EOMKKD_hasKeyWithImpPtr(NSDictionary* mkkd,GDL2IMP_BOOL* impPtr,NSString* key);

GDL2CONTROL_EXPORT unsigned int EOMKKD_indexForKeyWithImpPtr(EOMutableKnownKeyDictionary* mkkd,GDL2IMP_UINT* impPtr,NSString* key);
GDL2CONTROL_EXPORT unsigned int EOMKKDInitializer_indexForKeyWithImpPtr(EOMKKDInitializer* mkkdInit,GDL2IMP_UINT* impPtr,NSString* key);

// ==== EOEditingContext ====

GDL2CONTROL_EXPORT id EOEditingContext_objectForGlobalIDWithImpPtr(EOEditingContext* edContext,IMP* impPtr,EOGlobalID* gid);
EOGlobalID* EOEditingContext_globalIDForObjectWithImpPtr(EOEditingContext* edContext,IMP* impPtr,id object);
GDL2CONTROL_EXPORT id EOEditingContext_recordObjectGlobalIDWithImpPtr(EOEditingContext* edContext,IMP* impPtr,id object,EOGlobalID* gid);


@interface NSObject (DeallocHack)
- (void) registerAssociationForDeallocHack:(id)object;
@end

@interface GDL2NonRetainingMutableArray : NSMutableArray
{
  void *_contents;
}
@end

#endif /* __EOControl_EOPrivate_h__ */
