/* 
   EOObserver.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __EOObserver_h__
#define __EOObserver_h__


#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

@class NSArray;


@interface NSObject (EOObserver)

- (void)willChange;

@end

@protocol EOObserving <NSObject>
- (void)objectWillChange: (id)subject;

@end

@interface EOObserverCenter : NSObject

+ (void)addObserver: (id <EOObserving>)observer forObject: (id)object;

+ (void)removeObserver: (id <EOObserving>)observer forObject: (id)object;

+ (void)notifyObserversObjectWillChange: (id)object;

+ (NSArray *)observersForObject: (id)object;

+ (id)observerForObject: (id)object ofClass: (Class)targetClass;

+ (void)suppressObserverNotification;
+ (void)enableObserverNotification;

+ (unsigned)observerNotificationSuppressCount;

+ (void)addOmniscientObserver: (id <EOObserving>)observer;
+ (void)removeOmniscientObserver: (id <EOObserving>)observer;

@end


@class EODelayedObserverQueue;

typedef enum {
  EOObserverPriorityImmediate,
  EOObserverPriorityFirst,
  EOObserverPrioritySecond,
  EOObserverPriorityThird,
  EOObserverPriorityFourth,
  EOObserverPriorityFifth,
  EOObserverPrioritySixth,
  EOObserverPriorityLater
} EOObserverPriority;

#define EOObserverNumberOfPriorities ((unsigned)EOObserverPriorityLater + 1)


@interface EODelayedObserver : NSObject <EOObserving>
{
  @public
    EODelayedObserver *_next;   // linked list.  Nil if not on list.
}

- (void)objectWillChange: (id)subject;

- (EOObserverPriority)priority;

- (EODelayedObserverQueue *)observerQueue;

// Must be implemented by subclasses
- (void)subjectChanged;

- (void)discardPendingNotification;

@end

// used with NSRunLoop's performSelector:target:argument:order:modes:
enum
{
  EOFlushDelayedObserversRunLoopOrdering = 400000
};


@interface EODelayedObserverQueue : NSObject
{
  EODelayedObserver *_queue[EOObserverNumberOfPriorities];  // lists for each priority
  unsigned _highestNonEmptyQueue;
  BOOL _haveEntryInNotificationQueue;
  NSArray *_modes;
}

+ (EODelayedObserverQueue *)defaultObserverQueue;

- (void)enqueueObserver: (EODelayedObserver *)observer;
- (void)dequeueObserver: (EODelayedObserver *)observer;

- (void)notifyObserversUpToPriority: (EOObserverPriority)lastPriority;

- (void)setRunLoopModes: (NSArray *)modes;
- (NSArray *)runLoopModes;

@end


@interface EOObserverProxy : EODelayedObserver
{
  id _target;
  SEL _action;
  EOObserverPriority _priority;
}

- initWithTarget: (id)target
	  action: (SEL)action
	priority: (EOObserverPriority)priority;

@end

#endif
