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

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#endif

#include <EOControl/EOFault.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EODatabaseContext.h>

#include "EOPrivate.h"

// ==== Classes ====
Class GDL2_EODatabaseContextClass=Nil;
Class GDL2_EOAttributeClass=Nil;
Class GDL2_EORelationshipClass=Nil;
Class GDL2_EOEntityClass=Nil;

// ==== IMPs ====
// ==== Init Method ====
void GDL2_EOAccessPrivateInit()
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized = YES;

      GDL2_PrivateInit();

      // ==== Classes ====
      GDL2_EODatabaseContextClass = [EODatabaseContext class];
      GDL2_EOAttributeClass = [EOAttribute class];
      GDL2_EORelationshipClass = [EORelationship class];
      GDL2_EOEntityClass = [EOEntity class];

    };
}

