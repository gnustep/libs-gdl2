/** 
   EOObserver.m <title>EOObserver</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

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
#include <Foundation/NSObject.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOClassDescription.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EONull.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EODebug.h>

#include <string.h>


@implementation NSObject (EOObserver)

- (void)willChange
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOObserver", @"willChange self=%p", self);
  [EOObserverCenter notifyObserversObjectWillChange: self];

  EOFLOGObjectFnStop();
}

@end


@implementation EOObserverCenter

static NSMapTable *observersMap = NULL;
static NSMutableArray *omniscientObservers=nil;
static unsigned int notificationSuppressCount=0;
static id lastObject;


+ (void)initialize
{
  observersMap = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, //No because it de-fault observed objects NSObjectMapKeyCallBacks, 
				  NSObjectMapValueCallBacks,
				  32);

  omniscientObservers = [NSMutableArray new];
  lastObject = nil;

  notificationSuppressCount = 0;
}

+ (void)addObserver: (id <EOObserving>)observer forObject: (id)object
{
  NSMutableArray *observersArray;

  observersArray = NSMapGet(observersMap, object);

  if (observersArray == nil)
    {
      observersArray = [NSMutableArray arrayWithCapacity: 16];
      [observersArray addObject: observer];

      RETAIN(object); //because not owned by observersMap
      NSMapInsert(observersMap, object, observersArray);
    }
  else
    {
      if ([observersArray containsObject: observer] == NO)
	[observersArray addObject: observer];
    }
}

+ (void)removeObserver: (id <EOObserving>)observer forObject: (id)object
{
  NSMutableArray *observersArray;

  observersArray = NSMapGet(observersMap, object);

  if (observersArray)
    {
      [observersArray removeObject: observer];

      if (![observersArray count])
        {
          NSMapRemove(observersMap, object);
          RELEASE(object); //because not owned by observersMap
        }
    }
}

+ (void)notifyObserversObjectWillChange: (id)object
{
  EOFLOGClassFnStart();

  EOFLOGObjectLevelArgs(@"EOObserver", @"object=%p", object);

  if (!notificationSuppressCount)
    {
      //EOFLOGObjectLevelArgs(@"EOObserver", @"object=%p", object);
      EOFLOGObjectLevelArgs(@"EOObserver", @"object=%p lastObject=%p",
			    object, lastObject);

      if (object == nil)
	lastObject = nil;
      else if (lastObject != object)
	{
          NSMutableArray *observersArray;
          NSEnumerator *obsEnum;
          id<EOObserving> observer;

	  lastObject = object;

	  observersArray = NSMapGet(observersMap, object);

          EOFLOGObjectLevelArgs(@"EOObserver", @"observersArray count=%d",
				[observersArray count]);

	  obsEnum = [observersArray objectEnumerator];
	  while ((observer = [obsEnum nextObject]))
	    [observer objectWillChange: object];

          EOFLOGObjectLevelArgs(@"EOObserver", @"omniscientObservers count=%d",
				[omniscientObservers count]);

	  obsEnum = [omniscientObservers objectEnumerator];
	  while ((observer = [obsEnum nextObject]))
	    [observer objectWillChange: nil];
	}
    }

  EOFLOGClassFnStop();
}

+ (NSArray *)observersForObject: (id)object
{
  return NSMapGet(observersMap, object);
}

+ (id)observerForObject: (id)object ofClass: (Class)targetClass
{
  NSArray *observersArray;

  observersArray = NSMapGet(observersMap, object);

  if (observersArray)
    {
      NSEnumerator *obsEnum;
      id observer;

      obsEnum = [observersArray objectEnumerator];
      while ((observer = [obsEnum nextObject]))
	if ([observer isKindOfClass: targetClass])
	  return observer;
    }

  return nil;
}

+ (void)suppressObserverNotification
{
  notificationSuppressCount++;
}

+ (void)enableObserverNotification
{
  if (notificationSuppressCount)
    notificationSuppressCount--;
  else
    {
      NSLog(@"enableObserverNotification called more than suppressObserverNotification");
    }
}

+ (unsigned int)observerNotificationSuppressCount
{
  return notificationSuppressCount;
}

+ (void)addOmniscientObserver: (id <EOObserving>)observer
{
  if ([omniscientObservers containsObject: observer] == NO)
    [omniscientObservers addObject: observer];
}

+ (void)removeOmniscientObserver: (id <EOObserving>)observer
{
  [omniscientObservers removeObject: observer];
}

@end


@implementation EODelayedObserver

- (void)objectWillChange: (id)subject
{
  [[EODelayedObserverQueue defaultObserverQueue] enqueueObserver: self];
}

- (EOObserverPriority)priority
{
  return EOObserverPriorityThird;
}

- (EODelayedObserverQueue *)observerQueue
{
  return [EODelayedObserverQueue defaultObserverQueue];
}

- (void)subjectChanged
{
}

- (void)discardPendingNotification
{
  [[EODelayedObserverQueue defaultObserverQueue] dequeueObserver: self];
}

@end


static EODelayedObserverQueue *observerQueue;


@implementation EODelayedObserverQueue

+ (EODelayedObserverQueue *)defaultObserverQueue
{
  if (!observerQueue)
    observerQueue = [[self alloc] init];

  return observerQueue;
}

- init
{
  if ((self == [super init]))
    {
      ASSIGN(_modes, [NSArray arrayWithObject: NSDefaultRunLoopMode]);
    }

  return self;
}

- (void)_notifyObservers: (id)ignore
{
  [self notifyObserversUpToPriority: EOObserverPrioritySixth];
  _haveEntryInNotificationQueue = NO;
}

- (void)enqueueObserver: (EODelayedObserver *)observer
{
  EOObserverPriority priority = [observer priority];

  if (priority == EOObserverPriorityImmediate)
    [observer subjectChanged];
  else
    {
      NSAssert2(observer->_next != nil, @"observer:%@ has ->next:%@",
		observer, observer->_next);

      if (_queue[priority])
	{
	  EODelayedObserver *obj = _queue[priority];
	  EODelayedObserver *last = nil;

	  for (; obj != nil && obj != observer; obj = obj->_next)
	    {
	      last = obj;
	    }
	  
	  if (obj == observer)
	    {
	      return;
	    }

	  NSAssert(last != nil, @"Currupted Queue");
	  last->_next = observer;
	}
      else
	_queue[priority] = observer;

      if (priority > _highestNonEmptyQueue)
	{
	  _highestNonEmptyQueue = priority;
	}

      if (_haveEntryInNotificationQueue == NO)
	{
	  [[NSRunLoop currentRunLoop]
	    performSelector: @selector(_notifyObservers:)
	    target: self
	    argument: nil
	    order: EOFlushDelayedObserversRunLoopOrdering
	    modes: _modes];

	  _haveEntryInNotificationQueue = YES;
	}
    }
}

- (void)dequeueObserver: (EODelayedObserver *)observer
{
  EOObserverPriority priority;
  EODelayedObserver *obj, *last = nil;

  if (!observer)
    return;

  priority = [observer priority];
  obj = _queue[priority];

  while (obj)
    {
      if (obj == observer)
	{
	  if (last)
	    {
	      last->_next = obj->_next;
	      obj->_next = nil;
	    }
	  else
	    {
	      _queue[priority] = obj->_next;
	      obj->_next = nil;
	    }


	  if (!_queue[priority])
	    {
	      int i = priority;

	      if (priority >= _highestNonEmptyQueue)
		{
		  for (; i > EOObserverPriorityImmediate; --i)
		    {
		      if (_queue[i])
			{
			  _highestNonEmptyQueue = i;
			  break;
			}
		    }
		}

	      if (priority == EOObserverPriorityFirst
		  || i == EOObserverPriorityImmediate)
		{
		  _highestNonEmptyQueue = EOObserverPriorityImmediate;
		}
	    }

	  return;
	}

      last = obj;
      obj = obj->_next;
    }
}

/**
 * Note that unlike the reference implementation, we dequeue the
 * observer after dispatching [EODelayedObserver-subjectChanged].
 */
- (void)notifyObserversUpToPriority: (EOObserverPriority)priority
{
  EOObserverPriority i = EOObserverPriorityFirst;
  EODelayedObserver *observer = nil;

  while (i <= priority)
    {
      observer = _queue[i];

      if (observer)
	{
	  [self dequeueObserver: observer];
	  [observer subjectChanged];
	  i = EOObserverPriorityFirst;
	}
      else
	{
	  i++;
	}
    }
}

- (void)setRunLoopModes: (NSArray *)modes
{
  ASSIGN(_modes, modes);
}

- (NSArray *)runLoopModes
{
  return _modes;
}

@end


@implementation EOObserverProxy

- initWithTarget: (id)target
	  action: (SEL)action
	priority: (EOObserverPriority)priority
{
  NSEmitTODO();
  return [self notImplemented: _cmd]; //TODO
}

@end
