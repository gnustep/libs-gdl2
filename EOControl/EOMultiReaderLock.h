/* -*-objc-*-
   EOMultiReaderLock.h

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: David Ayers <d.ayers@inode.at>
   Date: November 2005

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

#ifndef	__EOControl_EOMultiReaderLock_h__
#define	__EOControl_EOMultiReaderLock_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSMapTable.h>
#else
#include <Foundation/Foundation.h>
#endif

@class NSConditionLock;
@class NSThread;

/*
 * WARNING !!!
 * This class is in the middle of it's initial experimental implementation
 * Do not use it yet!  But if you'd like to help implementing, please
 * feel free.
 */
@interface EOMultiReaderLock : NSObject
{
  NSConditionLock *_mutex;
  int _readerFinishedCondition;
  int _writerFinishedCondition;
  NSMapTable *_readerThreads;
  unsigned int _writerLockCount;
  volatile NSThread *_writerLockThread;
}

- (BOOL)tryLockForReading;
- (void)lockForReading;
- (void)unlockForReading;

- (BOOL)tryLockForWriting;
- (void)lockForWriting;
- (void)unlockForWriting;

- (void)suspendReaderLocks;
- (void)retrieveReaderLocks;
@end

#endif
