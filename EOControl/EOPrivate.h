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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __EOControl_EOPrivate_h__
#define __EOControl_EOPrivate_h__

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
GDL2CONTROL_EXPORT Class GDL2NSArrayClass;
GDL2CONTROL_EXPORT Class GDL2NSMutableArrayClass;
GDL2CONTROL_EXPORT Class GDL2NSDictionaryClass;
GDL2CONTROL_EXPORT Class GDL2NSMutableDictionaryClass;
GDL2CONTROL_EXPORT Class GDL2NSStringClass;
GDL2CONTROL_EXPORT Class GDL2NSNumberClass;
GDL2CONTROL_EXPORT Class GDL2NSDecimalNumberClass;
GDL2CONTROL_EXPORT Class GDL2NSCalendarDateClass;
GDL2CONTROL_EXPORT Class GDL2NSDateClass;
GDL2CONTROL_EXPORT Class GDL2NSAutoreleasePoolClass;
GDL2CONTROL_EXPORT Class GDL2NSDataClass;
GDL2CONTROL_EXPORT Class GDL2EOFaultClass;
GDL2CONTROL_EXPORT Class GDL2MKKDClass;
GDL2CONTROL_EXPORT Class GDL2EOMKKDInitializerClass;
GDL2CONTROL_EXPORT Class GDL2EOEditingContextClass;

// ==== Selectors ====
GDL2CONTROL_EXPORT SEL GDL2_newSEL;
GDL2CONTROL_EXPORT SEL GDL2_allocWithZoneSEL;

// ---- String Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_isEqualToStringSEL;
GDL2CONTROL_EXPORT SEL GDL2_appendStringSEL;
GDL2CONTROL_EXPORT SEL GDL2_stringWithCString_lengthSEL;
GDL2CONTROL_EXPORT SEL GDL2_stringWithCStringSEL;
GDL2CONTROL_EXPORT SEL GDL2_defaultCStringEncodingSEL;

// ---- Data Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_dataWithBytes_lengthSEL;

// ---- Array Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_addObjectSEL;
GDL2CONTROL_EXPORT SEL GDL2_objectAtIndexSEL;
GDL2CONTROL_EXPORT SEL GDL2_indexOfObjectIdenticalToSEL;
GDL2CONTROL_EXPORT SEL GDL2_lastObjectSEL;
GDL2CONTROL_EXPORT SEL GDL2_arrayWithCapacitySEL;
GDL2CONTROL_EXPORT SEL GDL2_arrayWithArraySEL;
GDL2CONTROL_EXPORT SEL GDL2_arraySEL;

// ---- Enumerator Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_nextObjectSEL;

// ---- KVC Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_storedValueForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_takeStoredValueForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_valueForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_takeValueForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_validateValueForKeySEL;

// ---- GDL2 Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_recordObjectGlobalIDSEL;
GDL2CONTROL_EXPORT SEL GDL2_objectForGlobalIDSEL;
GDL2CONTROL_EXPORT SEL GDL2_globalIDForObjectSEL;

// ---- Dictionary Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_objectForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_setObjectForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_removeObjectForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_dictionaryWithCapacitySEL;

// ---- NSObject Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_respondsToSelectorSEL;

// ---- KMKKD Selectors ----
GDL2CONTROL_EXPORT SEL GDL2_hasKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_indexForKeySEL;

// ==== IMPs ====
GDL2CONTROL_EXPORT IMP GDL2NSAutoreleasePool_newIMP;
GDL2CONTROL_EXPORT IMP GDL2NSNumber_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSDecimalNumber_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSString_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSCalendarDate_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSData_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSData_dataWithBytes_lengthIMP;

GDL2CONTROL_EXPORT IMP GDL2NSString_stringWithCString_lengthIMP;
GDL2CONTROL_EXPORT IMP GDL2NSString_stringWithCStringIMP;
GDL2CONTROL_EXPORT GDL2IMP_NSStringEncoding GDL2NSString_defaultCStringEncodingIMP;

GDL2CONTROL_EXPORT IMP GDL2MKKD_objectForKeyIMP;
GDL2CONTROL_EXPORT IMP GDL2MKKD_setObjectForKeyIMP;
GDL2CONTROL_EXPORT IMP GDL2MKKD_removeObjectForKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_BOOL GDL2MKKD_hasKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_UINT GDL2MKKD_indexForKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_UINT GDL2EOMKKDInitializer_indexForKeyIMP;

GDL2CONTROL_EXPORT IMP GDL2EOEditingContext_recordObjectGlobalIDIMP;
GDL2CONTROL_EXPORT IMP GDL2EOEditingContext_objectForGlobalIDIMP;
GDL2CONTROL_EXPORT IMP GDL2EOEditingContext_globalIDForObjectIMP;

GDL2CONTROL_EXPORT IMP GDL2NSMutableArray_arrayWithCapacityIMP;
GDL2CONTROL_EXPORT IMP GDL2NSMutableArray_arrayWithArrayIMP;
GDL2CONTROL_EXPORT IMP GDL2NSMutableArray_arrayIMP;
GDL2CONTROL_EXPORT IMP GDL2NSArray_arrayIMP;
GDL2CONTROL_EXPORT IMP GDL2NSMutableDictionary_dictionaryWithCapacityIMP;

// ==== Constants ====
GDL2CONTROL_EXPORT NSNumber* GDL2NSNumberBool_Yes;
GDL2CONTROL_EXPORT NSNumber* GDL2NSNumberBool_No;
GDL2CONTROL_EXPORT EONull* GDL2EONull;

// ==== Init Method ====
GDL2CONTROL_EXPORT void GDL2PrivInit();

// ==== IMP Helpers ====

static inline BOOL
_isNilOrEONull(id obj) __attribute__ ((unused));
static inline BOOL
_isNilOrEONull(id obj)
{
  if (GDL2EONull == nil) GDL2PrivInit();
  return (obj == nil || obj == GDL2EONull) ? YES : NO;
}

//See also EOControl/EOFault.m
#define _isFault(v)	\
	(((v)==nil) ? NO : ((((EOFault*)(v))->isa == GDL2EOFaultClass) ? YES : NO))

// ---- NSMutableString appendString: ----
#define GDL2AppendStringWithImp(string,methodIMP,aString) \
	(*(methodIMP))((string),GDL2_appendStringSEL,(aString))

static inline void GDL2AppendStringWithImpPtr(NSMutableString* object,IMP* impPtr,NSString* string)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_appendStringSEL];
      (**impPtr)(object,GDL2_appendStringSEL,string);
    };
};

// ---- NSMutableArray addObject: ----
#define GDL2AddObjectWithImp(array,methodIMP,anObject) \
	(*(methodIMP))((array),GDL2_addObjectSEL,(anObject))

static inline void GDL2AddObjectWithImpPtr(id object,IMP* impPtr,id objectToAdd)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_addObjectSEL];
      (**impPtr)(object,GDL2_addObjectSEL,objectToAdd);
    };
};

// ---- NSArray objectAtIndex: ----
#define GDL2ObjectAtIndexWithImp(array,methodIMP,index) \
	(*(methodIMP))((array),GDL2_objectAtIndexSEL,(index))

static inline id GDL2ObjectAtIndexWithImpPtr(id object,IMP* impPtr,int index)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_objectAtIndexSEL];
      return (**impPtr)(object,GDL2_objectAtIndexSEL,index);
    }
  else
    return nil;
};

// ---- NSArray indexOfObjectIdenticalTo: ----
#define GDL2IndexOfObjectIdenticalToWithImp(array,methodIMP,anObject) \
	(*(methodIMP))((array),GDL2_indexOfObjectIdenticalToSEL,(anObject))


// ---- NSArray lastObject ----
#define GDL2LastObjectWithImp(array,methodIMP) \
	(*(methodIMP))((array),GDL2_lastObjectSEL)

static inline id GDL2LastObjectWithImpPtr(id object,IMP* impPtr)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_lastObjectSEL];
      return (**impPtr)(object,GDL2_lastObjectSEL);
    }
  else
    return nil;
};

// ---- NSEnumerator nextObject ----
#define GDL2NextObjectWithImp(enumerator,methodIMP) \
	(*(methodIMP))((enumerator),GDL2_nextObjectSEL)

static inline id GDL2NextObjectWithImpPtr(id object,IMP* impPtr)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_nextObjectSEL];
      return (**impPtr)(object,GDL2_nextObjectSEL);
    }
  else
    return nil;
};

// ---- KVC storedValueForKey: ----
#define GDL2StoredValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_storedValueForKeySEL,value,key)

static inline id GDL2StoredValueForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_storedValueForKeySEL];
      return (**impPtr)(object,GDL2_storedValueForKeySEL,key);
    }
  else
    return nil;
};

// ---- KVC takeStoredValue:forKey: ----
#define GDL2TakeStoredValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_takeStoredValueForKeySEL,value,key)

static inline void GDL2TakeStoredValueForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_takeStoredValueForKeySEL];
      (**impPtr)(object,GDL2_takeStoredValueForKeySEL,value,key);
    };
};

// ---- KVC valueForKey: ----
#define GDL2ValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_valueForKeySEL,value,key)

static inline id GDL2ValueForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_valueForKeySEL];
      return (**impPtr)(object,GDL2_valueForKeySEL,key);
    }
  else
    return nil;
};

// ---- KVC takeValue:forKey: ----
#define GDL2TakeValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_takeValueForKeySEL,value,key)

static inline void GDL2TakeValueForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_takeValueForKeySEL];
      (**impPtr)(object,GDL2_takeValueForKeySEL,value,key);
    };
};

// ---- KVC validateValue:forKey: ----
#define GDL2ValidateValueForKeyWithImp(object,methodIMP,valuePtr,key) \
	(*methodIMP)((object),GDL2_validateValueForKeySEL,valuePtr,key)

static inline id GDL2ValidateValueForKeyWithImpPtr(id object,IMP* impPtr,id* valuePtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_validateValueForKeySEL];
      return (**impPtr)(object,GDL2_validateValueForKeySEL,valuePtr,key);
    }
  else
    return nil;
};

// ---- Dictionary objectForKey: ----
#define GDL2ObjectForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_objectForKeySEL,value,key)

static inline id GDL2ObjectForKeyWithImpPtr(id object,IMP* impPtr,id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_objectForKeySEL];
      return (**impPtr)(object,GDL2_objectForKeySEL,key);
    }
  else
    return nil;
};

// ---- Dictionary setObject:forKey: ----
#define GDL2SetObjectForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_setObjectForKeySEL,value,key)

static inline void GDL2SetObjectForKeyWithImpPtr(id object,IMP* impPtr,id value, id key)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=[object methodForSelector:GDL2_setObjectForKeySEL];
      (**impPtr)(object,GDL2_setObjectForKeySEL,value,key);
    }
};

// ---- NSString stringWithCString:length: ----
#define GDL2StringWithCStringAndLength(cString,length)	\
	(*GDL2NSString_stringWithCString_lengthIMP)(GDL2NSStringClass,GDL2_stringWithCString_lengthSEL,(const char*)(cString),(int)(length))

// ---- NSString stringWithCString: ----
#define GDL2StringWithCString(cString)	\
	(*GDL2NSString_stringWithCStringIMP)(GDL2NSStringClass,GDL2_stringWithCStringSEL,(const char*)(cString))

// ---- NSString +defaultCStringEncoding ----
#define GDL2StringDefaultCStringEncoding()	\
	(*GDL2NSString_defaultCStringEncodingIMP)(GDL2NSStringClass,GDL2_defaultCStringEncodingSEL)

// ---- NSAutoreleasePool +new ----
#define GDL2NSAutoreleasePool_new() \
	(*GDL2NSAutoreleasePool_newIMP)(GDL2NSAutoreleasePoolClass,GDL2_newSEL)

// ---- NSString +alloc ----
#define GDL2NSString_alloc()	\
	(*GDL2NSString_allocWithZoneIMP)(GDL2NSStringClass,GDL2_allocWithZoneSEL,NULL)

// ---- NSDecimalNumber +alloc ----
#define GDL2NSDecimalNumber_alloc() \
	(*GDL2NSDecimalNumber_allocWithZoneIMP)(GDL2NSDecimalNumberClass,GDL2_allocWithZoneSEL,NULL) 

// ---- NSNumber +alloc ----
#define GDL2NSNumber_alloc() \
	(*GDL2NSNumber_allocWithZoneIMP)(GDL2NSNumberClass,GDL2_allocWithZoneSEL,NULL) 

// ---- NSCalendarDate +alloc ----
#define GDL2NSCalendarDate_alloc() \
	(*GDL2NSCalendarDate_allocWithZoneIMP)(GDL2NSCalendarDateClass,GDL2_allocWithZoneSEL,NULL) 

// ---- NSData +alloc ----
#define GDL2NSData_alloc()	\
	(*GDL2NSData_allocWithZoneIMP)(GDL2NSDataClass,GDL2_allocWithZoneSEL,NULL)

// ---- NSData dataWithBytes:length: ----
#define GDL2DataWithBytesAndLength(bytes,length)	\
	(*GDL2NSData_dataWithBytes_lengthIMP)(GDL2NSDataClass,GDL2_dataWithBytes_lengthSEL,(const void*)(bytes),(int)(length))

// ---- NSMutableArray +arrayWithCapacity: ----
#define GDL2MutableArrayWithCapacity(capacity)	\
	(*GDL2NSMutableArray_arrayWithCapacityIMP)(GDL2NSMutableArrayClass,GDL2_arrayWithCapacitySEL,capacity)

// ---- NSMutableArray +arrayWithArray: ----
#define GDL2MutableArrayWithArray(array)	\
	(*GDL2NSMutableArray_arrayWithArrayIMP)(GDL2NSMutableArrayClass,GDL2_arrayWithArraySEL,array)

// ---- NSMutableArray +array ----
#define GDL2MutableArray()	\
	(*GDL2NSMutableArray_arrayIMP)(GDL2NSMutableArrayClass,GDL2_arraySEL)

// ---- NSArray +array ----
#define GDL2Array()	\
	(*GDL2NSArray_arrayIMP)(GDL2NSArrayClass,GDL2_arraySEL)

// ---- NSMutableDictionary +dictionaryWithCapacity: ----
#define GDL2MutableDictionaryWithCapacity(capacity)	\
	(*GDL2NSMutableDictionary_dictionaryWithCapacityIMP)(GDL2NSMutableDictionaryClass,GDL2_dictionaryWithCapacitySEL,capacity)

// ---- NSObject respondsToSelector: ----
static inline BOOL GDL2RespondsToSelectorWithImpPtr(id object,GDL2IMP_BOOL* impPtr,SEL sel)
{
  if (object)
    {
      if (!*impPtr)
        *impPtr=(GDL2IMP_BOOL)[object methodForSelector:GDL2_respondsToSelectorSEL];
      return (**impPtr)(object,GDL2_respondsToSelectorSEL,sel);
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

#endif /* __EOControl_EOPrivate_h__ */
