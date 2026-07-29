/** 
   PostgreSQLPrivate.m <title>PostgreSQLPrivate: various definitions</title>

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

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EONull.h>
#include <EOAccess/EOAttribute.h>

// ==== Classes ====
Class PSQLA_NSStringClass=Nil;
Class PSQLA_NSNumberClass=Nil;
Class PSQLA_NSDecimalNumberClass=Nil;
Class PSQLA_NSCalendarDateClass=Nil;
Class PSQLA_NSDateClass=Nil;
Class PSQLA_NSMutableArrayClass;
Class PSQLA_EOAttributeClass=Nil;

// ==== IMPs ====

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

      // ==== IMPs ====







      // ==== Constants ====
      ASSIGN(PSQLA_NSNumberBool_Yes,[PSQLA_NSNumberClass numberWithBool:YES]);
      ASSIGN(PSQLA_NSNumberBool_No,[PSQLA_NSNumberClass numberWithBool:NO]);

      ASSIGN(PSQLA_EONull,[EONull null]);
      ASSIGN(PSQLA_NSArray,[NSArray array]);

    };
}
