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

#import <Foundation/NSNull.h>
#import <Foundation/NSString.h> 
#import <Foundation/NSDebug.h> 

#import <EOControl/EONull.h>
#import <EOControl/EODebug.h>


@implementation EONull

static EONull *sharedEONull = nil;

#ifndef FOUNDATION_HAS_KVC

+ (void)initialize
{
  // THREAD - do this operation under a lock
  sharedEONull = (EONull *)NSAllocateObject(self, 0, NSDefaultMallocZone());
}

+ null
{
  return sharedEONull;
}

+ allocWithZone
{
  return sharedEONull;
}

- copy
{
  return self;
}

- copyWithZone: (NSZone *)zone
{
  return self;
}

// One cannot destroy the shared null object

- (id)retain
{
  return self;
}

- (id)autorelease
{
  return self;
}

- (void)release
{
}

- (void)dealloc
{
}

#else
+ (void)initialize
{
  sharedEONull = (EONull *)[NSNull null];
}

+ null
{
  return sharedEONull;
}

+ allocWithZone
{
  return sharedEONull;
}

- copy
{
  return sharedEONull;
}

- copyWithZone: (NSZone *)zone
{
  return sharedEONull;
}

- (id)retain
{
  return sharedEONull;
}

- (id)autorelease
{
  return sharedEONull;
}

- (void)release
{
}

- (void)dealloc
{
}

// OK
- (id)valueForKey: (NSString *)key
{
  return self;
}

#endif

- (NSString *)sqlString
{
  EOFLOGObjectFnStart();
  EOFLOGObjectFnStop();
  return @"NULL";
}

@end /* EONull */

#ifdef FOUNDATION_HAS_KVC
@implementation NSNull (EOSQLFormatting)

- (NSString *)sqlString
{
  EOFLOGObjectFnStart();
  EOFLOGObjectFnStop();

  return @"NULL";
}

- (id)valueForKey:(NSString *)key
{
  return self;
};

@end
#endif


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
