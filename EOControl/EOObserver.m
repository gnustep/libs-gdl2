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

static char rcsId[] = "$Id$";

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSNotification.h>

#import <EOControl/EOClassDescription.h>
#import <EOControl/EOKeyValueCoding.h>
#import <EOControl/EONull.h>
#import <EOControl/EOObserver.h>


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
