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
#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <Foundation/Foundation.h>

#include <GNUstepBase/GSLock.h>

#include <EOControl/EOEditingContext.h>
#include <EOControl/EOObjectStoreCoordinator.h>
#include <EOControl/EOGlobalID.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOFault.h>
#include <EOControl/EONull.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODeprecated.h>
#include <EOControl/EODebug.h>
#include <EOControl/EOPriv.h>

@class EOEntityClassDescription;

/*
 * These EOAccess specific declarations are intended to
 * supress long compiler warnings.  Non the less we should
 * avoid dependancies on EOAccess.
 */
@interface NSObject(EOEntityWarningSupression)
- (NSString *) name;
- (EOGlobalID *) globalIDForRow:(NSDictionary *)row;
@end
@interface EOEntityClassDescription : EOClassDescription
- (NSObject *) entity;
@end

@interface EOEditingContext(EOEditingContextPrivate)
- (void) incrementUndoTransactionID;
- (BOOL) handleError: (NSException *)exception;
- (BOOL) handleErrors: (NSArray *)exceptions;

- (void) _enqueueEndOfEventNotification;
- (void) _sendOrEnqueueNotification: (NSNotification *)notification
                           selector: (SEL)selector;

- (void) _insertObject: (id)object
          withGlobalID: (EOGlobalID *)gid;

- (void) _processObjectStoreChanges: (NSDictionary *)changes;
- (void) _processDeletedObjects;
- (void) _processOwnedObjectsUsingChangeTable: (NSHashTable*)changeTable
                                  deleteTable: (NSHashTable*)deleteTable;
- (void)_processNotificationQueue;

- (void) _observeUndoManagerNotifications;

- (void) _registerClearStateWithUndoManager;

- (void) _forgetObjectWithGlobalID:(EOGlobalID *)gid;

- (void) _invalidateObject:(id)obj withGlobalID: (EOGlobalID *)gid;
- (void) _invalidateObjectsWithGlobalIDs: (NSArray*)gids;
- (NSDictionary *) _objectBasedChangeInfoForGIDInfo: (NSDictionary *)changes;

- (NSMutableSet *)_mutableSetFromToManyArray: (NSArray *)array;
- (NSArray *)_uncommittedChangesForObject: (id)obj
                             fromSnapshot: (NSDictionary *)snapshot;
- (NSArray *)_changesFromInvalidatingObjectsWithGlobalIDs: (NSArray *)globalIDs;

- (void) _resetAllChanges;

@end

@interface EOThreadSafeQueue : NSObject
{
  GSLazyRecursiveLock *lock;
  NSMutableArray *arr;
}
-(void)addItem:(id)object;
-(id)removeItem;
@end

@implementation EOThreadSafeQueue
- (id)init
{
  if ((self=[super init]))
    {
      lock = [GSLazyRecursiveLock new];
      arr = [NSMutableArray new];
    }
  return self;
}
- (void)dealloc
{
  RELEASE(lock);
  RELEASE(arr);
  [super dealloc];
}

-(void)addItem:(id)object
{
  NSParameterAssert(object);
  [lock lock];
  [arr addObject: object];
  [lock unlock];
}
-(id)removeItem
{
  id item = nil;
  [lock lock];
  if ([arr count])
    {
      item = [arr objectAtIndex: 0];
      [arr removeObjectAtIndex: 0];
    }
  [lock unlock];
  return item;
}
@end


@implementation EOEditingContext

static Class EOAssociationClass = nil;

static EOObjectStore *defaultParentStore = nil;
static NSTimeInterval defaultFetchLag = 3600.0;

static NSHashTable *ecDeallocHT = 0;
static NSHashTable *assocDeallocHT = 0;

/* Notifications */
NSString *EOObjectsChangedInEditingContextNotification
      = @"EOObjectsChangedInEditingContextNotification";
NSString *EOEditingContextDidSaveChangesNotification 
      = @"EOEditingContextDidSaveChangesNotification";

/* Local constants */
NSString *EOConstObject = @"EOConstObject";
NSString *EOConstChanges = @"EOConstChanges";

NSString *EOConstKey = @"EOConstKey";
NSString *EOConstValue = @"EOConstValue";
NSString *EOConstAdd = @"EOConstAdd";
NSString *EOConstDel = @"EOConstDel";

/*
 * This function is used during change processing to multiple changes 
 * to one class property.
 * Either value or the add and remove arrays should be set.
 * The arrays may be emtpy but they must be supplied unless
 * the value is supplied.
 * The value is set via the takeStoredValue:forKey: method (i.e. avoiding
 * the formal accessor machinery) replacing any EONull's with nil.
 * When add and remove arrays are given, processing starts with the remove
 * array and then continues with the add array.
 */
static inline void
_mergeValueForKey(id obj, id value, 
		 NSArray *add, NSArray *del, 
		 NSString *key)
{
  id relObj;
  unsigned int i,n;

  NSCAssert(((value == nil && add != nil && del !=nil)
	     || (value != nil && add == nil && del == nil)),
	    @"Illegal usage of function.");

  n = [del count];
  if (n>0)
    {
      IMP oaiIMP=[del methodForSelector: GDL2_objectAtIndexSEL];

      for (i = 0; i < n; i++)
        {
          relObj = GDL2ObjectAtIndexWithImp(del,oaiIMP,i);

          [obj removeObject: relObj
               fromPropertyWithKey: key];
        }
    };

  n = [add count];
  if (n>0)
    {
      IMP oaiIMP=[add methodForSelector: GDL2_objectAtIndexSEL];

      for (i = 0; i < n; i++)
        {
          relObj = GDL2ObjectAtIndexWithImp(add,oaiIMP,i);

          [obj addObject: relObj
               toPropertyWithKey: key];
        }
    };

  if (add == nil && del == nil)
    {
      value = (value == GDL2EONull) ? nil : value;
      [obj takeStoredValue: value forKey: key];
    }
}

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      BOOL gswapp = NO;
      initialized=YES;

      defaultParentStore = [EOObjectStoreCoordinator defaultCoordinator];
      EOAssociationClass = NSClassFromString(@"EOAssociation");
      gswapp = (NSClassFromString(@"GSWApplication") != nil 
		|| NSClassFromString(@"WOApplication") != nil);
      [self setUsesContextRelativeEncoding: gswapp];
    }
}

+ (void)objectDeallocated:(id)object
{
  [[object editingContext] forgetObject: object];
}

+ (NSTimeInterval)defaultFetchTimestampLag
{
  return defaultFetchLag;
}

+ (void)setDefaultFetchTimestampLag: (NSTimeInterval)lag
{
  defaultFetchLag = lag;
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

      /* We may not retain the objects we are managing.  */
      _globalIDsByObject = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
					    NSObjectMapValueCallBacks,
					    32);
      _objectsByGID = NSCreateMapTable(NSObjectMapKeyCallBacks, 
                                       NSNonOwnedPointerMapValueCallBacks,
                                       32);

      _snapshotsByGID = [[NSMutableDictionary alloc] initWithCapacity:16];
      _eventSnapshotsByGID = [[NSMutableDictionary alloc] initWithCapacity:16];

      _editors = [NSMutableArray new];
      
      _lock = [NSRecursiveLock new];

      _undoManager = [EOUndoManager new];

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
  EOObjectStore *defaultStore = [EOEditingContext defaultParentObjectStore];
  return [self initWithParentObjectStore: defaultStore];
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

  NSFreeMapTable(_globalIDsByObject);
  NSFreeMapTable(_objectsByGID);

  DESTROY(_snapshotsByGID);
  DESTROY(_eventSnapshotsByGID);

  DESTROY(_editors);
  DESTROY(_lock);

  [super dealloc];
}

/*
 * This method processes CHANGES which should be an array of
 * dictionaries with EOConstKey and either EOConstValue or
 * both EOConstAdd and EOConstDel entries and merges the changes
 * into OBJ.
 */
- (void) _mergeObject: (id)obj withChanges: (NSArray *)changes
{
  unsigned int i,n;
  NSString *key;
  NSArray *add, *del;
  NSDictionary *change;
  id val;

  n = [changes count];
  if (n>0)
    {
      IMP oaiIMP=[del methodForSelector: GDL2_objectAtIndexSEL];

      for(i = 0; i < n; i++)
        {
          change = GDL2ObjectAtIndexWithImp(changes,oaiIMP,i);
          key = [change objectForKey: EOConstKey];
          val = [change objectForKey: EOConstValue];
          if (val == nil)
            {
              add = [change objectForKey: EOConstAdd];
              del = [change objectForKey: EOConstDel];
              NSAssert(add!=nil && del!=nil,@"Invalid changes dictionary.");
            }
          _mergeValueForKey(obj, val, add, del, key);
        }
    };
}

/*
 * This method creates an dictionary of changed objects by the
 * change action, based on a similar dictionary with globalIDs.
 * For each key of EODeletedKey, EOInsertedKey, EOInvalidatedKey
 * and EOUpdatedKey an array of corresponding GIDs from the
 * CHANGES array will be mapped to the corresponding objects
 * managed by the receiver for ther returned dictionary. 
 */
- (NSDictionary *)_objectBasedChangeInfoForGIDInfo: (NSDictionary *)changes
{
  NSString *keys[] = { EODeletedKey,
                       EOInsertedKey,
                       EOInvalidatedKey,
                       EOUpdatedKey };
  NSArray *valueArray[4];
  NSDictionary   *dict = nil;
  int i;
  IMP objectForGlobalIDIMP = NULL;

  EOFLOGObjectFnStart();

  for (i=0; i<4; i++)
    {
      NSArray  *gids = [changes objectForKey: keys[i]];
      unsigned  cnt = [gids count];
      id        values[cnt>GS_MAX_OBJECTS_FROM_STACK?0:cnt];
      id       *valuesPStart;
      id       *valuesP;
      unsigned  j;

      valuesPStart = valuesP = (cnt > GS_MAX_OBJECTS_FROM_STACK
                                ? GSAutoreleasedBuffer(sizeof(id) * cnt)
                                : values);

      if (cnt>0)
        {
          IMP oaiIMP=[gids methodForSelector: GDL2_objectAtIndexSEL];

          for (j=0; j<cnt; j++)
            {
              EOGlobalID *gid = GDL2ObjectAtIndexWithImp(gids, oaiIMP, j);
              id obj = EOEditingContext_objectForGlobalIDWithImpPtr(self,&objectForGlobalIDIMP,gid);
              NSAssert2(obj, @"called with GID %@ not managed by receiver (%p).", gid, self);
              *valuesP++ = obj;
            }
        };
      valueArray[i] = [NSArray arrayWithObjects: valuesPStart
                               count: cnt];
    }

  dict = [NSDictionary dictionaryWithObjects: valueArray
                       forKeys: keys
                       count: 4];

  EOFLOGObjectFnStop();

  return dict;
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

/*
 * Process CHANGES, a dictionary of GlobalID arrays assigned
 * to on of the following processing keys: EOInsertedKey, EODeletedKey,
 * EOInvalidatedKey, EOUpdatedKey.
 * First and pending changes are processed via processRecentChanges.
 * The receiver will then forget all objects refered to in the 
 * EODeletedKey array, invalidate all objects refered to in the 
 * EOInvalidatedKey array and generate changes for the objects refered
 * to in the EOUpdatedKey array.
 * This method will reset the _unprocessedInserts, _unprocessedDeletes
 * and _unprocessedChanges hash tables.
 * If the delegate responds to editingContextDidMergeChanges:, it
 * will be notified.
 * Then an EOObjectsChangedInStoreNotification will be posted with the
 * changes with the array of EOGlobalID's followed by an
 * EOObjectsChangedInEditingContextNotification notification with the
 * same chanes but an array of the changes objects.
 */
- (void) _processObjectStoreChanges: (NSDictionary *)changes
{
  NSArray *updatedGIDs;
  NSArray *deletedGIDs;
  NSArray *invalidatedGIDs;
  NSArray *updatedChanges;
  NSDictionary *objectChangeInfo;
  unsigned i,n;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"changes=%@", changes);

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
                        [self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
                        [self objectsDescription]);

  [self processRecentChanges];

  deletedGIDs = [changes objectForKey: EODeletedKey];
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"deletedGIDs=%@",
                        deletedGIDs);

  n=[deletedGIDs count];
  if (n>0)
    {
      IMP oaiIMP=[deletedGIDs methodForSelector: GDL2_objectAtIndexSEL];
      for (i = 0; i < n; i++)
        {
          id obj = GDL2ObjectAtIndexWithImp(deletedGIDs,oaiIMP,i);
          [self _forgetObjectWithGlobalID: obj];
        }
    };

  invalidatedGIDs = [changes objectForKey: EOInvalidatedKey];
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"invalidatedGIDs=%@",
                        invalidatedGIDs);
  [self _invalidateObjectsWithGlobalIDs: invalidatedGIDs];

  updatedGIDs = [changes objectForKey: EOUpdatedKey];
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"updatedGIDs=%@",
                        updatedGIDs);
  updatedChanges
    = [self _changesFromInvalidatingObjectsWithGlobalIDs: updatedGIDs];

  NSResetHashTable(_unprocessedInserts);
  NSResetHashTable(_unprocessedDeletes);
  NSResetHashTable(_unprocessedChanges);

  if (updatedChanges != nil)
    {
      id obj;
      NSArray *chgs;
      NSDictionary *changeSet;
      unsigned i, n;

      [_undoManager removeAllActionsWithTarget: self];

      n = [updatedChanges count];
      if (n>0)
        {
          IMP oaiIMP=[deletedGIDs methodForSelector: GDL2_objectAtIndexSEL];

          for (i = 0; i < n; i++)
            {
              changeSet = GDL2ObjectAtIndexWithImp(updatedChanges,oaiIMP,i);
              obj = [changeSet objectForKey: EOConstObject];
              chgs = [changeSet objectForKey: EOConstChanges];
              
              [self _mergeObject: obj withChanges: chgs];
            }
        };
    }

  if ([updatedChanges count]
      && [_delegate respondsToSelector:
                      @selector(editingContextDidMergeChanges:)])
    {
      [_delegate editingContextDidMergeChanges: self];
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOObjectsChangedInStoreNotification
    object: self
    userInfo: changes];

  objectChangeInfo = [self _objectBasedChangeInfoForGIDInfo: changes];
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"objectChangeInfo=%@",
                        objectChangeInfo);

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOObjectsChangedInEditingContextNotification
    object: self
    userInfo: objectChangeInfo];

  EOFLOGObjectFnStop();
}

- (NSArray *)_changesFromInvalidatingObjectsWithGlobalIDs: (NSArray *)globalIDs
{
  NSMutableArray *chgs = nil;
  unsigned int i, n;

  if ((n = [globalIDs count]))
    {
      IMP oaiIMP=[globalIDs methodForSelector: GDL2_objectAtIndexSEL];
      SEL sel = @selector(editingContext:shouldMergeChangesForObject:);
      BOOL send;
      send = [_delegate respondsToSelector: sel];
      chgs = [NSMutableArray arrayWithCapacity: n];
      
      for (i = 0; i < n; i++)
        {
          EOGlobalID *globalID = GDL2ObjectAtIndexWithImp(globalIDs, oaiIMP, i);
          id obj = NSMapGet(_objectsByGID, globalID);

          if (obj != nil && [EOFault isFault: obj] == NO)
            {
              id hObj = NSHashGet(_changedObjects, obj);
              if (hObj != 0)
                {
                  if (send == NO
                      || [_delegate editingContext: self
                                    shouldMergeChangesForObject: obj])
                    {
                      NSDictionary *snapshot;
                      NSDictionary *chgDict;
                      NSArray *uncommitedChgs;

                      snapshot = [_snapshotsByGID objectForKey: globalID];
                      uncommitedChgs = [self _uncommittedChangesForObject: obj
                                             fromSnapshot: snapshot];

                      if (uncommitedChgs != 0)
                        {
			  chgDict 
			    = [NSDictionary dictionaryWithObjectsAndKeys:
					      obj, EOConstObject,
					    uncommitedChgs, EOConstChanges,
					    nil];
                          [chgs addObject: chgDict];
                        }
                      [self refaultObject: obj
                            withGlobalID: globalID
                            editingContext: self];
                    }
                  else
                    {
                      [self _invalidateObject: obj
                            withGlobalID: globalID];
                    }
                }
            }
        }
    }
  return chgs;
}

- (NSArray *)_uncommittedChangesForObject: (id)obj
                             fromSnapshot: (NSDictionary *)snapshot
{
  NSMutableArray *chgs = [NSMutableArray array];
  NSArray *attribKeys = [obj attributeKeys];
  NSArray *toOneKeys  = [obj toOneRelationshipKeys];
  NSArray *toManyKeys = [obj toManyRelationshipKeys];
  NSString *key;
  NSDictionary *change;
  id objVal, ssVal;
  unsigned i,n;
  IMP chgsAddObjectIMP=[chgs methodForSelector: GDL2_addObjectSEL];

  n = [attribKeys count];
  if (n>0)
    {
      IMP oaiIMP=[attribKeys methodForSelector: GDL2_objectAtIndexSEL];

      for(i = 0; i < n; i++)
        {
          key = GDL2ObjectAtIndexWithImp(attribKeys,oaiIMP, i);
          objVal = [obj storedValueForKey: key];
          ssVal  = [snapshot objectForKey: key];
          
          objVal = (objVal == nil) ? GDL2EONull : objVal;
          
          if ([objVal isEqual: ssVal] == NO)
            {
              change = [NSDictionary dictionaryWithObjectsAndKeys:
                                       key, EOConstKey,
                                     objVal, EOConstValue, nil];
              GDL2AddObjectWithImp(chgs, chgsAddObjectIMP, change);
            }
        }
    };

  n = [toOneKeys count];
  if (n>0)
    {
      IMP oaiIMP = [toOneKeys methodForSelector: GDL2_objectAtIndexSEL];
      IMP globalIDForObjectIMP = NULL;

      for(i = 0; i < n; i++)
        {
          key = GDL2ObjectAtIndexWithImp(toOneKeys, oaiIMP, i);
          objVal = [obj storedValueForKey: key];
          ssVal  = [snapshot objectForKey: key];
          if (objVal != nil)
            {
              EOGlobalID *gid = EOEditingContext_globalIDForObjectWithImpPtr(self, &globalIDForObjectIMP, objVal);
              objVal = (gid == nil) ? GDL2EONull : objVal;
              if (objVal != ssVal)
                {
                  change = [NSDictionary dictionaryWithObjectsAndKeys:
                                           key, EOConstKey,
                                         objVal, EOConstValue, nil];
                  GDL2AddObjectWithImp(chgs, chgsAddObjectIMP, change);
                }
            }
        }
    };

  n = [toManyKeys count];
  if (n>0)
    {
      IMP oaiIMP=[toManyKeys methodForSelector: GDL2_objectAtIndexSEL];

      for(i = 0; i < n; i++)
        {
          key = GDL2ObjectAtIndexWithImp(toManyKeys, oaiIMP, i);
          objVal = [obj storedValueForKey: key];
          ssVal = [snapshot objectForKey: key];
          if ([EOFault isFault: objVal] == NO
              && [EOFault isFault: ssVal] == NO)
            {
              NSMutableSet *objSet = [self _mutableSetFromToManyArray: objVal];
              NSMutableSet *ssSet  = [self _mutableSetFromToManyArray: ssVal];
              NSSet *_ssSet = [NSSet setWithSet: ssSet];
              
              [ssSet  minusSet: objSet]; /* now contains deleted objects */
              [objSet minusSet: _ssSet]; /* now contains added objects */
              
              if ([objSet count] != 0 || [ssSet count] != 0)
                {
                  NSArray *addArr = [objSet allObjects];
                  NSArray *delArr = [ssSet  allObjects];
                  
                  change = [NSDictionary dictionaryWithObjectsAndKeys:
                                           key, EOConstKey,
                                         addArr, EOConstAdd,
                                         delArr, EOConstDel,
                                         nil];
                  GDL2AddObjectWithImp(chgs, chgsAddObjectIMP, change);
                }
            }
        }
    };
  return ([chgs count] == 0) ? nil : chgs;
}

- (NSMutableSet *)_mutableSetFromToManyArray: (NSArray *)array
{
  EOGlobalID *gid;
  NSMutableSet *set;
  id obj;
  unsigned i,n;

  n = [array count];
  set = [NSMutableSet setWithCapacity: n];

  NSAssert(_objectsByGID, @"_objectsByGID does not exist!");

  if (n>0)
    {
      IMP oaiIMP=[array methodForSelector: GDL2_objectAtIndexSEL];
      IMP aoIMP=[set methodForSelector: GDL2_addObjectSEL];

      for (i=0; i<n; i++)
        {
          gid = GDL2ObjectAtIndexWithImp(array, oaiIMP, i);
          obj = NSMapGet(_objectsByGID, gid);
          GDL2AddObjectWithImp(set, aoIMP, obj);
        }
    };
  return set;
}

- (void)_objectsChangedInStore: (NSNotification *)notification
{
  if (_flags.ignoreChangeNotification == NO
      && [notification object] == _objectStore)
    {
      [self _sendOrEnqueueNotification: notification
            selector: @selector(_processObjectStoreChanges:)];
    }
}

/* 
 * This method is called when the an EOGlobalIDChangedNotification 
 * is posted. It updates the globalID mappings maintained by
 * the receiver accordingly.
 */
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

  NSAssert(_objectsByGID, @"_objectsByGID does not exist!");
  NSAssert(_globalIDsByObject, @"_globalIDsByObject does not exist!");

  while ((tempGID = [enumerator nextObject]))
    {
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"tempGID=%@", tempGID);

      gid = [userInfo objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@", gid);

      object = NSMapGet(_objectsByGID, tempGID);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"object=%@", object);

      if (object)
	{
	  /* This insert replaces the object->tmpGID mapping.  */
	  NSMapInsert(_globalIDsByObject, object, gid);

          EOFLOGObjectLevelArgs(@"EOEditingContext", 
                                @"objectsByGID: Remove Object tempGID=%@", 
                                tempGID);
	  NSMapRemove(_objectsByGID, tempGID);

          EOFLOGObjectLevelArgs(@"EOEditingContext", 
                                @"objectsByGID: Insert Object gid=%@", 
                                gid);
	  NSMapInsert(_objectsByGID, gid, object);
	}
      else
        {
          // object is from other editingcontext
          EOFLOGObjectLevelArgs(@"EOEditingContextValues",
                                @"nothing done: object with gid '%@' "
				@"is from other editing context", 
                                tempGID);
        }

      snapshot = [_snapshotsByGID objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EOEditingContext",
			    @"_snapshotsByGID snapshot=%@", snapshot);

      if (snapshot)
        {
          NSAssert2([gid isEqual: tempGID] == NO, 
		   @"gid %@ and temporary gid %@ are equal", gid, tempGID);
          [_snapshotsByGID setObject: snapshot
                           forKey: gid];
          [_snapshotsByGID removeObjectForKey: tempGID];
        }
      else if (object)
        {
          /* What should happen?  The object is maintained by
	     this editing context but it doesn't have a snapshot!
	     Should we creat it? */
	  /*
          // set snapshot with last committed values
          EOFLOGObjectLevelArgs(@"EOEditingContextValues", 
				@"adding new object = %@", 
				[self objectForGlobalID:gid]);
          EOFLOGObjectLevelArgs(@"EOEditingContextValues",
				@"object class = %@",
				NSStringFromClass([object class]));
          EOFLOGObjectLevelArgs(@"EOEditingContextValues",
				@"with snapshot = %@",
				[[self objectForGlobalID:gid] snapshot]);
          [_snapshotsByGID setObject:[[self objectForGlobalID:gid] snapshot] 
		           forKey:gid];
	  */
        }
      else
        {
          // object is from other editingcontext
          EOFLOGObjectLevelArgs(@"EOEditingContextValues",
                                @"nothing done: object with gid '%@' "
				@"is from other editing context", 
                                tempGID);
        }

      snapshot = [_eventSnapshotsByGID objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EOEditingContext",
			    @"_eventSnapshotsByGID snapshot=%@", snapshot);

      if (snapshot)
        {
          [_eventSnapshotsByGID removeObjectForKey: tempGID];
          [_eventSnapshotsByGID setObject: snapshot
                                forKey: gid];
	}
    }

  EOFLOGObjectFnStop();
}

- (void)_processNotificationQueue
{
  EOThreadSafeQueue *queue = _notificationQueue;
  NSDictionary *dict, *userInfo;
  NSString *name;
  SEL selector;

  if ([self tryLock])
    {
      while ((dict = [queue removeItem]))
	{
	  name = [dict objectForKey: @"selector"];
	  selector = NSSelectorFromString(name);
	  userInfo = [dict objectForKey: @"userInfo"];
      
	  [self performSelector: selector
		withObject: userInfo];
	}
      [self unlock];
    }
  else
    {
      /* Setup new call to _processNotificationQueue */
    }
}

- (void)_sendOrEnqueueNotification: (NSNotification *)notification
			  selector: (SEL)selector
{
  if ([self tryLock])
    {
      [self _processNotificationQueue];
      [self performSelector: selector
            withObject: [notification userInfo]];
      [self unlock];
    }
  else
    {
      static NSDictionary *emptyDict = nil;
      NSDictionary *userInfo = nil;
      NSDictionary *queDict;

      if (emptyDict == nil)
        {
          emptyDict = [NSDictionary new];
        }

      userInfo = [notification userInfo];
      if (userInfo == nil)
        {
          userInfo = emptyDict;
        }

      queDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                NSStringFromSelector(selector), @"selector",
                              userInfo, @"userInfo",
                              nil ];
      [(EOThreadSafeQueue *)_notificationQueue addItem: queDict];
    }
}

//"Invalidate All Objects"
- (void) invalidateAllObjects
{
  NSArray *gids;
  [self _resetAllChanges];

  /* The reference implementation seems to first obtain the objects
     via -registeredObjects and then calls globalIDForObject: on each
     but this seems wasteful and we have the array at easy access.  */

  gids = NSAllMapTableKeys(_objectsByGID);
  [_objectStore invalidateObjectsWithGlobalIDs: gids];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOInvalidatedAllObjectsInStoreNotification
    object: self
    userInfo: nil];
}

- (void)_invalidatedAllObjectsInStore: (NSNotification*)notification
{
  if ([notification object] == _objectStore)
    {
      [self _sendOrEnqueueNotification: notification
	    selector: @selector(_resetAllChanges:)];
      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOInvalidatedAllObjectsInStoreNotification
	object: self
	userInfo: nil];
    }
}

- (void) _forgetObjectWithGlobalID:(EOGlobalID*)gid
{
  id object = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"EOEditingContext", @"forgetObjectWithGlobalID: %@",
               gid);

  object = EOEditingContext_objectForGlobalIDWithImpPtr(self,NULL,gid);
  if (object != nil)
    {
      [self forgetObject: object];
      NSHashRemove(_insertedObjects, object);
      NSHashRemove(_deletedObjects, object);
      NSHashRemove(_changedObjects, object);

      if ([EOFault isFault: object] == NO)
        {
          [object clearProperties];
        }
    }

  EOFLOGObjectFnStop();
}

- (void) _invalidateObject: (id)object
              withGlobalID: (EOGlobalID*)gid
{
  SEL sel = @selector(editingContext:shouldInvalidateObject:globalID:);
  BOOL invalidate = YES;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"EOEditingContext", @"invalidateObject:withGlobalID: %@",
               gid);

  if ([_delegate respondsToSelector: sel])
    {
      invalidate = [_delegate editingContext: self
                              shouldInvalidateObject: object
                              globalID: gid];
    }
  if (invalidate == YES)
    {
      [self refaultObject: object
            withGlobalID: gid
            editingContext: self];
    }

  EOFLOGObjectFnStop();
}

- (void) _invalidateObjectWithGlobalID: (EOGlobalID*)gid
{
  id object = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"EOEditingContext", @"invalidateObjectWithGlobalID: %@",
               gid);

  object = EOEditingContext_objectForGlobalIDWithImpPtr(self,NULL,gid);
  if ((object != nil ) && ([EOFault isFault: object] == NO))
    {
      [self _invalidateObject: object withGlobalID: gid];
    }

  EOFLOGObjectFnStop();
}

- (void) _invalidateObjectsWithGlobalIDs: (NSArray*)gids
{
  unsigned count = 0;
  
  EOFLOGObjectFnStart();

  count=[gids count];

  if (count>0)
    {
      unsigned    i = 0;
      SEL         iowgidSEL = @selector(_invalidateObjectWithGlobalID:);//TODO optimz
      IMP         oaiIMP = [gids methodForSelector: GDL2_objectAtIndexSEL];
      IMP         iowgidIMP = [self methodForSelector: iowgidSEL];
      
      for (i=0; i<count; i++)
        {
          EOGlobalID *gid = GDL2ObjectAtIndexWithImp(gids, oaiIMP, i);
          (*iowgidIMP)(self, iowgidSEL, gid);
        }
    };

  EOFLOGObjectFnStop();
}

- (void) invalidateObjectsWithGlobalIDs: (NSArray*)gids
{
  NSMutableArray *insertedObjects = [NSMutableArray array];
  NSMutableArray *deletedObjects = [NSMutableArray array];
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  int i;
  int count = 0;

  EOFLOGObjectFnStart();

  [self processRecentChanges];

  count = [gids count];

  if (count>0)
    {
      IMP oaiIMP = [gids methodForSelector: GDL2_objectAtIndexSEL];
      IMP insertedAddObjectIMP = NULL;
      IMP deletedAddObjectIMP = NULL;
      IMP objectForGlobalIDIMP=NULL;

      for (i=0; i<count; i++)
        {
          EOGlobalID *gid = GDL2ObjectAtIndexWithImp(gids, oaiIMP, i);
          id obj = EOEditingContext_objectForGlobalIDWithImpPtr(self,&objectForGlobalIDIMP,gid);
          
          if (obj != nil)
            {
              if (NSHashGet(_insertedObjects, obj))
                {
                  if (!insertedAddObjectIMP)
                    insertedAddObjectIMP = [insertedObjects methodForSelector: GDL2_addObjectSEL];
                  GDL2AddObjectWithImp(insertedObjects, insertedAddObjectIMP, obj);
                }
              
              if (NSHashGet(_deletedObjects, obj))
                {
                  if (!deletedAddObjectIMP)
                    deletedAddObjectIMP = [deletedObjects methodForSelector: GDL2_addObjectSEL];
                  GDL2AddObjectWithImp(deletedObjects, deletedAddObjectIMP, obj);
                }
            }
        }
    };

  if ([insertedObjects count] != 0)
    {
      [dict setObject: insertedObjects forKey: EODeletedKey];
    }
  if ([deletedObjects count] != 0)
    {
      [dict setObject: deletedObjects forKey: EOInsertedKey];
    }

  if ([dict count] != 0)
    {
      [self _processObjectStoreChanges: dict];
    }

  /* Once we have a shared editing context we have to unlockForReading
     under certain circumstances...  */

  [_objectStore invalidateObjectsWithGlobalIDs: gids];

  /* ... and lockForReading again when apropriate.  */

  EOFLOGObjectFnStop();
}

- (void) _resetAllChanges: (NSDictionary *)dictionary
{
  [self _resetAllChanges];
}

- (void) _resetAllChanges
{
  //TODO: Ayers Verify
  EOFLOGObjectFnStart();

  [self processRecentChanges];

  NSResetHashTable(_insertedObjects);
  NSResetHashTable(_deletedObjects);
  NSResetHashTable(_changedObjects);

  [_undoManager removeAllActions];

  [self incrementUndoTransactionID];

  EOFLOGObjectFnStop();
}

- (void)_enqueueEndOfEventNotification
{
  EOFLOGObjectFnStart();

  if (_flags.registeredForCallback == NO && _flags.processingChanges == NO)
    {
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"_undoManager: %@",
                            _undoManager);

      if ([_undoManager groupsByEvent])
        {
          /*
           * Make sure there is something registered to force processing.
           * The seems to correspond to the reference implementation but
           * also seems very hacky.
           */
          [_undoManager registerUndoWithTarget: self
                        selector: @selector(noop:)
                        object: nil];
        }
      else
        {
          NSArray *modes;

          modes = [[EODelayedObserverQueue defaultObserverQueue] runLoopModes];
          [[NSRunLoop currentRunLoop]
            performSelector: @selector(_processEndOfEventNotification:)
            target: self
            argument: nil
            order: EOEditingContextFlushChangesRunLoopOrdering
            modes: modes];
        }
      _flags.registeredForCallback = YES;
    }
  EOFLOGObjectFnStop();
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

  gid = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);
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
          gid = AUTORELEASE([EOTemporaryGlobalID new]);
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
      EOFLOGObjectLevelArgs(@"EOEditingContext",
                            @"Already inserted gid=%@ object [_insertedObjects] %p=%@",
                            gid, object, object);      
    }
  else if (_unprocessedInserts && NSHashGet(_unprocessedInserts, object))
    {
//      NSLog(@"Already inserted object [_unprocessedInserts] %p=%@",object,object);
      EOFLOGObjectLevelArgs(@"EOEditingContext",
                            @"Already inserted gid=%@ object [_unprocessedInserts] %p=%@",
                            gid, object, object);      
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
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"gid=%@",gid);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  NSAssert(object, @"No Object");

  //GSWDisplayGroup -insertAtIndex+EODataSource createObject call insert ! So object is inserted twice

  if (_insertedObjects && NSHashGet(_insertedObjects, object))
    {
//      NSLog(@"Already inserted object [_insertedObjects] %p=%@",object,object);
      EOFLOGObjectLevelArgs(@"EOEditingContext", 
                            @"Already inserted gid=%@ object [_insertedObjects] %p=%@",
                            gid, object, object);    
    }
  else if (_unprocessedInserts && NSHashGet(_unprocessedInserts, object))
    {
//      NSLog(@"Already inserted object [_unprocessedInserts] %p=%@",object,object);
      EOFLOGObjectLevelArgs(@"EOEditingContext",
                            @"Already inserted gid=%@ object [_unprocessedInserts] %p=%@", 
                            gid, object, object);      
    }

  if ([gid isTemporary])
    {
      [self _registerClearStateWithUndoManager];
      [_undoManager registerUndoWithTarget: self
                    selector: @selector(deleteObject:)
                    object: object];

      gidBis = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);

      /* Record object for GID mappings.  */
      if (gidBis)
        {
          EOFLOGObjectLevelArgs(@"EOEditingContext",
                                @"Already recored gid=%@ previous gid=%@ object %p=%@", 
                                gid, gidBis, object, object);
        }
      else
        {
          NSAssert(gid, @"No gid");

          EOEditingContext_recordObjectGlobalIDWithImpPtr(self,NULL,object,gid);
        }

      /* Do the actual insert into the editing context,
	 independent  of whether this object has ever been
         previously tracked by the GID mappings.  */
      NSHashInsert(_unprocessedInserts, object);
      [self _enqueueEndOfEventNotification];
    }

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void)_processEndOfEventNotification: (NSNotification*)notification
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  if ([self tryLock])
    {
      [self processRecentChanges];
      [self _processNotificationQueue];
      [self unlock];
    }
  /* else ignore.  */

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Unprocessed: %@",
			[self unprocessedDescription]);
  EOFLOGObjectLevelArgs(@"EOEditingContext", @"Objects: %@",
			[self objectsDescription]);

  EOFLOGObjectFnStop();
}

- (void)noop: (id)object
{
  EOFLOGObjectFnStart();
  /*
   * This is just a dummy method which is only registered
   * to achieve the side effect of registering a method
   * with the undo manager.  The side effect is that the
   * undo manager will register another method which will later
   * post the NSUndoManagerCheckpointNotification.
   */
  EOFLOGObjectFnStop();
}

//"Receive NSUndoManagerCheckpointNotification Notification
- (void) _undoManagerCheckpoint: (NSNotification*)notification
{
  [self _processEndOfEventNotification: notification];
}

- (BOOL) _processRecentChanges
{
  BOOL result = YES;

  EOFLOGObjectFnStart();

  /* _assertSafeMultiThreadedAccess when/if necessary.  */

  if (_flags.processingChanges == NO)
    {
      NSMutableSet *cumulativeChanges = (id)[NSMutableSet set];
      NSMutableSet *consolidatedInserts = (id)[NSMutableSet set];
      NSMutableSet *deletedAndChanged = (id)[NSMutableSet set];
      NSMutableSet *insertedAndDeleted = (id)[NSMutableSet set];
      //  NSMutableSet *deletedAndInserted = (id)[NSMutableSet set];
      NSEnumerator *currEnum;
      EOGlobalID *globalID;
      id obj;
      IMP selfGlobalIDForObjectIMP = NULL;
      
      _flags.processingChanges = YES;

      while (NSCountHashTable (_unprocessedInserts)
             || NSCountHashTable (_unprocessedChanges)
             || NSCountHashTable (_unprocessedDeletes))
        {
          NSException *exception = nil;
          NSArray *unprocessedInsertsArray = nil;
          NSArray *unprocessedInsertsGlobalIDs = nil;
          NSArray *unprocessedDeletesArray = nil;
          NSArray *unprocessedDeletesGlobalIDs = nil;
          NSArray *unprocessedChangesArray = nil;
          NSArray *unprocessedChangesGlobalIDs = nil;
          NSMutableDictionary *objectsUserInfo = nil;
          NSMutableDictionary *globalIDsUserInfo = nil;
          NSHashEnumerator hashEnum;

          objectsUserInfo = (id)[NSMutableDictionary dictionary];
          globalIDsUserInfo = (id)[NSMutableDictionary dictionary];

          NSDebugMLLog(@"EOEditingContext", @"Unprocessed: %@",
                       [self unprocessedDescription]);
          NSDebugMLLog(@"EOEditingContext", @"Objects: %@",
                       [self objectsDescription]);

          [self _registerClearStateWithUndoManager];

          /* Propagate deletes.  */
          if (_flags.propagatesDeletesAtEndOfEvent == NO
              && [_undoManager isUndoing] == NO
              && [_undoManager isRedoing] == NO)
            {

              NS_DURING
                {
                  /* Delete propagation.  */
                  [_undoManager beginUndoGrouping];
                  [self _processDeletedObjects];
                  [_undoManager endUndoGrouping];
                }
              NS_HANDLER
                {
                  NSDictionary *snapshot;
                  /* If delete propagation fails, then this could
                     be due to a violation of EODeleteDeny rule.
                     So we reset all changes of this event loop.  */
                  [_undoManager endUndoGrouping];

                  hashEnum = NSEnumerateHashTable(_unprocessedChanges);

                  /* These changes happen in the parent undo grouping.  */
                  while ((obj = NSNextHashEnumeratorItem(&hashEnum)))
                    {
                      snapshot = [self committedSnapshotForObject: obj];
                      [obj updateFromSnapshot: snapshot];
                    }

                  /* Undo parent grouping and start a new one.  */
                  [_undoManager endUndoGrouping];
                  [_undoManager undo];
                  [_undoManager beginUndoGrouping];

                  NSResetHashTable(_unprocessedInserts);
                  NSResetHashTable(_unprocessedDeletes);
                  NSResetHashTable(_unprocessedChanges);

                  /* Now handle the Exception.  */
                  NS_DURING
                    {
                      [self handleError: exception];
                    }
                  NS_HANDLER
                    {
                      _flags.processingChanges = NO;
                      _flags.registeredForCallback = NO;
                      [localException raise];
                    }
                  NS_ENDHANDLER;

                  return NO;
                }
              NS_ENDHANDLER;
            }

          NSDebugMLLog(@"EOEditingContext", @"Unprocessed: %@",
                       [self unprocessedDescription]);
          NSDebugMLLog(@"EOEditingContext", @"Objects: %@",
                       [self objectsDescription]);

          EOFLOGObjectLevel(@"EOEditingContext",
                            @"process _unprocessedInserts");

          unprocessedInsertsArray = NSAllHashTableObjects(_unprocessedInserts);
          NSDebugMLLog(@"EOEditingContext", @"(1)unprocessedInsertsArray=%@",
                       unprocessedInsertsArray);

          /* Consoldate insert/deletes triggered by undo operations.
             Unprocessed inserts of deleted objects are undos, not
             real inserts.  */

          [consolidatedInserts addObjectsFromArray: unprocessedInsertsArray];
          hashEnum = NSEnumerateHashTable(_unprocessedInserts);
          while ((obj = NSNextHashEnumeratorItem(&hashEnum)))
            {
              if (NSHashGet(_deletedObjects, obj))
                {
                  NSHashRemove(_deletedObjects, obj);
                  [consolidatedInserts removeObject: obj];
                }
              else
                {
                  NSHashInsert(_insertedObjects, obj);
                }
            }

          unprocessedInsertsArray = NSAllHashTableObjects(_unprocessedInserts);
          NSDebugMLLog(@"EOEditingContext", @"(2)unprocessedInsertsArray=%@",
                       unprocessedInsertsArray);

          [objectsUserInfo setObject: unprocessedInsertsArray
                           forKey: EOInsertedKey];

          unprocessedInsertsGlobalIDs
            = [self resultsOfPerformingSelector: GDL2_globalIDForObjectSEL
                    withEachObjectInArray: unprocessedInsertsArray];

          [globalIDsUserInfo setObject: unprocessedInsertsGlobalIDs
                             forKey: EOInsertedKey];
          NSResetHashTable(_unprocessedInserts);

          EOFLOGObjectLevel(@"EOEditingContext",
                            @"process _unprocessedDeletes");

          hashEnum = NSEnumerateHashTable(_unprocessedDeletes);
          while ((obj = NSNextHashEnumeratorItem(&hashEnum)))
            {
              if (NSHashGet(_insertedObjects, obj))
                {
                  BOOL add = NO;
                  NSHashRemove(_insertedObjects, obj);
                  if ([consolidatedInserts containsObject: obj])
                    {
                      EOGlobalID *gid;
                      [consolidatedInserts removeObject: obj];
                      gid = EOEditingContext_globalIDForObjectWithImpPtr(self, &selfGlobalIDForObjectIMP, obj);
                      if ([gid isTemporary])
                        {
                          add = YES;
                        }
                    }
                  else
                    add = YES;

                  /* The insert was an undo of this delete.  */
                  if (add == NO) continue;

                  [insertedAndDeleted addObject: obj];
                }
              else
                {
                  if (NSHashGet(_unprocessedChanges, obj))
                    {
                      NSHashRemove(_unprocessedChanges, obj);
                    }
                  [deletedAndChanged addObject: obj];
                  NSHashInsert(_deletedObjects, obj);
                }
            }

          unprocessedDeletesArray = NSAllHashTableObjects(_unprocessedDeletes);
          NSDebugMLLog(@"EOEditingContext",
                       @"unprocessedDeletesArray=%@", unprocessedDeletesArray);

          [objectsUserInfo setObject: unprocessedDeletesArray
                           forKey: EODeletedKey];
          unprocessedDeletesGlobalIDs
            = [self resultsOfPerformingSelector: GDL2_globalIDForObjectSEL
                    withEachObjectInArray: unprocessedDeletesArray];

          [globalIDsUserInfo setObject: unprocessedDeletesGlobalIDs
                             forKey: EODeletedKey];

          NSResetHashTable(_unprocessedDeletes);

          //Changes
          EOFLOGObjectLevel(@"EOEditingContext",
                            @"process _unprocessedChanges");

          unprocessedChangesArray = NSAllHashTableObjects(_unprocessedChanges);
          NSDebugMLLog(@"EOEditingContext",
                       @"unprocessedChangesArray=%@", unprocessedChangesArray);

          [objectsUserInfo setObject:unprocessedChangesArray
                           forKey: EOUpdatedKey];

          unprocessedChangesGlobalIDs
            = [self resultsOfPerformingSelector: GDL2_globalIDForObjectSEL
                    withEachObjectInArray: unprocessedChangesArray];

          [globalIDsUserInfo setObject: unprocessedChangesGlobalIDs
                             forKey: EOUpdatedKey];

          hashEnum = NSEnumerateHashTable(_unprocessedChanges);
          while ((obj = NSNextHashEnumeratorItem(&hashEnum)))
            {
              NSHashInsert(_changedObjects, obj);
            }


          NSResetHashTable(_unprocessedChanges);
          [cumulativeChanges addObjectsFromArray: unprocessedChangesArray];

          [EOObserverCenter notifyObserversObjectWillChange: nil];

          [[NSNotificationCenter defaultCenter]
            postNotificationName: EOObjectsChangedInStoreNotification
            object: self
            userInfo: globalIDsUserInfo];

          [[NSNotificationCenter defaultCenter]
            postNotificationName: EOObjectsChangedInEditingContextNotification
            object: self
            userInfo: objectsUserInfo];
        }

      currEnum = [cumulativeChanges objectEnumerator];
      while ((obj = [currEnum nextObject]))
        {
          if ([consolidatedInserts containsObject: obj])
            {
              /* This is a 'new' object.
                 Clear any implicit snapshot records.  */
              globalID = EOEditingContext_globalIDForObjectWithImpPtr(self, &selfGlobalIDForObjectIMP, obj);
              [_snapshotsByGID removeObjectForKey: globalID];
              [_eventSnapshotsByGID removeObjectForKey: globalID];
            }
          else
            {
              /* This is a 'modified' object.
                 Register for undo operation.  */
              [self registerUndoForModifiedObject: obj];
              if ([deletedAndChanged containsObject: obj])
                {
                  /* Make sure the object only gets registered once.  */
                  [deletedAndChanged removeObject: obj];
                }
            }
        }

      /* Register deleted and changed objects for undo
         that have not already been registered.  */
      currEnum = [deletedAndChanged objectEnumerator];
      while ((obj = [currEnum nextObject]))
        {
          [self registerUndoForModifiedObject: obj];
        }

      _flags.processingChanges = NO;
      _flags.registeredForCallback = NO;
    }

  EOFLOGObjectFnStop();

  return result;
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

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"unprocessed: %@",
			[self unprocessedDescription]);

  validateForDelete = [self validateTable: _deletedObjects
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
      BOOL validateForInsert = [self validateTable: _insertedObjects
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
	    = [self validateTable: _changedObjects
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

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"table: %@",
			NSStringFromHashTable(table));

  EOFLOGObjectLevelArgs(@"EOEditingContext", @"sel: %@",
			NSStringFromSelector(sel));

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
      NSArray *toOneRelationshipKeys = nil;
      NSArray *toManyRelationshipKeys = nil;
      int i;
      int count;

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"object:%@", object);

      toOneRelationshipKeys = [object toOneRelationshipKeys]; 
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"toOneRelationshipKeys:%@",
			    toOneRelationshipKeys);

      count = [toOneRelationshipKeys count];
      if (count > 0)
        {
          IMP oaiIMP=[toOneRelationshipKeys methodForSelector: GDL2_objectAtIndexSEL];
          
          for (i = 0; i < count; i++)
            {
              NSString *relKey = GDL2ObjectAtIndexWithImp(toOneRelationshipKeys, oaiIMP, i);
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
                      if (_isNilOrEONull(value))
                        {
                          if (!_isNilOrEONull(existingObject))//value is new
                            {                      
                              //existing object is removed
                              //TODO ?? ad it in delete table ??
                              NSEmitTODO();
                              NSLog(@"object=%@",object);
                              NSLog(@"objectSnapshot=%@",objectSnapshot);
                              NSLog(@"relKey=%@",relKey);
                              NSLog(@"value=%@",value);
                              NSLog(@"existingObject=%@",existingObject);
                              [self notImplemented:_cmd]; //TODO
                            }
                        }
                      else
                        {
                          if (!_isNilOrEONull(existingObject))//value is new
                            {                      
                              //existing object is removed
                              //TODO ?? ad it in delete table ??
                              NSEmitTODO();
                              NSLog(@"object=%@",object);
                              NSLog(@"objectSnapshot=%@",objectSnapshot);
                              NSLog(@"relKey=%@",relKey);
                              NSLog(@"value=%@",value);
                              NSLog(@"existingObject=%@",existingObject);
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
        };

      toManyRelationshipKeys = [object toManyRelationshipKeys];

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"object:%@", object);
      EOFLOGObjectLevelArgs(@"EOEditingContext", @"toManyRelationshipKeys: %@",
			    toManyRelationshipKeys);

      count = [toManyRelationshipKeys count];
      
      IMP oaiIMP=[toManyRelationshipKeys methodForSelector: GDL2_objectAtIndexSEL];
      
      for (i = 0; i < count; i++)
        {
          NSString *relKey = GDL2ObjectAtIndexWithImp(toManyRelationshipKeys, oaiIMP, i);
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

  gid = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);
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

-(void)setLevelsOfUndo:(int)levels
{
  //TODO
};

- (void) _registerClearStateWithUndoManager
{
//pas appellee dans le cas d'un delete ?
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

- (void)_clearChangedThisTransaction:(NSNumber *)transID
{
  EOFLOGObjectFnStart();
  if (_undoTransactionID == [transID unsignedShortValue])
    {
      static NSDictionary *info = nil;

      if (info == nil)
        {
          NSArray *arr = [NSArray array];
          info = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         arr, EOInsertedKey,
                                       arr, EODeletedKey,
                                       arr, EOUpdatedKey,
                                       nil];
        }

      [self processRecentChanges];
      NSResetHashTable(_changedObjects);

      [self incrementUndoTransactionID];
      [[NSNotificationCenter defaultCenter]
        postNotificationName: EOObjectsChangedInEditingContextNotification
        object: self
        userInfo: info];

    }
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
     NSUndoManager *undoManager;
     //EOGlobalID *gid = [self globalIDForObject: object];

     [self _registerClearStateWithUndoManager];

     undoManager = (NSUndoManager*)[self undoManager];
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
  EOGlobalID *gid = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);

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
     || NSCountHashTable(_changedObjects)
     || NSCountHashTable(_unprocessedInserts)
     || NSCountHashTable(_unprocessedDeletes)
     || NSCountHashTable(_unprocessedChanges))
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
    EOGlobalID *gid=nil;
    IMP objectForGlobalIDIMP=NULL;

    enumerator = [[_snapshotsByGID allKeys] objectEnumerator];

    while ((gid = [enumerator nextObject]))
      {
        id ofgid=EOEditingContext_objectForGlobalIDWithImpPtr(self,&objectForGlobalIDIMP,gid);
        id snapshot=[ofgid snapshot];
        EOFLOGObjectLevelArgs(@"EOEditingContext",
                              @"gid=%@ snapshot=%@",
                              gid,snapshot);
        [_snapshotsByGID setObject: snapshot
                         forKey: gid];
      }
  }

  [[NSNotificationCenter  defaultCenter]
    postNotificationName: @"EOEditingContextDidSaveChangesNotification"
    object: self
    userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			      objectsForNotification[0], EOInsertedKey,
			    objectsForNotification[1], EODeletedKey,
			    objectsForNotification[2], EOUpdatedKey,
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
  EOGlobalID *gid=nil;
  IMP objectForGlobalIDIMP=NULL;

  enumerator = [_eventSnapshotsByGID keyEnumerator];
  while ((gid = [enumerator nextObject]))
    {
      id ofgid=EOEditingContext_objectForGlobalIDWithImpPtr(self,&objectForGlobalIDIMP,gid);
      [ofgid updateFromSnapshot: [_eventSnapshotsByGID objectForKey: gid]];
    }

  [_undoManager removeAllActions];
  [_undoManager beginUndoGrouping];

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
  EOGlobalID *gid = nil;

  EOFLOGObjectFnStart();

  gid = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);

  if (gid)
    {
      [_snapshotsByGID removeObjectForKey: gid];
    }

  EOFLOGObjectFnStop();
}

- (id)objectForGlobalID:(EOGlobalID *)globalID
{
  id object = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext", 
                        @"EditingContext: %p gid=%@", 
                        self, globalID);

  object = NSMapGet(_objectsByGID, globalID);

  EOFLOGObjectLevelArgs(@"EOEditingContext", 
                        @"EditingContext: %p gid=%@ object=%p", 
                        self, globalID, object);

  EOFLOGObjectFnStop();

  return object;
}

- (EOGlobalID *)globalIDForObject: (id)object
{
  //Consider OK
  EOGlobalID *gid = nil;

  /*
    [self recordForObject:object]
    [self notImplemented:_cmd]; //TODO
  */

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"ed context=%p _globalIDsByObject=%p object=%p",
			self, _globalIDsByObject, object);

  gid = NSMapGet(_globalIDsByObject, object);

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

      EOFLOGObjectLevelArgs(@"EOEditingContext", @"*** editingContext=%p object change %p %@",
			    self,object, [object class]);
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
          EOFLOGObjectLevelArgs(@"EOEditingContext", @"*** editingContext=%p object change %p %@. Snapshot Already Inserted: %p",
                                self,object, [object class], 
                                [_snapshotsByGID objectForKey:EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object)]);
          EOFLOGObjectLevel(@"EOEditingContext",
			    @"_enqueueEndOfEventNotification");
	  [self _enqueueEndOfEventNotification];

	  if(_undoManager)
	    [_undoManager registerUndoWithTarget: self
			  selector:@selector(_revertChange:)
			  object:[NSDictionary dictionaryWithObjectsAndKeys:
						 object, @"object",
					       [object snapshot], @"snapshot",
					       nil]];
	}
      else
	{
          //???????????
          NSDictionary *snapshot = nil;
          EOGlobalID *gid = nil;

          EOFLOGObjectLevelArgs(@"EOEditingContext", @"*** editingContext=%p object change %p %@. Snapshot Not Already Inserted: %p",
                                self,object, [object class], 
                                [_snapshotsByGID objectForKey:EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object)]);

          snapshot = [object snapshot]; // OK
          gid = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);

          EOFLOGObjectLevelArgs(@"EOEditingContext",
                                @"insert into snapshotsByGID: gid=%@ snapshot %p=%@",
                                gid,snapshot,snapshot);

	  [_eventSnapshotsByGID setObject: snapshot
				forKey: gid];

	  [_snapshotsByGID setObject: snapshot
                           forKey: gid];

	  if (_flags.autoLocking == YES)
	    [self lockObject: object];

	  [self _enqueueEndOfEventNotification];
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
			@"Record %p for %@ in ed context %p _globalIDsByObject=%p",
			object, globalID, self, _globalIDsByObject);

  NSAssert(object, @"No Object");
  NSAssert(globalID, @"No GlobalID");
  
  /* Global hash table for faster dealloc.  */
  if (!ecDeallocHT)
    {
      ecDeallocHT 
	= NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 64);
    }
  NSHashInsert(ecDeallocHT, object);

  EOFLOGObjectLevel(@"EOEditingContext", @"insertInto _globalIDsByObject");
  NSMapInsert(_globalIDsByObject, object, globalID);

  //TODO: Remove this test code
  {
    id aGID2 = nil;
    id aGID = NSMapGet(_globalIDsByObject, object);

    NSAssert1(aGID, @"Object %p recorded but can't retrieve it directly !",
	      object);

    aGID2 = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);

    NSAssert1(aGID2, @"Object %p recorded but can't retrieve it with globalIDForObject: !", object);
  }

  EOFLOGObjectLevelArgs(@"EOEditingContext", 
                        @"EditingContext: %p objectsByGID: Insert Object gid=%@", 
                        self, globalID);

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

  EOFLOGObjectFnStart();

  /* Global hash table for faster dealloc.  */
  NSHashRemove(ecDeallocHT, object);

  gid = EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);

  EOFLOGObjectLevelArgs(@"EOEditingContext",
                        @"forgetObject gid: %@",
                        gid);

  NSMapRemove(_globalIDsByObject, object);
  NSMapRemove(_objectsByGID, gid);

  [EOObserverCenter removeObserver: self
                    forObject: object];

  EOFLOGObjectFnStop();
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

  [self _processRecentChanges];
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
  EOGlobalID* gid=nil;
  NSDictionary* snapshot=nil;

  EOFLOGObjectFnStart();

  gid=EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);
  snapshot=[_snapshotsByGID objectForKey: gid];

  EOFLOGObjectLevelArgs(@"EOEditingContext",
			@"object=%p snapshot %p=%@",
			object,snapshot,snapshot);

  EOFLOGObjectFnStop();

  return snapshot;
}

/** Returns a dictionary containing a snapshot of object with 
its state as it was at the beginning of the current event loop. 
After the end of the current event, upon invocation of 
processRecentChanges, the snapshot is updated to hold the 
modified state of the object.**/
- (NSDictionary *)currentEventSnapshotForObject: (id)object
{
  //OK
  EOGlobalID* gid=EOEditingContext_globalIDForObjectWithImpPtr(self,NULL,object);
  return [_eventSnapshotsByGID objectForKey: gid];
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
  id obj = nil;
  IMP globalIDForObjectIMP=NULL;

  [self processRecentChanges];

  [objs addObjectsFromArray: NSAllMapTableKeys(_globalIDsByObject)];

  [objs removeObjectsInArray: [self insertedObjects]];
  [objs removeObjectsInArray: [self deletedObjects]];
  [objs removeObjectsInArray: [self updatedObjects]];

  objsEnum = [objs objectEnumerator];

  while ((obj = [objsEnum nextObject]))
    {
      EOGlobalID* gid=EOEditingContext_globalIDForObjectWithImpPtr(self,&globalIDForObjectIMP,obj);
      [self refaultObject: obj
            withGlobalID: gid
            editingContext: self];
    };
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
  id object = EOEditingContext_objectForGlobalIDWithImpPtr(self,NULL,globalID);

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
  object = EOEditingContext_objectForGlobalIDWithImpPtr(self,NULL,globalID);

  if (object)
    {
      if (context == self)
	return object;

      objectCopy = [classDesc createInstanceWithEditingContext: context
			      globalID: globalID
			      zone: NULL];

      NSAssert1(objectCopy, @"No Object. classDesc=%@", classDesc);
      [objectCopy updateFromSnapshot: [object snapshot]];

      EOEditingContext_recordObjectGlobalIDWithImpPtr(context,NULL,objectCopy,globalID);

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
  NSArray *fault = nil;
  id object = EOEditingContext_objectForGlobalIDWithImpPtr(self,NULL,globalID);
  id objectCopy = nil;

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

          EOEditingContext_recordObjectGlobalIDWithImpPtr(context,NULL,objectCopy,globalID);

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
          NSLog(@"%@ (%@). globalID=%@ relationshipName=%@", 
                localException, [localException reason],
                globalID, name);
          NSDebugMLog(@"%@ (%@). globalID=%@ relationshipName=%@", 
                      localException, [localException reason],
                      globalID, name);
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
      NS_DURING // Debugging Purpose
        {        
          NSArray *objects;
          NSEnumerator *objsEnum;
          EOGlobalID *gid;
          id object, localObject;
          IMP objectForGlobalIDIMP=NULL;
          IMP globalIDForObjectIMP=NULL;

          objects = [context insertedObjects];
          
          objsEnum = [objects objectEnumerator];
          while ((object = [objsEnum nextObject]))
            {
              gid=EOEditingContext_globalIDForObjectWithImpPtr(context,&globalIDForObjectIMP,object);
              
              localObject = [[EOClassDescription classDescriptionForEntityName:
                                                   [gid entityName]]
                              createInstanceWithEditingContext: context
                              globalID: gid
                              zone: NULL];
              
              NSAssert1(localObject, @"No Object. gid=%@", gid);
              
              [localObject updateFromSnapshot: [object snapshot]];
              
              EOEditingContext_recordObjectGlobalIDWithImpPtr(self,NULL,localObject,gid);
            }
          
          objects = [context updatedObjects];
          
          objsEnum = [objects objectEnumerator];
          while ((object = [objsEnum nextObject]))
            {
              gid=EOEditingContext_globalIDForObjectWithImpPtr(context,&globalIDForObjectIMP,object);
              localObject = EOEditingContext_objectForGlobalIDWithImpPtr(self,&objectForGlobalIDIMP,gid);
              
              [localObject updateFromSnapshot:[object snapshot]];
            }
          
          objects = [context deletedObjects];
          
          objsEnum = [objects objectEnumerator];
          while ((object = [objsEnum nextObject]))
            {
              gid=EOEditingContext_globalIDForObjectWithImpPtr(context,&globalIDForObjectIMP,object);
              localObject = EOEditingContext_objectForGlobalIDWithImpPtr(self,&objectForGlobalIDIMP,gid);
              
              [self deleteObject: localObject];
            }
        }
      NS_HANDLER
        {
          NSLog(@"Exception in %@ -%@ %@ (%@)",
                NSStringFromClass([self class]), NSStringFromSelector(_cmd),
                localException, [localException reason]);
          NSDebugMLog(@"Exception in %@ -%@ %@ (%@)",
                      NSStringFromClass([self class]),NSStringFromSelector(_cmd),
                      localException, [localException reason]);
          
          [localException raise];
        }
      NS_ENDHANDLER;
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
static BOOL usesContextRelativeEncoding = NO;
+ (void)setUsesContextRelativeEncoding: (BOOL)flag
{
  usesContextRelativeEncoding = flag ? YES : NO;
}

+ (BOOL)usesContextRelativeEncoding
{
  return usesContextRelativeEncoding;
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
    {
      _lockCount++;
    }

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

- (NSDictionary*)unprocessedObjects
{
  NSDictionary *infoDict = nil;

  EOFLOGObjectFnStart();

  infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             NSAllHashTableObjects(_unprocessedChanges), @"update",
                           NSAllHashTableObjects(_unprocessedDeletes), @"delete",
                           NSAllHashTableObjects(_unprocessedInserts), @"insert",
                           nil, nil];

  EOFLOGObjectFnStop();

  return infoDict;  
}

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
                             objectsForInfo[0], @"update",
                           objectsForInfo[1], @"delete",
                           objectsForInfo[2], @"insert",
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
			     objectsForInfo[0], EOInsertedKey,
			   objectsForInfo[1], EODeletedKey,
			   objectsForInfo[2], EOUpdatedKey,
			   nil, nil];

  NSDebugMLog(@"infoDict=%@", infoDict);
  EOFLOGObjectFnStop();

  return infoDict;  
}

/** Returns YES if there unprocessed changes or deletes or inserts **/
- (BOOL)hasUnprocessedChanges
{
  if(NSCountHashTable(_unprocessedChanges)
     || NSCountHashTable(_unprocessedDeletes)
     || NSCountHashTable(_unprocessedInserts))
    return YES;

  return NO;
}

@end

@implementation NSObject (DeallocHack)
/*
 * This is a real hack that shows that the design of this
 * library did not take the reference counting mechanisms
 * of OpenStep to heart.  I'm sorry kids, but this seems
 * how it has to be done to remain compatible.  Any hints
 * on how to speed this up are appreciated.  But understand
 * that we don't know the classes which need to call this
 * and there could be deep hierarchy.
 */
- (void) dealloc
{
  if (ecDeallocHT && NSHashGet(ecDeallocHT, self))
    {
      [GDL2EOEditingContextClass objectDeallocated: self];
    }
  if (assocDeallocHT && NSHashGet(assocDeallocHT, self))
    {
      [EOAssociationClass objectDeallocated: self];
    }

  NSDeallocateObject (self);
}
@end

id EOEditingContext_objectForGlobalIDWithImpPtr(EOEditingContext* edContext,IMP* impPtr,EOGlobalID* gid)
{
  if (edContext)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(edContext)==GDL2EOEditingContextClass
              && GDL2EOEditingContext_objectForGlobalIDIMP)
            imp=GDL2EOEditingContext_objectForGlobalIDIMP;
          else
            imp=[edContext methodForSelector:GDL2_objectForGlobalIDSEL];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(edContext,GDL2_objectForGlobalIDSEL,gid);
    }
  else
    return nil;
};

EOGlobalID* EOEditingContext_globalIDForObjectWithImpPtr(EOEditingContext* edContext,IMP* impPtr,id object)
{
  if (edContext)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(edContext)==GDL2EOEditingContextClass
              && GDL2EOEditingContext_globalIDForObjectIMP)
            imp=GDL2EOEditingContext_globalIDForObjectIMP;
          else
            imp=[edContext methodForSelector:GDL2_globalIDForObjectSEL];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(edContext,GDL2_globalIDForObjectSEL,object);
    }
  else
    return nil;
};

id EOEditingContext_recordObjectGlobalIDWithImpPtr(EOEditingContext* edContext,IMP* impPtr,id object,EOGlobalID* gid)
{
  if (edContext)
    {
      IMP imp=NULL;
      if (impPtr)
        imp=*impPtr;
      if (!imp)
        {
          if (GSObjCClass(edContext)==GDL2EOEditingContextClass
              && GDL2EOEditingContext_recordObjectGlobalIDIMP)
            imp=GDL2EOEditingContext_recordObjectGlobalIDIMP;
          else
            imp=[edContext methodForSelector:GDL2_recordObjectGlobalIDSEL];
          if (impPtr)
            *impPtr=imp;
        }
      return (*imp)(edContext,GDL2_recordObjectGlobalIDSEL,object,gid);
    }
  else
    return nil;
};
