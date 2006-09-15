/** 
   PostgresPrivate.m <title>PostgresPrivate: various definitions</title>

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#include <Foundation/Foundation.h>

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EONull.h>
#include <EOAccess/EOAttribute.h>

#include "PostgresValues.h"

// ==== Classes ====
Class PSQLA_NSStringClass=Nil;
Class PSQLA_NSNumberClass=Nil;
Class PSQLA_NSDecimalNumberClass=Nil;
Class PSQLA_NSCalendarDateClass=Nil;
Class PSQLA_NSDateClass=Nil;
Class PSQLA_NSMutableArrayClass;
Class PSQLA_EOAttributeClass=Nil;
Class PSQLA_PostgresValuesClass=Nil;

// ==== IMPs ====
IMP PSQLA_NSNumber_allocWithZoneIMP=NULL;
IMP PSQLA_NSDecimalNumber_allocWithZoneIMP=NULL;
IMP PSQLA_NSString_allocWithZoneIMP=NULL;
IMP PSQLA_NSCalendarDate_allocWithZoneIMP=NULL;
IMP PSQLA_NSMutableArray_allocWithZoneIMP=NULL;
IMP PSQLA_EOAttribute_allocWithZoneIMP=NULL;
IMP PSQLA_PostgresValues_newValueForBytesLengthAttributeIMP=NULL;

// ==== Constants ====
NSNumber *PSQLA_NSNumberBool_Yes=nil;
NSNumber *PSQLA_NSNumberBool_No=nil;

EONull   *PSQLA_EONull=nil;
NSArray  *PSQLA_NSArray=nil;
NSString *PSQLA_postgresCalendarFormat=@"%Y-%m-%d %H:%M:%S.%F %z";

// ==== Init Method ====
void
PSQLA_PrivInit(void)
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized = YES;

      // ==== Classes ====
      PSQLA_NSMutableArrayClass=[NSMutableArray class];
      PSQLA_NSStringClass=[NSString class];
      PSQLA_NSNumberClass=[NSNumber class];
      PSQLA_NSDecimalNumberClass=[NSDecimalNumber class];
      PSQLA_NSCalendarDateClass=[NSCalendarDate class];
      PSQLA_NSDateClass=[NSDate class];
      PSQLA_EOAttributeClass = [EOAttribute class];
      PSQLA_PostgresValuesClass = [PostgresValues class];

      // ==== IMPs ====
      PSQLA_NSNumber_allocWithZoneIMP=
        [PSQLA_NSNumberClass methodForSelector:@selector(allocWithZone:)];

      PSQLA_NSDecimalNumber_allocWithZoneIMP=
        [PSQLA_NSDecimalNumberClass methodForSelector:@selector(allocWithZone:)];

      PSQLA_NSString_allocWithZoneIMP=
        [PSQLA_NSStringClass methodForSelector:@selector(allocWithZone:)];

      PSQLA_NSCalendarDate_allocWithZoneIMP=
        [PSQLA_NSCalendarDateClass methodForSelector:@selector(allocWithZone:)];

      PSQLA_NSMutableArray_allocWithZoneIMP=
        [PSQLA_NSMutableArrayClass methodForSelector:@selector(allocWithZone:)];

      PSQLA_EOAttribute_allocWithZoneIMP=
        [PSQLA_EOAttributeClass methodForSelector:@selector(allocWithZone:)];

      PSQLA_PostgresValues_newValueForBytesLengthAttributeIMP=
        [PSQLA_PostgresValuesClass methodForSelector:@selector(newValueForBytes:length:attribute:)];

      // ==== Constants ====
      ASSIGN(PSQLA_NSNumberBool_Yes,[PSQLA_NSNumberClass numberWithBool:YES]);
      ASSIGN(PSQLA_NSNumberBool_No,[PSQLA_NSNumberClass numberWithBool:NO]);

      ASSIGN(PSQLA_EONull,[EONull null]);
      ASSIGN(PSQLA_NSArray,[NSArray array]);

    };
}
