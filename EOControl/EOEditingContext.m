/** 
   EOEditingContext.m <title>EOEditingContext Class</title>

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

//TODO EOMultiReaderLocks 
#import <Foundation/Foundation.h>

#import <EOControl/EOEditingContext.h>
#import <EOControl/EOObjectStoreCoordinator.h>
#import <EOControl/EOGlobalID.h>
#import <EOControl/EOClassDescription.h>
#import <EOControl/EOKeyValueCoding.h>
#import <EOControl/EOFault.h>
#import <EOControl/EONull.h>
#import <EOControl/EOUndoManager.h>
#import <EOControl/EONSAddOns.h>
#import <EOControl/EODebug.h>


@class EOEntityClassDescription;


@implementation EOEditingContext


static EOObjectStore *defaultParentStore = nil;

//Notifications
NSString *EOObjectsChangedInEditingContextNotification = @"EOObjectsChangedInEditingContextNotification";
NSString *EOEditingContextDidSaveChangesNotification = @"EOEditingContextDidSaveChangesNotification";


+ (void)initialize
{
  if (self == [EOEditingContext class] && !defaultParentStore)
    defaultParentStore = [EOObjectStoreCoordinator defaultCoordinator];
}

+ (void)setInstancesRetainRegisteredObjects: (BOOL)flag
{
  [self notImplemented: _cmd];
}

+ (BOOL)instancesRetainRegisteredObjects
{
  [self notImplemented: _cmd];
  return NO;
}

- (void) _eoNowMultiThreaded: (NSNotification *)notification
{
  //TODO
}

- (id) initWithParentObjectStore: (EOObjectStore *)parentObjectStore
{
  //OK
  if ((self = [super init]))
    {
      _flags.propagatesDeletesAtEndOfEvent = YES; //Default behavior
      ASSIGN(_objectStore, [EOEditingContext defaultParentObjectStore]); //parentObjectStore instead of defaultParentObjectStore ?

      _unprocessedChanges = NSCreateHashTable(NSObjectHashCallBacks, 32);
      _unprocessedDeletes = NSCreateHashTable(NSObjectHashCallBacks, 32);
      _unprocessedInserts = NSCreateHashTable(NSObjectHashCallBacks, 32);
      _insertedObjects = NSCreateHashTable(NSObjectHashCallBacks, 32);
      _deletedObjects = NSCreateHashTable(NSObjectHashCallBacks, 32);
      _changedObjects = NSCreateHashTable(NSObjectHashCallBacks, 32);

      _objectsById = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,//NSObjectMapKeyCallBacks,  retained by _objectsByGID
                                      NSObjectMapValueCallBacks,
                                      32);
      _objectsByGID = NSCreateMapTable(NSObjectMapKeyCallBacks, 
                                       NSObjectMapValueCallBacks,
                                       32);

      _snapshotsByGID = [[NSMutableDictionary alloc] initWithCapacity:16];
      _eventSnapshotsByGID = [[NSMutableDictionary alloc] initWithCapacity:16];

      _editors = [NSMutableArray new];
      
      _lock = [NSRecursiveLock new];

//TODO-NOW      _undoManager = [EOUndoManager new];
      [_undoManager beginUndoGrouping]; //??

      [self _observeUndoManagerNotifications];

/*
  [self setStopsValidationAfterFirstError:YES];
  [self setPropagatesDeletesAtEndOfEvent:YES];
*/

      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_objectsChangedInStore:)
        name: EOObjectsChangedInStoreNotification
        object: _objectStore];

      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_invalidatedAllObjectsInStore:)
        name: EOInvalidatedAllObjectsInStoreNotification
        object: _objectStore];

      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_globalIDChanged:)
        name: EOGlobalIDChangedNotification
        object: nil];

      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_eoNowMultiThreaded:)
        name: NSWillBecomeMultiThreadedNotification
        object: nil];
/*
      [self setStopsValidationAfterFirstError:NO];
      
      [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(_objectsChangedInSubStore:)
        name:EOObjectsChangedInStoreNotification
        object:nil];
*/    
    }

  return self;
}

- (id) init
{
  return [self initWithParentObjectStore:
		 [EOEditingContext defaultParentObjectStore]];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  DESTROY(_objectStore);
  DESTROY(_undoManager);

  NSFreeHashTable(_unprocessedChanges);
  NSFreeHashTable(_unprocessedDeletes);
  NSFreeHashTable(_unprocessedInserts);
  NSFreeHashTable(_insertedObjects);
  NSFreeHashTable(_deletedObjects);
  NSFreeHashTable(_changedObjects);

  NSFreeMapTable(_objectsById);
  NSFreeMapTable(_objectsByGID);

  DESTROY(_snapshotsByGID);
  DESTROY(_eventSnapshotsByGID);

  DESTROY(_editors);
  DESTROY(_lock);

  [super dealloc];
}

- (id) parentPath
{
  NSEmitTODO();  
  return [self notImplemented: _cmd]; //TODO
}

-(void)_observeUndoManagerNotifications
{
  //OK
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_undoManagerCheckpoint:)
    name: NSUndoManagerCheckpointNotification
    object: _undoManager];
}

- (void) _processObjectStoreChanges: (NSNotification *)notification
{
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  [self notImplemented: _cmd]; //TODO
}

//"Receive EOObjectsChangedInStoreNotification notification"
//oldname:_handleObjectsChangedInStoreNotification:
- (void)_objectsChangedInStore: (NSNotification *)notification
{
  NSEnumerator *arrayEnum;
  EOGlobalID   *gid;
  NSArray *array = nil;

  NSEmitTODO();
  // userInfo = {deleted = (); inserted = (); updated = ([GID: CustomerCredit, (1)]); }}

  if ([notification object] != self)
    {
      // Notification is posted from EODatabase
      array = [[notification userInfo] objectForKey: EOInsertedKey];

      if (array)
	{
	}

      array = [[notification userInfo] objectForKey: EODeletedKey];
      if (array)
	{
	}

      array = [[notification userInfo] objectForKey: EOUpdatedKey];
      if (array)
	{
          if (_flags.processingChanges == NO)
	    {
	      arrayEnum = [array objectEnumerator];

	      while ((gid = [arrayEnum nextObject]))
		{
		  [self refaultObject: [self objectForGlobalID:gid]
			withGlobalID: gid
			editingContext: self];

		  // TODO: verify modified objects
		}
	    }
	}

      array = [[notification userInfo] objectForKey: EOInvalidatedKey];
      if (array)
	{
          // these none-EOTemporary-GID EOObjects are retransformed into EOFaults
          // all snapshots accesses to their gid's are invalid and must remove

          arrayEnum = [array objectEnumerator];
          while ((gid = [arrayEnum nextObject]))
            {
              if ([gid isTemporary] == NO)
		{
		  [_snapshotsByGID removeObjectForKey: gid];
		  [_eventSnapshotsByGID removeObjectForKey: gid];
		}
            }
	}
    }
}

//"Receive EOGlobalIDChangedNotification notification"
- (void)_globalIDChanged: (NSNotification *)notification
{
  NSDictionary *snapshot = nil;
  NSDictionary *userInfo;
  NSEnumerator *enumerator;
  EOGlobalID *tempGID;
  EOGlobalID *gid = nil;
  id object = nil;

  EOFLOGObjectFnStart();

  userInfo = [notification userInfo];
  enumerator = [userInfo keyEnumerator];

  while ((tempGID = [enumerator nextObject]))
    {
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"tempGID=%@", tempGID);

      gid = [userInfo objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);

      if (_objectsByGID)
        {
          object = NSMapGet(_objectsByGID, tempGID);

          EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);

          RETAIN(object);
          NSAssert(_objectsById, @"no _objectsById");

          if (object)
            {
              NSMapInsert(_objectsById, object, gid);
              NSMapRemove(_objectsByGID, tempGID);
              NSMapInsert(_objectsByGID, gid, object);
              AUTORELEASE(object);
            }
        }

      if (!object)
        {
          // object is from other editingcontext
          EOFLOGObjectLevelArgs(@"EOEditingContextValues",
                                @"nothing done , object with gid '%@' is from other ed", 
                                tempGID);
        }

      //if (object)     
      snapshot = [_snapshotsByGID objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EOEditingContext",
			    @"_snapshotsByGID snapshot=%@", snapshot);

      if (snapshot)
        {
          RETAIN(snapshot);

          [_snapshotsByGID removeObjectForKey: tempGID];
          EOFLOGObjectLevel(@"EOEditingContext", @"After Remove");

          [_snapshotsByGID setObject: snapshot
                           forKey: gid];          
          EOFLOGObjectLevel(@"EOEditingContext", @"After SetObject");

          AUTORELEASE(snapshot);
        }
      else 
        {
          // set snapshot with last committed values
          //EOFLOGObjectLevelArgs(@"EOEditingContextValues", @"adding new object = %@", [self objectForGlobalID:gid]);
          //EOFLOGObjectLevelArgs(@"EOEditingContextValues", @"object class = %@", NSStringFromClass([object class]));
          //EOFLOGObjectLevelArgs(@"EOEditingContextValues", @"with snapshot = %@", [[self objectForGlobalID:gid] snapshot]);
          
          // ?? [_snapshots setObject:[[self objectForGlobalID:gid] snapshot]  forKey:gid];
        }

      snapshot = [_eventSnapshotsByGID objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EOEditingContext",
			    @"_eventSnapshotsByGID snapshot=%@", snapshot);

      if (snapshot)
        {
          RETAIN(snapshot);
          [_eventSnapshotsByGID removeObjectForKey: tempGID];
          [_eventSnapshotsByGID setObject: snapshot
                                forKey: gid];

          AUTORELEASE(snapshot);
	}
    }

  EOFLOGObjectFnStop();
}

- (void) _processNotificationQueue
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) _sendOrEnqueueNotification: (id)param0
                           selector: (SEL)param1
{
  [self notImplemented: _cmd]; //TODO
}

//"Invalidate All Objects"
- (void) invalidateAllObjects
{
  NSEmitTODO();

  [super invalidateAllObjects]; //??
  [self notImplemented: _cmd]; //TODO-NOW
}

//"Receive ???? notification"
- (void) _invalidatedAllObjectsInStore: (NSNotification*)notification
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) _forgetObjectWithGlobalID:(EOGlobalID*)gid
{
  NSEmitTODO();
  [self notImplemented:_cmd]; //TODO
}

- (void) _invalidateObject: (id)object
              withGlobalID: (EOGlobalID*)gid
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) _invalidateObjectWithGlobalID: (EOGlobalID*)gid
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) invalidateObjectsWithGlobalIDs: (NSArray*)gids
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) _resetAllChanges: (NSNotification*)notification //??
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) _resetAllChanges
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
}

- (void) _enqueueEndOfEventNotification
{
  [_undoManager groupsByEvent];
  [_undoManager registerUndoWithTarget: self
                selector: @selector(noop:)
                object: nil];

  _flags.registeredForCallback = YES;
}

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetch
{
  NSArray *objects;

  EOFLOGObjectFnStart();

  objects = [self objectsWithFetchSpecification: fetch
		  editingContext: self];

  EOFLOGObjectFnStop();

  return objects;
}

- (void)insertObject: (id)object
{
  EOGlobalID *gid;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  gid = [self globalIDForObject: object];
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);

  //GSWDisplayGroup -insertAtIndex+EODataSource createObject call insert ! So object is inserted twice

  if (_insertedObjects && NSHashGet(_insertedObjects, object))
    {
//      NSLog(@"Already inserted object [_insertedObjects] %p=%@",object,object);
//      EOFLOGObjectLevelArgs(@"EOEditingContext",@"Already inserted object [_insertedObjects] %p=%@",object,object);      
    }
  else if (_unprocessedInserts && NSHashGet(_unprocessedInserts, object))
    {
//      NSLog(@"Already inserted object [_unprocessedInserts] %p=%@",object,object);
//      EOFLOGObjectLevelArgs(@"EOEditingContext",@"Already inserted object [_unprocessedInserts] %p=%@",object,object);    
    }
  else
    {
      if (!gid)
        {
          gid = [EOTemporaryGlobalID temporaryGlobalID];
          EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);
        }

      EOFLOGObjectLevelArgs(@"EOEditingContext",
			    @"InsertObjectWithGlobalID object: %p=%@",
			    object, object);

      [self insertObject: object
            withGlobalID: gid];
    }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void)insertObject: (id)object
        withGlobalID: (EOGlobalID *)gid
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  //GSWDisplayGroup -insertAtIndex+EODataSource createObject call insert ! So object is inserted twice

  if (_insertedObjects && NSHashGet(_insertedObjects, object))
    {
//      NSLog(@"Already inserted object [_insertedObjects] %p=%@",object,object);
//      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Already inserted object [_insertedObjects] %p=%@", object, object);      
    }
  else if (_unprocessedInserts && NSHashGet(_unprocessedInserts, object))
    {
//      NSLog(@"Already inserted object [_unprocessedInserts] %p=%@",object,object);
//      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Already inserted object [_unprocessedInserts] %p=%@", object, object);      
    }

  [self _insertObject: object
        withGlobalID: gid];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Awake object: %p=%@",
			object, object);

  [object awakeFromInsertionInEditingContext: self];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void)_insertObject: (id)object
        withGlobalID: (EOGlobalID *)gid
{
  EOGlobalID *gidBis = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Object %p=%@", object, object);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  NSAssert(object, @"No Object");

  //GSWDisplayGroup -insertAtIndex+EODataSource createObject call insert ! So object is inserted twice

  if (_insertedObjects && NSHashGet(_insertedObjects, object))
    {
//      NSLog(@"Already inserted object [_insertedObjects] %p=%@",object,object);
//      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Already inserted object [_insertedObjects] %p=%@", object, object);    
    }
  else if (_unprocessedInserts && NSHashGet(_unprocessedInserts, object))
    {
//      NSLog(@"Already inserted object [_unprocessedInserts] %p=%@",object,object);
//      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Already inserted object [_unprocessedInserts] %p=%@", object, object);      
    }

  if ([gid isTemporary])
    {
      [self _registerClearStateWithUndoManager];
      [_undoManager registerUndoWithTarget: self
                    selector: @selector(deleteObject:)
                    object: object];

      gidBis = [self globalIDForObject: object];

      if (!gidBis)
        {
          NSAssert(gid, @"No gid");

          [self recordObject: object
                globalID: gid];

          NSHashInsert(_unprocessedInserts, object);
          [self _enqueueEndOfEventNotification];
        }
    }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void) _processEndOfEventNotification: (NSNotification*)notification
{
  NSEmitTODO();

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  if ([self tryLock])
    {
      [self processRecentChanges];
      [self unlock];
    }
  else
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void) noop: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

//"Receive NSUndoManagerCheckpointNotification Notification
- (void) _undoManagerCheckpoint: (NSNotification*)notification
{
  NSEmitTODO();

  [self _processEndOfEventNotification: notification]; //OK
}

- (BOOL) _processRecentChanges
{
  //Near OK for insert and update
  BOOL result = YES;

  EOFLOGObjectFnStart();

  if (!_flags.processingChanges)
    {
      NSArray *unprocessedInsertsArray = nil;
      NSArray *unprocessedInsertsGlobalIDs = nil;
      NSArray *unprocessedDeletesArray = nil;
      NSArray *unprocessedDeletesGlobalIDs = nil;
      NSArray *unprocessedChangesArray = nil;
      NSArray *unprocessedChangesGlobalIDs = nil;
      NSMutableDictionary *objectsArray = [NSMutableDictionary dictionary];
      NSMutableDictionary *objectGIDsArray = [NSMutableDictionary dictionary];
      int count = 0;

      _flags.processingChanges = YES;

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);

      [self _registerClearStateWithUndoManager];

      //_undoManager isUndoing //ret NO //TODO
      //_undoManager isRedoing //ret NO //TODO
      [_undoManager beginUndoGrouping];

      /*in undomanager beginUndoGrouping
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NSUndoManagerCheckpointNotification" 
        object:_undoManager]; //call _undoManagerCheckpoint:
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NSUndoManagerDidOpenUndoGroupNotification"
        object:_undoManager];
      */

      [self _processDeletedObjects];

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);

      [_undoManager endUndoGrouping];

      /*in undomanager endUndoGrouping
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NSUndoManagerCheckpointNotification"
        object:_undoManager] //call _undoManagerCheckpoint:
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NSUndoManagerWillCloseUndoGroupNotification"
        object:_undoManager];
      */
      
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);
      //on inserted objects
      EOFLOGObjectLevel(@"EOEditingContext",
			@"process _unprocessedInserts");

      unprocessedInsertsArray = NSAllHashTableObjects(_unprocessedInserts);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"unprocessedInsertsArray=%@",
			    unprocessedInsertsArray);

      [objectsArray setObject: unprocessedInsertsArray
                    forKey: @"inserted"];

      unprocessedInsertsGlobalIDs
	= [self resultsOfPerformingSelector: @selector(globalIDForObject:)
		withEachObjectInArray: unprocessedInsertsArray];

      [objectGIDsArray setObject: unprocessedInsertsGlobalIDs
                       forKey: @"inserted"];

      count = [unprocessedInsertsArray count];

      if (count > 0)
        {
          int i;

          for (i = 0; i < count; i++)
            NSHashInsertIfAbsent(_insertedObjects,
				 [unprocessedInsertsArray objectAtIndex: i]);

          NSResetHashTable(_unprocessedInserts);
        }
      
      //on deleted or updated
      EOFLOGObjectLevel(@"EOEditingContext",
			@"process _unprocessedDeletes");

      unprocessedDeletesArray = NSAllHashTableObjects(_unprocessedDeletes);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"unprocessedDeletesArray=%@",
			    unprocessedDeletesArray);

      [objectsArray setObject: unprocessedDeletesArray 
                    forKey: @"deleted"];
      unprocessedDeletesGlobalIDs = [self resultsOfPerformingSelector:
					    @selector(globalIDForObject:)
					  withEachObjectInArray:
					    unprocessedDeletesArray];

      [objectGIDsArray setObject: unprocessedDeletesGlobalIDs
                       forKey: @"deleted"];

      count = [unprocessedDeletesArray count];

      if (count > 0)
        {
          int i;

          for (i = 0; i < count; i++)
            NSHashInsertIfAbsent(_deletedObjects,
				 [unprocessedDeletesArray objectAtIndex: i]);

          NSResetHashTable(_unprocessedDeletes);
        }

      //Changes
      EOFLOGObjectLevel(@"EOEditingContext",
			@"process _unprocessedChanges");

      unprocessedChangesArray = NSAllHashTableObjects(_unprocessedChanges);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"unprocessedChangesArray=%@",
			    unprocessedChangesArray);

      [objectsArray setObject:unprocessedChangesArray
                    forKey:@"updated"];

      unprocessedChangesGlobalIDs = [self resultsOfPerformingSelector:
					    @selector(globalIDForObject:)
					  withEachObjectInArray:
					    unprocessedChangesArray];

      [objectGIDsArray setObject: unprocessedChangesGlobalIDs
                       forKey: @"updated"];

      count = [unprocessedChangesArray count];

      if (count > 0)
        {
          int i;

          for (i = 0; i < count; i++)
            {
              id object = [unprocessedChangesArray objectAtIndex: i];

              EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%p", object);

              if (!NSHashGet(_insertedObjects, object)) //Don't update inserted objects ??
                NSHashInsertIfAbsent(_changedObjects, object);
            }

          NSResetHashTable(_unprocessedChanges);
        }

      [EOObserverCenter notifyObserversObjectWillChange: nil];

      [[NSNotificationCenter defaultCenter]
	postNotificationName: @"EOObjectsChangedInStoreNotification"
	object: self
	userInfo: objectGIDsArray];

      [[NSNotificationCenter defaultCenter]
	postNotificationName: @"EOObjectsChangedInEditingContextNotification"
	object: self
	userInfo: objectsArray];

      count = [unprocessedChangesArray count];

      if (count > 0)
        {
          int i;

          for (i = 0; i < count; i++)          
            {
              id object = [unprocessedChangesArray objectAtIndex: i];

              EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%p", object);
              [self registerUndoForModifiedObject: object];
            }
        }

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);

      _flags.processingChanges = NO;
    }

  EOFLOGObjectFnStop();

  return result;
/*
 (count=0)
  NSMutableDictionary *userInfo;
  NSMutableArray *changedObjects, *invalidatedObjects;
  NSMutableArray *objectsToRemove, *objectsToKeep;
  NSEnumerator *objEnum;
  NSException *exp;
  NSArray *deletedObjects;
  EOGlobalID *gid;
  EONull *null = [EONull null];
  BOOL propagatesDeletes = YES, validateChanges = YES;
  id object;

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process recent changes");

  objectsToKeep   = [NSMutableArray arrayWithCapacity:8];
  objectsToRemove = [NSMutableArray arrayWithCapacity:8];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process2");

  objEnum = [NSAllHashTableObjects(_unprocessedChanges) objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      NSDictionary *snapshot, *oldSnapshot, *changes;
      NSArray *toRelArray;
      NSEnumerator *toRelEnum;
      NSString *key;

      gid = [self globalIDForObject:object];
      oldSnapshot = [_eventSnapshotsByGID objectForKey:gid];
      snapshot = [object snapshot];
      changes = [object changesFromSnapshot:oldSnapshot];

      toRelArray = [object toOneRelationshipKeys];
      toRelEnum = [toRelArray objectEnumerator];
      while((key = [toRelEnum nextObject]))
	{
	  id val = [changes objectForKey:key];

          if(val == null)
          val = nil;

	  if(val &&
	     [object ownsDestinationObjectsForRelationshipKey:key] == YES)
	    {
	      if(val != null)
		[objectsToKeep addObject:val];

	      val = [oldSnapshot objectForKey:key];
	      if(val != null)
		[objectsToRemove addObject:val];
	    }
	}

      toRelArray = [object toManyRelationshipKeys];
      toRelEnum = [toRelArray objectEnumerator];
      while((key = [toRelEnum nextObject]))
	{
	  NSArray *val = [changes objectForKey:key];

          if(val == null)
          val = nil;

	  if(val &&
	     [object ownsDestinationObjectsForRelationshipKey:key] == YES)
	    {
	      [objectsToKeep addObjectsFromArray:[val objectAtIndex:0]];
	      [objectsToRemove addObjectsFromArray:[val objectAtIndex:0]];
	    }
	}

      [_eventSnapshotsByGID setObject:snapshot
		       forKey:gid];
    }

  [objectsToRemove removeObjectsInArray:objectsToKeep];
  objEnum = [objectsToRemove objectEnumerator];
  while((object = [objEnum nextObject]))
    NSHashInsert(_unprocessedDeletes, object);

  deletedObjects = NSAllHashTableObjects(_unprocessedDeletes);
  objEnum = [deletedObjects objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if(validateChanges)
	{

//in 
validateTable:(NSHashTable*)table
          withSelector:(SEL)sel
        exceptionArray:(id*)param2
  continueAfterFailure:
	  exp = [object validateForDelete];

	  if(exp) // TODO
	    {
	      if(_flags.stopsValidation == NO)
		{
		  if(_delegate == nil ||
		     _delegateRespondsTo.shouldPresentException == NO ||
		     (_delegateRespondsTo.shouldPresentException &&

		      [_delegate editingContext:self
				 shouldPresentException:exp] == YES))
		    [_messageHandler editingContext:self
				     presentErrorMessage:[exp reason]];
		}
	      else
		[exp raise];
	    }
	}
//fin in...
      NSHashInsert(_deletedObjects, object);

      if(_undoManager)
	[_undoManager registerUndoWithTarget:self
		      selector:@selector(_revertDelete:)
		      object:object];
    }


*/

/*
//propagatesDeletesUsingTable:(NSHashTable*)deleteTable
  if(_flags.processingChanges == YES &&
     _delegateRespondsTo.shouldValidateChanges)
    validateChanges = [_delegate editingContextShouldValidateChanges:self];

  if(_flags.processingChanges == NO && [self propagatesDeletesAtEndOfEvent] == NO)
    propagatesDeletes = NO;

  if(propagatesDeletes == YES)
    {
      if([self propagatesDeletesAtEndOfEvent] == YES)
	objEnum = [NSAllHashTableObjects(_deletedObjects) objectEnumerator];
      else
	objEnum = [NSAllHashTableObjects(_unprocessedDeletes)
					objectEnumerator];

      while((object = [objEnum nextObject]))
	[object propagatesDeleteWithEditingContext:self];

      if([self propagatesDeletesAtEndOfEvent] == YES)
	{
	  objEnum = [NSAllHashTableObjects(_unprocessedDeletes)
					  objectEnumerator];
	  while((object = [objEnum nextObject]))
	    NSHashInsert(_deletedObjects, object);

	  deletedObjects = NSAllHashTableObjects(_deletedObjects);
	}
      else
	deletedObjects = NSAllHashTableObjects(_unprocessedDeletes);
    }
  else
    deletedObjects = NSAllHashTableObjects(_unprocessedDeletes);

  objEnum = [deletedObjects objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if(validateChanges)
	{
	  exp = [object validateForDelete];

	  if(exp) // TODO
	    {
	      if(_flags.stopsValidation == NO)
		{
		  if(_delegate == nil ||
		     _delegateRespondsTo.shouldPresentException == NO ||
		     (_delegateRespondsTo.shouldPresentException &&

		      [_delegate editingContext:self
				 shouldPresentException:exp] == YES))
		    [_messageHandler editingContext:self
				     presentErrorMessage:[exp reason]];
		}
	      else
		[exp raise];
	    }
	}

      if(propagatesDeletes == NO || [self propagatesDeletesAtEndOfEvent] == NO)
	NSHashInsert(_deletedObjects, object);

      if(_undoManager)
	[_undoManager registerUndoWithTarget:self
		      selector:@selector(_revertDelete:)
		      object:object];
    }
*/




/*
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process recent changes: prop delete");

  objEnum = [NSAllHashTableObjects(_unprocessedChanges) objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if(validateChanges)
	{
	  exp = [object validateForUpdate];

	  if(exp)
	    {
	      if(_flags.stopsValidation == NO)
		{
		  if(_delegate == nil ||
		     _delegateRespondsTo.shouldPresentException == NO ||
		     (_delegateRespondsTo.shouldPresentException &&

		      [_delegate editingContext:self
				 shouldPresentException:exp] == YES))
		    [_messageHandler editingContext:self
				     presentErrorMessage:[exp reason]];
		}
	      else
		[exp raise];
	    }
	}
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"** add changed");
      NSHashInsert(_changedObjects, object);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"** add changed2");

      if(_undoManager)
	[_undoManager registerUndoWithTarget:self
		      selector:@selector(_revertChanged:) // TODO si pianta
		      object:object];
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"** add changed: undo");
    }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process recent changes: validated changes");

  objEnum = [NSAllHashTableObjects(_unprocessedInserts) objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if(validateChanges)
	{
	  exp = [object validateForInsert];

	  if(exp)
	    {
	      if(_flags.stopsValidation == NO)
		{
		  if(_delegate == nil ||
		     _delegateRespondsTo.shouldPresentException == NO ||
		     (_delegateRespondsTo.shouldPresentException &&

		      [_delegate editingContext:self
				 shouldPresentException:exp] == YES))
		    [_messageHandler editingContext:self
				     presentErrorMessage:[exp reason]];
		}
	      else
		[exp raise];
	    }
	}

      NSHashInsert(_insertedObjects, object);

      if(_undoManager)
	[_undoManager registerUndoWithTarget:self
		      selector:@selector(_revertInsert:)
		      object:object];
    }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process recent changes: validated inserts");

  [_undoManager endUndoGrouping];
  [_undoManager beginUndoGrouping];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process recent changes: end undo");

  userInfo = [NSMutableDictionary dictionaryWithCapacity:3];

  changedObjects = [NSMutableArray arrayWithCapacity:8];
  objEnum = [NSAllHashTableObjects(_unprocessedDeletes) objectEnumerator];
  while((object = [objEnum nextObject]))
    [changedObjects addObject:[self globalIDForObject:object]];

  [userInfo setObject:changedObjects
	    forKey:EODeletedKey];

  changedObjects = [NSMutableArray arrayWithCapacity:8];
  objEnum = [NSAllHashTableObjects(_unprocessedInserts) objectEnumerator];
  while((object = [objEnum nextObject]))
    [changedObjects addObject:[self globalIDForObject:object]];

  [userInfo setObject:changedObjects
	    forKey:EOInsertedKey];

  invalidatedObjects = [NSMutableArray arrayWithCapacity:8];
  changedObjects     = [NSMutableArray arrayWithCapacity:8];

  objEnum = [NSAllHashTableObjects(_changedObjects) objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if([EOFault isFault:object] == YES)
	[invalidatedObjects addObject:[self globalIDForObject:object]];
      else
	[changedObjects addObject:[self globalIDForObject:object]];
    }

  [userInfo setObject:changedObjects
	    forKey:EOUpdatedKey];
  [userInfo setObject:invalidatedObjects
	    forKey:EOInvalidatedKey];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:EOObjectsChangedInStoreNotification
    object:self
    userInfo:userInfo];

  userInfo = [NSMutableDictionary dictionaryWithCapacity:3];

  [userInfo setObject:NSAllHashTableObjects(_unprocessedDeletes)
	    forKey:EODeletedKey];
  [userInfo setObject:NSAllHashTableObjects(_unprocessedInserts)
	    forKey:EOInsertedKey];

  invalidatedObjects = [NSMutableArray arrayWithCapacity:8];
  changedObjects     = [NSMutableArray arrayWithCapacity:8];

  objEnum = [NSAllHashTableObjects(_unprocessedChanges) objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if([EOFault isFault:object] == YES)
	[invalidatedObjects addObject:object];
      else
	[changedObjects addObject:object];
    }

  [userInfo setObject:changedObjects
	    forKey:EOUpdatedKey];
  [userInfo setObject:invalidatedObjects
	    forKey:EOInvalidatedKey];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:EOObjectsChangedInEditingContextNotification
    object:self
    userInfo:userInfo];

  NSResetHashTable(_unprocessedChanges);
  NSResetHashTable(_unprocessedDeletes);
  NSResetHashTable(_unprocessedInserts);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"** process finished");

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"process recent changes END");
*/
}

- (void) _processDeletedObjects
{
  //OK finished ??
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  [self _processOwnedObjectsUsingChangeTable: _unprocessedChanges
        deleteTable: _unprocessedDeletes];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  [self propagatesDeletesUsingTable: _unprocessedDeletes];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);
  [self validateDeletesUsingTable: _unprocessedDeletes];

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

/*

//verify
 BOOL propagatesDeletes = YES, validateChanges = YES;
  if(_flags.processingChanges == YES
     && _delegateRespondsTo.shouldValidateChanges)
    validateChanges = [_delegate editingContextShouldValidateChanges:self];

  if(_flags.processingChanges == NO && [self propagatesDeletesAtEndOfEvent] == NO)
    propagatesDeletes = NO;

  if(propagatesDeletes == YES)
    {
      if([self propagatesDeletesAtEndOfEvent] == YES)
	objEnum = [NSAllHashTableObjects(_deletedObjects) objectEnumerator];
      else
	objEnum = [NSAllHashTableObjects(_unprocessedDeletes)
					objectEnumerator];

      while((object = [objEnum nextObject]))
	[object propagatesDeleteWithEditingContext:self];

      if([self propagatesDeletesAtEndOfEvent] == YES)
	{
	  objEnum = [NSAllHashTableObjects(_unprocessedDeletes)
					  objectEnumerator];
	  while((object = [objEnum nextObject]))
	    NSHashInsert(_deletedObjects, object);

	  deletedObjects = NSAllHashTableObjects(_deletedObjects);
	}
      else
	deletedObjects = NSAllHashTableObjects(_unprocessedDeletes);
    }
  else
    deletedObjects = NSAllHashTableObjects(_unprocessedDeletes);

  objEnum = [deletedObjects objectEnumerator];
  while((object = [objEnum nextObject]))
    {
      if(validateChanges)
	{
	  exp = [object validateForDelete];

	  if(exp) // TODO
	    {
	      if(_flags.stopsValidation == NO)
		{
		  if(_delegate == nil ||
		     _delegateRespondsTo.shouldPresentException == NO ||
		     (_delegateRespondsTo.shouldPresentException &&

		      [_delegate editingContext:self
				 shouldPresentException:exp] == YES))
		    [_messageHandler editingContext:self
				     presentErrorMessage:[exp reason]];
		}
	      else
		[exp raise];
	    }
	}

      if(propagatesDeletes == NO || [self propagatesDeletesAtEndOfEvent] == NO)
	NSHashInsert(_deletedObjects, object);

      if(_undoManager)
	[_undoManager registerUndoWithTarget:self
		      selector:@selector(_revertDelete:)
		      object:object];
    }

}
*/

- (void)validateChangesForSave
{
  NSMutableArray *exceptions = nil;
  BOOL validateForDelete = NO;

  EOFLOGObjectFnStart();

  validateForDelete = [self validateTable: _unprocessedDeletes
			    withSelector: @selector(validateForDelete)
			    exceptionArray: &exceptions
			    continueAfterFailure: NO];

  if (!validateForDelete)
    {
      switch ([exceptions count])
        {
        case 1:
          [[exceptions objectAtIndex: 0] raise];
          break;
        case 0:
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
          break;
        default:
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
          break;
        }
    }
  else
    {
      BOOL validateForInsert = [self validateTable: _unprocessedInserts
				     withSelector: @selector(validateForInsert)
				     exceptionArray: &exceptions
				     continueAfterFailure: NO];

      if (!validateForInsert)
        {
          switch ([exceptions count])
            {
            case 1:
              [[exceptions objectAtIndex: 0] raise];
              break;
            case 0:
              NSEmitTODO();
              [self notImplemented: _cmd]; //TODO
              break;
            default:
              NSEmitTODO();
              [self notImplemented: _cmd]; //TODO
              break;
            }
        }
      else
        {
          BOOL validateForUpdate
	    = [self validateTable: _unprocessedInserts
		    withSelector: @selector(validateForUpdate)
		    exceptionArray: &exceptions
		    continueAfterFailure: NO];

          if (!validateForUpdate)
            {
              switch ([exceptions count])
                {
                case 1:
                  [[exceptions objectAtIndex: 0] raise];
                  break;
                case 0:
                  NSEmitTODO();
                  [self notImplemented: _cmd]; //TODO
                  break;
                default:
                  NSEmitTODO();
                  [self notImplemented: _cmd]; //TODO
                  break;
                }
            }
        }
    }

  EOFLOGObjectFnStop();
}

- (void) validateDeletesUsingTable: (NSHashTable*)deleteTable
{
  NSMutableArray *exceptionArray = nil;

  if (![self validateTable: deleteTable
             withSelector: @selector(validateForDelete)
             exceptionArray: &exceptionArray
             continueAfterFailure: NO])
    {
      NSException *exception = [NSException aggregateExceptionWithExceptions:
					      exceptionArray];
      [exception raise];
    }
}

- (BOOL) validateTable: (NSHashTable*)table
          withSelector: (SEL)sel
        exceptionArray: (NSMutableArray**)exceptionArrayPtr
  continueAfterFailure: (BOOL)continueAfterFailure
{
  BOOL ok = YES;
  NSHashEnumerator enumerator;
  id object = nil;

  EOFLOGObjectFnStart();

  enumerator = NSEnumerateHashTable(table);

  while ((ok || continueAfterFailure)
	 && (object=(id)NSNextHashEnumeratorItem(&enumerator)))
    {
      NSException *exception = [object performSelector: sel];

      if (exception)
        {
          ok = NO;
          if (continueAfterFailure)
            {
              if (_delegate == nil
		  || _delegateRespondsTo.shouldPresentException == NO
		  || (_delegateRespondsTo.shouldPresentException
		      && [_delegate editingContext: self
                                   shouldPresentException: exception] == YES))
                [_messageHandler editingContext: self
                                 presentErrorMessage: [exception reason]];
            }

          if (exceptionArrayPtr)
            {
              if (!*exceptionArrayPtr)
                *exceptionArrayPtr = [NSMutableArray array];

              [*exceptionArrayPtr addObject: exception];
            }
        }
    }

//  NSEndHashTableEnumeration(enumerator);
  EOFLOGObjectFnStop();

  return ok;
}

- (BOOL) handleErrors: (id)p
{
  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO

  return NO;
}

- (BOOL) handleError: (NSException*)exception
{
  [exception raise]; //raise the exception??

  return NO;
}

- (void) propagatesDeletesUsingTable: (NSHashTable*)deleteTable
{
  NSHashEnumerator enumerator;
  id object = nil;

  EOFLOGObjectFnStart();

  enumerator = NSEnumerateHashTable(deleteTable);

  while ((object = (id)NSNextHashEnumeratorItem(&enumerator)))
    [object propagateDeleteWithEditingContext: self];

  EOFLOGObjectFnStop();
}

- (void) _processOwnedObjectsUsingChangeTable: (NSHashTable*)changeTable 
                                  deleteTable: (NSHashTable*)deleteTable
{
  NSHashTable *objectsToInsert = NSCreateHashTable(NSObjectHashCallBacks, 32);
  NSHashEnumerator enumerator;
  id object = nil;

  EOFLOGObjectFnStart();

  enumerator = NSEnumerateHashTable(changeTable);

  while ((object = (id)NSNextHashEnumeratorItem(&enumerator)))
    {
      NSDictionary *objectSnapshot = nil;
      NSArray *toOneRelationshipKeys;
      NSArray *toManyRelationshipKeys = nil;
      int i;
      int count;

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"object:%@", object);

      toOneRelationshipKeys = [object toOneRelationshipKeys]; 
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"toOneRelationshipKeys:%@",
			    toOneRelationshipKeys);

      count = [toOneRelationshipKeys count];

      for (i = 0; i < count; i++)
        {
          NSString *relKey = [toOneRelationshipKeys objectAtIndex: i];
          BOOL ownsDestinationObjects
	    = [object ownsDestinationObjectsForRelationshipKey:relKey];

          EOFLOGObjectLevelArgs(@"EOEditingContext", @"relKey:%@", relKey);
          EOFLOGObjectLevelArgs(@"EOEditingContext",
				@"ownsDestinationObjects: %s",
				(ownsDestinationObjects ? "YES" : "NO"));

          if (ownsDestinationObjects)
            {
              id existingObject = nil;
              id value = nil;

              if (!objectSnapshot)
                objectSnapshot = [self currentEventSnapshotForObject: object];

              EOFLOGObjectLevelArgs(@"EOEditingContext", @"objectSnapshot:%@",
				    objectSnapshot);

              existingObject = [objectSnapshot objectForKey: relKey];
              EOFLOGObjectLevelArgs(@"EOEditingContext", @"existingObject:%@",
				    existingObject);

              value = [object storedValueForKey: relKey];
              EOFLOGObjectLevelArgs(@"EOEditingContext", @"value:%@", value);

              if (value != existingObject)
                {
                  if (isNilOrEONull(value))
                    {
                      if (!isNilOrEONull(existingObject))//value is new
                        {                      
                          //existing object is removed
                          //TODO ?? ad it in delete table ??
                          NSEmitTODO();
                          [self notImplemented:_cmd]; //TODO
                        }
                    }
                  else
                    {
                      if (!isNilOrEONull(existingObject))//value is new
                        {                      
                          //existing object is removed
                          //TODO ?? ad it in delete table ??
                          NSEmitTODO();
                          [self notImplemented:_cmd]; //TODO
                        }
                      if (!NSHashGet(changeTable,value))//id not already in change table
                        {
                          //We will insert it
                          NSHashInsertIfAbsent(objectsToInsert,value);
                          EOFLOGObjectLevelArgs(@"EOEditingContext",@"Will insert %@",value);
                        }
                    }
                }
            }
        }

      toManyRelationshipKeys = [object toManyRelationshipKeys];

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"object:%@", object);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"toManyRelationshipKeys: %@",
			    toManyRelationshipKeys);

      count = [toManyRelationshipKeys count];

      for (i = 0; i < count; i++)
        {
          NSString *relKey = [toManyRelationshipKeys objectAtIndex: i]; //1-1 payments
          BOOL ownsDestinationObjects
	    = [object ownsDestinationObjectsForRelationshipKey: relKey];

          EOFLOGObjectLevelArgs(@"EOEditingContext", @"relKey: %@", relKey);
          EOFLOGObjectLevelArgs(@"EOEditingContext",
				@"ownsDestinationObjects: %s",
				(ownsDestinationObjects ? "YES" : "NO"));

          if (ownsDestinationObjects) //1-1 YES
            {
              NSArray *existingObjects = nil;
              NSArray *currentObjects = nil;
              NSArray *newObjects = nil;
              int newObjectsCount = 0;
              int iNewObject = 0;

              if (!objectSnapshot)
                objectSnapshot = [self currentEventSnapshotForObject: object];

              EOFLOGObjectLevelArgs(@"EOEditingContext",
				    @"objectSnapshot:%p: %@",
				    objectSnapshot, objectSnapshot);

              existingObjects = [objectSnapshot objectForKey: relKey];
              EOFLOGObjectLevelArgs(@"EOEditingContext",
				    @"key %@ existingObjects: %@",
				    relKey, existingObjects);

              currentObjects = [object storedValueForKey: relKey];
              EOFLOGObjectLevelArgs(@"EOEditingContext",
				    @"key %@ currentObjects: %@",
				    relKey, currentObjects);
//TODO              YY=[currentObjects shallowCopy];

              newObjects = [currentObjects arrayExcludingObjectsInArray:
					     existingObjects]; 
              EOFLOGObjectLevelArgs(@"EOEditingContext", @"newObjects: %@",
				    newObjects);

              newObjectsCount = [newObjects count];

              for (iNewObject = 0; iNewObject < newObjectsCount; iNewObject++)
                {
                  id newObject = [newObjects objectAtIndex: iNewObject];

                  EOFLOGObjectLevelArgs(@"EOEditingContext", @"newObject: %@",
					newObject);

                  if (!NSHashGet(changeTable, newObject)) //id not already in change table (or in insertTable ?)
                    {
                      //We will insert it
                      NSHashInsertIfAbsent(objectsToInsert, newObject);
                      EOFLOGObjectLevelArgs(@"EOEditingContext",
					    @"Will insert %@", newObject);
                    }
                }

//TODO              XX=[existingObjects arrayExcludingObjectsInArray:(newObjects or currentObjects)];//nil
//=========>
	      NSEmitTODO();
//TODO              [self notImplemented:_cmd]; //TODO
            }
        }
    }

  enumerator = NSEnumerateHashTable(objectsToInsert);

  while ((object = (id)NSNextHashEnumeratorItem(&enumerator)))
    {
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Insert %@", object);
      [self insertObject: object];
    }

  NSFreeHashTable(objectsToInsert);

  //TODO-NOW: use deleteTable !
  //[self notImplemented:_cmd]; //TODO

  EOFLOGObjectFnStop();
}

- (void) registerUndoForModifiedObject: (id)object
{
  EOGlobalID *gid;
  NSDictionary *snapshot;
  NSDictionary *undoObject;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);

  gid = [self globalIDForObject: object];
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);

  snapshot = [self currentEventSnapshotForObject: object];
  undoObject = [NSDictionary dictionaryWithObjectsAndKeys:
			       object, @"object",
			     snapshot, @"snapshot",
			     nil, nil];

  [_undoManager registerUndoWithTarget: self
                selector: @selector(_undoUpdate:)
                object: undoObject];

  [_eventSnapshotsByGID removeObjectForKey: gid];

  EOFLOGObjectFnStop();
}

- (void) _undoUpdate: (id)param0
{
  NSEmitTODO();
  //TODO
//  receive a dict with object and snapshot ? (cf registerUndoForModifiedObject:)
}

- (void)incrementUndoTransactionID
{
  _undoTransactionID++;
  _flags.registeredUndoTransactionID = NO;
}

- (void) _registerClearStateWithUndoManager
{
//pas appellé dans le cas d'un delete ?
  id object;

  EOFLOGObjectFnStart();

  object = [NSNumber numberWithUnsignedInt: _undoTransactionID];
  _flags.registeredUndoTransactionID = YES;

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"_undoManager=%p", _undoManager);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"_undoManager=%@", _undoManager);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"self=%@", self);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);

  [_undoManager registerUndoWithTarget: self
                selector: @selector(_clearChangedThisTransaction:)
                object: object];

  EOFLOGObjectFnStop();
}

- (void)deleteObject: (id)object
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  if (!NSHashGet(_unprocessedDeletes, object)
     && !NSHashGet(_deletedObjects, object))
   {
     NSMethodSignature *undoMethodSignature = nil;
     EOUndoManager *undoManager;
     //EOGlobalID *gid = [self globalIDForObject: object];

     [self _registerClearStateWithUndoManager];

     undoManager = (EOUndoManager*)[self undoManager];
     [undoManager prepareWithInvocationTarget: self];

     undoMethodSignature = [undoManager methodSignatureForSelector: 
					  @selector(_insertObject:withGlobalID:)];
     /*
       //TODO
       if base class of undoManager ret nil, undomanager call editingcont methodSignatureForSelector: _insertObject:withGlobalID:
       
       undoManager forwardInvocation:
       <NSInvocation selector: _insertObject:withGlobalID: signature: NMethodSignature: types=v@:@@ nargs=4 sizeOfParams=16 returnValueLength=0; >
                        _NSUndoInvocation avec selector:_insertObject:withGlobalID:
                        target self (editing context)
       [undoManager _registerUndoObject:arget: EOEditingContext  -- selector:_insertObject:withGlobalID:
            _invocation=NSInvocation * object: Description:<NSInvocation selector: _insertObject:withGlobalID: signature: NSMethodSignature: types=v@:@@ nargs=4 sizeOfParams=16 returnValueLength=0; >
            next=_NSUndoObject * object:0x0 Description:*nil*
            previous=_NSUndoObject * object:0x0 Description:*nil*
            _target=id object: Description:<EOEditingContext>
     [self _prepareEventGrouping];
*/

     NSHashInsert(_unprocessedDeletes, object);
     [self _enqueueEndOfEventNotification];
   }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void)lockObject: (id)object
{
  EOGlobalID *gid = [self globalIDForObject: object];

  if (gid == nil)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: globalID for object 0x%x not found",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 object];

  [self lockObjectWithGlobalID: gid
	editingContext: self];
}

// Saving
- (BOOL)hasChanges
{
  if(NSCountHashTable(_insertedObjects)
     || NSCountHashTable(_deletedObjects)
     || NSCountHashTable(_changedObjects))
    return YES;

  return NO;
}

- (void)didSaveChanges
{
  NSHashTable *hashTables[3]={ _insertedObjects,
                               _deletedObjects,//??
                               _changedObjects };
  NSMutableArray *objectsForNotification[3]={ [NSMutableArray array],//inserted
                                              [NSMutableArray array],//deleted
                                              [NSMutableArray array] };//updated 
  NSEnumerator *enumerator = nil;
  id object = nil;
  int which;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"Changes nb: inserted:%d deleted:%d changed:%d",
			NSCountHashTable(_insertedObjects),
			NSCountHashTable(_deletedObjects),
			NSCountHashTable(_changedObjects));

  _flags.ignoreChangeNotification=NO; //MG??

  for (which = 0; which < 3; which++)
    {
      NSHashEnumerator hashEnumerator = NSEnumerateHashTable(hashTables[which]);

      while ((object = (id)NSNextHashEnumeratorItem(&hashEnumerator)))
        {
          [objectsForNotification[which] addObject: object];
          [self clearOriginalSnapshotForObject: object]; //OK for update
        }
    }

  enumerator = [NSAllHashTableObjects(_deletedObjects) objectEnumerator];
  while ((object = [enumerator nextObject]))
    {
      [self forgetObject: object];
      [object clearProperties];
    }

  NSResetHashTable(_insertedObjects);
  NSResetHashTable(_deletedObjects);
  NSResetHashTable(_changedObjects);
  [self incrementUndoTransactionID]; //OK for update

  {
    EOGlobalID *gid;

    enumerator = [[_snapshotsByGID allKeys] objectEnumerator];

    while ((gid = [enumerator nextObject]))
      {
        [_snapshotsByGID setObject: [[self objectForGlobalID:gid] snapshot]
                         forKey: gid];
      }
  }

  [[NSNotificationCenter  defaultCenter]
    postNotificationName: @"EOEditingContextDidSaveChangesNotification"
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      objectsForNotification[0], @"inserted",
			    objectsForNotification[1], @"deleted",
			    objectsForNotification[2], @"updated",
			    nil, nil]];

  EOFLOGObjectFnStop();
}

- (void)saveChanges
{
  id object = nil;
  NSEnumerator *enumerator;

  EOFLOGObjectFnStart();

  //TODOLOCK
  [self lock];

  NS_DURING
    {        
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);

      enumerator = [_editors objectEnumerator];

      while ((object = [enumerator nextObject]))
        [object editingContextWillSaveChanges: self];
      
      if (_delegateRespondsTo.willSaveChanges)
        [_delegate editingContextWillSaveChanges: self];

      [self _processRecentChanges]; // filled lists _changedObjects, _deletedObjects, _insertedObjects, breaks relations

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);

      _flags.registeredForCallback = NO;

      [self validateChangesForSave]; // may raise exception

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			    [self unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			    [self objectsDescription]);
      //?? [EOObserverCenter notifyObserversObjectWillChange: nil];
      
      _flags.ignoreChangeNotification = YES;

      EOFLOGObjectLevel(@"EOEditingContext",
			@"_objectStore saveChangesInEditingContext");

      [_objectStore saveChangesInEditingContext: self];
      EOFLOGObjectLevel(@"EOEditingContext", @"self didSaveChanges");

      [self didSaveChanges];

      EOFLOGObjectFnStop();
    }
  NS_HANDLER
    {
      NSLog(@"%@ (%@)", localException, [localException reason]);
      NSDebugMLog(@"%@ (%@)", localException, [localException reason]);

      [self unlock];
      [localException raise];
    }
  NS_ENDHANDLER;

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  [self unlock];
}

- (NSException *) tryToSaveChanges
{
  NSException *newException = nil;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  NS_DURING
    {
      [self saveChanges];
    }
  NS_HANDLER
    {
      if(_messageHandler
	 && [_messageHandler
	      respondsToSelector: @selector(editingContext:presentErrorMessage:)] == YES)
	[_messageHandler editingContext: self
			 presentErrorMessage: [localException reason]];

        newException = localException;
    }
  NS_ENDHANDLER;

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");
  
  return newException;
}

- (void)revert
{
  NSEnumerator *enumerator;
  EOGlobalID *gid;

  enumerator = [_eventSnapshotsByGID keyEnumerator];
  while ((gid = [enumerator nextObject]))
    {
      [[self objectForGlobalID: gid]
	updateFromSnapshot: [_eventSnapshotsByGID objectForKey: gid]];
    }

#if 0
  [_undoManager removeAllActions];
  [_undoManager beginUndoGrouping];
#endif

  NSResetHashTable(_unprocessedChanges);
  NSResetHashTable(_unprocessedDeletes);
  NSResetHashTable(_unprocessedInserts);

  NSResetHashTable(_changedObjects);
  NSResetHashTable(_deletedObjects);
  NSResetHashTable(_insertedObjects);
}

- (void) clearOriginalSnapshotForObject: (id)object
{
  //Consider OK
  EOGlobalID *gid = [self globalIDForObject: object];

  if (gid)
    {
      [_snapshotsByGID removeObjectForKey: gid];
    }
}

- (id)objectForGlobalID:(EOGlobalID *)globalID
{
  id object;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", globalID);
//  NSDebugMLLog(@"XXX",@"_objectsByGID=%@",NSAllMapTableKeys(_objectsByGID));

  object = NSMapGet(_objectsByGID, globalID);

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%p", object);

  EOFLOGObjectFnStop();

  return object;
}

- (EOGlobalID *)globalIDForObject: (id)object
{
  //Consider OK
  EOGlobalID *gid;

  /*
    [self recordForObject:object]
    [self notImplemented:_cmd]; //TODO
  */

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"ed context=%p _objectsById=%p object=%p",
			self, _objectsById, object);
//  EOFLOGObjectLevelArgs(@"EOEditingContext",@"_objectsById Values=%@",NSAllMapTableValues(_objectsById));

  gid = NSMapGet(_objectsById, object);

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);

  EOFLOGObjectFnStop();

  return gid;
}

- (NSHashTable*) recordForGID: (EOGlobalID *)globalID
{
  [self notImplemented: _cmd]; //TODO
  return NULL;
}

- (NSHashTable*) recordForObject: (id)object
{
  [self notImplemented: _cmd]; //TODO
  return NULL;
}

- (void)setDelegate: (id)delegate
{
  _delegate = delegate;
  _delegateRespondsTo.willRunLoginPanel = 
    [delegate respondsToSelector: @selector(databaseContext:willRunLoginPanelToOpenDatabaseChannel:)];
  _delegateRespondsTo.shouldFetchObjects = 
    [delegate respondsToSelector: @selector(editingContext:shouldFetchObjectsDescribedByFetchSpecification:)];
  _delegateRespondsTo.shouldInvalidateObject = 
    [delegate respondsToSelector: @selector(editingContext:shouldInvalidateObject:globalID:)];
  _delegateRespondsTo.shouldMergeChanges = 
    [delegate respondsToSelector: @selector(editingContext:shouldMergeChangesForObject:)];
  _delegateRespondsTo.shouldPresentException = 
    [delegate respondsToSelector: @selector(editingContext:shouldPresentException:)];
  _delegateRespondsTo.shouldUndoUserActions = 
    [delegate respondsToSelector: @selector(editingContextShouldUndoUserActionsAfterFailure:)];
  _delegateRespondsTo.shouldValidateChanges = 
    [delegate respondsToSelector: @selector(editingContextShouldValidateChanges:)];
  _delegateRespondsTo.willSaveChanges = 
    [delegate respondsToSelector: @selector(editingContextWillSaveChanges:)];
}

- (id)delegate
{
  return _delegate;
}

- (EOObjectStore *)parentObjectStore
{
  return _objectStore;
}

- (EOObjectStore *)rootObjectStore
{
  EOObjectStore *rootObjectStore;

  EOFLOGObjectFnStart();

  if ([_objectStore isKindOfClass: [EOEditingContext class]] == YES)
    rootObjectStore = [(EOEditingContext *)_objectStore rootObjectStore];
  else
    rootObjectStore=_objectStore;

  EOFLOGObjectFnStop();

  return rootObjectStore;
}


// Advanced methods //////////////////////////

- (void)setUndoManager: (NSUndoManager *)undoManager
{
  ASSIGN(_undoManager, undoManager);
}

- (NSUndoManager *)undoManager
{
  return _undoManager;
}

- (void)_revertChange: (NSDictionary *)dict
{
  [[dict objectForKey: @"object"]
    updateFromSnapshot: [dict objectForKey: @"snapshot"]];
}

- (void)objectWillChange: (id)object
{
  EOFLOGObjectFnStart();

//  EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);
  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"object=%@ _flags.ignoreChangeNotification=%d",
			object, (int)_flags.ignoreChangeNotification);

  if (_flags.ignoreChangeNotification == NO)
    {
      NSDictionary *snapshot;

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"*** object change %p %@",
			    object, [object class]);
      //recordForObject:

      snapshot = [object snapshot]; // OK

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"snapshot=%@", snapshot);
//if not in _unprocessedChanges: add in snaps and call _enqueueEndOfEventNotification
/*
[_undoManager registerUndoWithTarget:self
			  selector:@selector(noop:)
			  object:nil;];
*/
////////
      if (NSHashInsertIfAbsent(_unprocessedChanges, object)) //The object is already here
	{
          EOFLOGObjectLevel(@"EOEditingContext",
			    @"_enqueueEndOfEventNotification");
          [self _enqueueEndOfEventNotification];

          /*
	  if(_undoManager)
	    [_undoManager registerUndoWithTarget:self
			  selector:@selector(_revertChange:)
			  object:[NSDictionary dictionaryWithObjectsAndKeys:
						 object, @"object",
					       [object snapshot], @"snapshot",
					       nil]];
          */
	}
      else
	{
          //???????????
          EOGlobalID *gid = [self globalIDForObject: object];

          EOFLOGObjectLevel(@"EOEditingContext",
			    @"insert into xxsnapshotsByGID");

	  [_eventSnapshotsByGID setObject: [object snapshot]
				forKey: gid];

	  [_snapshotsByGID setObject: [object snapshot]
                           forKey: gid];

	  if (_flags.autoLocking == YES)
	    [self lockObject: object];
	}
    }

  EOFLOGObjectFnStop();
}

- (void)recordObject: (id)object
            globalID: (EOGlobalID *)globalID
{
  //OK
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"Record %p for %@ in ed context %p _objectsById=%p",
			object, globalID, self, _objectsById);

  NSAssert(object, @"No Object");
  NSAssert(globalID, @"No GlobalID");
  
  EOFLOGObjectLevel(@"EOEditingContext", @"insertInto _objectsById");
  NSMapInsert(_objectsById, object, globalID);

  //TODO: delete
  {
    id aGID2;
    id aGID = NSMapGet(_objectsById, object);

    NSAssert1(aGID, @"Object %p recorded but can't retrieve it directly !",
	      object);

    aGID2 = [self globalIDForObject: object];

    NSAssert1(aGID2, @"Object %p recorded but can't retrieve it with globalIDForObject: !", object);
  }

  EOFLOGObjectLevel(@"EOEditingContext", @"insertInto _objectsByGID");

  NSMapInsert(_objectsByGID, globalID, object);

  EOFLOGObjectLevel(@"EOEditingContext", @"addObserver");

  [EOObserverCenter addObserver: self
                    forObject: object];
//call EOAccessFaultHandler  targetClass
  EOFLOGObjectFnStop();
}

- (void)forgetObject: (id)object
{
  EOGlobalID *gid;

  gid = [self globalIDForObject: object];
  NSMapRemove(_objectsById, object);
  NSMapRemove(_objectsByGID, gid);

  [EOObserverCenter removeObserver: self
                    forObject: object];
}

- (NSArray *)registeredObjects
{
  return NSAllMapTableValues(_objectsByGID);
}

- (NSArray *)updatedObjects
{
  NSMutableArray *updatedObjects = [NSMutableArray array];
  NSHashEnumerator changedEnum = NSEnumerateHashTable(_changedObjects);
  id object;

  while ((object = (id)NSNextHashEnumeratorItem(&changedEnum)))
    {
      if (!NSHashGet(_deletedObjects, (const void*)object))
          [updatedObjects addObject: object];
    }

//  NSEndHashTableEnumeration(changedEnum);

  return updatedObjects;
}

- (NSArray *)insertedObjects
{
  return NSAllHashTableObjects(_insertedObjects);
  //TODO: remove inserted objectss which are deleted ???
}

- (NSArray *)deletedObjects
{
  return NSAllHashTableObjects(_deletedObjects);
}


- (void)_revertInsert: (id)object
{
  NSHashRemove(_insertedObjects, object);
}

- (void)_revertUpdate: (id)object
{
  NSHashRemove(_changedObjects, object);
}

- (void)_revertDelete: (id)object
{
  NSHashRemove(_deletedObjects, object);
}

//	***************************
//	*
//	*	Objects for DELETE
//	*
//	* compares object from _unprocessedChanges
//  * between their state from _eventSnapshots  and [object snapshot]
//  *
//  * you can see if any other instead of this EditingContext has changed the object
//  *
//  * decision of keeping or deleting these changed objects (RelationshipObjects)
//	*
//	****************************
- (void)processRecentChanges
{
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);
  NSEmitTODO();

//  [self notImplemented:_cmd]; //TODO
  [self _processRecentChanges]; //ret YES
}

- (BOOL)propagatesDeletesAtEndOfEvent
{
  return _flags.propagatesDeletesAtEndOfEvent;
}

- (void)setPropagatesDeletesAtEndOfEvent: (BOOL)propagatesDeletesAtEndOfEvent
{
  _flags.propagatesDeletesAtEndOfEvent = propagatesDeletesAtEndOfEvent;
}

- (BOOL)stopsValidationAfterFirstError
{
  return !_flags.exhaustiveValidation;
}

- (void)setStopsValidationAfterFirstError:(BOOL)flag
{
  _flags.exhaustiveValidation = !flag;
}

- (BOOL)locksObjectsBeforeFirstModification
{
  return _flags.autoLocking;
}

- (void)setLocksObjectsBeforeFirstModification: (BOOL)flag
{
  _flags.autoLocking = flag;
}


// Snapshotting

/** Returns a dictionary containing a snapshot of object that 
reflects its committed values (last values putted in the 
database; i.e. values before changes were made on the object).
It is updated after commiting new values.
**/

- (NSDictionary *)committedSnapshotForObject: (id)object
{
  //OK
  return [_snapshotsByGID objectForKey: [self globalIDForObject: object]];
}

/** Returns a dictionary containing a snapshot of object with 
its state as it was at the beginning of the current event loop. 
After the end of the current event, upon invocation of 
processRecentChanges, the snapshot is updated to hold the 
modified state of the object.**/
- (NSDictionary *)currentEventSnapshotForObject: (id)object
{
  //OK
  return [_eventSnapshotsByGID objectForKey: [self globalIDForObject: object]];
}

- (NSDictionary *)uncommittedChangesForObject: (id)object
{
  return [object changesFromSnapshot:
		   [self currentEventSnapshotForObject: object]];
}

- (void)refaultObjects
{
  NSMutableArray *objs = [[NSMutableArray new] autorelease];
  NSEnumerator *objsEnum;
  id obj;

  [self processRecentChanges];

  [objs addObjectsFromArray: NSAllMapTableKeys(_objectsById)];

  [objs removeObjectsInArray: [self insertedObjects]];
  [objs removeObjectsInArray: [self deletedObjects]];
  [objs removeObjectsInArray: [self updatedObjects]];

  objsEnum = [objs objectEnumerator];

  while ((obj = [objsEnum nextObject]))
    [self refaultObject: obj
	  withGlobalID: [self globalIDForObject: obj]
	  editingContext: self];
}

// Refaults all objects that haven't been modified, inserted or deleted.

- (void)setInvalidatesObjectsWhenFreed: (BOOL)flag
{
  _flags.skipInvalidateOnDealloc = flag;
}

- (BOOL)invalidatesObjectsWhenFreed
{
  return _flags.skipInvalidateOnDealloc; // TODO contrario ??
}

- (void)addEditor: (id)editor
{
  [_editors addObject: editor];
}

- (void)removeEditor: (id)editor
{
  [_editors removeObject: editor];
}

- (NSArray *)editors
{
  return _editors;
}

- (void)setMessageHandler: (id)handler
{
  _messageHandler = handler;
}

- (id)messageHandler
{
  return _messageHandler;
}

- (id)faultForGlobalID: (EOGlobalID *)globalID
	editingContext: (EOEditingContext *)context
{
  //OK
  id object = [self objectForGlobalID: globalID];

  if (!object)
    {
      BOOL isTemporary = [globalID isTemporary];

      if (isTemporary)
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
      else
        {
          object = [_objectStore faultForGlobalID: globalID
				 editingContext: self];
        }
    }

  return object;
}

- (id)faultForRawRow: (NSDictionary *)row
	 entityNamed: (NSString *)entityName
      editingContext: (EOEditingContext *)context
{
  EOEntityClassDescription *classDesc;
  EOGlobalID *globalID;
  id object;
  id objectCopy;

  classDesc = (id)[EOClassDescription classDescriptionForEntityName:
					entityName];
#warning (stephane@sente.ch) ERROR: trying to use EOEntity/EOEntityDescription which are defined in EOAccess
  globalID = [[classDesc entity] globalIDForRow: row];
  object = [self objectForGlobalID: globalID];

  if (object)
    {
      if (context == self)
	return object;

      objectCopy = [classDesc createInstanceWithEditingContext: context
			      globalID: globalID
			      zone: NULL];

      NSAssert1(objectCopy, @"No Object. classDesc=%@", classDesc);
      [objectCopy updateFromSnapshot: [object snapshot]];

      [context recordObject: objectCopy
	       globalID: globalID];

      return objectCopy;
    }

  object = [_objectStore faultForRawRow: row
			 entityNamed: entityName
			 editingContext: self];

  return object;
}

- (id)faultForRawRow: (id)row entityNamed: (NSString *)entityName
{
  id object;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  object = [self faultForRawRow: row
                 entityNamed: entityName 
                 editingContext: self];  

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return object;
}

- (NSArray *)arrayFaultWithSourceGlobalID: (EOGlobalID *)globalID
			 relationshipName: (NSString *)name
			   editingContext: (EOEditingContext *)context
{
  NSArray *fault;
  id object = [self objectForGlobalID: globalID];
  id objectCopy;

  if (object)
    {
      if (context == self)
	{
	  fault = [object valueForKey:name];
	  if (fault)
	    return fault;
	}
      else
	{
	  objectCopy = [[EOClassDescription classDescriptionForEntityName:
					      [globalID entityName]]
			 createInstanceWithEditingContext: context
			 globalID: globalID
			 zone: NULL];

          NSAssert1(objectCopy, @"No Object. globalID=%@", globalID);
	  [objectCopy updateFromSnapshot: [object snapshot]];

	  [context recordObject: objectCopy
		   globalID: globalID];

	  return [objectCopy valueForKey: name];
	}
    }

  return [_objectStore arrayFaultWithSourceGlobalID: globalID
		       relationshipName: name
		       editingContext: self];
}

- (void)initializeObject: (id)object
	    withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context
{
//near OK
  EOObjectStore *objectStore = nil;

  _flags.ignoreChangeNotification = YES;

  if (self == context)
    {
      objectStore = [(EOObjectStoreCoordinator*)_objectStore objectStoreForGlobalID: globalID];
      [objectStore initializeObject: object
                   withGlobalID: globalID
                   editingContext: context];
    }
  else
    {
      NSEmitTODO();
      [self notImplemented: _cmd];//TODO
    }
  // [EOObserverCenter notifyObserversObjectWillChange: nil];
  _flags.ignoreChangeNotification = NO;
}

- (NSArray *)objectsForSourceGlobalID: (EOGlobalID *)globalID
		     relationshipName: (NSString *)name
		       editingContext: (EOEditingContext *)context
{
  NSArray *objects = nil;

  if (self == context)
    {
      //TODOLOCK
      [self lock];
      NS_DURING
        {  
          objects = [_objectStore objectsForSourceGlobalID: globalID
				  relationshipName: name
				  editingContext: context];
        }
      NS_HANDLER
        {
          NSLog(@"%@ (%@)", localException, [localException reason]);
          NSDebugMLog(@"%@ (%@)", localException, [localException reason]);
          [self unlock];
          [localException raise];
        }
      NS_ENDHANDLER;

      [self unlock];
    }
  else
    {
      NSEmitTODO();
      [self notImplemented: _cmd];//TODO
    }

  return objects;
}

- (void)refaultObject: object
	 withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context
{
  //Near OK
  if (object)
    {
      //call globalID isTemporary //ret NO
      if (self == context)//??
        {
          //NO: in EODatabaseConetxt [object clearProperties];

          //OK
          [_objectStore refaultObject: object
                        withGlobalID: globalID
                        editingContext: context];
          //OK
          [self clearOriginalSnapshotForObject: object];
        }
      else
        {
          [self notImplemented: _cmd];
        }
    }
}

- (void)saveChangesInEditingContext: (EOEditingContext *)context
{
  if (context != self)
    {
      NSArray *objects;
      NSEnumerator *objsEnum;
      EOGlobalID *gid;
      id object, localObject;

      objects = [context insertedObjects];

      objsEnum = [objects objectEnumerator];
      while ((object = [objsEnum nextObject]))
        {
          gid = [context globalIDForObject: object];

          localObject = [[EOClassDescription classDescriptionForEntityName:
                                               [gid entityName]]
                          createInstanceWithEditingContext: context
                          globalID: gid
                          zone: NULL];

          NSAssert1(localObject, @"No Object. gid=%@", gid);

          [localObject updateFromSnapshot: [object snapshot]];

          [self recordObject: localObject
                globalID: gid];
        }

      objects = [context updatedObjects];

      objsEnum = [objects objectEnumerator];
      while ((object = [objsEnum nextObject]))
        {
          gid = [context globalIDForObject: object];
          localObject = [self objectForGlobalID: gid];

          [localObject updateFromSnapshot:[object snapshot]];
        }

      objects = [context deletedObjects];

      objsEnum = [objects objectEnumerator];
      while ((object = [objsEnum nextObject]))
        {
          gid = [context globalIDForObject: object];
          localObject = [self objectForGlobalID: gid];

          [self deleteObject: localObject];
        }
    }
}

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetch
			    editingContext: (EOEditingContext *)context
{
  //OK
  NSArray *objects = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"_objectStore=%@ fetch=%@ context=%@",
			_objectStore, fetch, context);

  [self lock]; //TODOLOCK

  NS_DURING
    {
      objects = [_objectStore objectsWithFetchSpecification: fetch
			      editingContext: context];
    }
  NS_HANDLER
    {
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"EXCEPTION: %@",
			    localException);

      [self unlock]; //TODOLOCK

      if ([self handleError: localException])
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
      else
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
    }
  NS_ENDHANDLER;

  [self unlock]; //TODOLOCK

  EOFLOGObjectFnStop();

  return objects;
}

- (void)lockObjectWithGlobalID: (EOGlobalID *)gid
		editingContext: (EOEditingContext *)context
{
  [_objectStore lockObjectWithGlobalID: gid
		editingContext: context];
}

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)gid
		    editingContext: (EOEditingContext *)context
{
  return [_objectStore isObjectLockedWithGlobalID: gid
		       editingContext: context];
}

@end


@implementation NSObject (EOEditingContext)

- (EOEditingContext *)editingContext
{
  return [EOObserverCenter observerForObject: self
			   ofClass: [EOEditingContext class]];
}

@end


@implementation NSObject (EOEditors)

/** Called by the EOEditingContext to determine if the editor is "dirty" **/
- (BOOL)editorHasChangesForEditingContext: (EOEditingContext *)editingContext
{
  return NO;
}

- (void)editingContextWillSaveChanges: (EOEditingContext *)editingContext
{
  return;
}

@end


//
// EOMessageHandler informal protocol
//
@implementation NSObject (EOMessageHandlers)

- (void)editingContext: (EOEditingContext *)editingContext
   presentErrorMessage: (NSString *)message
{
  NSDebugMLog(@"error=%@", message);
}

- (BOOL)editingContext: (EOEditingContext *)editingContext
shouldContinueFetchingWithCurrentObjectCount: (unsigned)count
	 originalLimit: (unsigned)limit
	   objectStore: (EOObjectStore *)objectStore
{
  return NO;
}

@end


@implementation EOEditingContext (EORendezvous)

+ (void)setSubstitutionEditingContext: (EOEditingContext *)ec
{
  [self notImplemented: _cmd]; //TODO
}

+ (EOEditingContext *)substitutionEditingContext
{
  return [self notImplemented: _cmd]; //TODO
}

+ (void)setDefaultParentObjectStore: (EOObjectStore *)store
{
  ASSIGN(defaultParentStore, store);
}

+ (EOObjectStore *)defaultParentObjectStore
{
  return defaultParentStore;
}

@end

@implementation EOEditingContext (EOStateArchiving)

+ (void)setUsesContextRelativeEncoding: (BOOL)yn
{
  [self notImplemented: _cmd]; //TODO
}

+ (BOOL)usesContextRelativeEncoding
{
  [self notImplemented: _cmd]; //TODO
  return NO;
}

+ (void)encodeObject: (id)object
           withCoder: (NSCoder *)coder
{
  [self notImplemented: _cmd]; //TODO
}

+ (id)initObject: (id)object
       withCoder: (NSCoder *)coder
{
  return [self notImplemented: _cmd]; //TODO
}

@end


// Target action methods for InterfaceBuilder
//
@implementation EOEditingContext (EOTargetAction)

- (void)saveChanges: (id)sender // TODO
{
  NS_DURING
    [self saveChanges];
  NS_HANDLER
    {
      if(_messageHandler
	 && [_messageHandler
	      respondsToSelector: @selector(editingContext:presentErrorMessage:)] == YES)
	[_messageHandler editingContext: self
			 presentErrorMessage: [localException reason]];
    }
  NS_ENDHANDLER;
}

- (void)refault: (id)sender
{
  [self refaultObjects];
}

- (void)revert: (id)sender
{
  [self revert];
}

- (void)refetch: (id)sender
{
  [self invalidateAllObjects];
}

- (void)undo: (id)sender
{
  [_undoManager undo];
}

- (void)redo: (id)sender
{
  [_undoManager redo];
}

- (NSString*)unprocessedDescription
{
  NSString *desc;

  EOFLOGObjectFnStart();

  desc = [NSString stringWithFormat: @"<%p:\nunprocessedChanges [nb:%d]=%p %@\n\nunprocessedDeletes [nb:%d]=%p %@\n\nunprocessedInserts[nb:%d]=%p %@>\n",
		   self,
		   NSCountHashTable(_unprocessedChanges),
		   _unprocessedChanges,
		   NSStringFromHashTable(_unprocessedChanges),
		   NSCountHashTable(_unprocessedDeletes),
		   _unprocessedDeletes,
		   NSStringFromHashTable(_unprocessedDeletes),
		   NSCountHashTable(_unprocessedInserts),
		   _unprocessedInserts,
		   NSStringFromHashTable(_unprocessedInserts)];

  EOFLOGObjectFnStop();

  return desc;
}

- (NSString*)objectsDescription
{
  NSString *desc;

  EOFLOGObjectFnStart();

  desc = [NSString stringWithFormat: @"<%p:\nchangedObjects [nb:%d]=%p %@\n\ndeletedObjects [nb:%d]=%p %@\n\ninsertedObjects [nb:%d]=%p %@>\n",
		   self,
		   NSCountHashTable(_changedObjects),
		   _changedObjects,
		   NSStringFromHashTable(_changedObjects),
		   NSCountHashTable(_deletedObjects),
		   _deletedObjects,
		   NSStringFromHashTable(_deletedObjects),
		   NSCountHashTable(_insertedObjects),
		   _insertedObjects,
		   NSStringFromHashTable(_insertedObjects)];

  EOFLOGObjectFnStop();

  return desc;
}

@end


// To support multithreaded operation
@implementation EOEditingContext(EOMultiThreaded)

+ (void)setEOFMultiThreadedEnabled: (BOOL)flag
{
  [self notImplemented: _cmd];
}

- (BOOL)tryLock
{
  BOOL tryLock = NO;

  EOFLOGObjectFnStart();

  tryLock = [_lock tryLock];

  if (tryLock)
    _lockCount++;

  EOFLOGObjectFnStop();

  return tryLock;
}

- (void)lock
{
  EOFLOGObjectFnStart();

  [_lock lock];
  _lockCount++;

  EOFLOGObjectFnStop();
}

- (void)unlock
{
  EOFLOGObjectFnStart();

  _lockCount--;
  [_lock unlock];

  EOFLOGObjectFnStop();
}

- (void) _assertSafeMultiThreadedAccess: (SEL)param0
{
  [self notImplemented: _cmd]; //TODO
}

@end

// Informations
@implementation EOEditingContext(EOEditingContextInfo)

- (NSDictionary*)unprocessedInfo
{
  NSDictionary *infoDict = nil;
  NSHashTable *hashTables[3] = { _unprocessedChanges,
				 _unprocessedDeletes,
				 _unprocessedInserts };
  NSMutableArray *objectsForInfo[3] = { [NSMutableArray array], //inserted
					[NSMutableArray array], //deleted
					[NSMutableArray array] }; //updated 
  id object;
  int which;

  EOFLOGObjectFnStart();

  for (which = 0; which < 3; which++)
    {
      NSHashEnumerator hashEnumerator = NSEnumerateHashTable(hashTables[which]);

      while ((object = (id)NSNextHashEnumeratorItem(&hashEnumerator)))
        {
          NSString *info = [NSString stringWithFormat: @"%@ (%p)",
				     [[object entity] name],
				     object];

          [objectsForInfo[which] addObject: info];
        }
    }

  infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             objectsForInfo[0], @"insert",
                           objectsForInfo[1], @"delete",
                           objectsForInfo[2], @"update",
                           nil, nil];

  NSDebugMLog(@"infoDict=%@", infoDict);
  EOFLOGObjectFnStop();

  return infoDict;  
}

- (NSDictionary*)pendingInfo
{
  NSDictionary *infoDict = nil;
  NSHashTable *hashTables[3] = { _insertedObjects,
				 _deletedObjects,
				 _changedObjects };
  NSMutableArray *objectsForInfo[3] = { [NSMutableArray array], //inserted
					[NSMutableArray array], //deleted
					[NSMutableArray array] }; //updated 
  id object;
  int which;

  EOFLOGObjectFnStart();

  for (which = 0; which < 3; which++)
    {
      NSHashEnumerator hashEnumerator = NSEnumerateHashTable(hashTables[which]);

      while ((object = (id)NSNextHashEnumeratorItem(&hashEnumerator)))
        {
          NSString *info = [NSString stringWithFormat: @"%@ (%p)",
				     [[object entity] name],
				     object];

          [objectsForInfo[which] addObject: info];
        }
    }

  infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
			     objectsForInfo[0], @"inserted",
			   objectsForInfo[1], @"deleted",
			   objectsForInfo[2], @"updated",
			   nil, nil];

  NSDebugMLog(@"infoDict=%@", infoDict);
  EOFLOGObjectFnStop();

  return infoDict;  
}

@end
