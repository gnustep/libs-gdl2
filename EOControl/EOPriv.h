/* -*-objc-*-
   EOPriv.h

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

#ifndef __EOPriv_h__
#define __EOPriv_h__

#include <EOControl/EODefines.h>

@class NSNumber;
@class EONull;

typedef unsigned int (*GDL2IMP_UINT)(id, SEL, ...);
typedef BOOL (*GDL2IMP_BOOL)(id, SEL, ...);

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
GDL2CONTROL_EXPORT Class GDL2EODatabaseContextClass;
GDL2CONTROL_EXPORT Class GDL2EOEditingContextClass;
GDL2CONTROL_EXPORT Class GDL2EOAttributeClass;

GDL2CONTROL_EXPORT SEL GDL2_newSEL;
GDL2CONTROL_EXPORT SEL GDL2_allocWithZoneSEL;
GDL2CONTROL_EXPORT SEL GDL2_isEqualToStringSEL;
GDL2CONTROL_EXPORT SEL GDL2_appendStringSEL;
GDL2CONTROL_EXPORT SEL GDL2_stringWithCString_lengthSEL;
GDL2CONTROL_EXPORT SEL GDL2_stringWithCStringSEL;
GDL2CONTROL_EXPORT SEL GDL2_addObjectSEL;
GDL2CONTROL_EXPORT SEL GDL2_objectAtIndexSEL;
GDL2CONTROL_EXPORT SEL GDL2_indexOfObjectIdenticalToSEL;
GDL2CONTROL_EXPORT SEL GDL2_nextObjectSEL;
GDL2CONTROL_EXPORT SEL GDL2_takeStoredValueForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_snapshotForGlobalIDSEL;
GDL2CONTROL_EXPORT SEL GDL2_objectForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_setObjectForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_removeObjectForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_respondsToSelectorSEL;
GDL2CONTROL_EXPORT SEL GDL2_hasKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_indexForKeySEL;
GDL2CONTROL_EXPORT SEL GDL2_snapshotForGlobalIDSEL;
GDL2CONTROL_EXPORT SEL GDL2_recordObjectGlobalIDSEL;
GDL2CONTROL_EXPORT SEL GDL2_objectForGlobalIDSEL;
GDL2CONTROL_EXPORT SEL GDL2_globalIDForObjectSEL;

GDL2CONTROL_EXPORT IMP GDL2NSAutoreleasePool_newIMP;
GDL2CONTROL_EXPORT IMP GDL2NSNumber_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSDecimalNumber_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSString_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSCalendarDate_allocWithZoneIMP;
GDL2CONTROL_EXPORT IMP GDL2NSData_allocWithZoneIMP;

GDL2CONTROL_EXPORT IMP GDL2NSString_stringWithCString_lengthIMP;
GDL2CONTROL_EXPORT IMP GDL2NSString_stringWithCStringIMP;

GDL2CONTROL_EXPORT IMP GDL2MKKD_objectForKeyIMP;
GDL2CONTROL_EXPORT IMP GDL2MKKD_setObjectForKeyIMP;
GDL2CONTROL_EXPORT IMP GDL2MKKD_removeObjectForKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_BOOL GDL2MKKD_hasKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_UINT GDL2MKKD_indexForKeyIMP;
GDL2CONTROL_EXPORT GDL2IMP_UINT GDL2EOMKKDInitializer_indexForKeyIMP;

GDL2CONTROL_EXPORT IMP GDL2EODatabaseContext_snapshotForGlobalIDIMP;

GDL2CONTROL_EXPORT IMP GDL2EOEditingContext_recordObjectGlobalIDIMP;
GDL2CONTROL_EXPORT IMP GDL2EOEditingContext_objectForGlobalIDIMP;
GDL2CONTROL_EXPORT IMP GDL2EOEditingContext_globalIDForObjectIMP;

GDL2CONTROL_EXPORT NSNumber* GDL2NSNumberBool_Yes;
GDL2CONTROL_EXPORT NSNumber* GDL2NSNumberBool_No;
GDL2CONTROL_EXPORT EONull* GDL2EONull;
GDL2CONTROL_EXPORT NSCharacterSet* GDL2_shellPatternCharacterSet;

GDL2CONTROL_EXPORT void GDL2PrivInit();

#define _isNilOrEONull(v)	\
        (isNilOrEONull(v))

//	(((v)==nil || (v)==GDL2EONull) ? YES : NO)

//See also EOControl/EOFault.m
#define _isFault(v)	\
	(((v)==nil) ? NO : ((((EOFault*)(v))->isa == GDL2EOFaultClass) ? YES : NO))

#define GDL2AppendStringWithImp(string,methodIMP,aString) \
	(*(methodIMP))((string),GDL2_appendStringSEL,(aString))

#define GDL2AddObjectWithImp(array,methodIMP,anObject) \
	(*(methodIMP))((array),GDL2_addObjectSEL,(anObject))

#define GDL2ObjectAtIndexWithImp(array,methodIMP,index) \
	(*(methodIMP))((array),GDL2_objectAtIndexSEL,(index))

#define GDL2IndexOfObjectIdenticalToWithImp(array,methodIMP,anObject) \
	(*(methodIMP))((array),GDL2_indexOfObjectIdenticalToSEL,(anObject))

#define GDL2NextObjectWithImp(enumerator,methodIMP) \
	(*(methodIMP))((array),GDL2_nextObjectSEL)

#define GDL2TakeStoredValueForKeyWithImp(object,methodIMP,value,key) \
	(*methodIMP)((object),GDL2_takeStoredValueForKeySEL,value,key)

#define GDL2StringWithCStringAndLength(cString,length)	\
	(*GDL2NSString_stringWithCString_lengthIMP)(GDL2NSStringClass,GDL2_stringWithCString_lengthSEL,(const char*)(cString),(int)(length))

#define GDL2StringWithCString(cString)	\
	(*GDL2NSString_stringWithCStringIMP)(GDL2NSStringClass,GDL2_stringWithCStringSEL,(const char*)(cString))

#define GDL2NSAutoreleasePool_new() \
	(*GDL2NSAutoreleasePool_newIMP)(GDL2NSAutoreleasePoolClass,GDL2_newSEL)

#define GDL2NSString_alloc()	\
	(*GDL2NSString_allocWithZoneIMP)(GDL2NSStringClass,GDL2_allocWithZoneSEL,NULL)

#define GDL2NSDecimalNumber_alloc() \
	(*GDL2NSDecimalNumber_allocWithZoneIMP)(GDL2NSDecimalNumberClass,GDL2_allocWithZoneSEL,NULL) 

#define GDL2NSNumber_alloc() \
	(*GDL2NSNumber_allocWithZoneIMP)(GDL2NSNumberClass,GDL2_allocWithZoneSEL,NULL) 

#define GDL2NSCalendarDate_alloc() \
	(*GDL2NSCalendarDate_allocWithZoneIMP)(GDL2NSCalendarDateClass,GDL2_allocWithZoneSEL,NULL) 

#define GDL2NSData_alloc()	\
	(*GDL2NSData_allocWithZoneIMP)(GDL2NSDataClass,GDL2_allocWithZoneSEL,NULL)

static inline BOOL GDL2RespondsToSelectorWithImpPtr(id object,GDL2IMP_BOOL* impPtr,SEL sel)
{
  if (!*impPtr)
    *impPtr=(GDL2IMP_BOOL)[object methodForSelector:GDL2_respondsToSelectorSEL];
  return (**impPtr)(object,GDL2_respondsToSelectorSEL,sel);
};

#endif /* __EOPriv_h__ */

