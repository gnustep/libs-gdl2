/* -*-objc-*-
   EOMultiReaderLock.m

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>
   Date: November 2005

   This file is part of the GNUstep Database Library.

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
*/

#include "EOMultiReaderLock.h"

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSLock.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSMapTable.h>
#endif

#define LCK_CND_UNLOCKD 0
#define LCK_CND_READING 1
#define LCK_CND_WAITWRT 2
#define LCK_CND_WRITING 3

#define LCK_CND_ALLOW_READER_LOCK 0
#define LCK_CND_ALLOW_WRITER_LOCK 1

/**
 * WARNING !!!
 * This class is in the middle of its initial experimental implementation
 * Do not use it yet!  But if you'd like to help implementing, please
 * feel free.
 * EOMultiReaderLock is a recursive lock which allows multiple
 * threads to hold a lock for reading but only one thread
 * to hold a lock for writing and only when all reading locks
 * have been relinquished.  Once thread requests for a lock to write
 * further requests for a read lock are blocked until the write lock
 * has been granted and relinquished again.  But this only holds true
 * if the thread requesting the reading lock does not already hold
 * a reading lock in which case it is granted as it is assumed that
 * this thread needs to continue to release the previously acquired lock
 * or locks.
 */
@implementation EOMultiReaderLock

- (id)init
{
  if ((self = [super init]))
    {
      _mutex = [[NSConditionLock alloc] initWithCondition: LCK_CND_UNLOCKD];
      _readerThreads = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
					NSIntMapValueCallBacks, 32);
    }
  return self;
}
/**
 * <p>Tries to obtain a lock for reading.  Returns NO upon failure.</p>
 * <p>If the thread already holds this lock for reading or writing
 * the method returns true.  All successful locks must be paired with
 * corresponding unlocks.</p>
 */
- (BOOL)tryLockForReading
{
  NSThread *ct = [NSThread currentThread];
  NSInteger cnt = (NSInteger)NSMapGet(_readerThreads,ct);
  BOOL flag;

  if (ct == _writerLockThread)
    {
      NSMapInsert(_readerThreads,ct,(void *)(++cnt));
      return YES;
    }

  if (cnt > 0)
    {
      NSMapInsert(_readerThreads,ct,(void *)(++cnt));
      return YES;
    }

  if ((flag = [_mutex tryLock]))
    {
      if (_writerLockThread)
	{
	  flag = NO;
	}
      else
	{
	  NSMapInsert(_readerThreads,ct,(void *)(++cnt));
	  flag = YES;
	}
      [_mutex unlock];
    }

  return flag;
}

/**
 * <p>Blocks until a lock for reading is obtained.</p>
 * <p>If the thread already holds this lock for reading or writing
 * the method returns immediatly.  All successful locks must be paired with
 * corresponding unlocks.</p>
 */
- (void)lockForReading
{
  NSThread *ct = [NSThread currentThread];

  int cnt = (int)NSMapGet(_readerThreads,ct);

  if (ct == _writerLockThread)
    {
      NSMapInsert(_readerThreads,ct,(void *)(++cnt));
      return;
    }

  if (cnt > 0)
    {
      NSMapInsert(_readerThreads,ct,(void *)(++cnt));
      return;
    }

  while (1)
    {
      [_mutex lock];

      if (_writerLockThread)
	{
	  [_mutex unlock];
	  continue;
	}
      else
	{
	  NSMapInsert(_readerThreads,ct,(void *)(++cnt));
	  [_mutex unlock];
	  break;
	}
    }
}

/**
 * <p>Relinquishes obtained a previously obtained lock for reading.</p>
 * <p>If the thread already holds this lock for reading or writing
 * the method returns immediatly.  All successful locks must be paired with
 * corresponding unlocks.</p>
 */
- (void)unlockForReading
{
  NSThread *ct = [NSThread currentThread];
  int cnt = (int)NSMapGet(_readerThreads,ct);
  if (--cnt)
    {
      NSMapInsert(_readerThreads,ct,(void *)(cnt));
    }
  else
    {
      NSMapRemove(_readerThreads,ct);
    }
}

/**
 * <p>Tries to obtain a lock for writing.  Returns NO upon failure.</p>
 * <p>If the thread already holds this lock for reading or writing
 * the method returns true.  All successful locks must be paired with
 * corresponding unlocks.</p>
 */
- (BOOL)tryLockForWriting
{
  NSThread *ct = [NSThread currentThread];
  
  if (ct == _writerLockThread)
    {
      _writerLockCount++;
      return YES;
    }
  if (_writerLockThread) return NO;
  if ([_mutex tryLock])
    {
      int entries;
      if (_writerLockThread)
	{
	  [_mutex unlock];
	  return NO;
	}
      entries = (int)NSCountMapTable(_readerThreads);
      if (entries > 1)
	{
	  [_mutex unlock];
	  return NO;
	}
      if (entries == 0 || NSMapGet(_readerThreads,ct))
	{
	  _writerLockThread = ct;
	  _writerLockCount = 1;
	  [_mutex unlock];
	  return YES;
	}
      [_mutex unlock];
      return NO;
    }
  return NO;
}

/**
 * <p>Blocks until a lock for writing is obtained.</p>
 * <p>If the thread already holds this lock for reading or writing
 * the method returns immediatly.  All successful locks must be paired with
 * corresponding unlocks.</p>
 */
- (void)lockForWriting
{
  return;
}

/**
 * <p>Relinquishes obtained a previously obtained lock for writing.</p>
 * <p>If the thread already holds this lock for reading or writing
 * the method returns immediatly.  All successful locks must be paired with
 * corresponding unlocks.</p>
 */
- (void)unlockForWriting
{
  return;
}

/**
 * <p>Disables the currently registered reader locks.</p>
 * <p>Subsequent calls may increment the count for it's thread
 * but the lock is not reactivated.</p>
 */
- (void)suspendReaderLocks
{
  return;
}

/**
 * <p>Reenables the current registred locks.</p>
 * <p>This method blocks as long as a writer lock is held by
 * another thread.</p>
 */
- (void)retrieveReaderLocks
{
  return;
}

@end
