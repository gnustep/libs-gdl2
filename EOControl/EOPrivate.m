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

#include <Foundation/Foundation.h>

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOEditingContext.h>
#include <EOControl/EOFault.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>

#include "EOPrivate.h"

// ==== Classes ====
Class GDL2NSArrayClass=Nil;
Class GDL2NSMutableArrayClass=Nil;
Class GDL2NSDictionaryClass=Nil;
Class GDL2NSMutableDictionaryClass=Nil;
Class GDL2NSStringClass=Nil;
Class GDL2NSNumberClass=Nil;
Class GDL2NSDecimalNumberClass=Nil;
Class GDL2NSCalendarDateClass=Nil;
Class GDL2NSDateClass=Nil;
Class GDL2NSAutoreleasePoolClass=Nil;
Class GDL2NSDataClass=Nil;
Class GDL2EOFaultClass=Nil;
Class GDL2MKKDClass=Nil;
Class GDL2EOMKKDInitializerClass=Nil;
Class GDL2EOEditingContextClass=Nil;

// ==== IMPs ====
IMP GDL2NSAutoreleasePool_newIMP=NULL;
IMP GDL2NSNumber_allocWithZoneIMP=NULL;
IMP GDL2NSDecimalNumber_allocWithZoneIMP=NULL;
IMP GDL2NSString_allocWithZoneIMP=NULL;
IMP GDL2NSCalendarDate_allocWithZoneIMP=NULL;
IMP GDL2NSData_allocWithZoneIMP=NULL;
IMP GDL2NSData_dataWithBytes_lengthIMP=NULL;

IMP GDL2NSString_stringWithCString_lengthIMP=NULL;
IMP GDL2NSString_stringWithCStringIMP=NULL;
GDL2IMP_NSStringEncoding GDL2NSString_defaultCStringEncodingIMP=NULL;

IMP GDL2MKKD_objectForKeyIMP=NULL;
IMP GDL2MKKD_setObjectForKeyIMP=NULL;
IMP GDL2MKKD_removeObjectForKeyIMP=NULL;
GDL2IMP_BOOL GDL2MKKD_hasKeyIMP=NULL;
GDL2IMP_UINT GDL2MKKD_indexForKeyIMP=NULL;
GDL2IMP_UINT GDL2EOMKKDInitializer_indexForKeyIMP=NULL;

IMP GDL2EOEditingContext_recordObjectGlobalIDIMP=NULL;
IMP GDL2EOEditingContext_objectForGlobalIDIMP=NULL;
IMP GDL2EOEditingContext_globalIDForObjectIMP=NULL;

IMP GDL2NSMutableArray_arrayWithCapacityIMP=NULL;
IMP GDL2NSMutableArray_arrayWithArrayIMP=NULL;
IMP GDL2NSMutableArray_arrayIMP=NULL;
IMP GDL2NSArray_arrayIMP=NULL;

IMP GDL2NSMutableDictionary_dictionaryWithCapacityIMP=NULL;

// ==== Constants ====
NSNumber* GDL2NSNumberBool_Yes=nil;
NSNumber* GDL2NSNumberBool_No=nil;

EONull* GDL2EONull=nil;

// ==== Init Method ====
void GDL2PrivInit()
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      // ==== Classes ====
      GDL2NSArrayClass=[NSArray class];
      GDL2NSMutableArrayClass=[NSMutableArray class];
      GDL2NSDictionaryClass=[NSDictionary class];
      GDL2NSMutableDictionaryClass=[NSMutableDictionary class];
      GDL2NSStringClass=[NSString class];
      GDL2NSNumberClass=[NSNumber class];
      GDL2NSDecimalNumberClass=[NSDecimalNumber class];
      GDL2NSCalendarDateClass=[NSCalendarDate class];
      GDL2NSDateClass = [NSDate class];
      GDL2NSAutoreleasePoolClass = [NSAutoreleasePool class];
      GDL2NSDataClass = [NSData class];
      GDL2EOFaultClass = [EOFault class];
      GDL2MKKDClass = [EOMutableKnownKeyDictionary class];
      GDL2EOMKKDInitializerClass = [EOMKKDInitializer class];
      GDL2EOEditingContextClass = [EOEditingContext class];

      // ==== IMPs ====
      GDL2NSAutoreleasePool_newIMP=
        [GDL2NSAutoreleasePoolClass methodForSelector:@selector(new)];

      GDL2NSNumber_allocWithZoneIMP=
        [GDL2NSNumberClass methodForSelector:@selector(allocWithZone:)];

      GDL2NSDecimalNumber_allocWithZoneIMP=
        [GDL2NSDecimalNumberClass methodForSelector:@selector(allocWithZone:)];

      GDL2NSString_allocWithZoneIMP=
        [GDL2NSStringClass methodForSelector:@selector(allocWithZone:)];

      GDL2NSCalendarDate_allocWithZoneIMP=
        [GDL2NSCalendarDateClass methodForSelector:@selector(allocWithZone:)];

      GDL2NSData_allocWithZoneIMP=
        [GDL2NSDataClass methodForSelector:@selector(allocWithZone:)];

      GDL2NSData_dataWithBytes_lengthIMP=
        [GDL2NSDataClass methodForSelector:@selector(dataWithBytes:length:)];

      GDL2NSString_stringWithCString_lengthIMP=
        [GDL2NSStringClass methodForSelector:@selector(stringWithCString:length:)];

      GDL2NSString_stringWithCStringIMP=
        [GDL2NSStringClass methodForSelector:@selector(stringWithCString:)];

      GDL2NSString_defaultCStringEncodingIMP=
        (GDL2IMP_NSStringEncoding)[GDL2NSStringClass methodForSelector:@selector(defaultCStringEncoding)];

      GDL2MKKD_objectForKeyIMP=[GDL2MKKDClass instanceMethodForSelector:@selector(objectForKey:)];
      GDL2MKKD_setObjectForKeyIMP=[GDL2MKKDClass instanceMethodForSelector:@selector(setObject:forKey:)];
      GDL2MKKD_removeObjectForKeyIMP=[GDL2MKKDClass instanceMethodForSelector:@selector(removeObjectForKey:)];
      GDL2MKKD_hasKeyIMP=(GDL2IMP_BOOL)[GDL2MKKDClass instanceMethodForSelector:@selector(hasKey:)];
      GDL2MKKD_indexForKeyIMP=(GDL2IMP_UINT)[GDL2MKKDClass instanceMethodForSelector:@selector(indexForKey:)];
      GDL2EOMKKDInitializer_indexForKeyIMP=(GDL2IMP_UINT)[GDL2EOMKKDInitializerClass instanceMethodForSelector:@selector(indexForKey:)];

      GDL2EOEditingContext_recordObjectGlobalIDIMP==[GDL2EOEditingContextClass instanceMethodForSelector:@selector(recordObject:globalID:)];
      GDL2EOEditingContext_objectForGlobalIDIMP=[GDL2EOEditingContextClass instanceMethodForSelector:@selector(objectForGlobalID:)];
      GDL2EOEditingContext_globalIDForObjectIMP=[GDL2EOEditingContextClass instanceMethodForSelector:@selector(globalIDForObject:)];

      GDL2NSMutableArray_arrayWithCapacityIMP=[GDL2NSMutableArrayClass 
                                                methodForSelector:@selector(arrayWithCapacity:)];

      GDL2NSMutableArray_arrayWithArrayIMP=[GDL2NSMutableArrayClass 
                                             methodForSelector:@selector(arrayWithArray:)];

      GDL2NSMutableArray_arrayIMP=[GDL2NSMutableArrayClass 
                                    methodForSelector:@selector(array)];

      GDL2NSArray_arrayIMP=[GDL2NSArrayClass 
                             methodForSelector:@selector(array)];

      GDL2NSMutableDictionary_dictionaryWithCapacityIMP=[GDL2NSMutableDictionaryClass 
                                    methodForSelector:@selector(dictionaryWithCapacity:)];

      // ==== Constants ====
      ASSIGN(GDL2NSNumberBool_Yes,[GDL2NSNumberClass numberWithBool:YES]);
      ASSIGN(GDL2NSNumberBool_No,[GDL2NSNumberClass numberWithBool:NO]);

      ASSIGN(GDL2EONull,[EONull null]);

    };
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
          if (GSObjCClass(mkkd)==GDL2MKKDClass
              && GDL2MKKD_objectForKeyIMP)
            imp=GDL2MKKD_objectForKeyIMP;
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
          if (GSObjCClass(mkkd)==GDL2MKKDClass
              && GDL2MKKD_setObjectForKeyIMP)
            imp=GDL2MKKD_setObjectForKeyIMP;
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
          if (GSObjCClass(mkkd)==GDL2MKKDClass
              && GDL2MKKD_removeObjectForKeyIMP)
            imp=GDL2MKKD_removeObjectForKeyIMP;
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
          if (GSObjCClass(mkkd)==GDL2MKKDClass
              && GDL2MKKD_hasKeyIMP)
            imp=GDL2MKKD_hasKeyIMP;
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

unsigned int 
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
          if (GSObjCClass(mkkd)==GDL2MKKDClass
              && GDL2MKKD_indexForKeyIMP)
            imp=GDL2MKKD_indexForKeyIMP;
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

unsigned int
EOMKKDInitializer_indexForKeyWithImpPtr(EOMKKDInitializer* mkkdInit,
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
          if (GSObjCClass(mkkdInit)==GDL2EOMKKDInitializerClass
              && GDL2EOMKKDInitializer_indexForKeyIMP)
            imp=GDL2EOMKKDInitializer_indexForKeyIMP;
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
          if (GSObjCClass(edContext)==GDL2EOEditingContextClass
              && GDL2EOEditingContext_objectForGlobalIDIMP)
            imp=GDL2EOEditingContext_objectForGlobalIDIMP;
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
          if (GSObjCClass(edContext)==GDL2EOEditingContextClass
              && GDL2EOEditingContext_globalIDForObjectIMP)
            imp=GDL2EOEditingContext_globalIDForObjectIMP;
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
          if (GSObjCClass(edContext)==GDL2EOEditingContextClass
              && GDL2EOEditingContext_recordObjectGlobalIDIMP)
            imp=GDL2EOEditingContext_recordObjectGlobalIDIMP;
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
