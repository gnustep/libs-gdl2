/** 
   EONull.m <title>EONull Class</title>

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: 1996

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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
  EOFLOGObjectFnStart();
  EOFLOGObjectFnStop();

  return @"NULL";
}

//OK
- (id)valueForKey:(NSString *)key
{
  return self;
}

@end


@implementation NSObject (EONull)

- (BOOL)isEONull
{  
  return ((id)self == [NSNull null]);
}

- (BOOL)isNotEONull
{
  return ![self isEONull];
}

@end

BOOL isNilOrEONull(id v)
{
  return ((!v) || [v isEONull]);
}

/*
 * We keep this class to support NSClassFromString() which
 * scripting libraries my depend on.  Note that this is
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

