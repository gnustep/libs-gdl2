/** 
   EONull.m <title>EONull Class</title>

   Copyright (C) 1996-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: 1996

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EONull.h>
#include <EOControl/EODebug.h>


@implementation EONull (EOSQLFormatting)

- (NSString *)sqlString
{



  return @"NULL";
}

//OK
- (id)valueForKey:(NSString *)key
{
  return self;
}

@end


/*
 * We keep this class to support NSClassFromString() which
 * scripting libraries may depend on.  Note that this is
 * not a fail-safe implementation.  You should rely on
 * [EONull+null] and pointer comparison.  Do not rely on
 * [obj isKindOfClass: NSClassFromString(@"EONull")]
 * or similar constructs.  They will return wrong results.
 * This is a small backdraw from using the new extension classes
 * in base / Foundation.
 */
#undef EONull
@interface EONull : NSNull
@end
@implementation EONull
+ (Class) class
{
  return [NSNull class];
}

+ (id) allocWithZone: (NSZone *)zone
{
  return [NSNull null];
}

+ null
{
  return [NSNull null];
}

@end

