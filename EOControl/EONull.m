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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSNull.h>
#include <Foundation/NSString.h> 
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <gnustep/base/GNUstep.h>
#endif

#include <EOControl/EONull.h>
#include <EOControl/EODebug.h>


@implementation EONull

static EONull *sharedEONull = nil;

+ (void) initialize
{
  sharedEONull = (EONull *)[NSNull null];
}

+ null
{
  return sharedEONull;
}

+ (id) allocWithZone:(NSZone *)zone
{
  return sharedEONull;
}

- (id) copy
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
  return sharedEONull;
}

- (id) copyWithZone: (NSZone *)zone
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
  return sharedEONull;
}

- (id) retain
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
  return sharedEONull;
}

- (id) autorelease
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
  return sharedEONull;
}

- (void) release
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
}

- (void) dealloc
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
}

- (id)valueForKey: (NSString *)key
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
  return nil;
}

- (NSString *) sqlString
{
  NSAssert1(NO,@"EONull instance received:%@",NSStringFromSelector(_cmd));
  return nil;
}

@end /* EONull */

@implementation NSNull (EOSQLFormatting)

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
  return (((id)self) == sharedEONull || (((id)self) == [NSNull null]));
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
