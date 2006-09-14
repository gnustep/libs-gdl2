/** 
   EOGlobalID.m <title>EOGlobalID</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

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

#ifdef GNUSTEP
#include <Foundation/NSCoder.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSHost.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EOGlobalID.h>
#include <EOControl/EODebug.h>

#include <string.h>

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

- (BOOL)isEqual: (id)other
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
  return RETAIN(self);
}

@end


@implementation EOTemporaryGlobalID

static unsigned short sequence = (unsigned short)-1;

+ (EOTemporaryGlobalID *)temporaryGlobalID
{
  return [[[self alloc] init] autorelease];
}

/**
 * Fills the supplied buffer with 12 bytes that are unique to the
 * subnet.  The first two bytes encode a sequence of the process.  
 * Then two bytes encode the process ID followed by four bytes which
 * encode a time stamp.  The last four bytes encode the IP address.  
 * The caller must insure that the buffer pointed to is large enough
 * to hold the twelve bytes.
 */
+ (void)assignGloballyUniqueBytes: (unsigned char *)buffer
{
  static int pid = 0;
  static unsigned char ipComp[4];
  unsigned char *bPtr;
  unsigned short seq;
  unsigned int i;
  union { NSTimeInterval interval; unsigned long stamp; } time;

  EOFLOGObjectFnStart();

  if (pid == 0)
    {
      NSString *ipString;
      NSArray *ipComps;

      pid = [[NSProcessInfo processInfo] processIdentifier];
      pid %= 0xFFFF;

      ipString = [[NSHost currentHost] address];
      ipComps = [ipString componentsSeparatedByString: @"."];

      for (i=0;  i<4; i++)
	{
	  NSString *comp = [ipComps objectAtIndex: i];
	  ipComp[i] = (unsigned char)[comp intValue];
	}
    }

  memset (buffer, 0, 12);

  seq = sequence-- % 0xFFFF;
  bPtr = (unsigned char *)&seq;
  buffer[0] = bPtr[0];
  buffer[1] = bPtr[1];

  bPtr = (unsigned char *)&pid;
  buffer[2] = bPtr[0];
  buffer[3] = bPtr[1];

  time.interval = [NSDate timeIntervalSinceReferenceDate];
  time.stamp %= 0xFFFFFFFF;
  bPtr = (unsigned char *)&time.stamp;
  buffer[4] = bPtr[0];
  buffer[5] = bPtr[1];
  buffer[6] = bPtr[2];
  buffer[7] = bPtr[3];

  buffer[8]  = ipComp[0];
  buffer[9]  = ipComp[1];
  buffer[10] = ipComp[2];
  buffer[11] = ipComp[3];

  if (sequence == 0)
    {
      sequence = (unsigned short)-1;
    }
  
  EOFLOGObjectFnStop();
}

- (id)init
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

- (BOOL)isEqual: (id)other
{
  if (self == other)
    return YES;

  if ([other isKindOfClass: [EOTemporaryGlobalID class]] == NO)
    return NO;

  if (!memcmp(_bytes, ((EOTemporaryGlobalID *)other)->_bytes, sizeof(_bytes)))
    return YES;

  return NO;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(unsigned) at: &_refCount];
  [coder encodeValueOfObjCType: @encode(unsigned char[12]) at: _bytes];
}

- (id)initWithCoder: (NSCoder *)coder
{
  self = [super init];

  [coder decodeValueOfObjCType: @encode(unsigned) at: &_refCount];
  [coder decodeValueOfObjCType: @encode(unsigned char[12]) at: _bytes];

  return self;
}

- (NSString *)description
{
  unsigned char dst[(EOUniqueBinaryKeyLength<<1)   /* 2 x buffer */
		    + (EOUniqueBinaryKeyLength>>2) /* + 1 space per 4 byte */
		    + 1];                          /* + terminator */
  unsigned int i,j;

  #define num2char(num) ((num) < 0xa ? ((num)+'0') : ((num)+0x57))
  for (i = 0, j = 0; i < EOUniqueBinaryKeyLength; i++, j++)
    {
      dst[j] = num2char((_bytes[i]>>4) & 0x0f);
      dst[++j] = num2char(_bytes[i] & 0x0f);

      /* Insert a space per 4 bytes.  */
      if ((i & 3) == 3 && i < EOUniqueBinaryKeyLength-1)
	{
	  dst[++j] = ' ';
	}
    }
  dst[j] = 0;
  return [NSString stringWithFormat: @"<%s %s>",
		   GSClassNameFromObject(self), dst];
}

@end
