/* -*-objc-*-
   EOGlobalID.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOGlobalID_h__
#define __EOGlobalID_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>

/**
 * This notification is intended to allow EOTemporaryGlobalIDs
 * to be replaced with the corresponding EOKeyGlobalIDs.  In theory 
 * one could interpret this as a mechanism to allow primary key
 * attributes to be mutable class properties.  Even though EOF also posts
 * this notification in that case, it fails to consistently propagate
 * the new value through relationships.  GDL2 may attempt to correct
 * that shortcoming in the future, but it may have serious performance
 * implications.
 */
GDL2CONTROL_EXPORT NSString *EOGlobalIDChangedNotification;

@interface EOGlobalID : NSObject <NSCopying>

- (BOOL)isEqual: (id)other;
- (unsigned)hash;

- (BOOL)isTemporary;

@end

enum {
  EOUniqueBinaryKeyLength = 12
};


@interface EOTemporaryGlobalID : EOGlobalID <NSCoding>
{
  unsigned _refCount;
  unsigned char _bytes[EOUniqueBinaryKeyLength];
}

+ (EOTemporaryGlobalID *)temporaryGlobalID;
+ (void)assignGloballyUniqueBytes: (unsigned char *)buffer;
/* Sequence (2) - ProcessID (2) - Time (4) - IP (4) */

- (BOOL)isTemporary;

- (void)encodeWithCoder: (NSCoder *)coder;
- (id)initWithCoder: (NSCoder *)decoder;

@end

#endif
