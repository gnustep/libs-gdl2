/** 
   EOPriv.m <title>EOPriv: various definitions</title>

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

#include <EOControl/EOPriv.h>
#include <EOControl/EOFault.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOAccess/EODatabaseContext.h>

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
Class GDL2EODatabaseContextClass=Nil;
Class GDL2EOEditingContextClass=Nil;
Class GDL2EOAttributeClass=Nil;

SEL GDL2_newSEL=NULL;
SEL GDL2_allocWithZoneSEL=NULL;
SEL GDL2_isEqualToStringSEL=NULL;
SEL GDL2_appendStringSEL=NULL;
SEL GDL2_stringWithCString_lengthSEL=NULL;
SEL GDL2_stringWithCStringSEL=NULL;
SEL GDL2_addObjectSEL=NULL;
SEL GDL2_objectAtIndexSEL=NULL;
SEL GDL2_indexOfObjectIdenticalToSEL=NULL;
SEL GDL2_nextObjectSEL=NULL;
SEL GDL2_takeStoredValueForKeySEL=NULL;
SEL GDL2_snapshotForGlobalIDSEL=NULL;
SEL GDL2_objectForKeySEL=NULL;
SEL GDL2_respondsToSelectorSEL=NULL;
SEL GDL2_setObjectForKeySEL=NULL;
SEL GDL2_removeObjectForKeySEL=NULL;
SEL GDL2_hasKeySEL=NULL;
SEL GDL2_indexForKeySEL=NULL;

SEL GDL2_recordObjectGlobalIDSEL=NULL;
SEL GDL2_objectForGlobalIDSEL=NULL;
SEL GDL2_globalIDForObjectSEL=NULL;

IMP GDL2NSAutoreleasePool_newIMP=NULL;
IMP GDL2NSNumber_allocWithZoneIMP=NULL;
IMP GDL2NSDecimalNumber_allocWithZoneIMP=NULL;
IMP GDL2NSString_allocWithZoneIMP=NULL;
IMP GDL2NSCalendarDate_allocWithZoneIMP=NULL;
IMP GDL2NSData_allocWithZoneIMP=NULL;

IMP GDL2NSString_stringWithCString_lengthIMP=NULL;
IMP GDL2NSString_stringWithCStringIMP=NULL;

IMP GDL2MKKD_objectForKeyIMP=NULL;
IMP GDL2MKKD_setObjectForKeyIMP=NULL;
IMP GDL2MKKD_removeObjectForKeyIMP=NULL;
GDL2IMP_BOOL GDL2MKKD_hasKeyIMP=NULL;
GDL2IMP_UINT GDL2MKKD_indexForKeyIMP=NULL;
GDL2IMP_UINT GDL2EOMKKDInitializer_indexForKeyIMP=NULL;

IMP GDL2EODatabaseContext_snapshotForGlobalIDIMP=NULL;
IMP GDL2EOEditingContext_recordObjectGlobalIDIMP=NULL;
IMP GDL2EOEditingContext_objectForGlobalIDIMP=NULL;
IMP GDL2EOEditingContext_globalIDForObjectIMP=NULL;

NSNumber* GDL2NSNumberBool_Yes=nil;
NSNumber* GDL2NSNumberBool_No=nil;

EONull* GDL2EONull=nil;

NSCharacterSet* GDL2_shellPatternCharacterSet=nil;


void GDL2PrivInit()
{
  static BOOL initialized=NO;
  if (!initialized)
    {
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
      GDL2EODatabaseContextClass = [EODatabaseContext class];
      GDL2EOEditingContextClass = [EOEditingContext class];
      GDL2EOAttributeClass = [EOAttribute class];

      GDL2_newSEL=@selector(new);
      GDL2_allocWithZoneSEL=@selector(alloc);
      GDL2_isEqualToStringSEL=@selector(isEqualToString:);
      GDL2_appendStringSEL=@selector(appendString:);
      GDL2_stringWithCString_lengthSEL=@selector(stringWithCString:length:);
      GDL2_stringWithCStringSEL=@selector(stringWithCString:);
      GDL2_addObjectSEL=@selector(addObject:);
      GDL2_objectAtIndexSEL=@selector(objectAtIndex:);
      GDL2_indexOfObjectIdenticalToSEL=@selector(indexOfObjectIdenticalTo:);
      GDL2_nextObjectSEL=@selector(nextObject);
      GDL2_takeStoredValueForKeySEL=@selector(takeStoredValue:forKey:);
      GDL2_snapshotForGlobalIDSEL=@selector(snapshotForGlobalID:);
      GDL2_objectForKeySEL=@selector(objectForKey:);
      GDL2_setObjectForKeySEL=@selector(setObject:forKey:);
      GDL2_removeObjectForKeySEL=@selector(removeObjectForKey:);
      GDL2_respondsToSelectorSEL=@selector(respondsToSelector:);
      GDL2_hasKeySEL=@selector(hasKey:);
      GDL2_indexForKeySEL=@selector(indexForKey:);
      GDL2_snapshotForGlobalIDSEL=@selector(snapshotForGlobalID:);
      GDL2_recordObjectGlobalIDSEL=@selector(recordObject:globalID:);
      GDL2_objectForGlobalIDSEL=@selector(objectForGlobalID:);
      GDL2_globalIDForObjectSEL=@selector(globalIDForObject:);

      GDL2NSAutoreleasePool_newIMP=[GDL2NSAutoreleasePoolClass 
                                     methodForSelector:GDL2_newSEL];

      GDL2NSNumber_allocWithZoneIMP=[GDL2NSNumberClass 
                              methodForSelector:GDL2_allocWithZoneSEL];

      GDL2NSDecimalNumber_allocWithZoneIMP=[GDL2NSDecimalNumberClass
                                     methodForSelector:GDL2_allocWithZoneSEL];

      GDL2NSString_allocWithZoneIMP=[GDL2NSStringClass 
                              methodForSelector:GDL2_allocWithZoneSEL];

      GDL2NSCalendarDate_allocWithZoneIMP=[GDL2NSCalendarDateClass 
                                    methodForSelector:GDL2_allocWithZoneSEL];

      GDL2NSData_allocWithZoneIMP=[GDL2NSDataClass 
                                    methodForSelector:GDL2_allocWithZoneSEL];

      GDL2NSString_stringWithCString_lengthIMP=
        [GDL2NSStringClass methodForSelector:GDL2_stringWithCString_lengthSEL];

      GDL2NSString_stringWithCStringIMP=
        [GDL2NSStringClass methodForSelector:GDL2_stringWithCStringSEL];

      GDL2MKKD_objectForKeyIMP=[GDL2MKKDClass instanceMethodForSelector:GDL2_objectForKeySEL];
      GDL2MKKD_setObjectForKeyIMP=[GDL2MKKDClass instanceMethodForSelector:GDL2_setObjectForKeySEL];
      GDL2MKKD_removeObjectForKeyIMP=[GDL2MKKDClass instanceMethodForSelector:GDL2_removeObjectForKeySEL];
      GDL2MKKD_hasKeyIMP=(GDL2IMP_BOOL)[GDL2MKKDClass instanceMethodForSelector:GDL2_hasKeySEL];
      GDL2MKKD_indexForKeyIMP=(GDL2IMP_UINT)[GDL2MKKDClass instanceMethodForSelector:GDL2_indexForKeySEL];
      GDL2EOMKKDInitializer_indexForKeyIMP=(GDL2IMP_UINT)[GDL2EOMKKDInitializerClass instanceMethodForSelector:GDL2_indexForKeySEL];

      GDL2EODatabaseContext_snapshotForGlobalIDIMP=[GDL2EODatabaseContextClass instanceMethodForSelector:GDL2_snapshotForGlobalIDSEL];

      GDL2EOEditingContext_recordObjectGlobalIDIMP==[GDL2EOEditingContextClass instanceMethodForSelector:GDL2_recordObjectGlobalIDSEL];
      GDL2EOEditingContext_objectForGlobalIDIMP=[GDL2EOEditingContextClass instanceMethodForSelector:GDL2_objectForGlobalIDSEL];
      GDL2EOEditingContext_globalIDForObjectIMP=[GDL2EOEditingContextClass instanceMethodForSelector:GDL2_globalIDForObjectSEL];

      ASSIGN(GDL2NSNumberBool_Yes,[GDL2NSNumberClass numberWithBool:YES]);
      ASSIGN(GDL2NSNumberBool_No,[GDL2NSNumberClass numberWithBool:NO]);

      ASSIGN(GDL2EONull,[EONull null]);

      ASSIGN(GDL2_shellPatternCharacterSet,([NSCharacterSet characterSetWithCharactersInString:@"*?%_"]));
    };
}
