/** 
   EODatabaseContext.m  <title>EODatabaseContext Class</title>

   Copyright (C) 2000-2003 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSZone.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDebug.h>
#if FOUNDATION_HAS_KVC
#import <Foundation/NSKeyValueCoding.h>
#endif

#include <string.h>

#import <EOAccess/EOAdaptor.h>
#import <EOAccess/EOAdaptorChannel.h>
#import <EOAccess/EOAdaptorContext.h>
#import <EOAccess/EOModel.h>
#import <EOAccess/EOModelGroup.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EORelationship.h>
#import <EOAccess/EOAttribute.h>
#import <EOAccess/EOStoredProcedure.h>
#import <EOAccess/EOJoin.h>

#import <EOAccess/EODatabase.h>
#import <EOAccess/EODatabaseContext.h>
#import <EOAccess/EODatabaseContextPriv.h>
#import <EOAccess/EODatabaseChannel.h>
#import <EOAccess/EODatabaseOperation.h>
#import <EOAccess/EOAccessFault.h>
#import <EOAccess/EOAccessFaultPriv.h>
#import <EOAccess/EOExpressionArray.h>

#import <EOControl/EOFault.h>
#import <EOControl/EOEditingContext.h>
#import <EOControl/EOClassDescription.h>
#import <EOControl/EOGenericRecord.h>
#import <EOControl/EOQualifier.h>
#import <EOControl/EOKeyGlobalID.h>
#import <EOControl/EOFetchSpecification.h>
#import <EOControl/EOSortOrdering.h>
#import <EOControl/EOKeyValueCoding.h>
#import <EOControl/EOMutableKnownKeyDictionary.h>
#import <EOControl/EOCheapArray.h>
#import <EOControl/EONSAddOns.h>
#import <EOControl/EONull.h>
#import <EOControl/EODebug.h>

#include <string.h>


#define _LOCK_BUFFER 128


NSString *EODatabaseChannelNeededNotification = @"EODatabaseChannelNeededNotification";

NSString *EODatabaseContextKey = @"EODatabaseContextKey";
NSString *EODatabaseOperationsKey = @"EODatabaseOperationsKey";
NSString *EOFailedDatabaseOperationKey = @"EOFailedDatabaseOperationKey";


@interface EODatabaseContext(EOObjectStoreSupportPrivate)
- (id) entityForGlobalID: (EOGlobalID *)globalID;
@end

@implementation EODatabaseContext

// Initializing instances

static Class _contextClass = Nil;

+ (void)initialize
{
  if (!_contextClass)
    {
      _contextClass = [EODatabaseContext class];
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_registerDatabaseContext:)
        name: EOCooperatingObjectStoreNeeded
        object: nil];
    }
}

+ (EODatabaseContext*)databaseContextWithDatabase: (EODatabase *)database
{
  return [[[self alloc] initWithDatabase: database] autorelease];
}

+ (void)_registerDatabaseContext:(NSNotification *)notification
{
  EOObjectStoreCoordinator *coordinator = [notification object];
  EODatabaseContext *dbContext = nil;
  EOModel *model = nil;
  NSString *entityName = nil;
  id keyValue = nil;

  keyValue = [[notification userInfo] objectForKey: @"globalID"];

  if (keyValue == nil)
    keyValue = [[notification userInfo] objectForKey: @"fetchSpecification"];

  if (keyValue == nil)
    keyValue = [[notification userInfo] objectForKey: @"object"];

  if (keyValue)
    entityName = [keyValue entityName];

  model = [[[EOModelGroup defaultGroup] entityNamed:entityName] model];

  if (model == nil)
    NSLog(@"%@ -- %@ 0x%x: No model for entity named %@",
	  NSStringFromSelector(_cmd), 
	  NSStringFromClass([self class]),
	  self,
	  entityName);

  dbContext = [EODatabaseContext databaseContextWithDatabase:
				   [EODatabase databaseWithModel: model]];

  [coordinator addCooperatingObjectStore:dbContext];
}

- (void) registerForAdaptorContextNotifications: (EOAdaptorContext*)adaptorContext
{
  //OK
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_beginTransaction)
    name: EOAdaptorContextBeginTransactionNotification
    object: adaptorContext];
  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_commitTransaction)
    name: EOAdaptorContextCommitTransactionNotification
    object: adaptorContext];

  [[NSNotificationCenter defaultCenter]
    addObserver: self
    selector: @selector(_rollbackTransaction)
    name: EOAdaptorContextRollbackTransactionNotification
    object: adaptorContext];
}

- (id) initWithDatabase: (EODatabase *)database
{
  //OK
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"database=%p",database);

  if ((self = [super init]))
    {
      _adaptorContext = RETAIN([[database adaptor] createAdaptorContext]);

      if (_adaptorContext == nil)
        {
          NSLog(@"EODatabaseContext could not create adaptor context");
          [self autorelease];

          return nil;
        }
      _database = RETAIN(database);

      // Register this object into database
      [_database registerContext: self];
      [self setUpdateStrategy: EOUpdateWithOptimisticLocking];

      _uniqueStack = [NSMutableArray new];
      _deleteStack = [NSMutableArray new];
      _uniqueArrayStack = [NSMutableArray new];

      _registeredChannels = [NSMutableArray new];
      _batchFaultBuffer = [NSMutableDictionary new];
      _batchToManyFaultBuffer = [NSMutableDictionary new];

      // We want to know when snapshots change in database
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_snapshotsChangedInDatabase:)
        name: EOObjectsChangedInStoreNotification
        object: _database];

      // We want to know when objects change
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_objectsChanged:)
        name: EOObjectsChangedInStoreNotification
        object: self];

      [self registerForAdaptorContextNotifications: _adaptorContext];

//???
/*NO      _snapshots = [NSMutableDictionary new];
      _toManySnapshots = [NSMutableDictionary new];
*/
      
      
      
      
//NO      _lock = [NSRecursiveLock new];
      
//NO      _numLocked = 0;
//After      _lockedObjects = NSZoneMalloc(NULL, _LOCK_BUFFER*sizeof(id));
      
      
      
      /* //TODO ?
         transactionStackTop = NULL;
         transactionNestingLevel = 0;
         isKeepingSnapshots = YES;
         isUniquingObjects = [database uniquesObjects];
         [database contextDidInit:self];*/
    }

  EOFLOGObjectFnStop();

  return self;
}

- (void)_snapshotsChangedInDatabase: (NSNotification *)notification
{
  //OK EOObjectsChangedInStoreNotification EODatabase 
  EOFLOGObjectFnStart();

  if ([notification object] == _database)//??
    [[NSNotificationCenter defaultCenter]
      postNotificationName: [notification name]
      object: self
      userInfo: [notification userInfo]];//==> _objectsChanged

  EOFLOGObjectFnStop();
}
 
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [_database unregisterContext: self];

  DESTROY(_adaptorContext);
  DESTROY(_database);

  if (_dbOperationsByGlobalID)
    {
      NSDebugMLog(@"MEMORY: dbOperationsByGlobalID count=%u",NSCountMapTable(_dbOperationsByGlobalID));
      NSFreeMapTable(_dbOperationsByGlobalID);
      _dbOperationsByGlobalID = NULL;
    }
/*NO
  DESTROY(_snapshots);
  DESTROY(_toManySnapshots);
*/
  DESTROY(_uniqueStack);
  DESTROY(_deleteStack);
  DESTROY(_uniqueArrayStack);

  DESTROY(_registeredChannels);

  DESTROY(_batchFaultBuffer);
  DESTROY(_batchToManyFaultBuffer);

  DESTROY(_lastEntity);

  if (_nonPrimaryKeyGenerators)
    {
      NSDebugMLog(@"MEMORY: dbOperationsByGlobalID count=%u",
		  NSCountMapTable(_dbOperationsByGlobalID));

      NSFreeHashTable(_nonPrimaryKeyGenerators);
      _nonPrimaryKeyGenerators = NULL;
    }

  if (_lockedObjects)
      NSZoneFree(NULL, _lockedObjects);         // Turbocat

  DESTROY(_lock);

  [super dealloc];
}

+ (EODatabaseContext *)registeredDatabaseContextForModel: (EOModel *)model
					  editingContext: (EOEditingContext *)editingContext
{
  EOObjectStoreCoordinator *edObjectStore;
  NSArray		   *cooperatingObjectStores;
  NSEnumerator	           *storeEnum;
  EOCooperatingObjectStore *coObjectStore;
  EODatabase		   *anDatabase;
  NSArray		   *models;
  EODatabaseContext        *dbContext = nil;

  EOFLOGClassFnStartOrCond2(@"DatabaseLevel", @"EODatabaseContext");

  if (model && editingContext)
    { 
      edObjectStore = (EOObjectStoreCoordinator *)[editingContext rootObjectStore];
      cooperatingObjectStores = [edObjectStore cooperatingObjectStores];	// get all EODatabaseContexts

      storeEnum = [cooperatingObjectStores objectEnumerator];

      while ((coObjectStore = [storeEnum nextObject]))
	{
	  if ([coObjectStore isKindOfClass: [EODatabaseContext class]])
	    {
	      anDatabase = [(EODatabaseContext *)coObjectStore database];

	      if (anDatabase && (models = [anDatabase models]))
		{
		  if ([models containsObject: model])
		    {
		      dbContext = (EODatabaseContext *)coObjectStore;
		      break;
		    }
		}
	    }
	}
      
      if (!dbContext) 
        {
          // no EODatabaseContext found, create a new one
          dbContext = [EODatabaseContext databaseContextWithDatabase:
					   [EODatabase databaseWithModel:
							 model]];

          if (dbContext)
            {
              [edObjectStore addCooperatingObjectStore: dbContext];
            }
	}
    }

  EOFLOGClassFnStopOrCond2(@"DatabaseLevel", @"EODatabaseContext");

  return dbContext;
}


+ (Class)contextClassToRegister
{
  NSEmitTODO();
  // TODO;
  return _contextClass;
}

+ (void)setContextClassToRegister: (Class)contextClass
{
  _contextClass = contextClass;
}

/** Returns YES if we have at least one busy channel **/
- (BOOL)hasBusyChannels
{
  BOOL busy = NO;
  int i = 0;
  int count = 0;

  count = [_registeredChannels count];  

  for (i = 0 ; !busy && i < count; i++)
    {
      EODatabaseChannel *channel = [[_registeredChannels objectAtIndex: i]
				     nonretainedObjectValue];

      busy = [channel isFetchInProgress];
    }

  return busy;
}

- (NSArray *)registeredChannels
{
  NSMutableArray *array = nil;
  int i, count;

  count = [_registeredChannels count];
  array = [NSMutableArray arrayWithCapacity: count];

  for (i = 0; i < count; i++)
    [array addObject: [[_registeredChannels objectAtIndex: i]
			nonretainedObjectValue]];

  return array;
}

- (void)registerChannel: (EODatabaseChannel *)channel
{
//call channel databaseContext
//test if not exists  _registeredChannels indexOfObjectIdenticalTo:channel
  NSLog(@"** REGISTER channel ** debug:%d ** total registered:%d",
        [[channel adaptorChannel] isDebugEnabled],
        [_registeredChannels count] + 1);

  [_registeredChannels addObject:
			 [NSValue valueWithNonretainedObject: channel]];
  [channel setDelegate: nil];
}

- (void)unregisterChannel: (EODatabaseChannel *)channel
{
  int i;

  for (i = [_registeredChannels count] - 1; i >= 0; i--)
    {
      if ([[_registeredChannels objectAtIndex: i]
	    nonretainedObjectValue] == channel)
	{
	  [_registeredChannels removeObjectAtIndex: i];
	  break;
	}
    }
}

/** returns a non busy channel if any, nil otherwise **/
-(EODatabaseChannel *)_availableChannelFromRegisteredChannels
{
  NSEnumerator *channelsEnum;
  NSValue *channel = nil;

  channelsEnum = [_registeredChannels objectEnumerator];

  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"REGISTERED CHANNELS nb=%d",
                        [_registeredChannels count]);

  while ((channel = [channelsEnum nextObject]))
    {
      if ([(EODatabaseChannel *)[channel nonretainedObjectValue]
                               isFetchInProgress] == NO)
        {
          EOFLOGObjectLevelArgs(@"EODatabaseContext",@"CHANNEL %p is not busy",
		      [channel nonretainedObjectValue]);

          return [channel nonretainedObjectValue];
        }
      else
        {
          EOFLOGObjectLevelArgs(@"EODatabaseContext",@"CHANNEL %p is busy",
                                [channel nonretainedObjectValue]);
        }
    }

  return nil;
}

/** return a non busy channel **/
- (EODatabaseChannel *)availableChannel
{
  EODatabaseChannel *channel = nil;
  int num = 2;

  while (!channel && num)
    {
      channel = [self _availableChannelFromRegisteredChannels];

      if (!channel)
        {
          //If not channel and last try: send a EODatabaseChannelNeededNotification notification before this last try
          if (--num)
            [[NSNotificationCenter defaultCenter]
              postNotificationName: EODatabaseChannelNeededNotification
              object: self];
        }
    }

  if (!channel)
    channel = [EODatabaseChannel databaseChannelWithDatabaseContext: self];

  return channel;
}

/** returns the database **/
- (EODatabase *)database
{
  return _database;
}

/** returns the coordinator **/
- (EOObjectStoreCoordinator *)coordinator
{
  return _coordinator;
}

/** returns the adaptor context **/
- (EOAdaptorContext *)adaptorContext
{
  return _adaptorContext;
}

/** Set the update strategy to 'strategy'
May raise an exception if transaction has began or if you want pessimistic lock when there's already a snapshot recorded
**/
- (void)setUpdateStrategy: (EOUpdateStrategy)strategy
{
  if (_flags.beganTransaction)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: transaction in progress", 
                 NSStringFromSelector(_cmd), 
                 NSStringFromClass([self class]),
                 self];

  //Can't set pessimistic locking where there's already snapshosts !
  if (strategy == EOUpdateWithPessimisticLocking
      && [_database snapshots])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: can't set EOUpdateWithPessimisticLocking when receive's EODatabase already has snapshots",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  _updateStrategy = strategy;
}

/** Get the update strategy **/
- (EOUpdateStrategy)updateStrategy
{
  return _updateStrategy;
}

/** Get the delegate **/
- (id)delegate
{
  return _delegate;
}

/** Set the delegate **/
- (void)setDelegate:(id)delegate
{
  NSEnumerator *channelsEnum = [_registeredChannels objectEnumerator];
  EODatabaseChannel *channel = nil;

  _delegate = delegate;

  _delegateRespondsTo.willRunLoginPanelToOpenDatabaseChannel = 
    [delegate respondsToSelector: @selector(databaseContext:willRunLoginPanelToOpenDatabaseChannel:)];
  _delegateRespondsTo.newPrimaryKey = 
    [delegate respondsToSelector: @selector(databaseContext:newPrimaryKeyForObject:entity:)];
  _delegateRespondsTo.willPerformAdaptorOperations = 
    [delegate respondsToSelector: @selector(databaseContext:willPerformAdaptorOperations:adaptorChannel:)];
  _delegateRespondsTo.shouldInvalidateObject = 
    [delegate respondsToSelector: @selector(databaseContext:shouldInvalidateObjectWithGlobalID:snapshot:)];
  _delegateRespondsTo.willOrderAdaptorOperations = 
    [delegate respondsToSelector: @selector(databaseContext:willOrderAdaptorOperationsFromDatabaseOperations:)];
  _delegateRespondsTo.shouldLockObject = 
    [delegate respondsToSelector: @selector(databaseContext:shouldLockObjectWithGlobalID:snapshot:)];
  _delegateRespondsTo.shouldRaiseForLockFailure = 
    [delegate respondsToSelector: @selector(databaseContext:shouldRaiseExceptionForLockFailure:)];
  _delegateRespondsTo.shouldFetchObjects = 
    [delegate respondsToSelector: @selector(databaseContext:shouldFetchObjectsWithFetchSpecification:editingContext:)];
  _delegateRespondsTo.didFetchObjects = 
    [delegate respondsToSelector: @selector(databaseContext:didFetchObjects:fetchSpecification:editingContext:)];
  _delegateRespondsTo.shouldFetchObjectFault = 
    [delegate respondsToSelector: @selector(databaseContext:shouldFetchObjectsWithFetchSpecification:editingContext:)];
  _delegateRespondsTo.shouldFetchArrayFault = 
    [delegate respondsToSelector: @selector(databaseContext:shouldFetchArrayFault:)];

  while ((channel == [channelsEnum nextObject]))
    [channel setDelegate: delegate];
}

- (void)handleDroppedConnection
{
  int i;

  EOFLOGObjectFnStartOrCond2(@"DatabaseLevel", @"EODatabaseContext");

  DESTROY(_adaptorContext);
  
  for (i = [_registeredChannels count] - 1; i >= 0; i--)
    {
      [(EODatabaseChannel *)[[_registeredChannels objectAtIndex: i]
			      nonretainedObjectValue] release];
    }

  DESTROY(_registeredChannels);

  _adaptorContext = RETAIN([[[self database] adaptor] createAdaptorContext]);
  _registeredChannels = [NSMutableArray new];

  EOFLOGObjectFnStopOrCond2(@"DatabaseLevel", @"EODatabaseContext");
}

@end


@implementation EODatabaseContext (EOObjectStoreSupport)

/** Return a fault for row 'row' **/
- (id)faultForRawRow: (NSDictionary *)row
	 entityNamed: (NSString *)entityName
      editingContext: (EOEditingContext *)context
{
  EOEntity *entity;
  EOGlobalID *gid;
  id object;

  EOFLOGObjectFnStart();

  entity = [_database entityNamed: entityName];
  gid = [entity globalIDForRow: row];

  object = [self faultForGlobalID: gid
		 editingContext: context];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p of class (%@)",
			object, [object class]);

  EOFLOGObjectFnStop();

  return object;
}

/** return entity corresponding to 'globalID' **/
- (id) entityForGlobalID: (EOGlobalID *)globalID
{
  //OK
  NSString *entityName;
  EOEntity *entity;

  DESTROY(_lastEntity);

  entityName = [globalID entityName];
  entity = [_database entityNamed: entityName];

  ASSIGN(_lastEntity, entity);

  return entity;
}

/** Make object a fault **/
- (void) _turnToFault: (id)object
                  gid: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context
           isComplete: (BOOL)isComplete
{
  //OK
  EOAccessFaultHandler *handler;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p", object);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"globalID=%@", globalID);

  NSAssert(globalID, @"No globalID");
  NSAssert1([globalID isKindOfClass: [EOKeyGlobalID class]],
	    @"globalID is not a EOKeyGlobalID but a %@",
	    [globalID class]);

  if ([(EOKeyGlobalID*)globalID areKeysAllNulls])
    NSWarnLog(@"All key of globalID %p (%@) are nulls",
              globalID,
              globalID);

  handler = [EOAccessFaultHandler
	      accessFaultHandlerWithGlobalID: (EOKeyGlobalID*)globalID
	      databaseContext: self
	      editingContext: context];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"handler=%@", handler);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object->isa=%p", object->isa);

  [EOFault makeObjectIntoFault: object
	   withHandler: handler];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object->isa=%p", object->isa);

  [self _addBatchForGlobalID: (EOKeyGlobalID*)globalID
        fault: object];

  EOFLOGObjectFnStop();
  //TODO: use isComplete
}

/** Get a fault for 'globalID' **/
- (id)faultForGlobalID: (EOGlobalID *)globalID
	editingContext: (EOEditingContext *)context
{
  //Seems OK
  EOClassDescription *classDescription = nil;
  EOEntity *entity;
  id object = nil;
  BOOL isFinal;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"globalID=%@", globalID);

  isFinal = [(EOKeyGlobalID *)globalID isFinal];
  entity = [self entityForGlobalID: globalID];

  NSAssert(entity, @"no entity");

  classDescription = [entity classDescriptionForInstances];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"classDescription=%@",
			classDescription);

  object = [classDescription createInstanceWithEditingContext: context
			     globalID: globalID
			     zone: NULL];

  NSAssert1(object, @"No Object. classDescription=%@", classDescription);
/*mirko: NO
  NSDictionary *pk;
  NSEnumerator *pkEnum;
  NSString *pkKey;
  NSArray  *classPropertyNames;
classPropertyNames = [entity classPropertyNames];
  pk = [entity primaryKeyForGlobalID:(EOKeyGlobalID *)globalID];
  pkEnum = [pk keyEnumerator];
  while ((pkKey = [pkEnum nextObject]))
    {
      if ([classPropertyNames containsObject:pkKey] == YES)
	[obj takeStoredValue:[pk objectForKey:pkKey]
	     forKey:pkKey];
    }
*/
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p", object);

  if ([(EOKeyGlobalID *)globalID areKeysAllNulls])
    NSWarnLog(@"All key of globalID %p (%@) are nulls",
              globalID,
              globalID);

  [self _turnToFault: object
        gid: globalID
        editingContext: context
        isComplete: isFinal];//??
  
  EOFLOGObjectLevel(@"EODatabaseContext", @"Record Object");

  [context recordObject: object
	   globalID: globalID];

  EOFLOGObjectFnStop();

  return object;
}

/** Get an array fault for globalID for relationshipName **/
- (NSArray *)arrayFaultWithSourceGlobalID: (EOGlobalID *)globalID
			 relationshipName: (NSString *)relationshipName
			   editingContext: (EOEditingContext *)context
{
  //Seems OK
  NSArray *obj = nil;

  if (![globalID isKindOfClass: [EOKeyGlobalID class]])
    {
      [NSException raise: NSInvalidArgumentException
                   format: @"%@ -- %@ The globalID %@ must be an EOKeyGlobalID to be able to construct a fault",
                   NSStringFromSelector(_cmd), 
                   NSStringFromClass([self class]),
                   globalID];
    }
  else
    {
      EOAccessArrayFaultHandler *handler = nil;

      obj = [EOCheapCopyMutableArray array];
      handler = [EOAccessArrayFaultHandler
		  accessArrayFaultHandlerWithSourceGlobalID:
		    (EOKeyGlobalID*)globalID
		  relationshipName: relationshipName
		  databaseContext: self
		  editingContext: context];

      [EOFault makeObjectIntoFault: obj
               withHandler: handler];

      [self _addToManyBatchForSourceGlobalID: (EOKeyGlobalID *)globalID
            relationshipName: relationshipName
            fault: (EOFault*)obj];
    }

  return obj;
}

- (void)initializeObject: (id)object
	    withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context
{
//near OK
  EOEntity *entity = nil;

  EOFLOGObjectFnStart();

  if ([globalID isTemporary])
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }

  if (![(EOKeyGlobalID *)globalID isFinal])
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }

  //mirko:
  if (_updateStrategy == EOUpdateWithPessimisticLocking)
    [self registerLockedObjectWithGlobalID: globalID];

  entity = [self entityForGlobalID: globalID];

/*Mirko:
  if ([object respondsToSelector:@selector(entity)])
    entity = [object entity];
  else
    entity = [_database entityNamed:[globalID entityName]];
*/

  [self initializeObject: object
        row: [self snapshotForGlobalID: globalID] //shound be _currentSnapshot
        entity: entity
        editingContext: context];

  EOFLOGObjectFnStop();
}

- (void) _objectsChanged: (NSNotification*)notification
{
  EOFLOGObjectFnStart();

/*object==self EOObjectsChangedInStoreNotification
userInfo = {
    deleted = (List Of GlobalIDs); 
    inserted = (List Of GlobalIDs); 
    updated = (List Of GlobalIDs); 
*/

  if ([notification object] != self)
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }
  else
    {
      //OK for update
      //TODO-NOW for insert/delete
      NSDictionary *userInfo = [notification userInfo];
      NSArray *updatedObjects = [userInfo objectForKey: @"updated"];
      //NSArray *insertedObjects = [userInfo objectForKey: @"inserted"];
      //NSArray *deletedObjects = [userInfo objectForKey: @"deleted"];
      int i, count = [updatedObjects count];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"updatedObjects=%@",
			    updatedObjects);

      for (i = 0; i < count; i++)
        {
          EOKeyGlobalID *gid=[updatedObjects objectAtIndex: i];
          NSString *entityName;

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

          entityName = [gid entityName];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entityName=%@",
				entityName);

          [_database invalidateResultCacheForEntityNamed: entityName];
        }
    }

  EOFLOGObjectFnStop();
}

- (void) _snapshotsChangedInDatabase: (NSNotification*)notification
{
  EOFLOGObjectFnStart();

/*
 userInfo = {
    deleted = (List Of GlobalIDs); 
    inserted = (List Of GlobalIDs); 
    updated = (List Of GlobalIDs); 
}}
*/

  if ([notification object] != self)
    {
      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOObjectsChangedInStoreNotification
	object: self
	userInfo: [notification userInfo]];
//call _objectsChanged: and ObjectStoreCoordinator _objectsChangedInSubStore: 
    }

  EOFLOGObjectFnStop();
}

- (NSArray *)objectsForSourceGlobalID: (EOGlobalID *)globalID
		     relationshipName: (NSString *)name
		       editingContext: (EOEditingContext *)context
{
  //Near OK
  NSArray *objects = nil;
  id sourceObjectFault = nil;
  id relationshipValue = nil;
  NSArray *sourceSnapshot = nil;
  int sourceSnapshotCount = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"globalID=%@", globalID);

  //First get the id from which we search the source object
  sourceObjectFault = [context faultForGlobalID: globalID
			       editingContext: context];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceObjectFault %p=%@",
			sourceObjectFault, sourceObjectFault);

  // Get the fault value from source object
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationshipName=%@", name);

  relationshipValue = [sourceObjectFault storedValueForKey: name];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationshipValue %p=%@",
			relationshipValue, relationshipValue);

  //Try to see if there is a snapshot for the source object
  sourceSnapshot = [_database snapshotForSourceGlobalID: globalID
			      relationshipName: name];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceSnapshot %p (%@)=%@",
			sourceSnapshot, [sourceSnapshot class],
			sourceSnapshot);

  sourceSnapshotCount = [sourceSnapshot count];

  if (sourceSnapshotCount > 0)
    {
      EOGlobalID *snapGID = nil;
      id snapFault = nil;
      int i;

      [EOFault clearFault: relationshipValue];

      for (i = 0; i < sourceSnapshotCount; i++)
        {
          snapGID = [sourceSnapshot objectAtIndex: i];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapGID=%@", snapGID);

          snapFault = [context faultForGlobalID: snapGID
			       editingContext: context]; 

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapFault=%@",
				snapFault);

          [relationshipValue addObject: snapFault];
        }

      objects = relationshipValue;
    }
  else
    {  
      EOEntity *entity;
      EORelationship *relationship;
      unsigned int maxBatch = 0;
      BOOL isToManyToOne = NO;
      EOEntity *destinationEntity = nil;
      EOModel *destinationEntityModel = nil;
      NSArray *models = nil;
      EOQualifier *auxiliaryQualifier = nil;
      NSDictionary *contextSourceSnapshot = nil;
      id sourceObject = nil;
      EORelationship *inverseRelationship = nil;
      EOEntity *invRelEntity = nil;
      NSArray *invRelEntityClassProperties = nil;
      NSString *invRelName = nil;
      EOQualifier *qualifier = nil;
      EOFetchSpecification *fetchSpec = nil;

      // Get the source object entity
      entity = [self entityForGlobalID: globalID];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity name=%@",
			    [entity name]);

      //Get the relationship named 'name'
      relationship = [entity relationshipNamed: name];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
			    relationship);

      //Get the max number of fault to fetch
      maxBatch = [relationship numberOfToManyFaultsToBatchFetch];

      isToManyToOne = [relationship isToManyToOne];//NO

      if (isToManyToOne)
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO if isToManyToOne
        }

      //Get the fault entity (aka relationsip destination entity)
      destinationEntity = [relationship destinationEntity];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationEntity name=%@",
			    [destinationEntity name]);

      //Get the destination entity model
      destinationEntityModel = [destinationEntity model];

      //and _database model to verify if the destinationEntityModel is in database models
      models = [_database models];

      if ([models indexOfObjectIdenticalTo: destinationEntityModel]
	  == NSNotFound)
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO error
        }

      //Get the relationship qualifier if any
      auxiliaryQualifier = [relationship auxiliaryQualifier];//nil

      if (auxiliaryQualifier)
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO if auxqualif
        }

      //??
      contextSourceSnapshot = [self snapshotForGlobalID: globalID];

      NSEmitTODO();
      //TODO Why first asking for faultForGlobalID and now asking objectForGlobalID ??

      sourceObject = [context objectForGlobalID: globalID];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceObject=%@",
			    sourceObject);

      inverseRelationship = [relationship inverseRelationship];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"inverseRelationship=%@",
			    inverseRelationship);

      if (!inverseRelationship)
        {
          NSEmitTODO();
          //[self notImplemented: _cmd]; //TODO if !inverseRelationship
          inverseRelationship = [relationship hiddenInverseRelationship];
	  //VERIFY (don't know if this is the good way)
        }

      invRelEntity = [inverseRelationship entity];
      invRelEntityClassProperties = [invRelEntity classProperties];
      invRelName = [inverseRelationship name];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"invRelName=%@",
			    invRelName);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceObject=%@",
			    sourceObject);

      qualifier = [EOKeyValueQualifier qualifierWithKey: invRelName
				       operatorSelector: @selector(isEqualTo:)
				       value: sourceObject];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"qualifier=%@", qualifier);

      fetchSpec = [EOFetchSpecification fetchSpecification];

      [fetchSpec setQualifier: qualifier];
      [fetchSpec setEntityName: [destinationEntity name]];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"fetchSpec=%@", fetchSpec);

      objects = [context objectsWithFetchSpecification: fetchSpec
			 editingContext: context];

      [self _registerSnapshot: objects
            forSourceGlobalID: globalID
            relationshipName: name
            editingContext: context];//OK
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"objects=%@", objects);
  EOFLOGObjectFnStop();

  return objects;
}

- (void)_registerSnapshot: (NSArray*)snapshot
        forSourceGlobalID: (EOGlobalID*)globalID
         relationshipName: (NSString*)name
           editingContext: (EOEditingContext*)context
{
  //OK
  NSArray *gids;

  EOFLOGObjectFnStart();

  gids = [context resultsOfPerformingSelector: @selector(globalIDForObject:)
		  withEachObjectInArray: snapshot];

  [_database recordSnapshot: gids
             forSourceGlobalID: globalID
             relationshipName: name];

  EOFLOGObjectFnStop();
}

- (void)refaultObject: object
	 withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context
{
  EOFLOGObjectFnStart();

  [EOObserverCenter suppressObserverNotification];

  NS_DURING
    {
      [object clearProperties];//OK
    }
  NS_HANDLER
    {
      [EOObserverCenter enableObserverNotification];

      NSLog(@"EXCEPTION %@", localException);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"EXCEPTION %@",
			    localException);              

      [localException raise];
    }
  NS_ENDHANDLER;

  [EOObserverCenter enableObserverNotification];

  if ([(EOKeyGlobalID *)globalID areKeysAllNulls])
    NSWarnLog(@"All key of globalID %p (%@) are nulls",
              globalID,
              globalID);

  [self _turnToFault: object
        gid: globalID
        editingContext: context
        isComplete: YES]; //Why YES ?

  //NO: done in edcontext by calling clearOriginalSnapshotForObject: [self forgetSnapshotForGlobalID:globalID];

  EOFLOGObjectFnStop();
}

- (void)saveChangesInEditingContext: (EOEditingContext *)context
{
  //TODO: locks ?
  NSException *exception = nil;

  EOFLOGObjectFnStart();

  [self prepareForSaveWithCoordinator: nil
	editingContext: context];

  [self recordChangesInEditingContext];

  NS_DURING
    {                  
      [self performChanges];
    }
  NS_HANDLER
    {
      NSDebugMLog(@"EXCEPTION: %@", localException);
      exception = localException;
    }
  NS_ENDHANDLER;

  //I don't know if this is really the good place to catch exception and rollback...
  if (exception)
    {
      [self rollbackChanges];
      [exception raise];
    }
  else
    [self commitChanges];

  EOFLOGObjectFnStop();
}

- (void)_fetchRelationship: (EORelationship *)relationship
	       withObjects: (NSArray *)objsArray
	    editingContext: (EOEditingContext *)context
{
  NSMutableArray *qualArray = nil;
  NSEnumerator *objEnum = nil;
  NSEnumerator *relEnum = nil;
  NSDictionary *snapshot = nil;
  id obj = nil;
  id relObj = nil;

  EOFLOGObjectFnStart();

  if ([objsArray count] > 0)
    {
      qualArray = [NSMutableArray arrayWithCapacity: 5];

      if ([relationship isFlattened] == YES)
        {
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"relationship %@ isFlattened", relationship);

          relEnum = [[relationship componentRelationships] objectEnumerator];

          while ((relationship = [relEnum nextObject]))
            {
              // TODO rebuild object array for relationship path
              
              [self _fetchRelationship: relationship
                    withObjects: objsArray
                    editingContext: context];
            }
        }
      
      objEnum = [objsArray objectEnumerator];
      while ((obj = [objEnum nextObject]))
        {
          relObj = [obj storedValueForKey: [relationship name]];
          snapshot = [self snapshotForGlobalID:
                             [context globalIDForObject: relObj]];
          
          [qualArray addObject: [relationship
				  qualifierWithSourceRow: snapshot]];
        }
      
      [self objectsWithFetchSpecification:
              [EOFetchSpecification
                fetchSpecificationWithEntityName:
                  [[relationship destinationEntity] name]
                qualifier: [EOAndQualifier qualifierWithQualifierArray:
					     qualArray]
                sortOrderings: nil]
            editingContext: context];
    }

  EOFLOGObjectFnStop();
}

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetch
			    editingContext: (EOEditingContext *)context
{ // TODO
  EODatabaseChannel *channel = nil;
  NSMutableArray *array = nil;
  NSDictionary *snapshot = nil;
  NSString *entityName = nil;
  EOEntity *entity = nil;
  NSString *relationshipKeyPath = nil;
  NSEnumerator *relationshipKeyPathEnum = nil;
  NSMutableArray *qualArray = nil;

  /*NSEnumerator *subEntitiesEnum = nil;
    EOEntity *subEntity = nil;
    NSArray *subEntities = nil;*/
  NSArray* rawRowKeyPaths = nil;
  BOOL usesDistinct = NO;
  int num = 0;
  int limit=0;
  int i = 0;
  id obj = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"fetch=%@", fetch);

  if (_delegateRespondsTo.shouldFetchObjects == YES)
    {
      array = (id)[_delegate databaseContext: self
			     shouldFetchObjectsWithFetchSpecification: fetch
			     editingContext: context];
    }

  if (!array)
    {
      array = [NSMutableArray arrayWithCapacity: 8];

      entityName = [fetch entityName];//OK
      entity = [_database entityNamed: entityName];//OK
      NSAssert1(entity,@"No entity named %@",
                entityName);

      /* moved in EODatabaseChannel _selectWithFetchSpecification:(EOFetchSpecification *)fetch
         editingContext:(EOEditingContext *)context

         limit        = [fetch fetchLimit];
         usesDistinct = [fetch usesDistinct];


         subEntities = [entity subEntities];

         if ([subEntities count] && [fetch isDeep] == YES)
         {
         subEntitiesEnum = [subEntities objectEnumerator];
         while ((subEntity = [subEntitiesEnum nextObject]))
         {
         EOFetchSpecification *fetchSubEntity;

         fetchSubEntity = [[fetch copy] autorelease];
         [fetchSubEntity setEntityName:[entity name]];

         [array addObjectsFromArray:[context objectsWithFetchSpecification:
         fetchSubEntity]];
         }
         }
      */
      rawRowKeyPaths = [fetch rawRowKeyPaths];//OK
      if (rawRowKeyPaths)
#if 0
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
#else
      // (stephane@sente.ch) Adapted implementation of non raw rows
      {
          //cachesObject
          //fetchspe isDeep ret 1
	channel = [self _obtainOpenChannel];

	if (!channel)
          {
	    NSEmitTODO();
	    [self notImplemented: _cmd];//TODO
          }
	else
          {
	    EOFLOGObjectLevelArgs(@"EODatabaseContext", @"channel class %@ [channel isFetchInProgress]=%s",
				  [channel class],
				  ([channel isFetchInProgress] ? "YES" : "NO"));

	    NSLog(@"%@ -- %@ 0x%x: channel isFetchInProgress=%s",
		  NSStringFromSelector(_cmd),
		  NSStringFromClass([self class]),
		  self,
		  ([channel isFetchInProgress] ? "YES" : "NO"));

	    //mirko:
#if 0
	    if (_flags.beganTransaction == NO
		&& _updateStrategy == EOUpdateWithPessimisticLocking)
              {
		[_adaptorContext beginTransaction];

		EOFLOGObjectLevel(@"EODatabaseContext",
				  @"BEGAN TRANSACTION FLAG==>YES");
		_flags.beganTransaction = YES;
              }
#endif

	    if ([entity isAbstractEntity] == NO) //Mirko ???
	      // (stephane@sente) Should we test deepInheritanceFetch?
              {
		int autoreleaseSteps = 20;
		int autoreleaseStep = autoreleaseSteps;
		BOOL promptsAfterFetchLimit = NO;
		NSAutoreleasePool *arp = nil;//To avoid too much memory use when fetching a lot of objects
		int limit = 0;

		[channel selectObjectsWithFetchSpecification: fetch
			 editingContext: context];//OK

		EOFLOGObjectLevelArgs(@"EODatabaseContext",
				      @"[channel isFetchInProgress]=%s",
				      ([channel isFetchInProgress] ? "YES" : "NO"));

		limit = [fetch fetchLimit];//OK
		promptsAfterFetchLimit = [fetch promptsAfterFetchLimit];

		EOFLOGObjectLevel(@"EODatabaseContext", @"Will Fetch");

		NS_DURING
		  {
		    arp = [NSAutoreleasePool new];
		    EOFLOGObjectLevelArgs(@"EODatabaseContext",
					  @"[channel isFetchInProgress]=%s",
					  ([channel isFetchInProgress] ? "YES" : "NO"));

		    while ((obj = [channel fetchObject]))
		      {
			EOFLOGObjectLevel(@"EODatabaseContext",
					  @"fetched an object");
			EOFLOGObjectLevelArgs(@"EODatabaseContext",
					      @"FETCH OBJECT object=%@\n\n",
					      obj);
			EOFLOGObjectLevelArgs(@"EODatabaseContext",
					      @"%d usesDistinct: %s",
					      num,
					      (usesDistinct ? "YES" : "NO"));
			EOFLOGObjectLevelArgs(@"EODatabaseContext",
					      @"object=%@\n\n", obj);

			if (usesDistinct == YES && num)
			  // (stephane@sente) I thought that DISTINCT was done on server-side?!?
			  {
			    for (i = 0; i < num; i++)
			      {
				if ([[array objectAtIndex: i]
				      isEqual: obj] == YES)
				  {
				    obj = nil;
				    break;
				  }
			      }

			    if (obj == nil)
			      continue;
			  }

			EOFLOGObjectLevel(@"EODatabaseContext",
					  @"AFTER FETCH");
			[array addObject: obj];
			EOFLOGObjectLevelArgs(@"EODatabaseContext",
					      @"array count=%d",
					      [array count]);
			num++;

			if (limit > 0 && num >= limit)
			  {
			    if ([[context messageHandler]
				  editingContext: context
				  shouldContinueFetchingWithCurrentObjectCount: num
				  originalLimit: limit
				  objectStore: self] == YES)
			      limit = 0;//??
			    else
			      break;
			  }

			if (autoreleaseStep <= 0)
			  {
			    DESTROY(arp);
			    autoreleaseStep = autoreleaseSteps;
			    arp = [NSAutoreleasePool new];
			  }
			else
			  autoreleaseStep--;

			EOFLOGObjectLevel(@"EODatabaseContext",
					  @"WILL FETCH NEXT OBJECT");
			EOFLOGObjectLevelArgs(@"EODatabaseContext",
					      @"[channel isFetchInProgress]=%s",
					      ([channel isFetchInProgress] ? "YES" : "NO"));
		      }

		    EOFLOGObjectLevel(@"EODatabaseContext",
				      @"finished fetch");
		    EOFLOGObjectLevelArgs(@"EODatabaseContext",
					  @"array=%@", array);
		    EOFLOGObjectLevelArgs(@"EODatabaseContext",
					  @"step 0 channel is busy=%d",
					  (int)[channel isFetchInProgress]);

		    [channel cancelFetch]; //OK

		    EOFLOGObjectLevelArgs(@"EODatabaseContext",
					  @"step 1 channel is busy=%d",
					  (int)[channel isFetchInProgress]);
		    EOFLOGObjectLevelArgs(@"EODatabaseContext", @"array=%@",
					  array);

                                  //TODO
                                  /*
                                   handle exceptio in fetchObject
                                   channel fetchObject

                                   if eception:
                                   if ([editcontext handleError:localException])
                                   {
                                       //TODO
                                   }
                                   else
                                   {
                                       //TODO
                                   };
                                   */
		  }
		NS_HANDLER
		  {
		    EOFLOGObjectLevelArgs(@"EODatabaseContext",
					  @"AN EXCEPTION: %@",
					  localException);

		    RETAIN(localException);
		    DESTROY(arp);
		    [localException autorelease];
		    [localException raise];
		  }
		NS_ENDHANDLER;
              }
          }
	EOFLOGObjectLevelArgs(@"EODatabaseContext",
			      @"step 2 channel is busy=%d",
			      (int)[channel isFetchInProgress]);
      }
#endif

      else if ([entity cachesObjects] == YES)//OK
        {
          ///TODO MG!!!
          NSMutableArray *cache;
          NSEnumerator *cacheEnum;
          EOQualifier *qualifier;
          EOGlobalID *gid;
          BOOL isFault;

          qualifier = [fetch qualifier];

          cache = (id)[_database resultCacheForEntityNamed: entityName];
          if (cache == nil)
            {
              NSMutableDictionary *row = nil;
              EOAdaptorChannel *adaptorChannel = nil;

              channel = [self availableChannel];
              adaptorChannel = [channel adaptorChannel];

              if (_flags.beganTransaction == NO
                  && _updateStrategy == EOUpdateWithPessimisticLocking)
                {
                  [_adaptorContext beginTransaction];

                  EOFLOGObjectLevel(@"EODatabaseContext",
				    @"BEGAN TRANSACTION FLAG==>YES");

                  _flags.beganTransaction = YES;
                }

              [adaptorChannel selectAttributes: [entity attributesToFetch]
                              fetchSpecification:
                                [EOFetchSpecification
                                  fetchSpecificationWithEntityName: entityName
                                  qualifier: nil
                                  sortOrderings: nil]
                              lock: NO
                              entity: entity];

              cache = [NSMutableArray arrayWithCapacity: 16];

              while ((row = [adaptorChannel fetchRowWithZone: NULL]))
                {
                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"row=%@", row);

                  gid = [entity globalIDForRow: row];
                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

                  [_database recordSnapshot: row
                             forGlobalID: gid];
                  [cache addObject: gid];
                }

              EOFLOGObjectLevel(@"EODatabaseContext", @"Finished fetch");
              [channel cancelFetch];

              EOFLOGObjectLevel(@"EODatabaseContext", @"setResultCache");
              [_database setResultCache: cache
                         forEntityNamed: entityName];
            }

          cacheEnum = [cache objectEnumerator];
          while ((gid = [cacheEnum nextObject]))
            {
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

              snapshot = [self snapshotForGlobalID: gid];
              if (snapshot)
                {
                  if (!qualifier
		      || [qualifier evaluateWithObject: snapshot] == YES)
                    {
                      obj = [context objectForGlobalID: gid];
                
                      isFault = [EOFault isFault: obj];
                
                      if (obj == nil || isFault == YES)
                        {
                          if (isFault == NO)
                            {
                              obj = [[entity classDescriptionForInstances]
                                      createInstanceWithEditingContext: context
                                      globalID: gid
                                      zone: NULL];

                              NSAssert1(obj, @"No Object. [entity classDescriptionForInstances]=%@", [entity classDescriptionForInstances]);
                              [context recordObject: obj
                                       globalID: gid];
                            }
                          else
                            {
                              [self _removeBatchForGlobalID:
				      (EOKeyGlobalID *)gid
                                    fault: obj];

                              [EOFault clearFault: obj];
                            }

                          [context initializeObject: obj
                                   withGlobalID: gid
                                   editingContext: context];

                          [obj awakeFromFetchInEditingContext: context];
                        }
                
                      if (usesDistinct == YES && num)
                        {
                          for (i = 0; i < num; i++)
                            {
                              if ([[array objectAtIndex: i]
				    isEqual: obj] == YES)
                                {
                                  obj = nil;
                                  break;
                                }
                            }

                          if (obj == nil)
                            continue;
                        }
                
                      [array addObject: obj];
                      num++;
                
                      if (limit && num >= limit)
                        {
                          if ([[context messageHandler]
				editingContext: context
				shouldContinueFetchingWithCurrentObjectCount: num
				originalLimit: limit
				objectStore: self] == YES)
                            limit = 0;
                          else
                            break;
                        }
                    }
                }
            }

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"array before sort: %@",
				array);

          if ([fetch sortOrderings])
            array = (id)[array sortedArrayUsingKeyOrderArray:
				 [fetch	sortOrderings]];
        }
      else
        {
//cachesObject
//fetchspe isDeep ret 1
          channel = [self _obtainOpenChannel];

          if (!channel)
            {
              NSEmitTODO();
              [self notImplemented: _cmd];//TODO
            }
          else
            {
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"channel class %@ [channel isFetchInProgress]=%s",
				    [channel class],
				    ([channel isFetchInProgress] ? "YES" : "NO"));

              NSLog(@"%@ -- %@ 0x%x: channel isFetchInProgress=%s",
                    NSStringFromSelector(_cmd),
                    NSStringFromClass([self class]),
                    self,
                    ([channel isFetchInProgress] ? "YES" : "NO"));
          
              //mirko:
              if (_flags.beganTransaction == NO
                  && _updateStrategy == EOUpdateWithPessimisticLocking)
                {
                  [_adaptorContext beginTransaction];

                  EOFLOGObjectLevel(@"EODatabaseContext",
				    @"BEGAN TRANSACTION FLAG==>YES");
                  _flags.beganTransaction = YES;
                }

              if ([entity isAbstractEntity] == NO) //Mirko ???
                {
                  int autoreleaseSteps = 20;
                  int autoreleaseStep = autoreleaseSteps;
                  BOOL promptsAfterFetchLimit = NO;
                  NSAutoreleasePool *arp = nil;//To avoid too much memory use when fetching a lot of objects
                  int limit = 0;

                  [channel selectObjectsWithFetchSpecification: fetch
                           editingContext: context];//OK

                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"[channel isFetchInProgress]=%s",
					([channel isFetchInProgress] ? "YES" : "NO"));

                  limit = [fetch fetchLimit];//OK
                  promptsAfterFetchLimit = [fetch promptsAfterFetchLimit];

                  EOFLOGObjectLevel(@"EODatabaseContext", @"Will Fetch");

                  NS_DURING
                    {                  
                      arp = [NSAutoreleasePool new];
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"[channel isFetchInProgress]=%s",
					    ([channel isFetchInProgress] ? "YES" : "NO"));

                      while ((obj = [channel fetchObject]))
                        {
                          EOFLOGObjectLevel(@"EODatabaseContext",
					    @"fetched an object");
                          EOFLOGObjectLevelArgs(@"EODatabaseContext",
						@"FETCH OBJECT object=%@\n\n",
						obj);
                          EOFLOGObjectLevelArgs(@"EODatabaseContext",
						@"%d usesDistinct: %s",
						num,
						(usesDistinct ? "YES" : "NO"));
                          EOFLOGObjectLevelArgs(@"EODatabaseContext",
						@"object=%@\n\n", obj);

                          if (usesDistinct == YES && num)
                            {
                              for (i = 0; i < num; i++)
                                {
                                  if ([[array objectAtIndex: i]
					isEqual :obj] == YES)
                                    {
                                      obj = nil;
                                      break;
                                    }
                                }
                              
                              if (obj == nil)
                                continue;
                            }

                          EOFLOGObjectLevel(@"EODatabaseContext",
					    @"AFTER FETCH");
                          [array addObject: obj];
                          EOFLOGObjectLevelArgs(@"EODatabaseContext",
						@"array count=%d",
						[array count]);
                          num++;
                          
                          if (limit > 0 && num >= limit)
                            {
                              if ([[context messageHandler]
				    editingContext: context
				    shouldContinueFetchingWithCurrentObjectCount: num
				    originalLimit: limit
				    objectStore: self] == YES)
                                limit = 0;//??
                              else
                                break;
                            }

                          if (autoreleaseStep <= 0)
                            {
                              DESTROY(arp);
                              autoreleaseStep = autoreleaseSteps;
                              arp = [NSAutoreleasePool new];
                            }
                          else 
                            autoreleaseStep--;

                          EOFLOGObjectLevel(@"EODatabaseContext",
					    @"WILL FETCH NEXT OBJECT");
                          EOFLOGObjectLevelArgs(@"EODatabaseContext",
						@"[channel isFetchInProgress]=%s",
						([channel isFetchInProgress] ? "YES" : "NO"));
                        }
              
                      EOFLOGObjectLevel(@"EODatabaseContext",
					@"finished fetch");
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"array=%@", array);
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"step 0 channel is busy=%d",
                                            (int)[channel isFetchInProgress]);

                      [channel cancelFetch]; //OK

                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"step 1 channel is busy=%d",
                                            (int)[channel isFetchInProgress]);
                      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"array=%@",
                                            array);

                      //TODO
                      /*
                        handle exceptio in fetchObject
                        channel fetchObject
                        
                        if eception:
                        if ([editcontext handleError:localException])
                        {
                        //TODO
                        }
                        else
                        {
                        //TODO
                        };
                      */
                    }
                  NS_HANDLER
                    {
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"AN EXCEPTION: %@",
					    localException);

                      RETAIN(localException);
                      DESTROY(arp);
                      [localException autorelease];
                      [localException raise];
                    }
                  NS_ENDHANDLER;
                }
            }
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"step 2 channel is busy=%d",
                                (int)[channel isFetchInProgress]);
        }

      //VERIFY
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"array before prefetchingRelationshipKeyPaths: %@",
			    array);

      if ([fetch prefetchingRelationshipKeyPaths]) //OK
        qualArray = [NSMutableArray arrayWithCapacity: 5];

      relationshipKeyPathEnum = [[fetch prefetchingRelationshipKeyPaths]
                                  objectEnumerator];

      while ((relationshipKeyPath = [relationshipKeyPathEnum nextObject]))
        {
          NSArray *relationshipKeyArray = [relationshipKeyPath
                                            componentsSeparatedByString: @"."];
          NSEnumerator *relationshipKeyEnum;
          EORelationship *relationship;
          EOEntity *currentEntity = entity;
          NSString *relationshipKey;

          relationshipKeyEnum = [relationshipKeyArray objectEnumerator];
          while ((relationshipKey = [relationshipKeyEnum nextObject]))
            {
              relationship = [currentEntity relationshipNamed: relationshipKey];
              currentEntity = [relationship destinationEntity];

              // TODO rebuild object array for relationship path

              [self _fetchRelationship: relationship
                    withObjects: array
                    editingContext: context];
            }
        }

      if (_delegateRespondsTo.didFetchObjects == YES)
        [_delegate databaseContext: self
                   didFetchObjects: array
                   fetchSpecification: fetch
                   editingContext: context];

      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"step 1 channel is busy=%d",
                            (int)[channel isFetchInProgress]);
    }

  //EOFLOGObjectLevelArgs(@"EODatabaseContext", @"array: %@", array);
  EOFLOGObjectFnStop();

  return array;
}

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)gid
		    editingContext: (EOEditingContext *)context
{
  return [self isObjectLockedWithGlobalID: gid];
}

- (void)lockObjectWithGlobalID: (EOGlobalID *)globalID
		editingContext: (EOEditingContext *)context
{ // TODO
  EOKeyGlobalID *gid = (EOKeyGlobalID *)globalID;
  EODatabaseChannel *channel;
  EOEntity *entity;
  NSArray *attrsUsedForLocking, *primaryKeyAttributes;
  NSDictionary *snapshot;
  NSMutableDictionary *qualifierSnapshot, *lockSnapshot;
  NSMutableArray *lockAttributes;
  NSEnumerator *attrsEnum;
  EOQualifier *qualifier;
  EOAttribute *attribute;

  if ([self isObjectLockedWithGlobalID: gid] == NO)
    {
      snapshot = [self snapshotForGlobalID: gid];

      if (_delegateRespondsTo.shouldLockObject == YES &&
	 [_delegate databaseContext: self
		    shouldLockObjectWithGlobalID: gid
		    snapshot: snapshot] == NO)
	  return;

      channel = [self availableChannel];
      entity = [_database entityNamed: [gid entityName]];

      NSAssert1(entity, @"No entity named %@",
               [gid entityName]);

      attrsUsedForLocking = [entity attributesUsedForLocking];
      primaryKeyAttributes = [entity primaryKeyAttributes];

      qualifierSnapshot = [NSMutableDictionary dictionaryWithCapacity: 16];
      lockSnapshot = [NSMutableDictionary dictionaryWithCapacity: 8];
      lockAttributes = [NSMutableArray arrayWithCapacity: 8];

      attrsEnum = [primaryKeyAttributes objectEnumerator];
      while ((attribute = [attrsEnum nextObject]))
	{
	  NSString *name = [attribute name];

	  [lockSnapshot setObject: [snapshot objectForKey:name]
			forKey: name];
	}

      attrsEnum = [attrsUsedForLocking objectEnumerator];
      while ((attribute = [attrsEnum nextObject]))
	{
	  NSString *name = [attribute name];

	  if ([primaryKeyAttributes containsObject:attribute] == NO)
	    {
	      if ([attribute adaptorValueType] == EOAdaptorBytesType)
		{
		  [lockAttributes addObject: attribute];
		  [lockSnapshot setObject: [snapshot objectForKey:name]
				forKey: name];
		}
	      else
		[qualifierSnapshot setObject: [snapshot objectForKey:name]
				   forKey: name];
	    }
	}

      // Turbocat
      if ([[qualifierSnapshot allKeys] count] > 0)
        qualifier = [EOAndQualifier
		      qualifierWithQualifiers:
			[entity qualifierForPrimaryKey:
				  [entity primaryKeyForGlobalID: gid]],
		      [EOQualifier qualifierToMatchAllValues:
				     qualifierSnapshot],
		      nil];

      if ([lockAttributes count] == 0)
	lockAttributes = nil;
      if ([lockSnapshot count] == 0)
	lockSnapshot = nil;

      if (_flags.beganTransaction == NO)
	{
	  [[[channel adaptorChannel] adaptorContext] beginTransaction];

          EOFLOGObjectLevel(@"EODatabaseContext",
			    @"BEGAN TRANSACTION FLAG==>YES");

	  _flags.beganTransaction = YES;
	}

      NS_DURING
	[[channel adaptorChannel] lockRowComparingAttributes: lockAttributes
				  entity: entity
				  qualifier: qualifier
				  snapshot: lockSnapshot];
      NS_HANDLER
	{
	  if (_delegateRespondsTo.shouldRaiseForLockFailure == YES)
	    {
	      if ([_delegate databaseContext: self
			     shouldRaiseExceptionForLockFailure:localException]
		 == YES)
		[localException raise];
	    }
	  else
	    [localException raise];
	}
      NS_ENDHANDLER;

      [self registerLockedObjectWithGlobalID: gid];
    }
}

- (void)invalidateAllObjects
{
  [self invalidateObjectsWithGlobalIDs: [[_database snapshot] allKeys]];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOInvalidatedAllObjectsInStoreNotification
    object: self];
}

- (void)invalidateObjectsWithGlobalIDs: (NSArray *)globalIDs
{
  NSMutableArray *array = nil;
  NSEnumerator *enumerator;
  EOKeyGlobalID *gid;

  if (_delegateRespondsTo.shouldInvalidateObject == YES)
    {
      array = [NSMutableArray array];
      enumerator = [globalIDs objectEnumerator];

      while ((gid = [enumerator nextObject]))
	{
	  if ([_delegate databaseContext: self
			 shouldInvalidateObjectWithGlobalID: gid
			 snapshot: [self snapshotForGlobalID: gid]] == YES)
	    [array addObject: gid];
	}
    }

  [_database forgetSnapshotsForGlobalIDs: ((id)array ? (id)array : globalIDs)];
}

@end


@implementation EODatabaseContext(EOCooperatingObjectStoreSupport)

- (BOOL)ownsGlobalID: (EOGlobalID *)globalID
{
  if ([globalID isKindOfClass: [EOKeyGlobalID class]] &&
      [_database entityNamed: [globalID entityName]])
    return YES;

  return NO;
}

- (BOOL)ownsObject: (id)object
{
  if ([_database entityForObject: object])
    return YES;

  return NO;
}

- (BOOL)ownsEntityNamed: (NSString *)entityName
{
  if ([_database entityNamed: entityName])
    return YES;

  return NO;
}

- (BOOL)handlesFetchSpecification: (EOFetchSpecification *)fetchSpecification
{
  //OK
  if ([_database entityNamed: [fetchSpecification entityName]])
    return YES;
  else
    return NO;
}
/*//Mirko:
- (EODatabaseOperation *)_dbOperationWithObject:object
				       operator:(EODatabaseOperator)operator
{
  NSMapEnumerator gidEnum;
  EODatabaseOperation *op;
  EOGlobalID *gid;

  gidEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);
  while (NSNextMapEnumeratorPair(&gidEnum, (void **)&gid, (void **)&op))
    {
      if ([[op object] isEqual:object] == YES)
	{
	  if ([op databaseOperator] == operator)
	    return op;

	  return nil;
	}
    }

  return nil;
}

- (void)_setGlobalID:(EOGlobalID *)globalID
forDatabaseOperation:(EODatabaseOperation *)op
{
  EOGlobalID *oldGlobalID = [op globalID];

  [op _setGlobalID:globalID];

  NSMapInsert(_dbOperationsByGlobalID, globalID, op);
  NSMapRemove(_dbOperationsByGlobalID, oldGlobalID);
}

- (EODatabaseOperation *)_dbOperationWithGlobalID:(EOGlobalID *)globalID
					   object:object
					   entity:(EOEntity *)entity
					 operator:(EODatabaseOperator)operator
{
  EODatabaseOperation *op;
  NSMutableDictionary *newRow;
  NSMapEnumerator gidEnum;
  EOAttribute *attribute;
  EOGlobalID *gid;
  NSString *key;
  NSArray *classProperties;
  EONull *null = [EONull null];
  BOOL found = NO;
  int i, count;
  id val;

  gidEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);
  while (NSNextMapEnumeratorPair(&gidEnum, (void **)&gid, (void **)&op))
    {
      if ([[op object] isEqual:object] == YES)
	{
	  found = YES;
	  break;
	}
    }

  if (found == YES)
    return op;

  if (globalID == nil)
    globalID = [[[EOTemporaryGlobalID alloc] init] autorelease];

  op = [[[EODatabaseOperation alloc] initWithGlobalID:globalID
				     object:object
				     entity:entity] autorelease];

  [op setDatabaseOperator:operator];
  [op setDBSnapshot:[self snapshotForGlobalID:globalID]];

  newRow = [op newRow];

  classProperties = [entity classProperties];

  count = [classProperties count];
  for (i = 0; i < count; i++)
    {
      attribute = [classProperties objectAtIndex:i];
      if ([attribute isKindOfClass:[EOAttribute class]] == NO)
	continue;

      key = [attribute name];

      if ([attribute isFlattened] == NO)
	{
	  val = [object storedValueForKey:key];

	  if (val == nil)
	    val = null;

	  [newRow setObject:val forKey:key];
	}
    }

  NSLog(@"** %@ # %@", globalID, [op dbSnapshot]);
  NSLog(@"-- %@", [op newRow]);

  NSMapInsert(_dbOperationsByGlobalID, globalID, op);

  return op;
}

*/

// Prepares to save changes.  Obtains primary keys for any inserted objects
// in the EditingContext that are owned by this context.
- (void)prepareForSaveWithCoordinator: (EOObjectStoreCoordinator *)coordinator
		       editingContext: (EOEditingContext *)context
{
  //near OK
  NSArray *insertedObjects = nil;
  int i = 0;
  int count = 0;

  EOFLOGObjectFnStart();
  NSAssert(context, @"No editing context");

  _flags.preparingForSave = YES;
  _coordinator=coordinator;//RETAIN ?
  _editingContext=context;//RETAIN ?

  // First, create dbOperation map if there's none
  if (!_dbOperationsByGlobalID)
    _dbOperationsByGlobalID = NSCreateMapTable(NSObjectMapKeyCallBacks, 
                                               NSObjectMapValueCallBacks,
                                               32);

  // Next, build list of Entity which need PK generator
  [self _buildPrimaryKeyGeneratorListForEditingContext: context];

  // Now get newly inserted objects
  // For each objet, we will recordInsertForObject: and relay PK if it is !nil
  insertedObjects = [context insertedObjects];
  i = 0;
  count = [insertedObjects count];

  for (i = 0; i < count; i++)
    {
      id object = [insertedObjects objectAtIndex: i];

      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%@",object);

      if ([self ownsObject:object])
        {
          NSDictionary *objectPK = nil;
          EODatabaseOperation *dbOpe = nil;
          NSMutableDictionary *newRow = nil;
          EOEntity *entity = [_database entityForObject:object];

          [self recordInsertForObject: object];
          objectPK = [self _primaryKeyForObject: object];

          if (objectPK)
            {
              dbOpe = [self databaseOperationForObject: object];

              EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p dbOpe=%@",
                                    object,dbOpe);

              newRow=[dbOpe newRow];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow=%@", newRow);

              [self relayPrimaryKey: objectPK
                    object: object
                    entity: entity];
            }
        }
    }

  EOFLOGObjectFnStop();
}


- (void)recordChangesInEditingContext
{
  int which = 0;
  NSArray *objects[3] = {nil, nil, nil};

  EOFLOGObjectFnStart();

  [self _assertValidStateWithSelector:
	  @selector(recordChangesInEditingContext)];

  NSAssert(_editingContext, @"No editing context");
  // We'll examin object in the following order:
  // insertedObjects,
  // deletedObjects (because re-inserted object should be removed from deleteds)
  // updatedObjects (because inserted/deleted objects may cause some other objects to be updated).

  for (which = 0; which < 3; which++)
    {
      int i, count;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"Unprocessed: %@",
			    [_editingContext unprocessedDescription]);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"Objects: %@",
			    [_editingContext objectsDescription]);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"which=%d", which);

      if (which == 0)
        objects[which] = [_editingContext insertedObjects];
      else if (which == 1)
        objects[which] = [_editingContext deletedObjects];
      else
        objects[which] = [_editingContext updatedObjects];

      count = [objects[which] count];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"objects[which]=%@",
			    objects[which]);

      // For each object
      for (i = 0; i < count; i++)
        {
          NSDictionary *currentCommittedSnapshot = nil;
          NSArray *relationships = nil;
          EODatabaseOperation *dbOpe = nil;
          EOEntity *entity = nil;
          id object = [objects[which] objectAtIndex: i];

//Mirko ??      if ([self ownsObject:object] == YES)

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"object %p (class=%@):\n%@",
                                object,
                                [object class],
                                object);

          entity = [_database entityForObject: object]; //OK for Update 

          if (which == 0 || which == 2)//insert or update
            {
              NSDictionary *pk = nil;
              NSDictionary *snapshot;

              [self recordUpdateForObject: object //Why ForUpdate ? Becuase PK already generated ?
                    changes: nil]; //OK for update

              // Get a dictionary of object properties+PK+relationships CURRENT values 
              snapshot = [object snapshot]; //OK for Update+Insert

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot %p: %@",
				    snapshot, snapshot);
              EOFLOGObjectLevelArgs(@"EODatabaseContext",
				    @"currentCommittedSnapshot %p: %@",
				    currentCommittedSnapshot,
				    currentCommittedSnapshot);

              // Get a dictionary of object properties+PK+relationships DATABASES values 
              if (!currentCommittedSnapshot)
                currentCommittedSnapshot =
		  [self _currentCommittedSnapshotForObject:object]; //OK For Update

              EOFLOGObjectLevelArgs(@"EODatabaseContext",
				    @"currentCommittedSnapshot %p: %@",
				    currentCommittedSnapshot,
				    currentCommittedSnapshot);

              //TODO so what ?

              // Get the PK
              pk = [self _primaryKeyForObject: object];//OK for Update

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"pk=%@", pk);

              if (pk)
                [self relayPrimaryKey: pk
                      object: object
                      entity: entity]; //OK for Update 
            }

          relationships = [entity relationships]; //OK for Update

          EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p relationships: %@",
                                object,relationships);

          if (which == 1) //delete        //Not in insert //not in update
            {
              int iRelationship = 0;
              int relationshipsCount = [relationships count];

              for (iRelationship = 0; iRelationship < relationshipsCount;
		  iRelationship++)
                {
                  EORelationship *relationship = 
		    [relationships objectAtIndex: iRelationship];

                  if ([relationship isToManyToOne])
                    {
                      NSEmitTODO();
                      [self notImplemented: _cmd]; //TODO
                    }
                }

              EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object: %@",
                                    object);

              [self recordDeleteForObject: object];
            }

          dbOpe = [self databaseOperationForObject: object];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

          if (which == 0 || which == 2) //insert or update
            {
//En update: dbsnapshot
//en insert : snapshot ? en insert:dbsnap aussi
              int iRelationship = 0;
              int relationshipsCount = 0;
              NSDictionary *snapshot = nil;

              if (which == 0) //Insert //see wotRelSaveChanes.1.log seems to use dbSna for insert !
                {
                  snapshot=[object snapshot];//NEW2
                  //snapshot=[dbOpe dbSnapshot]; //NEW

                  NSDebugMLog(@"[dbOpe dbSnapshot]=%@", [dbOpe dbSnapshot]);
                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"Insert: [dbOpe snapshot] %p=%@",
					snapshot, snapshot);
                }
              else //Update
                {
                  //NEWsnapshot=[dbOpe dbSnapshot];
                  snapshot = [object snapshot];

                  //EOFLOGObjectLevelArgs(@"EODatabaseContext",@"Update: [dbOpe snapshot] %p=%@",snapshot,snapshot);
                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"Update: [object snapshot] %p=%@",
					snapshot, snapshot);
                }

              relationshipsCount = [relationships count];

              for (iRelationship = 0; iRelationship < relationshipsCount;
		   iRelationship++)
                {
                  NSArray *classProperties = nil;
                  EORelationship *relationship = nil;
                  EORelationship *substitutionRelationship = nil;

                  relationship = [relationships objectAtIndex: iRelationship];

/*
get rel entity
entity model
model modelGroup
*/

                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"HANDLE relationship %@ for object %p (class=%@):\n%@",
                                        [relationship name],
                                        object,
                                        [object class],
                                        object);
                  NSDebugMLog(@"HANDLE relationship %@ for object %p (class=%@):\n%@",
                              [relationship name],
                              object,
                              [object class],
                              object);

                  substitutionRelationship =
		    [relationship _substitutionRelationshipForRow: snapshot];

                  classProperties = [entity classProperties];

/*
rel name ==> toCountry

rel isToMany (0)
nullifyAttributesInRelationship:rel sourceObject:object destinationObject:nil (snapshot objectForKey: rel name ) ?
*/
                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"relationship: %@", relationship);
                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"classProperties: %@",
					classProperties);

                  if ([classProperties indexOfObjectIdenticalTo: relationship]
		      != NSNotFound) //(or subst)
                    {
                      BOOL valuesAreEqual = NO;
                      BOOL isToMany = NO;
                      id relationshipCommitedSnapshotValue = nil;
                      NSString *relationshipName = [relationship name];
                      id relationshipSnapshotValue;

                      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@",
					    dbOpe);
                      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"which=%d",
					    which);
                      //EOFLOGObjectLevelArgs(@"EODatabaseContext",@"OBJECT SNAPSHOT %p:\n%@\n\n",[object snapshot]);
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"snapshot for object %p:\nsnapshot %p (count=%d)= \n%@\n\n",
					    object, snapshot, [snapshot count],
					    snapshot);

                      // substitutionRelationship objectForKey:
                      relationshipSnapshotValue =
			[snapshot objectForKey: relationshipName];

                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"relationshipSnapshotValue (snapshot %p rel name=%@): %@",
					    snapshot,
					    relationshipName,
					    relationshipSnapshotValue);

                      if (which == 0) //Insert
                        currentCommittedSnapshot = [dbOpe dbSnapshot];
                      else //Update
                        {
                          if (!currentCommittedSnapshot)
                            currentCommittedSnapshot =
			      [self _currentCommittedSnapshotForObject: object]; //OK For Update
                        }
//update: _commited
//insert: dbSn
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"currentCommittedSnapshot %p: %@",
					    currentCommittedSnapshot,
					    currentCommittedSnapshot);

                      relationshipCommitedSnapshotValue =
			[currentCommittedSnapshot objectForKey:
						    relationshipName];

                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"relationshipCommitedSnapshotValue (snapshot %p rel name=%@): %@",
					    currentCommittedSnapshot,
					    relationshipName,
					    relationshipCommitedSnapshotValue);

                      isToMany = [relationship isToMany];

                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"isToMany: %s",
					    (isToMany ? "YES" : "NO"));
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"relationshipSnapshotValue %p=%@",
					    relationshipSnapshotValue,
					    relationshipSnapshotValue);
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"relationshipCommitedSnapshotValue %p=%@",
					    relationshipCommitedSnapshotValue,
					    ([EOFault isFault:relationshipCommitedSnapshotValue] ? 
                                             (NSString*)@"[Fault]" 
                                             : (NSString*)relationshipCommitedSnapshotValue));

                      if (relationshipSnapshotValue
			  == relationshipCommitedSnapshotValue)
                        valuesAreEqual = YES;
                      else if (isNilOrEONull(relationshipSnapshotValue))
                        valuesAreEqual = isNilOrEONull(relationshipCommitedSnapshotValue);
                      else if (isNilOrEONull(relationshipCommitedSnapshotValue))
                        valuesAreEqual = isNilOrEONull(relationshipSnapshotValue);
                      else if (isToMany)
                        valuesAreEqual = [relationshipSnapshotValue
                                           containsIdenticalObjectsWithArray:
                                             relationshipCommitedSnapshotValue];
                      else // ToOne bu not same object
                        valuesAreEqual = NO;

                      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p valuesAreEqual: %s",
                                            object,(valuesAreEqual ? "YES" : "NO"));

                      if (valuesAreEqual)
                        {
                          //Equal Values !
                        }
                      else
                        {
                          if (isToMany)
                            {
                              //relationshipSnapshotValue shallowCopy 
                              // Old Values are removed values
                              NSArray *oldValues = [relationshipCommitedSnapshotValue arrayExcludingObjectsInArray: relationshipSnapshotValue];
                              // Old Values are newly added values
                              NSArray *newValues = [relationshipSnapshotValue arrayExcludingObjectsInArray: relationshipCommitedSnapshotValue];

                              EOFLOGObjectLevelArgs(@"EODatabaseContext",
						    @"oldValues count=%d",
						    [oldValues count]);
                              EOFLOGObjectLevelArgs(@"EODatabaseContext",
						    @"oldValues=%@",
						    oldValues);
                              EOFLOGObjectLevelArgs(@"EODatabaseContext",
						    @"newValues count=%d",
						    [newValues count]);
                              EOFLOGObjectLevelArgs(@"EODatabaseContext",
						    @"newValues=%@",
						    newValues);

                              // Record new values snapshots
                              if ([newValues count] > 0)
                                {
                                  int newValuesCount = [newValues count];
                                  int iValue;
                                  NSMutableArray *valuesGIDs =
				    [NSMutableArray array];

                                  for (iValue = 0;
				       iValue < newValuesCount;
				       iValue++)
                                    {
                                      id aValue = [relationshipSnapshotValue
						    objectAtIndex: iValue];
                                      EOGlobalID *aValueGID = [self _globalIDForObject: aValue];

				      EOFLOGObjectLevelArgs(@"EODatabaseContext",
							    @"YYYY valuesGIDs=%@",
							    valuesGIDs);
				      EOFLOGObjectLevelArgs(@"EODatabaseContext",
							    @"YYYY aValueGID=%@",
							    aValueGID);
				      [valuesGIDs addObject:aValueGID];
                                    }

                                  [dbOpe recordToManySnapshot:valuesGIDs
                                         relationshipName: relationshipName];
                                }

                              // Nullify removed object relation attributes
                              if ([oldValues count] > 0)
                                {
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"will call nullifyAttributes from source %p (class %@)",
                                                        object, [object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"object %p=%@ (class=%@)",
                                                        object, object,
							[object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"relationshipName=%@",
                                                        relationshipName);

                                  [self nullifyAttributesInRelationship:
					  relationship
                                        sourceObject: object
                                        destinationObjects: oldValues];
                                }

                              // Relay relationship attributes in new objects
                              if ([newValues count] > 0)
                                {
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"will call relay from source %p (class %@)",
                                                        object, [object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"object %p=%@ (class=%@)",
                                                        object, object,
							[object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"relationshipName=%@",
                                                        relationshipName);

                                  [self relayAttributesInRelationship:
					  relationship
                                        sourceObject: object
                                        destinationObjects: newValues];
                                }
                            }
                          else // To One
                            {
                              //id destinationObject=[object storedValueForKey:relationshipName];

                              if (!isNilOrEONull(relationshipCommitedSnapshotValue)) // a value was removed
                                {
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"will call nullifyAttributes from source %p (class %@)",
                                                        object, [object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"object %p=%@ (class=%@)",
                                                        object, object,
							[object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"relationshipName=%@",
                                                        relationshipName);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"destinationObject %p=%@ (class=%@)",
                                                        relationshipCommitedSnapshotValue,
                                                        relationshipCommitedSnapshotValue,
                                                        [relationshipCommitedSnapshotValue class]);

                                  [self nullifyAttributesInRelationship:
					  relationship
                                        sourceObject: object
                                        destinationObject:
					  relationshipCommitedSnapshotValue];
                                }

                              if (!isNilOrEONull(relationshipSnapshotValue)) // a value was added
                                {
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"will call relay from source %p relname=%@",
                                                        object,
							relationshipName);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"object %p=%@ (class=%@)",
                                                        object, object,
							[object class]);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"relationshipName=%@",
                                                        relationshipName);
                                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
							@"destinationObject %p=%@ (class=%@)",
                                                        relationshipSnapshotValue,
                                                        relationshipSnapshotValue,
                                                        [relationshipSnapshotValue class]);

				  [self relayAttributesInRelationship:
					  relationship
					sourceObject: object
					destinationObject:
					  relationshipSnapshotValue];
				}
                            }
                        }
                    }
                  else
                    {
                      //!toMany:
                      //dbSnapshot was empty
                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
                                            @"will call nullifyAttributesInRelationship on source %p relname=%@",
                                            object, [relationship name]);
		      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"object %p=%@ (class=%@)",
					    object, object, [object class]);
		      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"relationshipName=%@",
					    [relationship name]);

                      [self nullifyAttributesInRelationship: relationship
                            sourceObject: object /*CountryLabel*/ 
                            destinationObjects: nil];
                    }

/*
		  NSMutableDictionary *row;
		  NSMutableArray *toManySnapshot, *newToManySnapshot;
		  NSArray *joins = [(EORelationship *)property joins];
		  NSString *joinName;
		  EOJoin *join;
		  int h, count;
		  id value;

		  name = [(EORelationship *)property name];
		  row = [NSMutableDictionary dictionaryWithCapacity:4];
		  count = [joins count];
		  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"rel name=%@", name);

		  if ([property isToMany] == YES)
		    {
		      NSMutableArray *toManyGIDArray;
		      NSArray *toManyObjects;
		      EOGlobalID *toManyGID;
		      id toManyObj;

		      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"rel 1 sourceGID=%@", gid);
		      toManySnapshot = [[[self snapshotForSourceGlobalID:gid
					       relationshipName:name]
					  mutableCopy] autorelease];
		      if (toManySnapshot == nil)
			toManySnapshot = [NSMutableArray array];
		      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"rel 1", name);

		      newToManySnapshot = [NSMutableArray
					    arrayWithCapacity:10];
		      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"rel 1", name);

		      toManyObjects = [object storedValueForKey:name];
		      toManyGIDArray = [NSMutableArray
					 arrayWithCapacity:
					   [toManyObjects count]];
		      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"rel 1", name);

		      enumerator = [toManyObjects objectEnumerator];
		      while ((toManyObj = [enumerator nextObject]))
			{
			  toManyGID = [_editingContext globalIDForObject:
							 toManyObj];

			  [toManyGIDArray addObject:toManyGID];


			  if ([toManySnapshot containsObject:toManyGID] == NO)
			    {
			      [newToManySnapshot addObject:toManyGID];

			      for (h=0; h<count; h++)
				{
				  join = [joins objectAtIndex:h];
				  joinName = [[join sourceAttribute] name];

				  value = [snapshot objectForKey:joinName];

				  if (value)
				    [row setObject:value
					 forKey:joinName];
				  else
				    NSLog(@"warning: key name=%@ in entity=%@ not found in object %@", joinName, [entity name], object);
				}

			      if ([self ownsObject:toManyObj] == YES)
				{
				  EODatabaseOperation *dbOp;

				  dbOp = [self _dbOperationWithGlobalID:gid
					       object:object
					       entity:entity
					       operator:
						 EODatabaseUpdateOperator];

				  [[dbOp newRow] addEntriesFromDictionary:row];
				}
			      else
				{
				  [_coordinator
				    forwardUpdateForObject:toManyObj
				    changes:row];
				}
			    }
			  else
			    [toManySnapshot removeObject:toManyGID];
			}

		      [op recordToManySnapshot:toManyGIDArray
			  relationshipName:name];

#if 0 // TODO we have to clear foreign keys of a removed object ?

		      enumerator = [toManySnapshot objectEnumerator];
		      while ((toManyGID = [enumerator nextObject]))
			{
			}
#endif
		    }
		  else
		    {
//IN relayAttributesInRelationship:sourceObject:destinationObject:

		      [[op newRow] addEntriesFromDictionary:row];
		    }
		}
*/

/*
#if 0
	  countProp = [classProperties count];
	  for (i=0; i<countProp; i++)
	    {
	      NSString *name;

	      property = [classProperties objectAtIndex:i];

	      if ([property isKindOfClass:[EOAttribute class]])
		{
		  name = [(EOAttribute *)property name];

		  if ([property isFlattened] == YES)
		    {
		    }
		}
	    }
#endif

*/
                }
            }
        }
    }

////FIN


// TODO
/*
  NSArray *changedObjects;
  NSArray *classProperties;
  NSEnumerator *objsEnum, *enumerator;
  EOEntity *entity;
  EODatabaseOperation *op;
  EOGlobalID *gid;
  int i, countProp;
  id object, property;

  NSDictionary *snapshot;
  EONull *null = [EONull null];

  changedObjects = [_editingContext updatedObjects];
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"*r* %@", changedObjects);
  objsEnum = [changedObjects objectEnumerator];
  while ((object = [objsEnum nextObject]))
    {
      if ([self ownsObject:object] == YES)
	{
	  entity = [_database entityForObject:object];
	  gid = [_editingContext globalIDForObject:object];
	
	  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object = %@", object);
//OK done
	  op = [self _dbOperationWithGlobalID:gid
		     object:object
		     entity:entity
		     operator:EODatabaseUpdateOperator];
///
	  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object2");

	  snapshot = [op newRow];

	  classProperties = [entity classProperties];

	  countProp = [classProperties count];
	  for (i=0; i<countProp; i++)
	    {
	      NSString *name;

	      property = [classProperties objectAtIndex:i];

	      if ([property isKindOfClass:[EORelationship class]])
		{

	    }
	}
    }
*/
/*
//OK done
  changedObjects = [_editingContext deletedObjects];

  objsEnum = [changedObjects objectEnumerator];
  while ((object = [objsEnum nextObject]))
  {
    if ([self ownsObject:object] == YES)
      {
	entity = [_database entityForObject:object];
	gid = [_editingContext globalIDForObject:object];
// Turbocat
 		if (gid && ([gid isTemporary] == NO)) {
	op = [self _dbOperationWithGlobalID:gid
		   object:object
		   entity:entity
		   operator:EODatabaseDeleteOperator];
}
      }
  }
*/

  EOFLOGObjectFnStop();
}

/** Contructs a list of EODatabaseOperations for all changes in the EOEditingContext
that are owned by this context.  Forward any relationship changes discovered
but not owned by this context to the coordinator.
**/
- (void)recordUpdateForObject: (id)object
                      changes: (NSDictionary *)changes
{
  //OK
  EODatabaseOperation *dbOpe = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%@", object);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"changes=%@", changes);

  [self _assertValidStateWithSelector:
	  @selector(recordUpdateForObject:changes:)];

  dbOpe = [self databaseOperationForObject: object];
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p dbOpe=%@",
                        object,dbOpe);

  [dbOpe setDatabaseOperator:EODatabaseUpdateOperator];
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p dbOpe=%@",
                        object,dbOpe);

  if ([changes count])
    {
      [[dbOpe newRow] addEntriesFromDictionary: changes];

      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p dbOpe=%@",
                            object,dbOpe);
    }

  EOFLOGObjectFnStop();
}

-(void)recordInsertForObject: (id)object
{
  NSDictionary *snapshot = nil;
  EODatabaseOperation *dbOpe = nil;

  EOFLOGObjectFnStart();

  dbOpe = [self databaseOperationForObject: object];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p dbOpe=%@", 
                        object,dbOpe);

  [dbOpe setDatabaseOperator: EODatabaseInsertOperator];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p dbOpe=%@", 
                        object, dbOpe);

  snapshot = [dbOpe dbSnapshot]; //TODO: sowhat
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p snapshot=%@", 
                        object, snapshot);

//call snapshot count

  EOFLOGObjectFnStop();
}

- (void) recordDeleteForObject: (id)object
{
  NSDictionary *snapshot = nil;
  EODatabaseOperation *dbOpe = nil;

  EOFLOGObjectFnStart();

  dbOpe = [self databaseOperationForObject: object];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

  [dbOpe setDatabaseOperator: EODatabaseDeleteOperator];
  snapshot = [dbOpe dbSnapshot]; //TODO: sowhat

  EOFLOGObjectFnStop();
}

/** Constructs EOAdaptorOperations for all EODatabaseOperations constructed in
during recordChangesInEditingContext and recordUpdateForObject:changes:.
Performs the EOAdaptorOperations on an available adaptor channel.
If the save is OK, updates the snapshots in the EODatabaseContext to reflect
the new state of the server.
Raises an exception is the adaptor is unable to perform the operations.
**/
- (void)performChanges
{
  NSMapEnumerator dbOpeEnum;
  EOGlobalID *gid = nil;
  EODatabaseOperation *dbOpe = nil;
  NSArray *orderedAdaptorOperations = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext",
			@"self=%p preparingForSave=%d beganTransaction=%d",
			self,
			(int)_flags.preparingForSave,
			(int)_flags.beganTransaction);

  [self _assertValidStateWithSelector: @selector(performChanges)];

  dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);

  while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid, (void **)&dbOpe))
    {
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

      //REVOIR
      if ([dbOpe databaseOperator] == EODatabaseNothingOperator)
        {
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"Db Ope %@ for Nothing !!!",
				dbOpe);
        }
      else
        {
          [self _verifyNoChangesToReadonlyEntity: dbOpe];
          //MIRKO snapshot = [op dbSnapshot];
          [self createAdaptorOperationsForDatabaseOperation: dbOpe];
        }
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"orderedAdaptorOperations A=%@",
			orderedAdaptorOperations);

  orderedAdaptorOperations = [self orderAdaptorOperations];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"orderedAdaptorOperations B=%@",
			orderedAdaptorOperations);
  EOFLOGObjectLevelArgs(@"EODatabaseContext",
			@"self=%p preparingForSave=%d beganTransaction=%d",
			self,
			(int)_flags.preparingForSave,
			(int)_flags.beganTransaction);

  if ([orderedAdaptorOperations count] > 0)
    {
      EOAdaptorChannel *adaptorChannel = nil;
      EODatabaseChannel *dbChannel = [self _obtainOpenChannel];

      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"self=%p preparingForSave=%d beganTransaction=%d",
			    self,
			    (int)_flags.preparingForSave,
			    (int)_flags.beganTransaction);                   

      if (_flags.beganTransaction == NO)//MIRKO
	{
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"self=%p [_adaptorContext transactionNestingLevel]=%d",
				self,
				(int)[_adaptorContext transactionNestingLevel]);

          if ([_adaptorContext transactionNestingLevel] == 0) //??
            [_adaptorContext  beginTransaction];

          EOFLOGObjectLevel(@"EODatabaseContext",
			    @"BEGAN TRANSACTION FLAG==>YES");

	  _flags.beganTransaction = YES;
        }

      adaptorChannel = [dbChannel adaptorChannel];

      if (_delegateRespondsTo.willPerformAdaptorOperations == YES)
	orderedAdaptorOperations = [_delegate databaseContext: self
                                              willPerformAdaptorOperations:
						orderedAdaptorOperations
                                              adaptorChannel: adaptorChannel];
      NS_DURING
        {
          EOFLOGObjectLevel(@"EODatabaseContext",
			    @"performAdaptorOperations:");
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"self=%p preparingForSave=%d beganTransaction=%d",
				self,
				(int)_flags.preparingForSave,
				(int)_flags.beganTransaction);

          [adaptorChannel performAdaptorOperations: orderedAdaptorOperations];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"self=%p preparingForSave=%d beganTransaction=%d",
				self,
				(int)_flags.preparingForSave,
				(int)_flags.beganTransaction);
          EOFLOGObjectLevel(@"EODatabaseContext",
			    @"after performAdaptorOperations:");
        }
      NS_HANDLER
	{
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"Exception in performAdaptorOperations:%@",
				localException);
          [localException raise];
          //MIRKO
          //TODO
          /*
            NSException *exp;
            NSMutableDictionary *userInfo;
            EOAdaptorOperation *adaptorOp;

            userInfo = [NSMutableDictionary dictionaryWithCapacity:10];
            [userInfo addEntriesFromDictionary:[localException userInfo]];
            [userInfo setObject:self forKey:EODatabaseContextKey];
            [userInfo setObject:dbOps
            forKey:EODatabaseOperationsKey];

            adaptorOp = [userInfo objectForKey:EOFailedAdaptorOperationKey];

            dbEnum = [dbOps objectEnumerator];
            while ((op = [dbEnum nextObject]))
	    if ([[op adaptorOperations] containsObject:adaptorOp] == YES)
            {
            [userInfo setObject:op
            forKey:EOFailedDatabaseOperationKey];
            break;
            }

            exp = [NSException exceptionWithName:EOGeneralDatabaseException
            reason:[NSString stringWithFormat:
            @"%@ -- %@ 0x%x: failed with exception name:%@ reason:\"%@\"", 
            NSStringFromSelector(_cmd),
            NSStringFromClass([self class]),
            self, [localException name],
            [localException reason]]
            userInfo:userInfo];

            [exp raise];
          */
	}
      NS_ENDHANDLER;
    
//This is not done by mirko:
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"self=%p preparingForSave=%d beganTransaction=%d",
			    self,
			    (int)_flags.preparingForSave,
			    (int)_flags.beganTransaction);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"self=%p _uniqueStack %p=%@",
			    self, _uniqueStack, _uniqueStack);

      dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);

      while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
				     (void **)&dbOpe))
        {
          EODatabaseOperator databaseOperator = EODatabaseNothingOperator;

          //call dbOpe adaptorOperations ?
          if ([dbOpe databaseOperator] == EODatabaseNothingOperator)
            {
              EOFLOGObjectLevelArgs(@"EODatabaseContext",
				    @"Db Ope %@ for Nothing !!!", dbOpe);
            }
          else
            {
              EOEntity *entity = nil;
              NSArray *dbSnapshotKeys = nil;
              NSMutableDictionary *newRow = nil;
              NSDictionary *values = nil;
              id object = nil;
              NSArray *adaptorOpe = nil;

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

              object = [dbOpe object];
              adaptorOpe = [dbOpe adaptorOperations];
              databaseOperator = [dbOpe databaseOperator];
              entity = [dbOpe entity];
              dbSnapshotKeys = [entity dbSnapshotKeys];

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbSnapshotKeys=%@",
				    dbSnapshotKeys);

              newRow = [dbOpe newRow];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow=%@",
				    newRow);

              values = [newRow valuesForKeys: dbSnapshotKeys];
              EOFLOGObjectLevelArgs(@"EODatabaseContext",
				    @"RECORDSNAPSHOT values=%@", values);
              //if update: forgetSnapshotForGlobalID:

              [self recordSnapshot: values
                    forGlobalID: gid];
              EOFLOGObjectLevelArgs(@"EODatabaseContext",
				    @"self=%p _uniqueStack %p=%@",
				    self, _uniqueStack, _uniqueStack);

              if (databaseOperator == EODatabaseUpdateOperator) //OK for update //Do it forInsert too //TODO
                {
                  NSDictionary *toManySnapshots = [dbOpe toManySnapshots];

                  if (toManySnapshots)
                    {
                      NSDebugMLog(@"toManySnapshots=%@", toManySnapshots);
                      NSEmitTODO();

                      //TODONOW [self notImplemented: _cmd]; //TODO
                    }
                }
            }
        }
    }

  EOFLOGObjectFnStop();
}

- (void)commitChanges
{
  BOOL doIt = NO;
  NSMutableArray *deletedObjects = [NSMutableArray array];
  NSMutableArray *insertedObjects = [NSMutableArray array];
  NSMutableArray *updatedObjects = [NSMutableArray array];
  NSMutableDictionary *gidChangedUserInfo = nil;

  EOFLOGObjectFnStart();
  [self _assertValidStateWithSelector: @selector(commitChanges)];

  //REVOIR: don't do it if no adaptor ope
  {
      NSMapEnumerator dbOpeEnum;
      EOGlobalID *gid = nil;
      EODatabaseOperation *dbOpe = nil;
      dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);

      while (!doIt && NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
					      (void **)&dbOpe))
        {
          doIt = ([dbOpe adaptorOperations] != nil);
        }
  }

  if (doIt)
    {
      if (_flags.beganTransaction != YES)//it is not set here in WO
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
      else if ([_adaptorContext transactionNestingLevel] == 0)
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
      else 
        {
          NSMapEnumerator dbOpeEnum;
          EOGlobalID *gid = nil;
          EODatabaseOperation *dbOpe = nil;

          EOFLOGObjectLevel(@"EODatabaseContext",
			    @"BEGAN TRANSACTION FLAG==>NO");

          _flags.beganTransaction = NO;
          [_adaptorContext commitTransaction]; //adaptorcontext transactionDidCommit

          dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);
          while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
					 (void **)&dbOpe))
            {
              EODatabaseOperator databaseOperator = EODatabaseNothingOperator;
              EOGlobalID *dbOpeGID = nil;
              EOGlobalID *newGID = nil;
              EOEntity *entity = nil;

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

              [EOObserverCenter suppressObserverNotification];

              NS_DURING
                {
                  databaseOperator = [dbOpe databaseOperator];
                  entity = [dbOpe entity];

                  if (databaseOperator == EODatabaseInsertOperator
                     || databaseOperator == EODatabaseUpdateOperator)//OK for update
                    {
                      id object = nil;
                      NSDictionary *newRowValues = nil;
                      //gid isTemporary
                      NSDictionary *primaryKeyDiffs = [dbOpe primaryKeyDiffs];//OK for update

                      if (primaryKeyDiffs)
                        {
                          NSEmitTODO();
                          NSAssert3(NO,@"primaryKeyDiffs=%@ dbOpe=%@ object=%@",
                                    primaryKeyDiffs,dbOpe,[dbOpe object]); //TODO: if primaryKeyDiffs
                        }

                      if (databaseOperator == EODatabaseInsertOperator)
                        {
                          NSArray *classPropertyAttributeNames =
			    [entity classPropertyAttributeNames];
                          NSDictionary *newRow = [dbOpe newRow];

                          newRowValues = [newRow valuesForKeys:
						   classPropertyAttributeNames];

                          //TODO REVOIR !!
                          newGID = [entity globalIDForRow: newRow
					   isFinal: YES];
                        }
                      else
                        {
                          NSArray *classPropertyAttributes = [entity _classPropertyAttributes];//OK for update

                          newRowValues = [dbOpe rowDiffsForAttributes: classPropertyAttributes];//OK for update
                        }

                      object = [dbOpe object];//OK for update 
                      [object takeStoredValuesFromDictionary: newRowValues];//OK for update 

                      /*mirko instead:
                        [object takeStoredValuesFromDictionary:
                        [op rowDiffsForAttributes:attributes]];
                    
                        EOFLOGObjectLevelArgs(@"EODatabaseContext",@"-_+ %@ # %@", gid, object);
                        EOFLOGObjectLevelArgs(@"EODatabaseContext",@"-_* %@", [op newRow]);
                        [_database recordSnapshot:[op newRow]
                        forGlobalID:gid];
                
                        toManySnapshots = [op toManySnapshots];
                        toManyEnum = [toManySnapshots keyEnumerator];
                        while ((key = [toManyEnum nextObject]))
                        [_database recordSnapshot:[toManySnapshots objectForKey:key]
                        forSourceGlobalID:gid
                        relationshipName:key];
                      */
                    }
                }
              NS_HANDLER
                {
                  [EOObserverCenter enableObserverNotification];

                  NSLog(@"EXCEPTION %@", localException);
                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"EXCEPTION %@",
					localException);

                  [localException raise];
                }
              NS_ENDHANDLER;

              [EOObserverCenter enableObserverNotification];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

              dbOpeGID = [dbOpe globalID]; //OK for update 
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpeGID=%@",
				    dbOpeGID);

              switch (databaseOperator)
                {
                case EODatabaseInsertOperator:
                  [insertedObjects addObject: dbOpeGID];

                  if (!gidChangedUserInfo)
                    gidChangedUserInfo = (NSMutableDictionary *)
		      [NSMutableDictionary dictionary];

                  [gidChangedUserInfo setObject: newGID
                                      forKey: dbOpeGID]; //[_editingContext globalIDForObject:object]];
                  break;

                case EODatabaseDeleteOperator:
                  [deletedObjects addObject: dbOpeGID];
                  [_database forgetSnapshotForGlobalID: dbOpeGID]; //Mirko/??
                  break;

                case EODatabaseUpdateOperator:
                  [updatedObjects addObject: dbOpeGID];
                  break;

                case EODatabaseNothingOperator:
                  break;
                }
            }
        }
    }

  EOFLOGObjectLevel(@"EODatabaseContext", @"call _cleanUpAfterSave");

  [self _cleanUpAfterSave];//OK for update

  if (doIt)
    {
      //from mirko. seems ok
      if (gidChangedUserInfo)
        {
          EOFLOGObjectLevel(@"EODatabaseContext",
			    @"post EOGlobalIDChangedNotification");

          [[NSNotificationCenter defaultCenter]
            postNotificationName: EOGlobalIDChangedNotification
            object: nil
            userInfo: gidChangedUserInfo];
        }

      EOFLOGObjectLevel(@"EODatabaseContext",
			@"post EOObjectsChangedInStoreNotification");

      [[NSNotificationCenter defaultCenter]
	postNotificationName: @"EOObjectsChangedInStoreNotification"
	object: _database
	userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
				  deletedObjects, @"deleted",
				insertedObjects, @"inserted",
				updatedObjects, @"updated",
				nil, nil]]; //call self _snapshotsChangedInDatabase:
    }

  EOFLOGObjectFnStop();
}

- (void)rollbackChanges
{ // TODO
//adaptorcontext transactionNestingLevel
//if 0 ? _cleanUpAfterSave
  EOFLOGObjectFnStart();

  if (_flags.beganTransaction == YES)
    {
      [_adaptorContext rollbackTransaction];

      EOFLOGObjectLevel(@"EODatabaseContext",
			@"BEGAN TRANSACTION FLAG==>NO");

      _flags.beganTransaction = NO;

      _numLocked = 0;
      _lockedObjects = NSZoneRealloc(NULL, _lockedObjects,
				     _LOCK_BUFFER*sizeof(id));

      NSResetMapTable(_dbOperationsByGlobalID);
/*//TODO
      [_snapshots removeAllObjects];
      [_toManySnapshots removeAllObjects];
*/
    }

  EOFLOGObjectFnStop();
}

- (NSDictionary *)valuesForKeys: (NSArray *)keys
                         object: (id)object
{
  //OK
  EOEntity *entity;
  EODatabaseOperation *dbOpe;
  NSDictionary *newRow;
  NSDictionary *values = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p keys=%@",
                        object, keys);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p (class=%@)",
			object, [object class]);

  //NSAssert(object, @"No object");

  if (!isNilOrEONull(object))
    {
      entity = [_database entityForObject: object];

      NSAssert1(entity, @"No entity for object %@", object);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity name=%@",
			    [entity name]);

      dbOpe = [self databaseOperationForObject: object];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%p", dbOpe);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

      newRow = [dbOpe newRow];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow=%p", newRow);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow=%@", newRow);

      values = [newRow valuesForKeys: keys];
    }
  else
    {
      EOFLOGObjectLevel(@"EODatabaseContext", @"No object");
      values = [NSDictionary dictionary];
    }

//  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"values=%@", values);

  EOFLOGObjectFnStop();

  return values;
}

-(void)nullifyAttributesInRelationship: (EORelationship*)relationship
                          sourceObject: (id)sourceObject
                     destinationObject: (id)destinationObject
{
  EODatabaseOperation *sourceDBOpe = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
			relationship);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceObject=%@",
			sourceObject);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationObject=%@",
			destinationObject);

  if (destinationObject)
    {
      //Get SourceObject database operation
      sourceDBOpe = [self databaseOperationForObject: sourceObject]; //TODO: useIt

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceDBOpe=%@",
			    sourceDBOpe);

      if ([relationship isToManyToOne])
        {
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
      else
        {
          // Key a dictionary of two array: destinationKeys and sourceKeys
          NSDictionary *sourceToDestinationKeyMap =
	    [relationship _sourceToDestinationKeyMap]; //{destinationKeys = (customerCode); sourceKeys = (code); }
          BOOL foreignKeyInDestination = [relationship foreignKeyInDestination];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"sourceToDestinationKeyMap=%@",
                                sourceToDestinationKeyMap);
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"foreignKeyInDestination=%d",
                                foreignKeyInDestination);

          if (foreignKeyInDestination)
            {
              NSArray *destinationKeys = [sourceToDestinationKeyMap
					   objectForKey: @"destinationKeys"];//(customerCode) 
              int i, destinationKeysCount = [destinationKeys count];
              NSMutableDictionary *changes = [NSMutableDictionary dictionaryWithCapacity: destinationKeysCount];
              id null = [EONull null];

              for (i = 0 ;i < destinationKeysCount; i++)
                {
                  id destinationKey = [destinationKeys objectAtIndex: i];

                  [changes setObject: null
                           forKey: destinationKey];
                }

              [self recordUpdateForObject: destinationObject
                    changes: changes];
            }
          else
            {
              //Do nothing ?
              NSEmitTODO();
              //[self notImplemented: _cmd]; //TODO
            }
        }
    }
}

- (void)nullifyAttributesInRelationship: (EORelationship*)relationship
			   sourceObject: (id)sourceObject
		     destinationObjects: (NSArray*)destinationObjects
{
  int destinationObjectsCount = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@", relationship);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceObject=%@", sourceObject);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationObjects=%@", destinationObjects);

  destinationObjectsCount = [destinationObjects count];

  if (destinationObjectsCount > 0)
    {
      int i;

      for (i = 0; i < destinationObjectsCount; i++)
        {
          id object = [destinationObjects objectAtIndex: i];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"destinationObject %p=%@ (class %@)",
				object, object, [object class]);

          [self nullifyAttributesInRelationship: relationship
                sourceObject: sourceObject
                destinationObject: object];
        }
    }

  EOFLOGObjectFnStop();
}

- (void)relayAttributesInRelationship: (EORelationship*)relationship
			 sourceObject: (id)sourceObject
		   destinationObjects: (NSArray*)destinationObjects
{
  int destinationObjectsCount = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@", relationship);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceObject=%@", sourceObject);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationObjects=%@", destinationObjects);

  destinationObjectsCount = [destinationObjects count];

  if (destinationObjectsCount > 0)
    {
      int i;

      for (i = 0; i < destinationObjectsCount; i++)
        {
          id object = [destinationObjects objectAtIndex: i];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",@"destinationObject %p=%@ (class %@)",
                                object,object,[object class]);

          [self relayAttributesInRelationship: (EORelationship*)relationship
                                 sourceObject: (id)sourceObject
                            destinationObject: object];
        }
    }

  EOFLOGObjectFnStop();
}

- (NSDictionary*)relayAttributesInRelationship: (EORelationship*)relationship
                                  sourceObject: (id)sourceObject
			     destinationObject: (id)destinationObject
{
  //OK
  NSMutableDictionary *relayedValues = nil;
  EODatabaseOperation *sourceDBOpe = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"relationship=%@",
                        relationship);
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"sourceObject %p=%@ (class=%@)",
                        sourceObject,sourceObject,[sourceObject class]);
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"destinationObject %p=%@ (class=%@)",
                        destinationObject,destinationObject,[destinationObject class]);

  //Get SourceObject database operation
  sourceDBOpe = [self databaseOperationForObject: sourceObject];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceDBOpe=%@", sourceDBOpe);

  if ([sourceDBOpe databaseOperator] == EODatabaseNothingOperator)
    {
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"Db Ope %@ for Nothing !!!", sourceDBOpe);
    }

  if ([relationship isToManyToOne])
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }
  else
    {
      // Key a dictionary of two array: destinationKeys and sourceKeys
      NSDictionary *sourceToDestinationKeyMap = [relationship _sourceToDestinationKeyMap];//{destinationKeys = (customerCode); sourceKeys = (code); } 
      NSArray *destinationKeys = [sourceToDestinationKeyMap
				   objectForKey: @"destinationKeys"];//(customerCode) 
      NSArray *sourceKeys = [sourceToDestinationKeyMap
			      objectForKey: @"sourceKeys"];//(code)
      NSMutableDictionary *sourceNewRow = [sourceDBOpe newRow];//OK in foreignKeyInDestination
      BOOL foreignKeyInDestination = [relationship foreignKeyInDestination];
      int i, count;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
			    relationship);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"sourceToDestinationKeyMap=%@",
			    sourceToDestinationKeyMap);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationKeys=%@",
			    destinationKeys);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceKeys=%@",
			    sourceKeys);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceNewRow=%@",
			    sourceNewRow);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"foreignKeyInDestination=%s",
			    (foreignKeyInDestination ? "YES" : "NO"));

      NSAssert([destinationKeys count] == [sourceKeys count],
               @"destination keys count!=source keys count");

      if (foreignKeyInDestination || [relationship propagatesPrimaryKey])
        {
          relayedValues = [[[sourceNewRow valuesForKeys: sourceKeys]
			     mutableCopy] autorelease];// {code = 0; }
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relayedValues=%@",
				relayedValues);

          count = [relayedValues count];

          for (i = 0; i < count; i++)
            {
              NSString *sourceKey = [sourceKeys objectAtIndex: i];
              NSString *destKey = [destinationKeys objectAtIndex: i];
              id sourceValue = [relayedValues objectForKey: sourceKey];

	      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceKey=%@",
				    sourceKey);
	      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destKey=%@",
				    destKey);
	      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceValue=%@",
				    sourceValue);

	      [relayedValues removeObjectForKey: sourceKey];
	      [relayedValues setObject: sourceValue
			     forKey: destKey];
            }

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relayedValues=%@",
				relayedValues);

          [self recordUpdateForObject: destinationObject
                changes: relayedValues];
        }
      else
        {
          //Verify !!
          NSDictionary *destinationValues;

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"Call valuesForKeys destinationObject %p (class %@)",
				destinationObject, [destinationObject class]);
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationKeys=%@",
				destinationKeys);
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
				relationship);
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceKeys=%@",
				sourceKeys);

          //Now take destinationKeys values
          destinationValues = [self valuesForKeys: destinationKeys
				    object: destinationObject];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationValues=%@",
				destinationValues);
          //And put these values for source keys in the return object (sourceValues)

          count = [destinationKeys count];
          relayedValues = (NSMutableDictionary*)[NSMutableDictionary dictionary];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relayedValues=%@",
				relayedValues);

          for (i = 0; i < count; i++)
            {
              id destinationKey = [destinationKeys objectAtIndex: i];
              id sourceKey = [sourceKeys objectAtIndex: i];
              id destinationValue = [destinationValues
				      objectForKey: destinationKey];

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destinationKey=%@",
				    destinationKey);
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"sourceKey=%@",
				    sourceKey);
              EOFLOGObjectLevelArgs(@"EODatabaseContext",
				    @"destinationValue=%@", destinationValue);

              if (!isNilOrEONull(destinationValue))//?? or always
                [relayedValues setObject: destinationValue
                               forKey: sourceKey];
            }
          //Put these values in source object database ope new row
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relayedValues=%@",
				relayedValues);

          [sourceNewRow takeValuesFromDictionary: relayedValues];
        }
    }

  if ([sourceDBOpe databaseOperator] == EODatabaseNothingOperator)
    {
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"Db Ope %@ for Nothing !!!", sourceDBOpe);
    }

  EOFLOGObjectFnStop();

  return relayedValues;
//Mirko Code:
/*
		      NSMutableArray *keys;
		      NSDictionary *values;
		      EOGlobalID *relationshipGID;
		      id objectTo;

		      objectTo = [object storedValueForKey:name];
		      relationshipGID = [_editingContext
					  globalIDForObject:objectTo];
		      if ([self ownsObject:objectTo] == YES)
			{
			  for (h=0; h<count; h++)
			    {
			      join = [joins objectAtIndex:h];

			      value = [objectTo
					storedValueForKey:
					  [[join destinationAttribute] name]];

			      if (value == nil)
				value = null;

			      [row setObject:value
				   forKey:[[join sourceAttribute] name]];
			    }
#if 0
			  inverse = [property inverseRelationship];
			  if (inverse)
			    {
			      toManySnapshot = [[[self snapshotForSourceGlobalID:gid
						       relationshipName:[inverse name]]
						  mutableCopy] autorelease];
			      if (toManySnapshot == nil)
				toManySnapshot = [NSMutableArray array];

			      [toManySnapshot addObject:gid];

			      [op recordToManySnapshot:toManySnapshot
				  relationshipName:name];
			    }
#endif
			}
		      else
			{
			  keys = [NSMutableArray arrayWithCapacity:count];

			  for (h=0; h<count; h++)
			    {
			      join = [joins objectAtIndex:h];
			      [keys addObject:[[join destinationAttribute]
						name]];
			    }

			  values = [_coordinator valuesForKeys:keys
						 object:objectTo];

			  for (h=0; h<count; h++)
			    {
			      join = [joins objectAtIndex:h];

			      value = [values
					objectForKey:
					  [[join destinationAttribute] name]];

			      if (value == nil)
				value = null;

			      [row setObject:value
				   forKey:[[join sourceAttribute] name]];
			    }
			}
*/
  EOFLOGObjectFnStop();
};

- (void)recordDatabaseOperation: (EODatabaseOperation*)databaseOpe
{
  //OK
  EOGlobalID *gid = nil;

  EOFLOGObjectFnStart();

  NSAssert(databaseOpe, @"No database operation");

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"databaseOpe=%@", databaseOpe);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_dbOperationsByGlobalID=%p",
			_dbOperationsByGlobalID);

  if (_dbOperationsByGlobalID)
    {
//      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"_dbOperationsByGlobalID=%@",NSStringFromMapTable(_dbOperationsByGlobalID));
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_dbOperationsByGlobalID=%@",
			    [NSDictionary dictionaryWithObjects:
					    NSAllMapTableValues(_dbOperationsByGlobalID)
					  forKeys:
					    NSAllMapTableKeys(_dbOperationsByGlobalID)]);

      /*
        // doesn't do this so some db operation are not recorded (when selecting objects)
        if (!_dbOperationsByGlobalID)
        _dbOperationsByGlobalID = NSCreateMapTable(NSObjectMapKeyCallBacks, 
        NSObjectMapValueCallBacks,
        32);
      */
      gid = [databaseOpe globalID];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

      NSMapInsert(_dbOperationsByGlobalID, gid, databaseOpe);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"_dbOperationsByGlobalID=%p",
			    _dbOperationsByGlobalID);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_dbOperationsByGlobalID=%@",
			    [NSDictionary dictionaryWithObjects:
					    NSAllMapTableValues(_dbOperationsByGlobalID)
					  forKeys:
					    NSAllMapTableKeys(_dbOperationsByGlobalID)]);
    }
  else
    {
      EOFLOGObjectLevel(@"EODatabaseContext",
			@"No _dbOperationsByGlobalID");
    }

  EOFLOGObjectFnStop();
}

- (EODatabaseOperation*)databaseOperationForGlobalID: (EOGlobalID*)gid
{
  //OK
  EODatabaseOperation *dbOpe = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_dbOperationsByGlobalID=%p",
			_dbOperationsByGlobalID);

  if (_dbOperationsByGlobalID)
    {
//      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"_dbOperationsByGlobalID=%@",NSStringFromMapTable(_dbOperationsByGlobalID));
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_dbOperationsByGlobalID=%@",
			    [NSDictionary dictionaryWithObjects:
					    NSAllMapTableValues(_dbOperationsByGlobalID)
					  forKeys:
					    NSAllMapTableKeys(_dbOperationsByGlobalID)]);

      dbOpe = (EODatabaseOperation*)NSMapGet(_dbOperationsByGlobalID,
					     (const void*)gid);

      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"dbOpe=%@",
                            dbOpe);
    }

  EOFLOGObjectFnStop();

  return dbOpe;
}

- (EODatabaseOperation*)databaseOperationForObject: (id)object
{
   //OK
   EODatabaseOperation *databaseOpe = nil;
   EOGlobalID *gid = nil;

   EOFLOGObjectFnStart();

   NS_DURING // for trace purpose
     {
       EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%@", object);

       if ([object isKindOfClass: [EOGenericRecord class]])
	 EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dictionary=%@ ",
			       [object debugDictionaryDescription]);

       gid = [self _globalIDForObject: object]; //OK
       EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

       databaseOpe = [self databaseOperationForGlobalID: gid]; //OK
       EOFLOGObjectLevelArgs(@"EODatabaseContext", @"databaseOpe=%@",
			     databaseOpe);

       if (!databaseOpe)//OK
         {
           NSDictionary *snapshot = nil;
           NSArray *classPropertyNames = nil;
           NSArray *dbSnapshotKeys = nil;
           int i = 0;
           int propNamesCount = 0;
           int snapKeyCount = 0;
           NSMutableDictionary *row = nil;
           NSMutableDictionary *newRow = nil;
           EOEntity *entity = nil;
           NSArray *primaryKeyAttributes = nil;

           entity = [_database entityForObject: object]; //OK
           EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity name=%@",
				 [entity name]);

           primaryKeyAttributes = [entity primaryKeyAttributes]; //OK

           EOFLOGObjectLevelArgs(@"EODatabaseContext",
				 @"primaryKeyAttributes=%@",
				 primaryKeyAttributes);

           databaseOpe = [EODatabaseOperation
			   databaseOperationWithGlobalID: gid
			   object: object
			   entity: entity]; //OK

           EOFLOGObjectLevelArgs(@"EODatabaseContext",
				 @"CREATED databaseOpe=%@\nfor object %p %@",
				 databaseOpe, object, object);

           snapshot = [self snapshotForGlobalID: gid];//OK
           EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot %p=%@",
				 snapshot, snapshot);

           if (!snapshot)
             snapshot = [NSDictionary dictionary];

           [databaseOpe setDBSnapshot: snapshot];
           EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p databaseOpe=%@",
                                 object,databaseOpe);

           classPropertyNames = [entity classPropertyNames]; //OK  (code, a3code, numcode, toLabel)
           EOFLOGObjectLevelArgs(@"EODatabaseContext",
				 @"classPropertyNames=%@", classPropertyNames);

           propNamesCount = [classPropertyNames count];
           EOFLOGObjectLevelArgs(@"EODatabaseContext", @"propNamesCount=%d",
				 (int)propNamesCount);

           //TODO: rewrite code: don't use temporary "row"
           row = (NSMutableDictionary*)[NSMutableDictionary dictionary];
           EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object %p (class %@)=%@ ",
                                 object,[object class],object);

           /*if ([object isKindOfClass: [EOGenericRecord class]])
	     EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dictionary=%@ ",
	     [object debugDictionaryDescription]);*/

           for (i = 0; i < propNamesCount; i++)
             {
               id value = nil;
               NSString *key = [classPropertyNames objectAtIndex: i];

               EOFLOGObjectLevelArgs(@"EODatabaseContext", @"key=%@", key);

               /*NO !! 
                 if ([attribute isKindOfClass:[EOAttribute class]] == NO)
                 continue;
                 // if ([attribute isFlattened] == NO)
                 */
               value = [object storedValueForKey: key]; //OK
               EOFLOGObjectLevelArgs(@"EODatabaseContext", @"key=%@ value=%@",
				     key, value);

               if (!value)
		 {
		   value = [EONull null];

		   [[[entity attributeNamed: key] validateValue: &value]
		     raise];
		 }

               EOFLOGObjectLevelArgs(@"EODatabaseContext", @"key=%@ value=%@",
				     key, value);

               [row setObject: value
                    forKey: key];
             }

           newRow = [[NSMutableDictionary alloc]
		       initWithDictionary: snapshot
		       copyItems: NO];

           EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow=%@", newRow);

           dbSnapshotKeys = [entity dbSnapshotKeys]; //OK (numcode, code, a3code)
           EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbSnapshotKeys=%@",
				 dbSnapshotKeys);

           snapKeyCount = [dbSnapshotKeys count];

           for (i = 0; i < snapKeyCount; i++)
             {
               id key = [dbSnapshotKeys objectAtIndex: i];
               id value = [row objectForKey: key]; //Really this key ?

               EOFLOGObjectLevelArgs(@"EODatabaseContext", @"key=%@ value=%@",
				     key, value);

	       //               NSAssert1(value,@"No value for %@",key);

	       if (value)
		 [newRow setObject: value
			 forKey: key];
             }

           EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow=%@", newRow);

           [databaseOpe setNewRow: newRow];
           [self recordDatabaseOperation: databaseOpe];
           [newRow release];
         }
    }
  NS_HANDLER
    {
      NSLog(@"EXCEPTION %@", localException);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"EXCEPTION %@",
			    localException);              

      [localException raise];
    }
  NS_ENDHANDLER;

  EOFLOGObjectFnStop();

  return databaseOpe;
}

- (void)relayPrimaryKey: (NSDictionary*)pk
           sourceObject: (id)sourceObject
	     destObject: (id)destObject
           relationship: (EORelationship*)relationship
{
  //OK
  NSDictionary *relayedAttributes = nil;
  EOEntity *destEntity = nil;
  NSArray *destAttributes = nil;
  NSArray *destAttributeNames = nil;
  NSDictionary *keyValues = nil;
  NSArray *values = nil;
  int i, count;
  BOOL nullPKValues = YES;

  EOFLOGObjectFnStart();

  destAttributes = [relationship destinationAttributes];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destAttributes=%@",
			destAttributes);

  destAttributeNames = [destAttributes resultsOfPerformingSelector:
					 @selector(name)];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"destAttributeNames=%@",
			destAttributeNames);

  keyValues = [self valuesForKeys: destAttributeNames
		    object: destObject];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"keyValues=%@", keyValues);

  values = [keyValues allValues];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"values=%@", values);

  //Now test if null values
  count = [values count];

  for (i = 0; nullPKValues && i < count; i++)
    nullPKValues = isNilOrEONull([values objectAtIndex:i]);

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"nullPKValues=%s",
			(nullPKValues ? "YES" : "NO"));

  if (nullPKValues)
    {
      relayedAttributes = [self relayAttributesInRelationship: relationship
				sourceObject: sourceObject
				destinationObject: destObject];

      destEntity = [relationship destinationEntity];

      [self relayPrimaryKey: relayedAttributes
            object: destObject
            entity: destEntity];
    }

  EOFLOGObjectFnStop();
}

- (void)relayPrimaryKey: (NSDictionary*)pk
		 object: (id)object
		 entity: (EOEntity*)entity
{
  //TODO finish
  NSArray *relationships = nil;
  NSArray *classPropertyNames = nil;
  EODatabaseOperation *dbOpe = nil;
  NSDictionary *dbSnapshot = nil;
  int i, count;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"pk=%@", pk);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%@", object);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity=%@", [entity name]);

  relationships = [entity relationships]; //OK
  classPropertyNames = [entity classPropertyNames];
  dbOpe = [self databaseOperationForObject: object];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

  dbSnapshot = [dbOpe dbSnapshot]; //OK
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbSnapshot=%@", dbSnapshot);

  count = [relationships count];

  for (i = 0; i < count; i++)
    {
      EORelationship *relationship = [relationships objectAtIndex: i];
      EORelationship *substRelationship = nil;
      BOOL propagatesPrimaryKey = NO;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
			    relationship);

      substRelationship = [relationship _substitutionRelationshipForRow:
					  dbSnapshot];
      propagatesPrimaryKey = [substRelationship propagatesPrimaryKey]; //substRelationship or relationship?

      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"object=%p relationship name=%@ ==> propagatesPrimaryKey=%s",
			    object,
			    [relationship name],
			    (propagatesPrimaryKey ? "YES" : "NO"));

      if (propagatesPrimaryKey)
        {
          NSString *relName = [substRelationship name]; //this one ??

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relName=%@", relName);

          if ([classPropertyNames containsObject: relName])
            {
              id value = nil;
              id snapshot = nil;
              id snapshotValue = nil;
              BOOL isToMany = NO;

              value = [object storedValueForKey: relName];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"value=%@", value);

              snapshot = [self _currentCommittedSnapshotForObject: object];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot=%@",
				    snapshot);

              snapshotValue = [snapshot objectForKey:relName];//ret nil
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshotValue=%@",
				    snapshotValue);

              isToMany = [substRelationship isToMany]; //this one ??
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"isToMany=%s",
				    (isToMany ? "YES" : "NO"));

              if (isToMany)
                {
                  int valueValuesCount = 0;
                  int iValueValue = 0;

                  value = [value shallowCopy];
                  valueValuesCount = [value count];
                  iValueValue = 0;

                  for (iValueValue = 0;
		       iValueValue < valueValuesCount;
		       iValueValue++)
                    {
                      id valueValue = [value objectAtIndex: iValueValue];

                      EOFLOGObjectLevelArgs(@"EODatabaseContext",
					    @"valueValue=%@", valueValue);

                      [self relayPrimaryKey: pk
                            sourceObject: object
                            destObject: valueValue
                            relationship: substRelationship]; //this one ??
                    }
                }
              else
                {
                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"value=%@",
					value);

                  [self relayPrimaryKey: pk
                        sourceObject: object
                        destObject: value
                        relationship: substRelationship]; //this one ??
                }
            }
        }
    }

  EOFLOGObjectFnStop();
}

- (void) createAdaptorOperationsForDatabaseOperation: (EODatabaseOperation*)dbOpe
                                          attributes: (NSArray*)attributes
{
  //NEAR OK
  BOOL isSomethingTodo = YES;
  EOEntity *entity = nil;
  EODatabaseOperator dbOperator = EODatabaseNothingOperator;
  NSDictionary *changedValues = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);
  NSAssert(dbOpe, @"No operation");

  entity = [dbOpe entity]; //OK
  dbOperator = [dbOpe databaseOperator]; //OK

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attributes=%@", attributes);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOperator=%d",
			(int)dbOperator);

  switch (dbOperator)
    {
    case EODatabaseUpdateOperator:
      {
        changedValues = [dbOpe rowDiffsForAttributes:attributes];

        EOFLOGObjectLevelArgs(@"EODatabaseContext", @"changedValues %p=%@",
			      changedValues, changedValues);

        if ([changedValues count] == 0)        
          isSomethingTodo = NO;
        else
          {
          }
      }
      break;

    case EODatabaseInsertOperator:
      {
        changedValues = [dbOpe newRow]; //OK

        EOFLOGObjectLevelArgs(@"EODatabaseContext", @"changedValues %p=%@",
			      changedValues, changedValues);
      }
      break;

    case EODatabaseDeleteOperator:
      {
        isSomethingTodo = YES;
      }
      break;

    case EODatabaseNothingOperator:
      {
        //Nothing!
      }
      break;

    default:
      {
        NSEmitTODO();
        //      [self notImplemented:_cmd]; //TODO
      }
      break;
    }

  if (isSomethingTodo)
    {
      EOAdaptorOperation *adaptorOpe = nil;
      NSString *procedureOpeName = nil;
      EOAdaptorOperator adaptorOperator = EOAdaptorUndefinedOperator;
      EOStoredProcedure *storedProcedure = nil;

      NSDictionary *valuesToWrite = nil;
      EOQualifier *lockingQualifier = nil;

      switch (dbOperator)
        {
        case EODatabaseUpdateOperator:
        case EODatabaseDeleteOperator:
          {
            NSArray *pkAttributes;
            NSArray *lockingAttributes;
            NSDictionary *dbSnapshot;

            pkAttributes = [self primaryKeyAttributesForAttributes: attributes
				 entity: entity];
            lockingAttributes = [self lockingAttributesForAttributes:
					attributes
				      entity: entity];

            dbSnapshot = [dbOpe dbSnapshot];
            lockingQualifier = [self qualifierForLockingAttributes:
				       lockingAttributes
				     primaryKeyAttributes: pkAttributes
				     entity: entity
				     snapshot: dbSnapshot];

            NSEmitTODO();

            //TODO=self lockingNonQualifiableAttributes:#####  ret nil
            EOFLOGObjectLevelArgs(@"EODatabaseContext", @"lockingQualifier=%@",
				  lockingQualifier);

            /*MIRKO for UPDATE:
              //TODO-NOW
              {
              if ([self isObjectLockedWithGlobalID:gid] == NO)
              {
              EOAdaptorOperation *lockOperation;
              EOQualifier *qualifier;
              EOAttribute *attribute;
              NSEnumerator *attrsEnum;
              NSArray *attrsUsedForLocking, *primaryKeyAttributes;
              NSMutableDictionary *qualifierSnapshot, *lockSnapshot;
              NSMutableArray *lockAttributes;
              
              lockOperation = [EOAdaptorOperation adaptorOperationWithEntity:
	      entity];
              
              attrsUsedForLocking = [entity attributesUsedForLocking];
              primaryKeyAttributes = [entity primaryKeyAttributes];
              
              qualifierSnapshot = [NSMutableDictionary
              dictionaryWithCapacity:16];
              lockSnapshot = [NSMutableDictionary dictionaryWithCapacity:8];
              lockAttributes = [NSMutableArray arrayWithCapacity:8];
              EOFLOGObjectLevelArgs(@"EODatabaseContext",@"lock start %@", snapshot);
              attrsEnum = [primaryKeyAttributes objectEnumerator];
              while ((attribute = [attrsEnum nextObject]))
              {
              NSString *name = [attribute name];
              EOFLOGObjectLevelArgs(@"EODatabaseContext",@" %@", name);
              [lockSnapshot setObject:[snapshot objectForKey:name]
              forKey:name];
              }
              EOFLOGObjectLevelArgs(@"EODatabaseContext",@"lock stop");
              
              EOFLOGObjectLevelArgs(@"EODatabaseContext",@"lock start2");
              attrsEnum = [attrsUsedForLocking objectEnumerator];
              while ((attribute = [attrsEnum nextObject]))
              {
              NSString *name = [attribute name];
              
              if ([primaryKeyAttributes containsObject:attribute] == NO)
                  {
                    if ([attribute adaptorValueType] == EOAdaptorBytesType)
                      {
                        [lockAttributes addObject:attribute];
                        [lockSnapshot setObject:[snapshot
                                                  objectForKey:name]
                                      forKey:name];
                      }
                    else
                      [qualifierSnapshot setObject:[snapshot
                                                     objectForKey:name]
                                         forKey:name];
                  }
              }
            EOFLOGObjectLevelArgs(@"EODatabaseContext",@"lock stop2");
            
            qualifier = [[[EOAndQualifier alloc]
                           initWithQualifiers:
                             [entity qualifierForPrimaryKey:
                                       [entity primaryKeyForGlobalID:
                                                 (EOKeyGlobalID *)gid]],
                           [EOQualifier qualifierToMatchAllValues:
                                          qualifierSnapshot],
                           nil]
                          autorelease];

                          if ([lockAttributes count] == 0)
                          lockAttributes = nil;
                          if ([lockSnapshot count] == 0)
                          lockSnapshot = nil;
                          
                          [lockOperation setAdaptorOperator:EOAdaptorLockOperator];
                          [lockOperation setQualifier:qualifier];
                          [lockOperation setAttributes:lockAttributes];
                          [lockOperation setChangedValues:lockSnapshot];
                          
                          EOFLOGObjectLevelArgs(@"EODatabaseContext",@"*+ %@", lockSnapshot);
                          [op addAdaptorOperation:lockOperation];
                          }
            */
          }
          break;

	case EODatabaseInsertOperator:
	  break;

	case EODatabaseNothingOperator:
	  break;
        }

      adaptorOpe = [EOAdaptorOperation adaptorOperationWithEntity: entity];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorOpe=%@", 
			    adaptorOpe);

      switch (dbOperator)
        {
        case EODatabaseInsertOperator:
          procedureOpeName = @"EOInsertProcedure";
          adaptorOperator = EOAdaptorInsertOperator;

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"changedValues %p=%@",
				changedValues, changedValues);

          valuesToWrite = [self valuesToWriteForAttributes: attributes
				entity: entity
				changedValues: changedValues];
          break;

        case EODatabaseUpdateOperator:
          procedureOpeName = @"EOUpdateProcedure";
          adaptorOperator = EOAdaptorUpdateOperator;
          valuesToWrite = [self valuesToWriteForAttributes: attributes
				entity: entity
				changedValues: changedValues];
          break;

        case EODatabaseDeleteOperator:
          procedureOpeName = @"EODeleteProcedure";
          adaptorOperator = EOAdaptorDeleteOperator;
          /*
            MIRKO
            NSMutableArray *newKeys = [[[NSMutableArray alloc]
            initWithCapacity:count]
            autorelease];
            NSMutableArray *newVals = [[[NSMutableArray alloc]
            initWithCapacity:count]
            autorelease];
            
            if ([entity isReadOnly] == YES)
            {
            [NSException raise:NSInvalidArgumentException format:@"%@ -- %@ 0x%x: cannot delete object for readonly entity %@", NSStringFromSelector(_cmd), NSStringFromClass([self class]), self, [entity name]];
            }
            
            [aOp setAdaptorOperator:EOAdaptorDeleteOperator];
            
            count = [primaryKeys count];
            for (i = 0; i < count; i++)
            {
            EOAttribute *attribute = [primaryKeys objectAtIndex:i];
            NSString *key = [attribute name];
            id val;
            if ([attribute isFlattened] == NO)
            {
     	// Turbocat
 		    //val = [object storedValueForKey:key];
 			if (currentSnapshot) {
 				val = [currentSnapshot objectForKey:key];
 			}
 
 			if (!val) {
 		[NSException raise:NSInvalidArgumentException format:@"%@ -- %@ 0x%x: cannot delete object (snapshot) '%@' for unkown primarykey value '%@'", NSStringFromSelector(_cmd), NSStringFromClass([self class]), self, currentSnapshot, key];
 			}       
            
            if (val == nil)
            val = null;
            
            [newKeys addObject:key];
            [newVals addObject:val];
            }
            }
            
            row = [NSDictionary dictionaryWithObjects:newVals
            forKeys:newKeys];
            
            [aOp setQualifier:[entity qualifierForPrimaryKey:[op newRow]]];
      
            ==>NO? in _commitTransaction      [self forgetSnapshotForGlobalID:[op globalID]];
          */
        break;

      case EODatabaseNothingOperator:
        EOFLOGObjectLevelArgs(@"EODatabaseContext",
			      @"Db Ope %@ for Nothing !!!", dbOpe);
        //Nothing?
        break;

      default:
        NSEmitTODO();
        [self notImplemented: _cmd]; //TODO
        break;
      }

    EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorOperator=%d",
			  adaptorOperator);

    // only for insert ??
    storedProcedure = [entity storedProcedureForOperation: procedureOpeName];
    if (storedProcedure)
      {
        adaptorOperator = EOAdaptorStoredProcedureOperator;
        NSEmitTODO();
        [self notImplemented: _cmd]; //TODO
      }

    EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorOperator=%d",
			  adaptorOperator);
    EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorOpe=%@", adaptorOpe);

    if (adaptorOpe)
      {
        [adaptorOpe setAdaptorOperator: adaptorOperator];
        EOFLOGObjectLevelArgs(@"EODatabaseContext", @"valuesToWrite=%@",
			      valuesToWrite);

        if (valuesToWrite)
          [adaptorOpe setChangedValues: valuesToWrite];

        EOFLOGObjectLevelArgs(@"EODatabaseContext", @"lockingQualifier=%@",
			      lockingQualifier);

        if (lockingQualifier)
          [adaptorOpe setQualifier: lockingQualifier];

        [dbOpe addAdaptorOperation: adaptorOpe];
      }
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorOpe=%@",
			    adaptorOpe);
  }

  EOFLOGObjectFnStop();
}

- (void) createAdaptorOperationsForDatabaseOperation: (EODatabaseOperation*)dbOpe
{
  //OK for Update - Test for others
  NSArray *attributesToSave = nil;
  NSMutableArray *attributes = nil;
  int i, count;
  EODatabaseOperator dbOperator = EODatabaseNothingOperator;
  EOEntity *entity = [dbOpe entity]; //OK
  NSDictionary *rowDiffs = nil;

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

  [self processSnapshotForDatabaseOperation: dbOpe]; //OK
  dbOperator = [dbOpe databaseOperator]; //OK

  if (dbOperator == EODatabaseUpdateOperator) //OK
    {
      rowDiffs = [dbOpe rowDiffs];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"rowDiffs=%@", rowDiffs);
    }

  attributesToSave = [entity _attributesToSave]; //OK for update, OK for insert
  attributes = [NSMutableArray array];

  count = [attributesToSave count];
  for (i = 0; i < count; i++)
    {
      EOAttribute *attribute = [attributesToSave objectAtIndex: i]; //OK

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attribute=%@", attribute);

      if (![attribute isFlattened] && ![attribute isDerived]) //VERIFY
        {
          [attributes addObject: attribute];

          if ([rowDiffs objectForKey: [attribute name]]
              && [attribute isReadOnly])
            {
              NSEmitTODO();
              [self notImplemented: _cmd]; //TODO: excption ???
            }
        }
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attributes=%@", attributes);

  [self createAdaptorOperationsForDatabaseOperation: dbOpe
        attributes: attributes];
}

- (NSArray*) orderAdaptorOperations
{
  //seems OK
  NSMutableArray *orderedAdaptorOpe = (NSMutableArray*)[NSMutableArray array];

  EOFLOGObjectFnStart();

  //MIRKO
  if (_delegateRespondsTo.willOrderAdaptorOperations == YES)
    orderedAdaptorOpe = (NSMutableArray*)
      [_delegate databaseContext: self
		 willOrderAdaptorOperationsFromDatabaseOperations:
		   NSAllMapTableValues(_dbOperationsByGlobalID)];
  else
    {
      NSArray *entities = nil;
      NSMutableArray *adaptorOperations = [NSMutableArray array];
      NSMapEnumerator dbOpeEnum;
      EOGlobalID *gid = nil;
      EODatabaseOperation *dbOpe = nil;
      NSHashTable *entitiesHashTable = NSCreateHashTable(NSNonOwnedPointerHashCallBacks,32);

      dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);

      while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
				     (void **)&dbOpe))
        {
          NSArray *dbOpeAdaptorOperations = [dbOpe adaptorOperations];
          int i, count = [dbOpeAdaptorOperations count];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

          for (i = 0; i < count; i++)
            {
              EOAdaptorOperation *adaptorOpe = [dbOpeAdaptorOperations
						 objectAtIndex: i];
              EOEntity *entity = nil;

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorOpe=%@",
				    adaptorOpe);

              [adaptorOperations addObject: adaptorOpe];
              entity = [adaptorOpe entity];

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity=%@",
				    [entity name]);
              NSHashInsertIfAbsent(entitiesHashTable, entity);
            }
        }

      entities = NSAllHashTableObjects(entitiesHashTable);
      NSFreeHashTable(entitiesHashTable);

      entitiesHashTable = NULL;
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entities=%@", entities);

      {
        NSArray *entityNameOrderingArray = [self entityNameOrderingArrayForEntities:entities];
        int iAdaptoOpe = 0;
        int adaptorOpeCount = [adaptorOperations count];
        int entitiesCount = [entityNameOrderingArray count];
        int iEntity;

        for (iEntity = 0; iEntity < entitiesCount; iEntity++)
          {
            EOEntity *entity = [entityNameOrderingArray
				 objectAtIndex: iEntity];          

            EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity=%@",
				  [entity name]);

            for (iAdaptoOpe = 0; iAdaptoOpe < adaptorOpeCount; iAdaptoOpe++)
              {
                EOAdaptorOperation *adaptorOpe = [adaptorOperations
						   objectAtIndex: iAdaptoOpe];
                EOEntity *opeEntity = [adaptorOpe entity];

                if (opeEntity == entity)
                  [orderedAdaptorOpe addObject: adaptorOpe];
              }
          }

        NSAssert2([orderedAdaptorOpe count] == adaptorOpeCount,
		  @"Different ordered (%d) an unordered adaptor operations count (%d)",
                  [orderedAdaptorOpe count],
                  adaptorOpeCount);
      }
    }

   EOFLOGObjectFnStop();

   return orderedAdaptorOpe;
}

- (NSArray*) entitiesOnWhichThisEntityDepends: (EOEntity*)entity
{
  NSMutableArray *entities = nil;
  NSArray *relationships = nil;
  int i, count;

  EOFLOGObjectFnStart();

  relationships = [entity relationships];
  count = [relationships count];

  for (i = 0; i < count; i++)
    {
      EORelationship *relationship = [relationships objectAtIndex: i];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
			    relationship);

      if (![relationship isToMany]) //If to many: do nothing
        {
          if ([relationship isFlattened])
            {
              //TODO VERIFY
              EOExpressionArray *definitionArray=[relationship _definitionArray];
              EORelationship *firstRelationship=[definitionArray objectAtIndex:0];
              EOEntity *firstDefEntity=[firstRelationship destinationEntity];
              NSArray *defDependEntities=[self
                                           entitiesOnWhichThisEntityDepends:firstDefEntity];
              if ([defDependEntities count]>0)
                {
                  if (!entities)
                    entities = [NSMutableArray array];
                  
                  [entities addObjectsFromArray: defDependEntities];
                };
            }
          else
            {
              //Here ??
              EOEntity *destinationEntity = [relationship destinationEntity];
              EORelationship *inverseRelationship = [relationship
						      anyInverseRelationship];

              if ([inverseRelationship isToMany])
                {
                  //Do nothing ?
                }
              else
                {
                  if ([inverseRelationship propagatesPrimaryKey])
                    {
                      //OK
                      if (!entities)
                        entities = [NSMutableArray array];

                      [entities addObject: destinationEntity];
                    }
                  else
                    {
                      if ([inverseRelationship ownsDestination])
                        {
                          NSEmitTODO();
                          [self notImplemented: _cmd]; //TODO
                        }
                    }
                }
            }
        }
    }

  EOFLOGObjectFnStop();

  return entities;
}

- (NSArray*)entityNameOrderingArrayForEntities: (NSArray*)entities
{
  //TODO
  NSMutableArray *ordering = [NSMutableArray array];
  NSMutableSet *orderedEntities = [NSMutableSet set];
  /*EODatabase *database = [self database];
    NSArray *models = [database models];*/
  NSMutableDictionary *dependsDict = [NSMutableDictionary dictionary];
  int i, count = [entities count];

  //TODO NSArray* originalOrdering=...
  /*TODO for each mdoel:
    userInfo (ret nil)
  */

  for (i = 0; i < count; i++)
    {
      //OK
      EOEntity *entity=[entities objectAtIndex: i];
      NSArray *dependsEntities = [self
				   entitiesOnWhichThisEntityDepends: entity];

      if ([dependsEntities count])
        [dependsDict setObject: dependsEntities
                     forKey: [entity name]];
    }
  
  ordering = [NSMutableArray array];
  for (i = 0; i < count; i++)
    {
      EOEntity *entity = [entities objectAtIndex: i];
      [self insertEntity: entity
            intoOrderingArray: ordering
            withDependencies: dependsDict
            processingSet: orderedEntities];
    }
  //TODO
  /*
    model userInfo //ret nil
   setUserInfo: {EOEntityOrdering = ordering; }
  */

  return ordering;
}

- (BOOL) isValidQualifierTypeForAttribute: (EOAttribute*)attribute
{
  //OK
  BOOL isValid = NO;
  EOEntity *entity = nil;
  EOModel *model = nil;
  EODatabase *database = nil;
  EOAdaptor *adaptor = nil;
  NSString *externalType = nil;

  EOFLOGObjectFnStart();

  entity = [attribute entity];

  NSAssert1(entity, @"No entity for attribute %@", attribute);

  model = [entity model];
  database = [self database];
  adaptor = [database adaptor];
  externalType = [attribute externalType];
  isValid = [adaptor isValidQualifierType: externalType
		     model: model];

  //TODO REMOVE
  if (!isValid)
    {
      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"attribute=%@",
                            attribute);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"externalType=%@",
                            externalType);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"entity name=%@",
                            entity);
    }

  EOFLOGObjectFnStop();

  return isValid;
}

- (id) lockingNonQualifiableAttributes: (NSArray*)attributes
{
  //TODO finish
  EOEntity *entity = nil;
  NSArray *attributesUsedForLocking = nil;
  int i, count = 0;

  count = [attributes count];
  
  for (i = 0; i < count; i++)
    {
      id attribute = [attributes objectAtIndex: i];

      if (!entity)
        {
          entity = [attribute entity];
          attributesUsedForLocking = [entity attributesUsedForLocking];
        }

      if (![self isValidQualifierTypeForAttribute: attribute])
        {
          NSEmitTODO();
          //              [self notImplemented:_cmd]; //TODO
        }
      else
        { 
          NSEmitTODO();
          //Nothing ??
          //              [self notImplemented:_cmd]; //TODO ??
        }
    }

 return nil;//??
}

- (NSArray*) lockingAttributesForAttributes: (NSArray*)attributes
                                     entity: (EOEntity*)entity
{
  //TODO
  NSArray *retAttributes = nil;
  int i, count = 0;
  NSArray *attributesUsedForLocking = nil;

  EOFLOGObjectFnStart();

  attributesUsedForLocking = [entity attributesUsedForLocking];
  count = [attributes count];

  for (i = 0; i < count; i++)
    {
      id attribute = [attributes objectAtIndex: i];
      //do this on 1st only
      BOOL isFlattened = [attribute isFlattened];

      if (isFlattened)
        { 
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
       }
      else
        {
          NSArray *rootAttributesUsedForLocking = [entity rootAttributesUsedForLocking];

          retAttributes = rootAttributesUsedForLocking;
        }
    }

  EOFLOGObjectFnStop();

  return retAttributes; //TODO
}

- (NSArray*) primaryKeyAttributesForAttributes: (NSArray*)attributes
                                        entity: (EOEntity*)entity
{
  //TODO
  NSArray *retAttributes = nil;
  int i, count = 0;

  EOFLOGObjectFnStart();
//TODO

  count = [attributes count];

  for (i = 0; i < count; i++)
    {
      id attribute = [attributes objectAtIndex: i];
      BOOL isFlattened = [attribute isFlattened];

      //call isFlattened on 1st only
      if (isFlattened)
        { 
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
       }
      else
        {
          NSArray *primaryKeyAttributes = [entity primaryKeyAttributes];

          retAttributes = primaryKeyAttributes;
        }
    }

  EOFLOGObjectFnStop();

  return retAttributes;
}

- (EOQualifier*) qualifierForLockingAttributes: (NSArray*)attributes
			  primaryKeyAttributes: (NSArray*)primaryKeyAttributes
					entity: (EOEntity*)entity
				      snapshot: (NSDictionary*)snapshot
{
  //OK
  EOQualifier *qualifier = nil;
  NSMutableArray *qualifiers = nil;
  int which;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attributes=%@", attributes);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"primaryKeyAttributes=%@",
			primaryKeyAttributes);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot=%@", snapshot);

  //First use primaryKeyAttributes, next use attributes
  for (which = 0; which < 2; which++)
    {
      NSArray *array = (which == 0 ? primaryKeyAttributes : attributes);
      int i, count = [array count];

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = [array objectAtIndex: i];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attribute=%@",
				attribute);

          if (which == 0 || ![primaryKeyAttributes containsObject: attribute])// Test if we haven't already processed it
            {
              if (![self isValidQualifierTypeForAttribute: attribute])
                {
		  NSLog(@"Invalid externalType for attribute '%@' of entity named '%@' - model '%@'",
			[attribute name], [[attribute entity] name],
			[[[attribute entity] model] name]);
                  NSEmitTODO();
                  [self notImplemented: _cmd]; //TODO
                }
              else
                {
                  NSString *attributeName = nil;
                  NSString *snapName = nil;
                  id value = nil;
                  EOQualifier *aQualifier = nil;

                  attributeName = [attribute name];
                  NSAssert1(attributeName, @"no attribute name for attribute %@", attribute);

                  snapName = [entity snapshotKeyForAttributeName: attributeName];
                  NSAssert2(snapName, @"no snapName for attribute %@ in entity %@", attributeName, [entity name]);

                  value = [snapshot objectForKey:snapName];

                  if (!value)
                    {
                      EOFLOGObjectLevel(@"EODatabaseContext", @"NO VALUE");
                    }

                  NSAssert3(value, @"no value for %@ in %p %@", snapName,
			    snapshot, snapshot);

                  aQualifier = [EOKeyValueQualifier
				 qualifierWithKey: attributeName
				 operatorSelector: @selector(isEqualTo:)
				 value: value];

                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"aQualifier=%@",
					aQualifier);

                  if (!qualifiers)
                    qualifiers = [NSMutableArray array];

                  [qualifiers addObject: aQualifier];

                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"qualifiers=%@",
					qualifiers);
                }
            }
        }
    }

  if ([qualifiers count] == 1)
    qualifier = [qualifiers objectAtIndex: 0];
  else
    qualifier = [EOAndQualifier qualifierWithQualifierArray: qualifiers];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"qualifier=%@", qualifier);

  EOFLOGObjectFnStop();

  return qualifier;
}

- (void) insertEntity: (EOEntity*)entity
    intoOrderingArray: (NSMutableArray*)orderingArray
     withDependencies: (NSDictionary*)dependencies
        processingSet: (NSMutableSet*)processingSet
{  
  //TODO: manage dependencies {CustomerCredit = (<EOEntity name: Customer>); } 
  // and processingSet
  [orderingArray addObject: entity];
  [processingSet addObject: [entity name]];
}


- (void) processSnapshotForDatabaseOperation: (EODatabaseOperation*)dbOpe
{
  //Near OK
  EOAdaptor *adaptor = [_database adaptor];//OK
  EOEntity *entity = [dbOpe entity];//OK
  NSDictionary *newRow = nil;
  NSDictionary *dbSnapshot = nil;
  NSEnumerator *attrNameEnum = nil;
  id attrName = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

  newRow = [dbOpe newRow]; //OK{a3code = Q77; code = Q7; numcode = 007; } //ALLOK
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRow %p=%@", newRow, newRow);

  dbSnapshot = [dbOpe dbSnapshot];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbSnapshot %p=%@",
			dbSnapshot, dbSnapshot);

  attrNameEnum = [newRow keyEnumerator];

  while ((attrName = [attrNameEnum nextObject]))
    {
      EOAttribute *attribute = [entity attributeNamed: attrName];
      id newRowValue = nil;
      id dbSnapshotValue = nil;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attribute=%@", attribute);

      newRowValue = [newRow objectForKey:attrName];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"newRowValue=%@",
			    newRowValue);

      dbSnapshotValue = [dbSnapshot objectForKey: attrName];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbSnapshotValue=%@",
			    dbSnapshotValue);

      if (dbSnapshotValue && ![newRowValue isEqual: dbSnapshotValue])
        {
          id adaptorValue = [adaptor fetchedValueForValue: newRowValue
				     attribute: attribute]; //this call is OK

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"adaptorValue=%@",
				adaptorValue);
          //TODO-NOW SO WHAT ?? may be replacing newRow diff values by adaptorValue if different ????
        }
    }

  EOFLOGObjectFnStop();
}


- (NSDictionary*) valuesToWriteForAttributes: (NSArray*)attributes
                                      entity: (EOEntity*)entity
                               changedValues: (NSDictionary*)changedValues
{
  //NEAR OK
  NSMutableDictionary *valuesToWrite = [NSMutableDictionary dictionary];
  BOOL isReadOnlyEntity = NO;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attributes=%@", attributes);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity=%@", [entity name]);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"changedValues=%@",
			changedValues);

  isReadOnlyEntity = [entity isReadOnly];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"isReadOnlyEntity=%s",
			(isReadOnlyEntity ? "YES" : "NO"));

  if (isReadOnlyEntity)
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }
  else
    {
      int i, count = [attributes count];

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = [attributes objectAtIndex: i];
          BOOL isReadOnly = [attribute isReadOnly];

          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attribute=%@",
				attribute);
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"isReadOnly=%s",
				(isReadOnly ? "YES" : "NO"));

          if (isReadOnly)
            {
              NSEmitTODO();
              NSDebugMLog(@"attribute=%@",attribute);
              [self notImplemented: _cmd]; //TODO
            }
          else
            {
              NSString *attrName = [attribute name];
              NSString *snapName = nil;
              id value = nil;

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"attrName=%@",
				    attrName);

              snapName = [entity snapshotKeyForAttributeName: attrName];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapName=%@",
				    snapName);

              value = [changedValues objectForKey: snapName];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"value=%@", value);

              if (value)
                [valuesToWrite setObject: value
                               forKey: attrName];
            }
        }
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"valuesToWrite=%@",
			valuesToWrite);

  EOFLOGObjectFnStop();

  return valuesToWrite;
}

@end


@implementation EODatabaseContext(EOBatchFaulting)

- (void)batchFetchRelationship: (EORelationship *)relationship
	      forSourceObjects: (NSArray *)objects
		editingContext: (EOEditingContext *)editingContext
{ // TODO
  NSMutableArray *qualifierArray, *valuesArray, *toManySnapshotArray;
  NSMutableDictionary *values;
  NSArray *array;
  NSEnumerator *objsEnum, *joinsEnum, *keyEnum;
  NSString *key;
  EOFetchSpecification *fetch;
  EOQualifier *qualifier;
  EOFault *fault;
  EOJoin *join;
  BOOL equal;
  int i, count;
  id object;

  qualifierArray = [NSMutableArray array];
  valuesArray = [NSMutableArray array];
  toManySnapshotArray = [NSMutableArray array];

  objsEnum = [objects objectEnumerator];
  while ((object = [objsEnum nextObject]))
    {
      values = [NSMutableDictionary dictionaryWithCapacity: 4];

      fault = [object valueForKey: [relationship name]];
      [EOFault clearFault: fault];

      joinsEnum = [[relationship joins] objectEnumerator];
      while ((join = [joinsEnum nextObject]))
	{
	  [values setObject: [object valueForKey: [[join sourceAttribute] name]]
		  forKey: [[join destinationAttribute] name]];
	}

      [valuesArray addObject: values];
      [toManySnapshotArray addObject: [NSMutableArray array]];

      [qualifierArray addObject: [EOQualifier qualifierToMatchAllValues:
						values]];
    }

  if ([qualifierArray count] == 1)
    qualifier = [qualifierArray objectAtIndex: 0];
  else
    qualifier = [EOOrQualifier qualifierWithQualifierArray: qualifierArray];

  fetch = [EOFetchSpecification fetchSpecificationWithEntityName:
				  [[relationship destinationEntity] name]
				qualifier: qualifier
				sortOrderings: nil];

  array = [self objectsWithFetchSpecification: fetch
		editingContext: editingContext];

  count = [valuesArray count];

  objsEnum = [array objectEnumerator];
  while ((object = [objsEnum nextObject]))
    {
      for (i = 0; i < count; i++)
	{
	  equal = YES;

	  values = [valuesArray objectAtIndex: i];
	  keyEnum = [values keyEnumerator];
	  while ((key = [keyEnum nextObject]))
	    {
	      if ([[object valueForKey: key]
		    isEqual: [values objectForKey:key]] == NO)
		{
		  equal = NO;
		  break;
		}
	    }

	  if (equal == YES)
	    {
	      [[[objects objectAtIndex: i] valueForKey: [relationship name]]
		addObject: object];
	      [[toManySnapshotArray objectAtIndex: i]
		addObject: [editingContext globalIDForObject: object]];

	      break;
	    }
	}
    }
  EOFLOGObjectLevel(@"EODatabaseContext",@"** 3");
//==> see _registerSnapshot:forSourceGlobalID:relationshipName:editingContext:

  for (i = 0; i < count; i++)
    [_database recordSnapshot: [toManySnapshotArray objectAtIndex: i]
	       forSourceGlobalID:
		 [editingContext globalIDForObject: [objects objectAtIndex: i]]
	       relationshipName: [relationship name]];

  EOFLOGObjectLevel(@"EODatabaseContext", @"** 4");
}

@end

@implementation EODatabaseContext (EODatabaseContextPrivate)

- (void) _fireArrayFault: (id)object
{
  //OK ??
  BOOL fetchIt = YES;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p", object);

  if (_delegateRespondsTo.shouldFetchObjectFault == YES)
    fetchIt = [_delegate databaseContext: self
                         shouldFetchObjectFault: object];

  if (fetchIt)
    {
      /*Class targetClass = Nil;
	void *extraData = NULL;*/
      EOAccessArrayFaultHandler *handler = (EOAccessArrayFaultHandler *)[EOFault handlerForFault:object];
      EOEditingContext *context = [handler editingContext];
      NSString *relationshipName= [handler relationshipName];
      EOKeyGlobalID *gid = [handler sourceGlobalID];
      NSArray *objects = nil;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationshipName=%@",
			    relationshipName);
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

      objects = [context objectsForSourceGlobalID: gid
			 relationshipName: relationshipName
			 editingContext: context];

      [EOFault clearFault: object]; //??
      /* in clearFault 
         [handler faultWillFire:object];
         targetClass=[handler targetClass];
         extraData=[handler extraData];
         [handler release];
      */
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"NEAR FINISHED 1 object count=%d %p %@",
			    [object count],
			    object,
			    object);
      EOFLOGObjectLevelArgs(@"EODatabaseContext",
			    @"NEAR FINISHED 1 objects count=%d %p %@",
			    [objects count],
			    objects,
			    objects);

      if (objects != object)
        {
          //No, not needed      [object removeObjectsInArray:objects];//Because some objects may be here. We don't want duplicate. It's a hack because I don't see why there's objects in object !
          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"NEAR FINISHED 1 object count=%d %p %@",
				[object count],
				object,
				object);

          [object addObjectsFromArray: objects];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"NEAR FINISHED 2 object count=%d %@",
				[object count],
				object);
        }
    }
  //END!
/*
}

- (void)_batchToMany:(id)fault
	 withHandler:(EOAccessArrayFaultHandler *)handler
{
*/

/*
  EOAccessArrayFaultHandler *usedHandler, *firstHandler, *lastHandler;
  EOAccessArrayFaultHandler *bufHandler;
  NSMutableDictionary *batchBuffer;
  EOEditingContext *context;
  NSMutableArray *objects;
  EOKeyGlobalID *gid;
  EOEntity *entity;
  EORelationship *relationship;
  unsigned int maxBatch;
  BOOL batch = YES, changeBatch = NO;


  gid = [handler sourceGlobalID];//OK
  context = [handler editingContext];//OK

  entity = [_database entityNamed:[gid entityName]];//-done
  relationship = [entity relationshipNamed:[handler relationshipName]];//-done
  maxBatch = [relationship numberOfToManyFaultsToBatchFetch];//-done

  batchBuffer = [_batchToManyFaultBuffer objectForKey:[entity name]];
  bufHandler = [batchBuffer objectForKey:[relationship name]];

  objects = [NSMutableArray array];

  [objects addObject:[context objectForGlobalID:gid]];//-done

  firstHandler = lastHandler = nil;
  usedHandler = handler;

  if (bufHandler && [bufHandler isEqual:usedHandler] == YES)
    changeBatch = YES;

  if (maxBatch > 1)
    {
      maxBatch--;

      while (maxBatch--)
	{
	  if (lastHandler == nil)
	    {
	      usedHandler = (EOAccessArrayFaultHandler *)[usedHandler
							   previous];

	      if (usedHandler)
		firstHandler = usedHandler;
	      else
		lastHandler = usedHandler = (EOAccessArrayFaultHandler *)
		  [handler next];
	    }
	  else
	    {
	      usedHandler = (EOAccessArrayFaultHandler *)[lastHandler next];

	      if (usedHandler)
		lastHandler = usedHandler;
	    }

	  if (usedHandler == nil)
	    break;

	  if (bufHandler && [bufHandler isEqual:usedHandler] == YES)
	    changeBatch = YES;

	  [objects addObject:[context objectForGlobalID:[usedHandler
							  sourceGlobalID]]];
	}
    }

  if (firstHandler == nil)
    firstHandler = handler;
  if (lastHandler == nil)
    lastHandler = handler;

  usedHandler = (id)[firstHandler previous];
  bufHandler = (id)[lastHandler next];
  if (usedHandler)
    [usedHandler _linkNext:bufHandler];

  usedHandler = bufHandler;
  if (usedHandler)
    {
      [usedHandler _linkPrev:[firstHandler previous]];
      if (bufHandler == nil)
	bufHandler = usedHandler;
    }

  if (changeBatch == YES)
    {
      if (bufHandler)
	[batchBuffer setObject:bufHandler
		     forKey:[relationship name]];
      else
	[batchBuffer removeObjectForKey:[relationship name]];
    }

  [self batchFetchRelationship:relationship
	forSourceObjects:objects
	editingContext:context];
*/

  EOFLOGObjectFnStop();
}

- (void) _fireFault: (id)object
{
  //TODO
  BOOL fetchIt = YES;//MIRKO

  EOFLOGObjectFnStart();

  //MIRKO
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"Fire Fault: object %p of class %@",
                        object,[object class]);

  if (_delegateRespondsTo.shouldFetchObjectFault == YES)
    fetchIt = [_delegate databaseContext: self
                         shouldFetchObjectFault: object];

  if (fetchIt)
    {
      EOAccessFaultHandler *handler;
      EOEditingContext *context;
      EOGlobalID *gid;
      NSDictionary *snapshot;
      EOEntity *entity = nil;
      NSString *entityName = nil;

      handler = (EOAccessFaultHandler *)[EOFault handlerForFault: object];
      context = [handler editingContext];
      gid = [handler globalID];
      snapshot = [self snapshotForGlobalID: gid]; //nil

      if (snapshot)
        {
          //TODO _fireFault snapshot
          NSEmitTODO();
//          [self notImplemented: _cmd]; //TODO
        }

      entity = [self entityForGlobalID: gid];
      entityName = [entity name];

      if ([entity cachesObjects])
        {
          //TODO _fireFault [entity cachesObjects]
          NSEmitTODO();
          [self notImplemented: _cmd]; //TODO
        }
      
      //??? generation # EOAccessGenericFaultHandler//ret 2
      {
        EOAccessFaultHandler *previousHandler;
        EOAccessFaultHandler *nextHandler;
        EOFetchSpecification *fetchSpecif;
        NSArray *objects;
        EOQualifier *qualifier;
        /*int maxNumberOfInstancesToBatchFetch =
	  [entity maxNumberOfInstancesToBatchFetch];
	  NSDictionary *snapshot = [self snapshotForGlobalID: gid];*///nil //TODO use it !
        NSDictionary *pk = [entity primaryKeyForGlobalID: (EOKeyGlobalID *)gid];
        EOQualifier *pkQualifier = [entity qualifierForPrimaryKey: pk];
        NSMutableArray *qualifiers = [NSMutableArray array];

        [qualifiers addObject: pkQualifier];

        previousHandler = (EOAccessFaultHandler *)[handler previous];
        nextHandler = (EOAccessFaultHandler *)[handler next]; //nil

        fetchSpecif = [[EOFetchSpecification new] autorelease];
        [fetchSpecif setEntityName: entityName];

        qualifier = [EOOrQualifier qualifierWithQualifierArray: qualifiers];

        [fetchSpecif setQualifier: qualifier];

        objects = [self objectsWithFetchSpecification: fetchSpecif
			editingContext: context];

        EOFLOGObjectLevelArgs(@"EODatabaseContext", @"objects %p=%@ class=%@",
			      objects, objects, [objects class]);
      }
    }

  EOFLOGObjectFnStop();
}

/*
- (void)_batchToOne:(id)fault
	withHandler:(EOAccessFaultHandler *)handler
{
  EOAccessFaultHandler *usedHandler, *firstHandler, *lastHandler;
  EOAccessFaultHandler *bufHandler;
  EOFetchSpecification *fetch;
  EOEditingContext *context;
  EOKeyGlobalID *gid;
  EOQualifier *qualifier;
  EOEntity *entity;
  NSMutableArray *qualifierArray;
  BOOL batch = YES, changeBatch = NO;
  unsigned int maxBatch;

  if (_delegateRespondsTo.shouldFetchObjectFault == YES)//-done
    batch = [_delegate databaseContext:self
		       shouldFetchObjectFault:fault];//-done

  if (batch == NO)//-done
    return;//-done

  gid = [handler globalID];//-done
  context = [handler editingContext];//-done

  entity = [_database entityNamed:[gid entityName]];//-done
  maxBatch = [entity maxNumberOfInstancesToBatchFetch];//-done

  bufHandler = [_batchFaultBuffer objectForKey:[entity name]];

  firstHandler = lastHandler = nil;
  usedHandler = handler;

  if (bufHandler && [bufHandler isEqual:usedHandler] == YES)
    changeBatch = YES;

  if (maxBatch <= 1)
    {
      qualifier = [entity qualifierForPrimaryKey:
			    [entity primaryKeyForGlobalID:gid]];
    }
  else
    {
      qualifierArray = [NSMutableArray array];

      [qualifierArray addObject:
			[entity qualifierForPrimaryKey:
				  [entity primaryKeyForGlobalID:gid]]];

      maxBatch--;

      while (maxBatch--)
	{
	  if (lastHandler == nil)
	    {
	      usedHandler = (EOAccessFaultHandler *)[usedHandler previous];

	      if (usedHandler)
		firstHandler = usedHandler;
	      else
		lastHandler = usedHandler = (EOAccessFaultHandler *)[handler
								      next];
	    }
	  else
	    {
	      usedHandler = (EOAccessFaultHandler *)[lastHandler next];

	      if (usedHandler)
		lastHandler = usedHandler;
	    }

	  if (usedHandler == nil)
	    break;

	  if (changeBatch == NO &&
	     bufHandler && [bufHandler isEqual:usedHandler] == YES)
	    changeBatch = YES;

	  [qualifierArray addObject:
			    [entity qualifierForPrimaryKey:
				      [entity primaryKeyForGlobalID:
						[usedHandler globalID]]]];
	}

      qualifier = [[[EOOrQualifier alloc]
		     initWithQualifierArray:qualifierArray] autorelease];
    }

  if (firstHandler == nil)
    firstHandler = handler;
  if (lastHandler == nil)
    lastHandler = handler;

  usedHandler = (id)[firstHandler previous];
  bufHandler = (id)[lastHandler next];
  if (usedHandler)
    [usedHandler _linkNext:bufHandler];

  usedHandler = bufHandler;
  if (usedHandler)
    {
      [usedHandler _linkPrev:[firstHandler previous]];
      if (bufHandler == nil)
	bufHandler = usedHandler;
    }

  if (changeBatch == YES)
    {
      if (bufHandler)
	[_batchFaultBuffer setObject:bufHandler
			   forKey:[entity name]];
      else
	[_batchFaultBuffer removeObjectForKey:[entity name]];
    }

  fetch = [EOFetchSpecification fetchSpecificationWithEntityName:[entity name]
				qualifier:qualifier
				sortOrderings:nil];//-done

  [context objectsWithFetchSpecification:fetch];//-done
}*/


// Clear all the faults for the relationship pointed by the source objects and
// make sure to perform only a single, efficient, fetch (two fetches if the
// relationship is many to many).

- (void)_addBatchForGlobalID: (EOKeyGlobalID *)globalID
		       fault: (EOFault *)fault
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"globalID=%@", globalID);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"fault=%@", fault);

  if (fault)
    {
      EOAccessGenericFaultHandler *handler = nil;
      NSString *entityName = [globalID entityName];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entityName=%@",
			    entityName);

      handler = [_batchFaultBuffer objectForKey: entityName];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"handler=%@", handler);

      if (handler)
        {
          [(EOAccessGenericFaultHandler *)
	    [EOFault handlerForFault: fault]
	             linkAfter: handler
	             usingGeneration: [handler generation]];
        }
      else
        {
          handler = (EOAccessGenericFaultHandler *)[EOFault handlerForFault:
							      fault];

          NSAssert1(handler, @"No handler for fault:%@", fault);

          [_batchFaultBuffer setObject: handler
                             forKey: entityName];
        }
    }

  EOFLOGObjectFnStop();
}

- (void)_removeBatchForGlobalID: (EOKeyGlobalID *)globalID
			  fault: (EOFault *)fault
{
  EOAccessGenericFaultHandler *handler, *prevHandler, *nextHandler;
  NSString *entityName = [globalID entityName];

  handler = (EOAccessGenericFaultHandler *)[EOFault handlerForFault: fault];

  prevHandler = [handler previous];
  nextHandler = [handler next];

  if (prevHandler)
    [prevHandler _linkNext: nextHandler];
  if (nextHandler)
    [nextHandler _linkPrev: prevHandler];

  if ([_batchFaultBuffer objectForKey: entityName] == handler)
    {
      if (prevHandler)
	[_batchFaultBuffer setObject: prevHandler
			   forKey: entityName];
      else if (nextHandler)
	[_batchFaultBuffer setObject: nextHandler
			   forKey: entityName];
      else
	[_batchFaultBuffer removeObjectForKey: entityName];
    }
}

- (void)_addToManyBatchForSourceGlobalID: (EOKeyGlobalID *)globalID
			relationshipName: (NSString *)relationshipName
				   fault: (EOFault *)fault
{
  if (fault)
    {
      NSMutableDictionary *buf;
      EOAccessGenericFaultHandler *handler;
      NSString *entityName = [globalID entityName];

      buf = [_batchToManyFaultBuffer objectForKey: entityName];

      if (buf == nil)
        {
          buf = [NSMutableDictionary dictionaryWithCapacity: 8];
          [_batchToManyFaultBuffer setObject: buf
                                   forKey: entityName];
        }
      
      handler = [buf objectForKey: relationshipName];

      if (handler)
        {
          [(EOAccessGenericFaultHandler *)
	    [EOFault handlerForFault: fault]
	             linkAfter: handler
	             usingGeneration: [handler generation]];
        }
      else
        [buf setObject: [EOFault handlerForFault: fault]
             forKey: relationshipName];
    }
}

@end


@implementation EODatabaseContext (EODatabaseSnapshotting)

- (void)recordSnapshot: (NSDictionary *)snapshot
	   forGlobalID: (EOGlobalID *)gid
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p database=%p",
			self, _database);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
			self, _uniqueStack, _uniqueStack);

  if ([_uniqueStack count] > 0)
    {
      NSMutableDictionary *snapshots = [_uniqueStack lastObject];

      [snapshots setObject: snapshot
                 forKey: gid];
    }
  else
    {
      NSEmitTODO();
      NSWarnLog(@"_uniqueStack is empty. May be there's no runing transaction !", "");

      [self notImplemented: _cmd]; //TODO
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
			self, _uniqueStack, _uniqueStack);

  EOFLOGObjectFnStop();
}

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
                                after: (NSTimeInterval)ti
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
{
  //OK
  NSDictionary *snapshot = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p database=%p",
			self, _database);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid %p=%@", gid, gid);

  snapshot = [self localSnapshotForGlobalID: gid];

  if (!snapshot)
    {
      NSAssert(_database, @"No database");
      snapshot = [_database snapshotForGlobalID: gid];
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot for gid %@: %p %@",
			gid, snapshot, snapshot);

  EOFLOGObjectFnStop();

  return snapshot;
}

- (void)recordSnapshot: (NSArray *)gids
     forSourceGlobalID: (EOGlobalID *)gid
      relationshipName: (NSString *)name
{
  EOFLOGObjectFnStart();

  NSEmitTODO();

  [self notImplemented: _cmd]; //TODO
/*
  NSMutableDictionary *toMany = [_toManySnapshots objectForKey:gid];

  if (toMany == nil)
    {
      toMany = [NSMutableDictionary dictionaryWithCapacity:16];
      [_toManySnapshots setObject:toMany
			forKey:gid];
    }

  [toMany setObject:gids
          forKey:name];
*/

  EOFLOGObjectFnStop();
}

- (NSArray *)snapshotForSourceGlobalID: (EOGlobalID *)gid
		      relationshipName: (NSString *)name
{
  NSArray *snapshot = nil;

  EOFLOGObjectFnStart();
  NSEmitTODO();

  [self notImplemented: _cmd]; //TODO
/*

  snapshot = [[_toManySnapshots objectForKey:gid] objectForKey:name];
  if (!snapshot)
    snapshot=[_database snapshotForSourceGlobalID:gid
                        relationshipName:name];
*/

  EOFLOGObjectFnStop();

  return snapshot;
}

- (NSDictionary *)localSnapshotForGlobalID: (EOGlobalID *)gid
{
  //OK
  NSDictionary *snapshot = nil;
  int i, snapshotsDictCount = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p database=%p",
			self, _database);

  snapshotsDictCount = [_uniqueStack count];

  for (i = 0; !snapshot && i < snapshotsDictCount; i++)
    {
      NSDictionary *snapshots = [_uniqueStack objectAtIndex: i];
      snapshot = [snapshots objectForKey: gid];
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot for gid %@: %p %@",
			gid, snapshot, snapshot);

  EOFLOGObjectFnStop();

  return snapshot;
}

- (NSArray *)localSnapshotForSourceGlobalID: (EOGlobalID *)gid
			   relationshipName: (NSString *)name
{
  NSArray *snapshot = nil;

  //TODO
  EOFLOGObjectFnStart();
  NSEmitTODO();

  [self notImplemented: _cmd]; //TODO
/*
  return [[_toManySnapshots objectForKey:gid] objectForKey:name];
*/

  EOFLOGObjectFnStop();

  return snapshot;
}

- (void)forgetSnapshotForGlobalID: (EOGlobalID *)gid
{
  //TODO-VERIFY deleteStack
  EOFLOGObjectFnStart();

  if ([_uniqueStack count] > 0)
    {
      NSMutableDictionary *snapshots = [_uniqueStack lastObject];

      //call _deleteStack lastObject
      [snapshots removeObjectForKey: gid];
      snapshots = [_uniqueArrayStack lastObject];
      [snapshots removeObjectForKey: gid];
    }

  EOFLOGObjectFnStop();
}

- (void)forgetSnapshotsForGlobalIDs: (NSArray *)gids
{
  //TODO
  NSEmitTODO();

  [self notImplemented: _cmd]; //TODO
/*
  int i, count;

  count = [gids count];

  for (i=0; i<count; i++)
    {
      id gid = [gids objectAtIndex:i];

      [_snapshots removeObjectForKey:gid];
    }
*/

  EOFLOGObjectFnStop();
}

- (void)recordSnapshots: (NSDictionary *)snapshots
{
  EOFLOGObjectFnStart();

  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
/*
  [_snapshots addEntriesFromDictionary:snapshots];
*/

  EOFLOGObjectFnStop();
}

- (void)recordToManySnapshots: (NSDictionary *)snapshots
{
  EOFLOGObjectFnStart();
  //OK

  if ([_uniqueArrayStack count] > 0)
    {
      NSMutableDictionary *toManySnapshots = [_uniqueArrayStack lastObject];
      NSArray *keys = [snapshots allKeys];
      int i, count = [keys count];

      for (i = 0; i < count; i++)
      {
        id key = [keys objectAtIndex: i];
        NSDictionary *snapshotsDict = [snapshots objectForKey: key];
        NSMutableDictionary *currentSnapshotsDict =
	  [toManySnapshots objectForKey: key];

        if (!currentSnapshotsDict)
          {
            currentSnapshotsDict = (NSMutableDictionary *)[NSMutableDictionary
							    dictionary];
            [toManySnapshots setObject: currentSnapshotsDict
                             forKey: key];
          }

        [currentSnapshotsDict addEntriesFromDictionary: snapshotsDict];
      }
    }

  EOFLOGObjectFnStop();
}

- (void)registerLockedObjectWithGlobalID: (EOGlobalID *)globalID
{
  EOFLOGObjectFnStart();

  if (_numLocked && (_numLocked+1) % _LOCK_BUFFER == 0)
    _lockedObjects = NSZoneRealloc(NULL, _lockedObjects,
				   (_numLocked+_LOCK_BUFFER)*sizeof(id));

  _lockedObjects[_numLocked++] = globalID;

  EOFLOGObjectFnStop();
}

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)globalID
{
  int i;

  EOFLOGObjectFnStart();

  for (i = 0; i < _numLocked; i++)
    if ([_lockedObjects[i] isEqual: globalID])
      return YES;

  EOFLOGObjectFnStop();

  return NO;
}

- (void)initializeObject: (id)object
                     row: (NSDictionary*)row
                  entity: (EOEntity*)entity
          editingContext: (EOEditingContext*)context
{
  //really near ok
  NSArray *relationships = nil;
  NSArray *classPropertyAttributeNames = nil;
  EONull *null = [EONull null];
  int i, count = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%d", object);

  classPropertyAttributeNames = [entity classPropertyAttributeNames];
  count = [classPropertyAttributeNames count];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"count=%d", count);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"row=%@", row);

  for (i = 0; i < count; i++)
    {
      id key = [classPropertyAttributeNames objectAtIndex: i];
      id value = nil;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"key=%@", key);
      value = [row objectForKey: key];

      if (value == null)
	value = nil;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"value=%@", value);

      [object takeStoredValue: value
              forKey: key];
    }

  relationships = [entity _relationshipsToFaultForRow: row];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationships=%@",
			relationships);

  count = [relationships count];

  for (i = 0; i < count; i++)
    {
      id relObject = nil;
      EORelationship *relationship = [relationships objectAtIndex: i];
      NSString *relName = [relationship name];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
			    relationship);

      if ([relationship isToMany])
        {
          EOGlobalID *gid = [entity globalIDForRow: row];

          relObject = [self arrayFaultWithSourceGlobalID: gid
			    relationshipName: [relationship name]
			    editingContext: context];
        }
      else
        {
          EOMutableKnownKeyDictionary *foreignKeyForSourceRow = nil;

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"relationship=%@ foreignKeyInDestination:%d",
                                [relationship name],[relationship foreignKeyInDestination]);

          foreignKeyForSourceRow = [relationship _foreignKeyForSourceRow: row];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
                                @"foreignKeyForSourceRow:%@\n=%@",
				foreignKeyForSourceRow, row);
          
          if (![foreignKeyForSourceRow
		 containsObjectsNotIdenticalTo: [EONull null]])
            {
              NSEmitTODO();//TODO: what to do if rel is mandatory ?
              relObject = nil;
            }
          else
            {
              EOEntity *destinationEntity = [relationship destinationEntity];
              EOGlobalID *relRowGid = [destinationEntity
					globalIDForRow: foreignKeyForSourceRow];

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relRowGid=%@",
				    relRowGid);

              if ([(EOKeyGlobalID*)relRowGid areKeysAllNulls])
                NSWarnLog(@"All key of relRowGid %p (%@) are nulls",
                          relRowGid,
                          relRowGid);

              relObject = [context faultForGlobalID: relRowGid
				   editingContext: context];

              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relObject=%p (%@)",
				    relObject, [relObject class]);
//end
/*
	      NSArray *joins = [(EORelationship *)prop joins];
	      EOJoin *join;
	      NSMutableDictionary *row;
	      EOGlobalID *faultGID;
	      int h, count;
	      id value, realValue = nil;

	      row = [NSMutableDictionary dictionaryWithCapacity:4];

	      count = [joins count];
	      for (h=0; h<count; h++)
		{
		  join = [joins objectAtIndex:h];

		  value = [snapshot objectForKey:[[join sourceAttribute]
						   name]];
		  if (value == null)
		    realValue = nil;
		  else
		    realValue = value;

		  [[prop validateValue:&realValue] raise];

		  [row setObject:value
		       forKey:[[join destinationAttribute]
				name]];
		}

	      if (realValue || [prop isMandatory] == YES)
		{
		  faultGID = [[(EORelationship *)prop destinationEntity]
			       globalIDForRow:row];

		  fault = [context objectForGlobalID:faultGID];

		  if (fault == nil)
		    fault = [context faultForGlobalID:faultGID
				     editingContext:context];
		}
	      else
		fault = nil;

*/
            }
        }

      EOFLOGObjectLevel(@"EODatabaseContext", @"TakeStoredValue");

      [object takeStoredValue: relObject
              forKey: relName];
    }

  EOFLOGObjectFnStop();
}

- (void)forgetAllLocks
{
 // TODO
  NSEmitTODO();
//  [self notImplemented:_cmd];
}

- (void)forgetLocksForObjectsWithGlobalIDs: (NSArray *)gids
{ // TODO
  NSEmitTODO();
  [self notImplemented: _cmd];
}

- (void) _rollbackTransaction
{ // TODO
  EOFLOGObjectFnStart();

  NSEmitTODO();
  [self notImplemented: _cmd];

  EOFLOGObjectFnStop();
}

- (void) _commitTransaction
{
  EOFLOGObjectFnStart();

  NSEmitTODO();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
			self, _uniqueStack, _uniqueStack);

  if ([_uniqueStack count] > 0)
    {
      NSMutableDictionary *snapshotsDict = [RETAIN([_uniqueStack lastObject]) autorelease];
      NSMutableDictionary *toManySnapshotsDict = [RETAIN([_uniqueArrayStack
							   lastObject])
							autorelease];
      /*NSMutableDictionary *deleteSnapshotsDict = [[[_deleteStack lastObject]
	retain] autorelease];*/ //??

      [_uniqueStack removeLastObject];
      [_uniqueArrayStack removeLastObject];
      [_deleteStack removeLastObject];

      [self forgetAllLocks];

      [_database recordSnapshots: snapshotsDict];
      [_database recordToManySnapshots: toManySnapshotsDict];

      /* //TODO
         if (moified ojects)
         call forgetSnapshotForGlobalID: ...
         <<<<
         DESTROY(_modifiedObjects);
      */
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
			self, _uniqueStack, _uniqueStack);

  EOFLOGObjectFnStop();
}

- (void) _beginTransaction
{
  EOFLOGObjectFnStart();

  [_uniqueStack addObject: [NSMutableDictionary dictionary]];
  [_uniqueArrayStack addObject: [NSMutableDictionary dictionary]];
  [_deleteStack addObject: [NSMutableDictionary dictionary]]; //TODO: put an object in the dictionary

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
			self, _uniqueStack, _uniqueStack);

  EOFLOGObjectFnStop();
}

- (EODatabaseChannel*) _obtainOpenChannel
{
  EODatabaseChannel *channel = [self availableChannel];

  if (![self _openChannelWithLoginPanel: channel])
    {
      NSEmitTODO();
      [self notImplemented: _cmd];//TODO
    }

  return channel;
}

- (BOOL) _openChannelWithLoginPanel: (EODatabaseChannel*)databaseChannel
{
  // veridy: LoginPanel ???
  EOAdaptorChannel *adaptorChannel = [databaseChannel adaptorChannel];

  if (![adaptorChannel isOpen]) //??
    {
      [adaptorChannel openChannel];
    }

  return [adaptorChannel isOpen];
}

- (void) _forceDisconnect
{ // TODO
  NSEmitTODO();
  [self notImplemented: _cmd];
}

@end


@implementation EODatabaseContext(EOMultiThreaded)

- (void)lock
{
  [_lock lock];
}

- (void)unlock
{
  [_lock unlock];
}

@end

@implementation EODatabaseContext (EODatabaseContextPrivate2)

- (void) _verifyNoChangesToReadonlyEntity: (EODatabaseOperation*)dbOpe
{
  //TODO
  EOEntity *entity = nil;

  EOFLOGObjectFnStart();

  entity = [dbOpe entity];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"dbOpe=%@", dbOpe);

  if ([entity isReadOnly])
    {
      //?? exception I presume
    }
  else
    {
      [dbOpe databaseOperator]; //SoWhat
    }

  EOFLOGObjectFnStop();
}

- (void) _cleanUpAfterSave
{
//TODO
  EOFLOGObjectFnStart();

  _coordinator = nil; //realesae ?
  _editingContext = nil; //realesae ?

  if (_dbOperationsByGlobalID)
    {
      //Really free it because we don't want to record some db ope (select for exemple).
      NSFreeMapTable(_dbOperationsByGlobalID);
      _dbOperationsByGlobalID = NULL;
    }

  _flags.preparingForSave = NO;
/*
//TODO HERE or in _commitTransaction ?
_numLocked = 0;
      _lockedObjects = NSZoneRealloc(NULL, _lockedObjects,
				     _LOCK_BUFFER*sizeof(id));

*/

  EOFLOGObjectFnStop();
}

- (EOGlobalID*)_globalIDForObject: (id)object
{
  EOEditingContext *objectEditingContext = nil;
  EOGlobalID *gid = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p of class %@",
                        object,[object class]);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_editingContext=%p",
			_editingContext);

  objectEditingContext = [object editingContext];
  NSAssert1(objectEditingContext, @"No editing context for object %p", object);

  gid = [objectEditingContext globalIDForObject: object];
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

  if (!gid)
    {
      NSEmitTODO();
      NSLog(@"TODO: no GID in EODatabaseContext _globalIDForObject:");
      //TODO exception ? ==> RollbackCh
    }

  EOFLOGObjectFnStop();

  return gid;
}

- (NSDictionary*)_primaryKeyForObject: (id)object
{
  //NEAR OK
  NSDictionary *pk = nil;
  EOEntity *entity = nil;
  NSArray *pkNames = nil;
  BOOL shouldGeneratePrimaryKey = NO;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%@", object);
  NSAssert(!isNilOrEONull(object), @"No object");

  entity = [_database entityForObject: object];
  shouldGeneratePrimaryKey = [self _shouldGeneratePrimaryKeyForEntityName:
				     [entity name]];
  EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p shouldGeneratePrimaryKey=%d",
                        object,shouldGeneratePrimaryKey);

/*
  if (shouldGeneratePrimaryKey)
*/
    {

      BOOL isPKValid = NO;
      EOGlobalID *gid = [self _globalIDForObject: object]; //OK
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

      pk = [entity primaryKeyForGlobalID: (EOKeyGlobalID*)gid]; //OK
      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p pk=%@",
                            object,pk);

      {
        NSDictionary *pk2 = nil;
        pkNames = [entity primaryKeyAttributeNames];

        pk2 = [self valuesForKeys: pkNames
		    object: object];

        EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p pk2=%@",
                              object,pk2);

        if (pk)
          {
            //merge pk2 into pk
            NSEnumerator *pk2Enum = [pk2 keyEnumerator];
            NSMutableDictionary *realPK = [NSMutableDictionary
					    dictionaryWithDictionary: pk];//revoir
            id key = nil;

            while ((key = [pk2Enum nextObject]))
              {
                [realPK setObject: [pk2 objectForKey: key]
                        forKey: key];
              }

            pk = realPK;
          }
        else
          pk=pk2;
      }

      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p pk=%@",
                            object,pk);

      isPKValid = [entity isPrimaryKeyValidInObject: pk];
      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"object=%p isPKValid=%d",
                            object,isPKValid);
      if (isPKValid == NO)
        pk = nil;

      if (isPKValid == NO && shouldGeneratePrimaryKey)
        {
          pk = nil;

          if (_delegateRespondsTo.newPrimaryKey == YES)
            pk = [_delegate databaseContext: self
                            newPrimaryKeyForObject: object
                            entity: entity];

          if (!pk)
            {
              NSArray *pkAttributes = nil;
              EOAdaptorChannel *channel = nil;
              EOStoredProcedure *nextPKProcedure = nil;

              nextPKProcedure = [entity storedProcedureForOperation:
					  EONextPrimaryKeyProcedureOperation];
#if 0 // TODO execute storedProcedure and fetch results;

              if (nextPKProcedure)
                [[[self _obtainOpenChannel] adaptorChannel]
                  executeStoredProcedure: nextPKProcedure
                  withValues:];
#endif                  

              pkAttributes = [entity primaryKeyAttributes];

              if (pk == nil && [pkAttributes count] == 1)
                {
                  EOAttribute *pkAttr = [pkAttributes objectAtIndex: 0];
                  //TODO attr: adaptorValueType //returned EOAdaptorNumberType
                  //TODO [entity rootParent];//so what

                  if (channel == nil)
                    {
                      channel = [[self _obtainOpenChannel] adaptorChannel];

                      if ([[channel adaptorContext]
			    transactionNestingLevel] == 0)
                        [[channel adaptorContext] beginTransaction];

                      if (_flags.beganTransaction == NO)
                        {
                          EOFLOGObjectLevel(@"EODatabaseContext",
					    @"BEGAN TRANSACTION FLAG==>NO");
                          _flags.beganTransaction = YES;
                        }
                    }

                  pk = [channel primaryKeyForNewRowWithEntity: entity];

                  EOFLOGObjectLevelArgs(@"EODatabaseContext",
					@"** prepare pk %@", pk);

                  if (pk == nil && [[pkAttr valueClassName]
				     isEqual:@"NSData"] == YES)
                    {
                      unsigned char data[EOUniqueBinaryKeyLength];

                      [EOTemporaryGlobalID assignGloballyUniqueBytes: data];

                      pk = [NSDictionary dictionaryWithObject:
                                           [NSData dataWithBytes: data
                                                   length:
						     EOUniqueBinaryKeyLength]
                                         forKey: [pkAttr name]];
                    }
                }
            }

          if (!pk)
            [NSException raise: NSInvalidArgumentException
                         format: @"%@ -- %@ 0x%x: cannot generate primary key for object '%@'",
                         NSStringFromSelector(_cmd),
                         NSStringFromClass([self class]),
                         self, object];
        }
    }
/*
  else // !shouldGeneratePrimaryKey
*/
  if (!pk)
    {
      // MG
      // Here we'll find if there is a "parent" objects which relay pk
      // I'm not sure if we could do it here but it's handle this case:
      //    object is a new child of a previous existing object.
      //	if we don't generate it's pk here, the chld object 
      //	will relay it's pk to parent which is not good
      NSDictionary *objectSnapshot=nil;
      NSArray *relationships=nil;
      int i=0;
      int relationshipsCount=0;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%@", object);

      // get object snapshot
      objectSnapshot = [object snapshot];      
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"objectSnapshot=%@",
                            objectSnapshot);

      // Get object relationships
      relationships = [entity relationships];      
      EOFLOGObjectLevelArgs(@"EODatabaseContext",@"relationships=%@",
                            relationships);
      
      relationshipsCount = [relationships count];
      
      for (i = 0; i < relationshipsCount; i++)
        {
          EORelationship *inverseRelationship = nil;

          EORelationship *relationship = [relationships objectAtIndex: i];
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationship=%@",
                                relationship);

          inverseRelationship = [relationship inverseRelationship];
          EOFLOGObjectLevelArgs(@"EODatabaseContext", @"inverseRelationship=%@",
                                inverseRelationship);
          
          // if there's inverse relationship with propagates primary key
          if ([inverseRelationship propagatesPrimaryKey])
            {
              NSString *relationshipName= [relationship name];
              NSDictionary *relationshipValuePK = nil;

              // get object value for the relationship
              id relationshipValue=[objectSnapshot valueForKey:relationshipName];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity name=%@ relationship name=%@ Value=%@",
                                    [entity name],relationshipName,relationshipValue);

              // get relationshipValue pk
              NSAssert2(!isNilOrEONull(relationshipValue), 
                        @"No relationshipValue for relationship %@ in objectSnapshot %@ ",
                        relationshipName,
                        objectSnapshot);

              relationshipValuePK = [self _primaryKeyForObject:relationshipValue];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationshipValuePK=%@",
                                    relationshipValuePK);

              // force object to relay pk now !
              [self relayPrimaryKey: relationshipValuePK
                    object: relationshipValue
                    entity: [_database entityForObject: relationshipValue]];
            };
        };
      pk = [self valuesForKeys: pkNames
                 object: object];
      if (![entity isPrimaryKeyValidInObject: pk])
        pk=nil;
    };
  if (pk)
    {
      EODatabaseOperation *dbOpe = [self databaseOperationForObject: object];
      NSMutableDictionary *newRow = [dbOpe newRow]; 
      
      [newRow addEntriesFromDictionary: pk];//VERIFY Here we replace previous key
    }
  
  EOFLOGObjectFnStop();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"pk=%@", pk);
  NSDebugMLog(@"object %p=%@\npk=%@",object, object, pk);

  return pk;
}

- (BOOL) _shouldGeneratePrimaryKeyForEntityName: (NSString*)entityName
{
  //OK
  BOOL shouldGeneratePK = YES;

  EOFLOGObjectFnStart();

  if (_nonPrimaryKeyGenerators)
    shouldGeneratePK = !NSHashGet(_nonPrimaryKeyGenerators, entityName);

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"shouldGeneratePK for %@: %s",
			entityName,
			(shouldGeneratePK ? "YES" : "NO"));
  NSAssert(![entityName isEqualToString: @"Country"]
	   || shouldGeneratePK, @"MGVALID: Failed");

  EOFLOGObjectFnStop();

  return shouldGeneratePK;
}

- (void)_buildPrimaryKeyGeneratorListForEditingContext: (EOEditingContext*)context
{
  NSArray *objects[3];
  NSHashTable *processedEntities = NULL;
  NSMutableArray *entityToProcess = nil;
  int i, which;

  EOFLOGObjectFnStart();

  if (_nonPrimaryKeyGenerators)
    {
      NSResetHashTable(_nonPrimaryKeyGenerators);
    }

  processedEntities = NSCreateHashTable(NSObjectHashCallBacks, 32);

  objects[0] = [context updatedObjects];
  objects[1] = [context insertedObjects];
  objects[2] = [context deletedObjects];

  for (which = 0; which < 3; which++)
    {
      int count = [objects[which] count];

      for (i = 0; i < count; i++)
        {
          id object = [objects[which] objectAtIndex: i];
          EOEntity *entity = [_database entityForObject: object];

          EOFLOGObjectLevelArgs(@"EODatabaseContext",
				@"add entity to process: %@", [entity name]);

          if (entityToProcess)
            [entityToProcess addObject: entity];
          else
            entityToProcess = [NSMutableArray arrayWithObject: entity];
        }
    }
  
  while ([entityToProcess count])
    {
      EOEntity *entity = [entityToProcess lastObject];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"test entity: %@",
			    [entity name]);

      [entityToProcess removeLastObject];

      if (!NSHashInsertIfAbsent(processedEntities, entity)) //Already processed ?
        {
          NSArray *relationships = nil;
          int iRelationship = 0;
          int relationshipsCount = 0;

          relationships = [entity relationships];              
          iRelationship = 0;
          relationshipsCount = [relationships count];

          for (iRelationship = 0;
	       iRelationship < relationshipsCount;
	       iRelationship++)
            {
              EORelationship *relationship = [relationships objectAtIndex:
							      iRelationship];
              EOFLOGObjectLevelArgs(@"EODatabaseContext", @"test entity: %@ relationship=%@",
                                    [entity name],
                                    relationship);

              if ([relationship propagatesPrimaryKey])
                {
                  EOEntity *destinationEntity = [relationship
						  destinationEntity];
                  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"test entity: %@ destinationEntity=%@",
                                        [entity name],
                                        [destinationEntity name]);

                  if (destinationEntity)
                    {
		      NSArray *destAttrs;
		      NSArray *pkAttrs;
		      int i, count;
		      BOOL destPK = NO;

		      destAttrs = [relationship destinationAttributes];
		      pkAttrs = [destinationEntity primaryKeyAttributes];
		      count = [destAttrs count];

		      for (i = 0; i < count; i++)
			{
			  if ([pkAttrs containsObject: [destAttrs
							 objectAtIndex: i]])
			    destPK = YES;
			}

		      if (destPK)
			{
			  EOFLOGObjectLevelArgs(@"EODatabaseContext",
						@"destination entity: %@ No PrimaryKey Generation [Relationship = %@]",
						[destinationEntity name],
						[relationship name]);

			  if (!_nonPrimaryKeyGenerators)
			    _nonPrimaryKeyGenerators = NSCreateHashTable(NSObjectHashCallBacks, 32);

			  NSHashInsertIfAbsent(_nonPrimaryKeyGenerators, [destinationEntity name]);
			  [entityToProcess addObject: destinationEntity];
			}
                    }
                }
            }
        }
    }

  EOFLOGObjectFnStop();

  NSFreeHashTable(processedEntities);
}

/** Returns a dictionary containing a snapshot of object that reflects its committed values (last values putted in the database; i.e. values before changes were made on the object).
It is updated after commiting new values.
If the object has been just inserted, the dictionary is empty.
**/
- (NSDictionary*)_currentCommittedSnapshotForObject: (id)object
{
  NSDictionary *snapshot = nil;
  EOGlobalID *gid = nil;
  EODatabaseOperation *dbOpe = nil;
  EODatabaseOperator dbOperator = (EODatabaseOperator)0;

  EOFLOGObjectFnStart();

  gid = [_editingContext globalIDForObject: object];
  dbOpe = [self databaseOperationForGlobalID: gid]; //I'm not sure. Retrieve it directly ?
  dbOperator = [dbOpe databaseOperator];

  switch (dbOperator)
    {
    case EODatabaseUpdateOperator:
      snapshot = [_editingContext committedSnapshotForObject: object];//OK
      break;

    case EODatabaseInsertOperator:
      snapshot = [NSDictionary dictionary];
      break;

//TODO
/*  else 
    snapshot=XX;//TODO
*/
    case EODatabaseDeleteOperator:
      break;

    case EODatabaseNothingOperator:
      break;
    }

  EOFLOGObjectFnStop();

  return snapshot;
}


- (void) _assertValidStateWithSelector: (SEL)sel
{
//  [self notImplemented:_cmd]; //TODO
}

- (id) _addDatabaseContextStateToException: (id)param0
{
  NSEmitTODO();
  return [self notImplemented: _cmd]; //TODO
}

- (id) _databaseContextState
{
  NSEmitTODO();
  return [self notImplemented: _cmd]; //TODO
}

@end
