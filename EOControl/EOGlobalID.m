/** 
   EOGlobalID.m <title>EOGlobalID</title>

   Copyright (C) 2000-2003 Free Software Foundation, Inc.

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

#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

#import <EOControl/EOGlobalID.h>
#import <EOControl/EODebug.h>

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>


NSString *EOGlobalIDChangedNotification = @"EOGlobalIDChangedNotification";


@implementation EOGlobalID

+ (void)initialize
{
  if (self == [EOGlobalID class])
    {
      Class cls = NSClassFromString(@"EODatabaseContext");

      if (cls != Nil)
	[cls class]; // Insure correct initialization.
    }
}

- (BOOL)isEqual: other
{
  return NO;
}

- (unsigned)hash
{
  return 0;
}

- (BOOL)isTemporary
{
  return NO;
}

- (id)copyWithZone: (NSZone *)zone
{
  EOGlobalID *gid = [[[self class] alloc] init];

  return gid;
}

@end


@implementation EOTemporaryGlobalID

static unsigned short sequence = 65535;
static unsigned long sequenceRev = 0;


+ (EOTemporaryGlobalID *)temporaryGlobalID
{
  return [[[self alloc] init] autorelease];
}

// < Sequence [2], ProcessID [2] , Time [4], IP Addr [4] >
+ (void)assignGloballyUniqueBytes: (unsigned char *)buffer
{
  EOFLOGObjectFnStart();
 // sprintf(buffer, "%02x%02x%04x%04x", sequence++ % 0xff, 0, (unsigned int)time( NULL ) % 0xffffffff, 0); // <-- overwrite memory

    // buffer should have space for EOUniqueBinaryKeyLength (12) bytes.
    // Assigns a world-wide unique ID made up of:
    // < Sequence [2], ProcessID [2] , Time [4], IP Addr [4] >

  //printf("sequence : %d (%02x,%02x,%04x,%04x)\n",sequence -1, (sequence - 1) % 0xff, getpid() % 0xff, (unsigned int)time( NULL ) % 0xffff, (sequenceRev+1) % 0xffff);

  snprintf(buffer, 12, 
           "%02x%02x%04x%04x", 
           sequence-- % 0xff, 
           getpid() % 0xff, 
           (unsigned int)time( NULL ) % 0xffff,
           (unsigned int)sequenceRev++ % 0xffff);

  if (sequence == 0)
    sequence = 65535;
  
  if (sequenceRev == 4294967295UL)
    sequenceRev = 1;

  EOFLOGObjectFnStop();

  return; // TODO
}

- init
{
  EOFLOGObjectFnStart();

  if ((self = [super init]))
    {
      [EOTemporaryGlobalID assignGloballyUniqueBytes:_bytes];
    }

  EOFLOGObjectFnStop();

  return self;
}

- (BOOL)isTemporary
{
  return YES;
}

- (unsigned char *)_bytes
{
  return _bytes;
}

- (BOOL)isEqual:other
{
  if (self == other)
    return YES;

  if ([other isKindOfClass: [EOTemporaryGlobalID class]] == NO)
    return NO;

  if (!memcmp(_bytes, [other _bytes], sizeof(_bytes)))
    return YES;

  return NO;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(unsigned) at: &_refCount];
  [coder encodeValueOfObjCType: @encode(unsigned char[]) at: _bytes];
}

- (id)initWithCoder: (NSCoder *)coder
{
  self = [super init];

  [coder decodeValueOfObjCType: @encode(unsigned) at: &_refCount];
  [coder decodeValueOfObjCType: @encode(unsigned char[]) at: _bytes];

  return self;
}

- (id)copyWithZone: (NSZone *)zone
{
  EOTemporaryGlobalID *gid = [super copyWithZone:zone];

  gid->_refCount = _refCount;
  memcpy(gid->_bytes, _bytes, sizeof(_bytes));

  return gid;
}

@end
