/** 
   EOObjectStoreCoordinator.m <title>EOObjectStoreCoordinator</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

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
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOObjectStoreCoordinator.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EODebug.h>


@implementation EOObjectStoreCoordinator


static EOObjectStoreCoordinator *defaultCoordinator = nil;

NSString *EOCooperatingObjectStoreWasAdded = @"EOCooperatingObjectStoreWasAdded";
NSString *EOCooperatingObjectStoreWasRemoved = @"EOCooperatingObjectStoreWasRemoved";
NSString *EOCooperatingObjectStoreNeeded = @"EOCooperatingObjectStoreNeeded";


+ (void) initialize
{
  if (self == [EOObjectStoreCoordinator class])
    {
      Class cls = NSClassFromString(@"EODatabaseContext");

      if (cls != Nil)
	[cls class]; // Insure correct initialization.
    }
}

- init
{
  self = [super init];

  _stores = [NSMutableArray new];

  return self;
}

- (void)dealloc
{
  NSDebugMLog(@"dealloc coordinator", "");
  DESTROY(_stores);
  DESTROY(_userInfo);

  [super dealloc];
  NSDebugMLog(@"dealloc coordinator end", "");
}

- (void)addCooperatingObjectStore: (EOCooperatingObjectStore *)store
{
  if ([_stores containsObject:store] == NO)
    {
      [_stores addObject:store];

      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOCooperatingObjectStoreWasAdded
	object: store];
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_objectsChangedInSubStore:)
        name: EOObjectsChangedInStoreNotification
        object: store];
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_invalidatedAllObjectsInSubStore:)
        name: EOInvalidatedAllObjectsInStoreNotification
        object: store];
    }
}

- (void)removeCooperatingObjectStore: (EOCooperatingObjectStore *)store
{
  if ([_stores containsObject:store] == YES)
    {
      [_stores removeObject: store];

      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOCooperatingObjectStoreWasRemoved
	object: store];
      //ODO remove aboservers
    }
}

- (NSArray *)cooperatingObjectStores
{
  return _stores;
}

- (void)forwardUpdateForObject: object
                       changes: (NSDictionary *)changes
{
  [[self objectStoreForObject: object]
    recordUpdateForObject: object changes: changes];
}

- (NSDictionary *)valuesForKeys: (NSArray *)keys
                         object: object
{
  return [[self objectStoreForObject: object]
	   valuesForKeys:keys object: object];
}

- (void) requestStoreForGlobalID: (EOGlobalID *)globalID
              fetchSpecification: (EOFetchSpecification *)fetchSpec
                          object: (id)object
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];

  if (globalID)  [dict setObject: globalID forKey: @"globalID"];
  if (fetchSpec) [dict setObject: fetchSpec forKey: @"fetchSpecification"];
  if (object)    [dict setObject: object forKey: @"object"];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOCooperatingObjectStoreNeeded
    object: self
    userInfo: dict];
}

- (EOCooperatingObjectStore*)objectStoreForGlobalID: (EOGlobalID *)globalID
{
  EOCooperatingObjectStore *store = nil;
  NSEnumerator *storeEnum = nil;
  int num = 2;

  while (num)
    {
      storeEnum = [_stores objectEnumerator];

      while ((store = [storeEnum nextObject]))
	if ([store ownsGlobalID: globalID] == YES)
	  return store;

      NSDebugMLLog(@"gsdb", @"num=%d", num);

      if(--num)
        [self requestStoreForGlobalID: globalID
              fetchSpecification: nil
              object: nil];
    }

  return nil;
}

- (EOCooperatingObjectStore *)objectStoreForObject: object
{
  EOCooperatingObjectStore *store;
  NSEnumerator *storeEnum;
  int num = 2;

  while (num)
    {
      storeEnum = [_stores objectEnumerator];

      while ((store = [storeEnum nextObject]))
	if ([store ownsObject: object] == YES)
	  return store;

      NSDebugMLLog(@"gsdb", @"num=%d", num);

      if(--num)
	[[NSNotificationCenter defaultCenter]
	  postNotificationName: EOCooperatingObjectStoreNeeded
	  object: self
	  userInfo: [NSDictionary dictionaryWithObject: object
				  forKey: @"object"]];
    }

  return nil;
}

- (EOCooperatingObjectStore *)objectStoreForFetchSpecification: (EOFetchSpecification *)fetchSpecification
{
  EOCooperatingObjectStore *store = nil;
  NSEnumerator *storeEnum = nil;
  int num = 2;

  while (num)
    {
      storeEnum = [_stores objectEnumerator];

      while ((store = [storeEnum nextObject]))
	if ([store handlesFetchSpecification: fetchSpecification] == YES)
	  return store;

      NSDebugMLLog(@"gsdb", @"num=%d", num);

      if(--num)
	[[NSNotificationCenter defaultCenter]
	  postNotificationName: EOCooperatingObjectStoreNeeded
	  object: self
	  userInfo: [NSDictionary dictionaryWithObject: fetchSpecification
				  forKey: @"fetchSpecification"]];
    }

  return nil;
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (void)setUserInfo: (NSDictionary *)info
{
  ASSIGN(_userInfo, info);
}


// TODO THREADS

+ (void)setDefaultCoordinator: (EOObjectStoreCoordinator *)coordinator
{
  if (defaultCoordinator)
    DESTROY(defaultCoordinator);

  ASSIGN(defaultCoordinator, coordinator);
}

+ (id)defaultCoordinator
{
  if (defaultCoordinator == nil)
    defaultCoordinator = [EOObjectStoreCoordinator new];

  return defaultCoordinator;
}


// EOObjectStore methods
- (id)faultForGlobalID: (EOGlobalID *)globalID
	editingContext: (EOEditingContext *)context
{
  id fault = nil;
  EOCooperatingObjectStore *objectStore = [self objectStoreForGlobalID:
						  globalID];

  if (objectStore)
    {
      fault = [objectStore faultForGlobalID: globalID
			   editingContext: context];
    }

  return fault;
}

- (NSArray *)arrayFaultWithSourceGlobalID: (EOGlobalID *)globalID
			 relationshipName: (NSString *)name
			   editingContext: (EOEditingContext *)context
{
  return [[self objectStoreForGlobalID: globalID]
	   arrayFaultWithSourceGlobalID: globalID
	   relationshipName: name
	   editingContext: context];
}

- (NSArray *)objectsForSourceGlobalID: (EOGlobalID *)globalID
		     relationshipName: (NSString *)name
		       editingContext: (EOEditingContext *)context
{
  return [[self objectStoreForGlobalID: globalID]
	   objectsForSourceGlobalID: globalID
	   relationshipName: name
	   editingContext: context];
}

- (void)refaultObject: object
	 withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context
{
  [[self objectStoreForGlobalID: globalID]
    refaultObject: object
    withGlobalID: globalID
    editingContext: context];
}

- (void)initializeObject: (id)object
	    withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context
{
  EOCooperatingObjectStore *objectStore = [self objectStoreForGlobalID:
						  globalID];

  [objectStore initializeObject: object
               withGlobalID: globalID
               editingContext: context];
}

- (void)saveChangesInEditingContext: (EOEditingContext *)context
{
  NSArray *insertedObjects;
  EOCooperatingObjectStore *objectStore = nil;
  NSException *exception = nil;
  int i, count;

  EOFLOGObjectFnStart();

  insertedObjects = [context insertedObjects];
  count = [insertedObjects count];

//TODO for inserted: verify

  for (i = 0; i < count; i++)
    {
      id object = [insertedObjects objectAtIndex: i];

      objectStore = [self objectStoreForObject: object];
      //SO WHAT //TODO
    }

  count = [_stores count];

  for (i = 0; i < count; i++)
    {
      objectStore = [_stores objectAtIndex: i];

      if ([objectStore respondsToSelector: @selector(lock)] == YES)
	[(id)objectStore lock];
    }

  NS_DURING
    {
      count = [_stores count];

      for (i = 0; i < count; i++)
        {
          objectStore = [_stores objectAtIndex: i];
          [objectStore prepareForSaveWithCoordinator: self
                       editingContext: context];
        }
      
      count = [_stores count];
      for (i = 0; i < count; i++)
        {
          // Contructs a list of EODatabaseOperations
	  // for all changes in the EditingContext
          objectStore = [_stores objectAtIndex: i];
          [objectStore recordChangesInEditingContext];
        }

      NS_DURING
        {
          count = [_stores count];

          for (i = 0; i < count; i++)
            {
              objectStore = [_stores objectAtIndex: i];
              [objectStore performChanges];
            }

          count = [_stores count];

          for (i = 0; i < count; i++)
            {
              objectStore = [_stores objectAtIndex: i];
              [objectStore commitChanges];
            }
        }
      NS_HANDLER
        {
          NSDebugMLog(@"Exception: %@", localException);

          exception = localException;
          count = [_stores count];

          for (i = 0; i < count; i++)
            {
              NS_DURING
                {
                  [objectStore rollbackChanges];	  
                }
              NS_HANDLER
                {
                  NSEmitTODO();
                  NSDebugMLog(@"Exception in exception: %@", localException);
                  NSLog(@"Exception in exception: %@", localException);
                }
              NS_ENDHANDLER;
            }
        }
      NS_ENDHANDLER;
    }
  NS_HANDLER
    {
      exception = localException;
    }
  NS_ENDHANDLER;

  count = [_stores count];

  for (i = 0; i < count; i++)
    {
      objectStore = [_stores objectAtIndex: i];

      if ([objectStore respondsToSelector: @selector(unlock)] == YES)
	[(id)objectStore unlock];
    }

  if (exception)
    [exception raise];

  EOFLOGObjectFnStop();
}

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetch
			    editingContext: (EOEditingContext *)context
{
  EOCooperatingObjectStore *objectStore =
    [self objectStoreForFetchSpecification: fetch];

  return [objectStore objectsWithFetchSpecification: fetch
                      editingContext: context];
}

/*
 * If there is only one store that we are coordinating then all our
 * objects were also invalidated.
 */
- (void) _invalidatedAllObjectsInSubStore: (NSNotification*)notification
{
  if ([_stores count] == 1)
    {
      NSAssert2([_stores containsObject: [notification object]],
		@"recived notification %@ for foreign store %@",
		notification, _stores);
      [[NSNotificationCenter defaultCenter]
        postNotificationName: EOInvalidatedAllObjectsInStoreNotification
        object: self
        userInfo: nil];
    }
}

/*
 * Let the EOEditingContexts know that some objects changed.
 */
- (void) _objectsChangedInSubStore: (NSNotification*)notification
{
  EOFLOGObjectFnStart();

  if ([notification object] != self)
    {
      [[NSNotificationCenter defaultCenter]
        postNotificationName: EOObjectsChangedInStoreNotification
        object: self
        userInfo: [notification userInfo]];
    }

  EOFLOGObjectFnStop();
}

- (void)invalidateAllObjects
{
  EOCooperatingObjectStore *store;
  NSEnumerator *storeEnum;

  EOFLOGObjectFnStart();

  storeEnum = [_stores objectEnumerator];

  while ((store = [storeEnum nextObject]))
    [store invalidateAllObjects];

  EOFLOGObjectFnStop();
}

- (void)invalidateObjectsWithGlobalIDs: (NSArray *)globalIDs
{
  NSMapTable *gidsByStore;
  NSMapEnumerator gbsEnum;
  EOCooperatingObjectStore *store;
  EOGlobalID *gid;
  NSMutableArray *array;
  unsigned i,n;

  EOFLOGObjectFnStart();

  gidsByStore = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
				 NSNonOwnedPointerMapValueCallBacks,
				 8);

  for (i=0, n=[globalIDs count]; i<n; i++)
    {
      gid = [globalIDs objectAtIndex: i];
      store = [self objectStoreForGlobalID: gid];

      NSAssert1(store,@"No store found for gid:%@", gid);

      array = NSMapGet(gidsByStore, store);
      if (array == nil)
	{
	  array = [NSMutableArray array];
	  NSMapInsertKnownAbsent(gidsByStore, store, array);
	}
      [array addObject: gid];
    }

  gbsEnum = NSEnumerateMapTable(gidsByStore);
  while (NSNextMapEnumeratorPair(&gbsEnum, (void**)&store, (void**)&array))
    {
      [store invalidateObjectsWithGlobalIDs: array];
    }

  NSEndMapTableEnumeration(&gbsEnum);
  NSFreeMapTable(gidsByStore);

  EOFLOGObjectFnStop();
}

- (void)lockObjectWithGlobalID: (EOGlobalID *)gid
                editingContext: (EOEditingContext *)context
{
  EOObjectStore *store = [self objectStoreForGlobalID: gid];
  [store lockObjectWithGlobalID: gid editingContext: context];
}

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)gid
		    editingContext: (EOEditingContext *)context
{
  EOObjectStore *store = [self objectStoreForGlobalID: gid];
  return [store isObjectLockedWithGlobalID: gid editingContext: context];
}

@end


@implementation EOCooperatingObjectStore

- (BOOL)ownsGlobalID: (EOGlobalID *)globalID
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL)ownsObject: (id)object
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL)ownsEntityNamed: (NSString *)entityName
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (BOOL)handlesFetchSpecification: (EOFetchSpecification *)fetchSpecification
{
  [self subclassResponsibility: _cmd];
  return NO;
}

- (void)prepareForSaveWithCoordinator: (EOObjectStoreCoordinator *)coordinator
		       editingContext: (EOEditingContext *)context
{
  [self subclassResponsibility: _cmd];
}

- (void)recordChangesInEditingContext
{
  [self subclassResponsibility: _cmd];
}

- (void)recordUpdateForObject: object
                      changes: (NSDictionary *)changes
{
  [self subclassResponsibility: _cmd];
}

- (void)performChanges
{
  [self subclassResponsibility: _cmd];
}

- (void)commitChanges
{
  [self subclassResponsibility: _cmd];
}

- (void)rollbackChanges
{
  [self subclassResponsibility: _cmd];
}

- (NSDictionary *)valuesForKeys: (NSArray *)keys
                         object: object
{
  [self subclassResponsibility: _cmd];
  return nil;
}

@end
