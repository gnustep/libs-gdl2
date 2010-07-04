/** 
   EODatabaseContext.m  <title>EODatabaseContext Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSZone.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyValueCoding.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#endif

#include <GNUstepBase/GSObjCRuntime.h>

#include <EOControl/EOFault.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOGenericRecord.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOSortOrdering.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EOCheapArray.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EONull.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOAttributePriv.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EOJoin.h>

#include <EOAccess/EODatabase.h>
#include <EOAccess/EODatabaseContext.h>
#include <EOAccess/EODatabaseChannel.h>
#include <EOAccess/EODatabaseOperation.h>
#include <EOAccess/EOAccessFault.h>
#include <EOAccess/EOExpressionArray.h>
#include <EOAccess/EOSQLExpression.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"
#include "EOAccessFaultPriv.h"
#include "EODatabaseContextPriv.h"

#include <string.h>


#define _LOCK_BUFFER 128


NSString *EODatabaseChannelNeededNotification = @"EODatabaseChannelNeededNotification";

NSString *EODatabaseContextKey = @"EODatabaseContextKey";
NSString *EODatabaseOperationsKey = @"EODatabaseOperationsKey";
NSString *EOFailedDatabaseOperationKey = @"EOFailedDatabaseOperationKey";

NSString *EOCustomQueryExpressionHintKey = @"EOCustomQueryExpressionHintKey";
NSString *EOStoredProcedureNameHintKey = @"EOStoredProcedureNameHintKey";

static BOOL _useToManyCaching = YES;

@interface EODatabaseContext(EOObjectStoreSupportPrivate)
- (id) entityForGlobalID: (EOGlobalID *)globalID;
@end

@implementation EODatabaseContext

// Initializing instances

static Class _contextClass = Nil;

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_EOAccessPrivateInit();

      _contextClass = GDL2_EODatabaseContextClass;

      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_registerDatabaseContext:)
        name: EOCooperatingObjectStoreNeeded
        object: nil];
    }
}

+ (EODatabaseContext*)databaseContextWithDatabase: (EODatabase *)database
{
  return AUTORELEASE([[self alloc] initWithDatabase: database]);
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

  if (entityName)
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

/*
 * this exists, see EOF 2.2 Release Notes
 * http://support.apple.com/kb/TA26740?viewlocale=en_US
 */

+ (void) _setUseToManyCaching:(BOOL) yn
{
  _useToManyCaching = yn;
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
  if ((self = [self init]))
    {
      _adaptorContext = RETAIN([[database adaptor] createAdaptorContext]);

      if (_adaptorContext == nil)
        {
          NSLog(@"EODatabaseContext could not create adaptor context");
          AUTORELEASE(self);

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
      _missingObjectGIDs = [NSMutableSet new];

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
      
      
      /* //TODO ?
         transactionStackTop = NULL;
         transactionNestingLevel = 0;
         isKeepingSnapshots = YES;
         isUniquingObjects = [database uniquesObjects];
         [database contextDidInit:self];*/
    }



  return self;
}

/**
 * Convenience method to check if our delegate handles database exceptions 
 * or if we have to do it ourself.
 */

- (BOOL) _delegateHandledDatabaseException:(NSException *) exception
{
  if (_delegateRespondsTo.shouldHandleDatabaseException)
  {
    
    return ([_delegate databaseContext:self
         shouldHandleDatabaseException:exception] == NO);
    
  } 
  return NO;
}

- (void)_snapshotsChangedInDatabase: (NSNotification *)notification
{
  //OK EOObjectsChangedInStoreNotification EODatabase 


  if ([notification object] == _database)//??
    [[NSNotificationCenter defaultCenter]
      postNotificationName: [notification name]
      object: self
      userInfo: [notification userInfo]];//==> _objectsChanged
}


- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [_database unregisterContext: self];

  DESTROY(_adaptorContext);
  DESTROY(_database);

  if (_dbOperationsByGlobalID)
    {
      NSDebugMLog(@"MEMORY: dbOperationsByGlobalID count=%u",
		  NSCountMapTable(_dbOperationsByGlobalID));
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
  DESTROY(_missingObjectGIDs);

  DESTROY(_lastEntity);

  if (_nonPrimaryKeyGenerators)
    {
      NSDebugMLog(@"MEMORY: nonPrimaryKeyGnerators count=%u",
		  NSCountHashTable(_nonPrimaryKeyGenerators));

      NSFreeHashTable(_nonPrimaryKeyGenerators);
      _nonPrimaryKeyGenerators = NULL;
    }

  if (_lockedObjects)
    {
      NSResetHashTable(_lockedObjects);
    }

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



  if (model && editingContext)
    { 
      IMP enumNO=NULL; // nextObject
      edObjectStore = (EOObjectStoreCoordinator *)[editingContext rootObjectStore];
      cooperatingObjectStores = [edObjectStore cooperatingObjectStores];	// get all EODatabaseContexts

      storeEnum = [cooperatingObjectStores objectEnumerator];

      while ((coObjectStore = GDL2_NextObjectWithImpPtr(storeEnum,&enumNO)))
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
  NSUInteger count = 0;

  count = [_registeredChannels count];  

  if (count>0)
    {
      NSUInteger i = 0;
      IMP oaiIMP=[_registeredChannels methodForSelector: @selector(objectAtIndex:)];

      for (i = 0 ; !busy && i < count; i++)
        {
          EODatabaseChannel *channel = GDL2_ObjectAtIndexWithImp(_registeredChannels,oaiIMP,i);
          
          busy = [channel isFetchInProgress];
        }
    };

  return busy;
}

- (NSArray *)registeredChannels
{
  return _registeredChannels;
}

/*
 Adds channel to the pool of available channels used to service database requests. 
 Registered channels are retained by the receiver. 
 */

- (void)registerChannel: (EODatabaseChannel *)channel
{
//call channel databaseContext
//test if not exists  _registeredChannels indexOfObjectIdenticalTo:channel
  NSDebugLog(@"** REGISTER channel ** debug:%d ** total registered:%d",
	     [[channel adaptorChannel] isDebugEnabled],
	     [_registeredChannels count] + 1);

  [_registeredChannels addObject:channel];
  [channel setDelegate: nil];
}

- (void)unregisterChannel: (EODatabaseChannel *)channel
{
  [_registeredChannels removeObjectIdenticalTo:channel];
}

/** returns a non busy channel if any, nil otherwise **/
-(EODatabaseChannel *)_availableChannelFromRegisteredChannels
{
  NSEnumerator *channelsEnum;
  EODatabaseChannel *channel = nil;
  IMP enumNO=NULL; // nextObject

  channelsEnum = [_registeredChannels objectEnumerator];

  while ((channel = GDL2_NextObjectWithImpPtr(channelsEnum,&enumNO)))
    {
      if ([channel isFetchInProgress] == NO)
        {
          return channel;
        }
      else
        {
//          NSDebugMLLog(@"EODatabaseContext",@"CHANNEL %p is busy",
//		       [channel nonretainedObjectValue]);
        }
    }

  return nil;
}

/** return a non busy channel **/
- (EODatabaseChannel *)availableChannel
{
  EODatabaseChannel *channel = nil;
  NSUInteger num = 2;

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

  if ((!channel) && ([_registeredChannels count] < 1)) {
    channel = [EODatabaseChannel databaseChannelWithDatabaseContext: self];
    if (channel)
    {
      [self registerChannel:channel];
    }
    
  }

  return channel;
}

/** returns the database **/
- (EODatabase *)database
{
  return _database;
}

- (void) setCoordinator:(EOObjectStoreCoordinator *) newCoordinator
{
  [super setCoordinator: newCoordinator];

  // TODO: locking magic.
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
      && [[_database snapshots] count])
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
  IMP enumNO=NULL; // nextObject

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
  _delegateRespondsTo.shouldHandleDatabaseException = 
  [delegate respondsToSelector: @selector(databaseContext:shouldHandleDatabaseException:)];
  _delegateRespondsTo.databaseContextFailedToFetchObject =
  [delegate respondsToSelector: @selector(databaseContext:failedToFetchObject:globalID:)];


  while ((channel = GDL2_NextObjectWithImpPtr(channelsEnum,&enumNO)))
    [channel setDelegate: delegate];
}

- (void)handleDroppedConnection
{
  DESTROY(_adaptorContext);

  DESTROY(_registeredChannels);

  _adaptorContext = RETAIN([[[self database] adaptor] createAdaptorContext]);
  _registeredChannels = [NSMutableArray new];

}

- (NSArray *) missingObjectGlobalIDs
{
  return [_missingObjectGIDs allObjects];
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



  entity = [_database entityNamed: entityName];
  gid = [entity globalIDForRow: row];

  object = [self faultForGlobalID: gid
		 editingContext: context];

  NSDebugMLLog(@"EODatabaseContext", @"object=%p of class (%@)",
	       object, [object class]);



  return object;
}

/** return entity corresponding to 'globalID' **/
- (id) entityForGlobalID: (EOGlobalID *)globalID
{
  NSString *entityName;

  entityName = [(EOKeyGlobalID *)globalID entityName];

  if ((_lastEntity) && (entityName == [_lastEntity name]))
  {
    return _lastEntity;
  }
  
  ASSIGN(_lastEntity, [_database entityNamed: entityName]);

  return _lastEntity;
}

/** Make object a fault **/
- (void) _turnToFault: (id)object
                  gid: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context
           isComplete: (BOOL)isComplete
{
  //OK
  EOAccessFaultHandler *handler;






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


  NSDebugMLLog(@"EODatabaseContext", @"object->class_pointer=%p",
	       GSObjCClass(object));

  [EOFault makeObjectIntoFault: object
	   withHandler: handler];

  NSDebugMLLog(@"EODatabaseContext", @"object->class_pointer=%p",
	       GSObjCClass(object));

  [self _addBatchForGlobalID: (EOKeyGlobalID*)globalID
        fault: object];


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





  isFinal = [(EOKeyGlobalID *)globalID isFinal];
  entity = [self entityForGlobalID: globalID];

  NSAssert(entity, @"no entity");

  classDescription = [entity classDescriptionForInstances];



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


  if ([(EOKeyGlobalID *)globalID areKeysAllNulls])
    NSWarnLog(@"All key of globalID %p (%@) are nulls",
              globalID,
              globalID);

  [self _turnToFault: object
        gid: globalID
        editingContext: context
        isComplete: isFinal];//??
  


  EOEditingContext_recordObjectGlobalIDWithImpPtr(context,NULL,object,globalID);



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
  NSDictionary * snapDict = nil;
  EOEntity     * entity = nil;

  /*
   TODO use this stuff -- dw
  if (globalID == _currentGlobalID)
  {
    snapDict = _currentSnapshot;
    entity = _lastEntity;
  } else ...
  */  
  
  if ([globalID isTemporary])
  {
    return;
  }
  
  snapDict = [self snapshotForGlobalID:globalID];
  
  if ([(EOKeyGlobalID *)globalID isFinal])
  {
    entity = [self entityForGlobalID:globalID];
  } else {
    object = [context objectForGlobalID:globalID];
    if (!object)
    {
      [NSException raise: NSInternalInconsistencyException
                  format: @"%s No object for gid %@ in %@", __PRETTY_FUNCTION__, globalID, context];      
    }
    entity = [_database entityForObject:object];
  }

  if (!snapDict)
  {
    [NSException raise: NSInternalInconsistencyException
                format: @"%s No snapshot for gid %@", __PRETTY_FUNCTION__, globalID];      
  } else {
    
    [self initializeObject: object
                       row: snapDict
                    entity: entity
            editingContext: context];
        
    [_database incrementSnapshotCountForGlobalID:globalID];
  }
  
}

- (void) _objectsChanged: (NSNotification*)notification
{
  /*object==self EOObjectsChangedInStoreNotification
   userInfo = {
   deleted = (List Of GlobalIDs); 
   inserted = (List Of GlobalIDs); 
   updated = (List Of GlobalIDs); 
   */
  
  if ([notification object] != self)
  {
    // not sure if that ever happens -- dw
    NSEmitTODO();
    [self notImplemented: _cmd]; //TODO
  }
  else
  {
    NSMutableArray * workArray = [NSMutableArray array];
    NSDictionary   * userInfo  = [notification userInfo];
    NSArray        * myObjects = nil;
    NSUInteger       i, count;
    
    if ((myObjects = [userInfo objectForKey: EOUpdatedKey])) 
    {
      [workArray addObjectsFromArray:myObjects];
    }
    
    if ((myObjects = [userInfo objectForKey: EOInsertedKey])) 
    {
      [workArray addObjectsFromArray:myObjects];
    }
    
    if ((myObjects = [userInfo objectForKey: EODeletedKey])) 
    {
      [workArray addObjectsFromArray:myObjects];
    }
    
    if ((myObjects = [userInfo objectForKey: EOInvalidatedKey])) 
    {
      [workArray addObjectsFromArray:myObjects];
    }
    
    count = [workArray count];
        
    if (count>0)
    {
      IMP oaiIMP=[workArray methodForSelector: @selector(objectAtIndex:)];
      
      for (i = 0; i < count; i++)
      {
        EOKeyGlobalID *gid=GDL2_ObjectAtIndexWithImp(workArray,oaiIMP,i);
        NSString *entityName;
        
        if ([gid isKindOfClass:[EOKeyGlobalID class]]) {
          entityName = [gid entityName];
          
          [_database invalidateResultCacheForEntityNamed: entityName];
        }
      }
    }
    
  }
}

- (void) _snapshotsChangedInDatabase: (NSNotification*)notification
{


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
  NSUInteger sourceSnapshotCount = 0;





  //First get the id from which we search the source object
  sourceObjectFault = [context faultForGlobalID: globalID
			       editingContext: context];

  NSDebugMLLog(@"EODatabaseContext", @"sourceObjectFault %p=%@",
	       sourceObjectFault, sourceObjectFault);

  // Get the fault value from source object


  relationshipValue = [sourceObjectFault storedValueForKey: name];

  NSDebugMLLog(@"EODatabaseContext", @"relationshipValue %p=%@",
	       relationshipValue, relationshipValue);

  //Try to see if there is a snapshot for the source object
  sourceSnapshot = [_database snapshotForSourceGlobalID: globalID
			      relationshipName: name];

  NSDebugMLLog(@"EODatabaseContext", @"sourceSnapshot %p (%@)=%@",
	       sourceSnapshot, [sourceSnapshot class],
	       sourceSnapshot);

  sourceSnapshotCount = [sourceSnapshot count];

  if (sourceSnapshotCount > 0)
    {
      EOGlobalID *snapGID = nil;
      id snapFault = nil;
      NSUInteger i;
      IMP addObjectIMP=NULL;
      IMP oaiIMP=NULL;

      [EOFault clearFault: relationshipValue];

      // Be carefull: Never call methodForSelector before clearing fault !
      addObjectIMP=[relationshipValue methodForSelector:@selector(addObject:)];
      oaiIMP=[sourceSnapshot methodForSelector: @selector(objectAtIndex:)];
          

      for (i = 0; i < sourceSnapshotCount; i++)
        {
          snapGID = GDL2_ObjectAtIndexWithImp(sourceSnapshot,oaiIMP,i);



          snapFault = [context faultForGlobalID: snapGID
			       editingContext: context]; 

          NSDebugMLLog(@"EODatabaseContext", @"snapFault=%@",
		       snapFault);

          GDL2_AddObjectWithImp(relationshipValue,addObjectIMP,snapFault);
        }

      objects = relationshipValue;
    }
  else
    {  
      EOEntity *entity;
      EORelationship *relationship;
      NSUInteger maxBatch = 0;
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

      NSDebugMLLog(@"EODatabaseContext", @"entity name=%@",
		   [entity name]);

      //Get the relationship named 'name'
      relationship = [entity relationshipNamed: name];

      NSDebugMLLog(@"EODatabaseContext", @"relationship=%@",
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
      NSDebugMLLog(@"EODatabaseContext", @"destinationEntity name=%@",
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
      contextSourceSnapshot = EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,globalID);

      //NSEmitTODO();
      //TODO Why first asking for faultForGlobalID and now asking objectForGlobalID ??

      sourceObject = [context objectForGlobalID: globalID];

      
      inverseRelationship = [relationship inverseRelationship];
      NSDebugMLLog(@"EODatabaseContext", @"inverseRelationship=%@",
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




      qualifier = [EOKeyValueQualifier qualifierWithKey: invRelName
				       operatorSelector: @selector(isEqualTo:)
				       value: sourceObject];



      fetchSpec = [EOFetchSpecification fetchSpecification];

      [fetchSpec setQualifier: qualifier];
      [fetchSpec setEntityName: [destinationEntity name]];



      objects = [context objectsWithFetchSpecification: fetchSpec
			 editingContext: context];

      [self _registerSnapshot: objects
            forSourceGlobalID: globalID
            relationshipName: name
            editingContext: context];//OK
    }




  return objects;
}

- (void)_registerSnapshot: (NSArray*)snapshot
        forSourceGlobalID: (EOGlobalID*)globalID
         relationshipName: (NSString*)name
           editingContext: (EOEditingContext*)context
{
  //OK
  NSArray *gids;



  gids = [context resultsOfPerformingSelector: @selector(globalIDForObject:)
		  withEachObjectInArray: snapshot];

  [_database recordSnapshot: gids
             forSourceGlobalID: globalID
             relationshipName: name];


}

- (void)refaultObject: object
	 withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context
{


  [EOObserverCenter suppressObserverNotification];

  NS_DURING
    {
      [object clearProperties];//OK
    }
  NS_HANDLER
    {
      [EOObserverCenter enableObserverNotification];



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

  [self forgetSnapshotForGlobalID:globalID];


}

- (void)saveChangesInEditingContext: (EOEditingContext *)context
{
  //TODO: locks ?
  NSException *exception = nil;



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



  if ([objsArray count] > 0)
    {
      IMP globalIDForObjectIMP=NULL;
      IMP enumNO=NULL; // nextObject

      qualArray = [NSMutableArray arrayWithCapacity: 5];

      if ([relationship isFlattened] == YES)
        {
          NSDebugMLLog(@"EODatabaseContext",
		       @"relationship %@ isFlattened", relationship);

          relEnum = [[relationship componentRelationships] objectEnumerator];
          enumNO=NULL;
          while ((relationship = GDL2_NextObjectWithImpPtr(relEnum,&enumNO)))
            {
              // TODO rebuild object array for relationship path
              
              [self _fetchRelationship: relationship
                    withObjects: objsArray
                    editingContext: context];
            }
        }
      
      objEnum = [objsArray objectEnumerator];
      enumNO=NULL;
      while ((obj = GDL2_NextObjectWithImpPtr(objEnum,&enumNO)))
        {
          EOGlobalID* gid=nil;
          relObj = [obj storedValueForKey: [relationship name]];
          gid = EOEditingContext_globalIDForObjectWithImpPtr(context,&globalIDForObjectIMP,relObj);
          snapshot = EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,gid);
          
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


}

- (NSArray*) _fetchRawRowKeyPaths:(NSArray *) rawRowKeyPaths
               fetchSpecification: (EOFetchSpecification*) fetchSpecification
                           entity: (EOEntity *) entity
                   editingContext: (EOEditingContext *) context
{
  EOAdaptorChannel * adaptorChannel = [[self availableChannel] adaptorChannel];
  NSMutableArray   * results        =  [NSMutableArray array];
  NSUInteger         fetchLimit     = 0;
  NSUInteger         rowsFetched    = 0;
  NSUInteger         keyCount       = [rawRowKeyPaths count];
  id                 messageHandler = nil;   // used to prompt the user after the fetch limit is reached.
  NSString         * hintKey = nil;
  BOOL               continueFetch  = NO;
  NSUInteger         k;
  EOSQLExpression  * expression     = nil;
    
  NSMutableArray * attributesToFetch;
  if (keyCount == 0)
  {
    // this is an NSMutableArray
    attributesToFetch = (NSMutableArray *) [entity attributesToFetch];
  } else {
    // Populate an array with the attributes we need
    attributesToFetch =  [NSMutableArray arrayWithCapacity:keyCount];
    BOOL hasNonFlattenedAttributes = NO;
    
    for (k = 0; k < keyCount; k++)
    {
      NSString * keyName = [rawRowKeyPaths objectAtIndex:k];
      EOAttribute * attr = [entity attributeNamed:keyName];
      if (!attr)
      {
        attr = [EOAttribute attributeWithParent:entity
                                     definition:keyName];

      } else {
        if ((!hasNonFlattenedAttributes) && (![attr isFlattened]))
        {
          hasNonFlattenedAttributes = YES;
        }
      }
      [attributesToFetch addObject:attr];
    }
    
    if (!hasNonFlattenedAttributes)
    {
      // check if lastObject is enouth.
      // the reference however does only checks the lastObject.
      
      EOAttribute    * attr = [attributesToFetch lastObject];
      EORelationship * relationship;
      
      if ([attr isFlattened])
      {
        relationship = [[attr _definitionArray] objectAtIndex:0];
      } else {
        NSString * lastPath = [rawRowKeyPaths lastObject];
        NSString * relName = [[lastPath componentsSeparatedByString:@"."] objectAtIndex:0];
        relationship = [entity relationshipNamed:relName];
        
        if ([relationship isFlattened])
        {
          relationship = [[relationship _definitionArray] objectAtIndex:0];
        }
      }
      
      EOJoin      * join   = [[relationship joins] lastObject];
      EOAttribute * attr2  = [join sourceAttribute];
      
      [attributesToFetch addObject:attr2];
    }
    // our channel does not support this.
    //[adaptorChannel _setRawDictionaryInitializerForAttributes:attributesToFetch];
  }
  if ((hintKey = [[fetchSpecification hints] objectForKey:@"EOCustomQueryExpressionHintKey"]))
  {
    if ([hintKey isKindOfClass:[NSString class]])
    {
      expression = [[[_adaptorContext adaptor] expressionClass] expressionForString:hintKey];
    } else {
      NSLog(@"%s - %@ is not an NSString but a %@",__PRETTY_FUNCTION__, hintKey, NSStringFromClass([hintKey class]));
    }
  } else {
    EOQualifier * qualifier = [[fetchSpecification qualifier] schemaBasedQualifierWithRootEntity:entity];
    
    if (qualifier != [fetchSpecification qualifier])
    {
      [fetchSpecification setQualifier:qualifier];
    }
  }
  if (![adaptorChannel isOpen])
  {
    [adaptorChannel openChannel];
  }
  if (expression)
  {
    [adaptorChannel evaluateExpression:expression];
    [adaptorChannel setAttributesToFetch:attributesToFetch];
  } else {
    [adaptorChannel selectAttributes:attributesToFetch
                  fetchSpecification:fetchSpecification
                                lock:NO
                              entity:entity];
  }
  
  // 0 is no fetch limit
  fetchLimit = [fetchSpecification fetchLimit];
  // TODO: check if we need to check for protocol EOMessageHandlers
  if ((fetchLimit > 0) && (([fetchSpecification promptsAfterFetchLimit]) &&
                           ([context messageHandler])))
  {
    messageHandler = [context messageHandler];
  }  
  
  
  do {
    do {
      NSMutableDictionary * dict = [adaptorChannel fetchRowWithZone:NULL];
      if (!dict) {
        break;
      }
      [results addObject:dict];
      rowsFetched++;
    } while ((fetchLimit == 0) || (rowsFetched < fetchLimit));
    
    if (!messageHandler) {
      break;
    }
    
    continueFetch = [messageHandler editingContext:context
      shouldContinueFetchingWithCurrentObjectCount:rowsFetched
                                     originalLimit:fetchLimit
                                       objectStore:self];
    
  } while (continueFetch);
  
  [adaptorChannel cancelFetch];
  
  if (_delegate)
  {
    
    [_delegate databaseContext: self
               didFetchObjects: results
            fetchSpecification: fetchSpecification
                editingContext: context];
  }
  return results;
}

- (void) _populateCacheForFetchSpecification:(EOFetchSpecification *) eofetchspecification
                              editingContext:(EOEditingContext *)eoeditingcontext
{
  NSEmitTODO();
}

- (BOOL) _validateQualifierForEvaluationInMemory:(EOQualifier *) qualifier
                                          entity:(EOEntity *)entity

{
  NSEmitTODO();
  return NO;
}

// _objectsFromEntityCacheWithFetchSpecEditingContext
- (NSArray*) _objectsFromEntityCacheWithFetchSpec:(EOFetchSpecification*) fetchSpecification
                                   editingContext: (EOEditingContext *)context
{
  NSEmitTODO();
  return nil;
}

- (void) _performPrefetchForFetchSpecification:(EOFetchSpecification*) fetchSpecification
                                editingContext:(EOEditingContext *)context
                                       results:(NSArray*) results
                                      keyPaths:(NSArray*) prefetchingRelationshipKeyPaths
{
  NSEmitTODO();
  return;
}


- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
			                      editingContext: (EOEditingContext *)context
{ 
  id                 messageHandler = nil;
  EODatabaseChannel *channel = nil;
  NSMutableArray *array = nil;
  NSString *entityName = nil;
  EOEntity *entity = nil;
  NSArray* rawRowKeyPaths = nil;
  NSUInteger fetchLimit=0;
  NSArray   * prefetchingRelationshipKeyPaths = nil;
  NSUInteger         rowsFetched    = 0;
  BOOL               continueFetch  = NO;

	channel = [self _obtainOpenChannel];
  
  if (_flags.beganTransaction == NO)
  {
    [_adaptorContext beginTransaction];
    
    _flags.beganTransaction = YES;
  }
  
  if (_delegateRespondsTo.shouldFetchObjects == YES)
  {
    array = (id)[_delegate databaseContext: self
  shouldFetchObjectsWithFetchSpecification: fetchSpecification
                            editingContext: context];
    if (array) {
      return array;
    }
  }
  
  entityName = [fetchSpecification entityName];
  entity = [_database entityNamed: entityName];
  
  if (!entity)
  {
    return [NSArray array];
  }
  
  if ([entity isAbstractEntity] && (![fetchSpecification isDeep]))
  {
    [NSException raise:NSInternalInconsistencyException
                format:@"A FetchSpecification for an abstract entity must be 'deep'! Entity: ",
     entityName];
  }
  
  rawRowKeyPaths = [fetchSpecification rawRowKeyPaths];
  if (rawRowKeyPaths)
  {
    NSArray * rawRows = [self _fetchRawRowKeyPaths:rawRowKeyPaths
                                fetchSpecification:fetchSpecification
                                            entity:entity
                                    editingContext:context];
    return rawRows;
  } 
  
  if ((!_flags.ignoreEntityCaching) && [entity cachesObjects])
  {
    [self _populateCacheForFetchSpecification:fetchSpecification
                               editingContext:context];
  }
  
  if (((!_flags.ignoreEntityCaching) && [entity cachesObjects]) && 
      ([fetchSpecification isDeep] && 
       [self _validateQualifierForEvaluationInMemory:[fetchSpecification qualifier]
                                              entity:entity]))
  {
    return [self _objectsFromEntityCacheWithFetchSpec:fetchSpecification
                                       editingContext:context];
  }
  
  array = [NSMutableArray arrayWithCapacity: 8];
  
  [channel selectObjectsWithFetchSpecification: fetchSpecification
                                editingContext: context];
  
  // 0 is no fetch limit. if there is no limit, it makes no sense to ask
  fetchLimit = [fetchSpecification fetchLimit];
  if ((fetchLimit > 0) && (([fetchSpecification promptsAfterFetchLimit]) &&
                           ([context messageHandler])))
  {
    messageHandler = [context messageHandler];
  }  
  
  do {
    do {
      id freshObj = [channel fetchObject];
      if (!freshObj) {
        break;
      }
      [array addObject:freshObj];
      rowsFetched++;
    } while ((fetchLimit == 0) || (rowsFetched < fetchLimit));
    
    if (!messageHandler) {
      break;
    }
    
    continueFetch = [messageHandler editingContext:context
      shouldContinueFetchingWithCurrentObjectCount:rowsFetched
                                     originalLimit:fetchLimit
                                       objectStore:self];
    
  } while (continueFetch);
  
  [channel cancelFetch];
  
  prefetchingRelationshipKeyPaths = [fetchSpecification prefetchingRelationshipKeyPaths];
  
  if ((prefetchingRelationshipKeyPaths) && ([prefetchingRelationshipKeyPaths count] > 0))
  {
    [self _performPrefetchForFetchSpecification:fetchSpecification
                                 editingContext:context
                                        results:array
                                       keyPaths:prefetchingRelationshipKeyPaths];
  }
  
  if (_delegateRespondsTo.didFetchObjects == YES)
    [_delegate databaseContext: self
               didFetchObjects: array
            fetchSpecification: fetchSpecification
                editingContext: context];
  
  [channel setCurrentEditingContext:nil];
  
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
  EOQualifier *qualifier = nil;
  EOAttribute *attribute;

  if ([self isObjectLockedWithGlobalID: gid] == NO)
    {
      IMP enumNO=NULL; // nextObject
      snapshot = EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,gid);

      if (_delegateRespondsTo.shouldLockObject == YES &&
	 [_delegate databaseContext: self
		    shouldLockObjectWithGlobalID: gid
		    snapshot: snapshot] == NO)
	  return;

      /* If we do not have a snapshot yet, the the object
	 is probably faulted.  The reference implementation seems
	 to ignore the lock in this case.  We will try to do better
	 and if we can't, we'll acually raise as documented.  */
      if (snapshot == nil)
	{
         id obj = [context objectForGlobalID: gid];
         if ([EOFault isFault: obj]) [obj self];
         snapshot = [self snapshotForGlobalID: gid];
	}
      NSAssert1(snapshot,@"Could not obtain snapshot for %@", gid);

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
      enumNO=NULL;
      while ((attribute = GDL2_NextObjectWithImpPtr(attrsEnum,&enumNO)))
	{
	  NSString *name = [attribute name];

	  [lockSnapshot setObject: [snapshot objectForKey:name]
			forKey: name];
	}

      attrsEnum = [attrsUsedForLocking objectEnumerator];
      enumNO=NULL;
      while ((attribute = GDL2_NextObjectWithImpPtr(attrsEnum,&enumNO)))
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

          NSDebugMLLog(@"EODatabaseContext",
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
  NSDictionary *snapshots;
  NSArray *gids;

  [_database invalidateResultCache];

  snapshots = [_database snapshots];
  gids = [snapshots allKeys];
  [self invalidateObjectsWithGlobalIDs: gids];

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
      IMP enumNO=NULL; // nextObject
      array = [NSMutableArray array];
      enumerator = [globalIDs objectEnumerator];

      while ((gid = GDL2_NextObjectWithImpPtr(enumerator,&enumNO)))
	{
	  if ([_delegate databaseContext: self
			 shouldInvalidateObjectWithGlobalID: gid
			 snapshot: EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,gid)] == YES)
	    [array addObject: gid];
	}
    }

  [self forgetSnapshotsForGlobalIDs: ((id)array ? (id)array : globalIDs)];
}

@end


@implementation EODatabaseContext(EOCooperatingObjectStoreSupport)

- (BOOL)ownsGlobalID: (EOGlobalID *)globalID
{
  if ([globalID isKindOfClass: [EOKeyGlobalID class]] &&
      [_database entityNamed: [(EOKeyGlobalID*) globalID entityName]])
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
/* //Mirko:
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
    globalID = AUTORELEASE([[EOTemporaryGlobalID alloc] init]);

  op = AUTORELEASE([[EODatabaseOperation alloc] initWithGlobalID:globalID
						object:object
						entity:entity]);

  [op setDatabaseOperator:operator];
  [op setDBSnapshot:EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,globalID)];

  newRow = [op newRow];

  classProperties = [entity classProperties];

  count = [classProperties count];
  if (count>0)
    {
      IMP oaiIMP=[classProperties methodForSelector: @selector(objectAtIndex:)];
          
      for (i = 0; i < count; i++)
        {
          attribute = GDL2_ObjectAtIndexWithImp(classProperties,oaiIMP,i);
          if ([attribute isKindOfClass:GDL2_EOAttributeClass] == NO)
            continue;
          
          key = [attribute name];
          
          if ([attribute isFlattened] == NO)
            {
              val = [object storedValueForKey:key];
              
              if (val == nil)
                val = GDL2_EONull;
              
              [newRow setObject:val forKey:key];
            }
        }
    };

  NSMapInsert(_dbOperationsByGlobalID, globalID, op);

  return op;
}

*/


// private
- (NSArray*) _batchNewPrimaryKeysWithEntity:(EOEntity *) eoentity 
                                      count:(NSUInteger) i
{
  NSArray * nsarray = nil;
  
  NS_DURING {
    nsarray = [[[self _obtainOpenChannel] adaptorChannel] primaryKeysForNewRowsWithEntity:eoentity
                                                                                    count:i];
  } NS_HANDLER {
    if ([self _delegateHandledDatabaseException:localException])
    {
      nsarray = [[[self _obtainOpenChannel] adaptorChannel] primaryKeysForNewRowsWithEntity:eoentity
                                                                                      count:i];
    } else {
      if ([[_database adaptor] isDroppedConnectionException:localException])
      {
        [_database handleDroppedConnection];
        nsarray = [[[self _obtainOpenChannel] adaptorChannel] primaryKeysForNewRowsWithEntity:eoentity
                                                                                        count:i];
      } else {
        [localException raise];
      }
    }
  } NS_ENDHANDLER;
  
  return nsarray;
}

// Prepares to save changes.  Obtains primary keys for any inserted objects
// in the EditingContext that are owned by this context.
- (void)prepareForSaveWithCoordinator: (EOObjectStoreCoordinator *)coordinator
                       editingContext: (EOEditingContext *)context
{
  NSArray *insertedObjects = nil;
  NSUInteger count = 0, idx = 0;
  NSMutableDictionary * rootDict = nil;
  
  NSAssert(context, @"No editing context");
  
  if (_flags.preparingForSave)
  {
    [NSException raise:NSInternalInconsistencyException
                format:@"%s %@ is currently saving for %@ so it cannot prepare to save for %@.",
     __PRETTY_FUNCTION__, self, _editingContext, context];
  }
  
  if (coordinator)
  {
    EOObjectStoreCoordinator * oldCoordinator = [self coordinator];
    if (!oldCoordinator)
    {
      [self setCoordinator:coordinator];
    } else {
      if (oldCoordinator != coordinator)
      {
        [NSException raise:NSInternalInconsistencyException
                    format:@"%s %@ already has an EOObjectStoreCoordinator. "
         @"The database context needs to be removed from the cooperating object stores "
         @"before it can be assigned to a different coordinator.",
         __PRETTY_FUNCTION__, self];        
      }
    }
  }
  
  _flags.willPrepareForSave = NO;
  _flags.preparingForSave = YES;
  _editingContext=context;//RETAIN ?
  
  if ([_missingObjectGIDs count] > 0)
  {
    NSArray    * updatedObjects = [_editingContext updatedObjects];
    NSUInteger   idx = [updatedObjects count];
    for (; idx > 0; idx--)
    {
      EOGlobalID * globalid = [_editingContext globalIDForObject:[updatedObjects objectAtIndex:idx-1]];
      if ([_missingObjectGIDs member:globalid] != nil)
      {
        [NSException raise:NSObjectNotAvailableException
                    format:@"%s Cannot save the object with globalID %@. "
         @"The row referenced by this globalID was missing from the database at the time a fetch was attempted. "
         @"Either it was removed from the database after this application got a pointer to it, or there is a "
         @"referential integrity problem with your database. To be notified when fetches fail, implement a "
         @"delegate on EODatabaseContext that responds to"
         @"databaseContext:failedToFetchObject:globalID:.",
         __PRETTY_FUNCTION__, globalid];                
      }
    }
  }
  
  // First, create dbOperation map if there's none
  if (!_dbOperationsByGlobalID)
    _dbOperationsByGlobalID = NSCreateMapTable(NSObjectMapKeyCallBacks, 
                                               NSObjectMapValueCallBacks,
                                               32);
  
  // Next, build list of Entity which need PK generator
  [self _buildPrimaryKeyGeneratorListForEditingContext: context];
  
  // Now get newly inserted objects
  // For each object, we will recordInsertForObject: and relay PK if it is !nil
  insertedObjects = [context insertedObjects];
  
  ASSIGN(_checkPropagatedPKs, [NSMutableArray array]);
  rootDict = [NSMutableDictionary dictionary];
  
  count = [insertedObjects count];
  if (count>0)
  {
    IMP oaiIMP=[insertedObjects methodForSelector: @selector(objectAtIndex:)];
    
    for (idx = 0; idx< count; idx++)
    {
      EOCustomObject * object = GDL2_ObjectAtIndexWithImp(insertedObjects,oaiIMP,idx);
      EOEntity       * entity = [_database entityForObject:object];
      
      if (!entity)
      {
        continue;
      }
      
      [self recordInsertForObject: object];
      
      if ([self _shouldGeneratePrimaryKeyForEntityName:[entity name]])
      {
        NSDictionary   * objectPK = nil;
        
        objectPK = [self _primaryKeyForObject: object
                               raiseException: NO];
        if (!objectPK)
        {
          NSString * rootName = [[entity rootParent] name];
          NSMutableArray * rootPKArray = [rootDict objectForKey:rootName];
          if (!rootPKArray)
          {
            rootPKArray = [NSMutableArray array];
            [rootDict setObject:rootPKArray 
                         forKey:rootName];
          }
          [rootPKArray addObject:object];
        } else {
          [[[self databaseOperationForObject: object] newRow] addEntriesFromDictionary:objectPK];
          
          [self relayPrimaryKey: objectPK
                         object: object
                         entity: entity];              
        }
      } else {
        [_checkPropagatedPKs addObject:object];
      }
    }
  }
  
  if ([rootDict count]) {
    NSEnumerator * keyEnumerator = [rootDict keyEnumerator];
    NSString     * key = nil;
    
    while ((key = [keyEnumerator nextObject]))
    {
      NSMutableArray * rootPKArray = [rootDict objectForKey:key];
      NSUInteger       keyCount = [rootPKArray count];
      NSUInteger       i = 0;
      NSArray * newPKs = [self _batchNewPrimaryKeysWithEntity:[_database entityNamed:key]
                                                        count:keyCount];
      
      if ((!newPKs) || ([newPKs count] != keyCount))
      {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Adaptor %@ "
         @"failed to provide new primary keys for entity '%@'.",
         [_database adaptor], key];        
      }
      
      for (i=0; i < keyCount; i++) {
        NSDictionary   * newPKDict = [newPKs objectAtIndex:i];
        EOCustomObject * eo = [rootPKArray objectAtIndex:i];
        
        [[[self databaseOperationForObject: eo] newRow] addEntriesFromDictionary:newPKDict];
        
        [self relayPrimaryKey: newPKDict
                       object: eo
                       entity: [_database entityForObject:eo]];                            
      }
    }          
  }
}

// PRIVATE

- (void) _patchUpPK:(EODatabaseOperation *) op
{
  if (!op)
  {
    return;
  }
  
  if (([op databaseOperator] == EODatabaseInsertOperator))
  {
    NSMutableDictionary * newRowDict = [op newRow];
    EOEntity            * entity = [op entity];
    EOCustomObject      * eo = [op object];
    NSArray             * pkAttributes = [entity primaryKeyAttributeNames];
    BOOL                  isEONull = NO;
    NSUInteger            i = 0;
    NSUInteger            pkCount = [pkAttributes count];
    
    
    for (; i < pkCount; i++) {
      if (([newRowDict objectForKey:[pkAttributes objectAtIndex:i]] == GDL2_EONull))
      {
        isEONull = YES;
        break;
      }
    }
    
    if (isEONull)
    {
      NSArray    * relationships = [entity relationships];
      NSUInteger   relCount = [relationships count];
      
      for (i = 0; i < relCount; i++)
      {
        EORelationship * relationship = [relationships objectAtIndex:i];
        EORelationship * inverseRelationship = [relationship inverseRelationship];
        EOCustomObject * relEO = nil;
        
        if ((!inverseRelationship) || (![inverseRelationship propagatesPrimaryKey]))
        {
          continue;
        }
        
        relEO = [eo valueForKey:[relationship name]];
        
        if (relEO)
        {
          [self relayAttributesInRelationship:inverseRelationship
                                 sourceObject:relEO
                            destinationObject:eo];
        }
      }
      
    }
  }
}

- (void)recordChangesInEditingContext
{
  //_EOAssertSafeMultiThreadedAccess
  
  [self _assertValidStateWithSelector:
   @selector(recordChangesInEditingContext)];
  
  
  NSArray * insertedObjects = [_editingContext insertedObjects];
  NSArray * deletedObjects = [_editingContext deletedObjects];
  NSArray * newObjects = nil;
  
  NSUInteger i = 0;
  
  for (i = [deletedObjects count]; i > 0; i--)
  {
    EOCustomObject * eo = [deletedObjects objectAtIndex:i - 1];
    EOEntity       * eoentity = [_database entityForObject:eo];
    NSArray        * relationships = nil;
    NSUInteger       idx = 0;

    if (!eoentity)
    {
      continue;
    }
    
    relationships = [eoentity relationships];
    
    for (idx = [relationships count]; idx > 0; idx--)
    {
      NSDictionary   * currentCSnapDict = nil;
      EORelationship * relationship = [relationships objectAtIndex:idx-1];

      if (![relationship isToManyToOne])
      {
        continue;
      }
      currentCSnapDict = [self _currentCommittedSnapshotForObject:eo];

      if (currentCSnapDict)
      {
        NSArray * destinationObjects = [currentCSnapDict objectForKey:[relationship name]];
        if (((id)destinationObjects == GDL2_EONull)) {
          destinationObjects = nil;
        }
        [self nullifyAttributesInRelationship:relationship
                                 sourceObject:eo
                           destinationObjects:destinationObjects];
        
      }
    }
    
    [self recordDeleteForObject:eo];
  }
  
  newObjects = [[_editingContext updatedObjects] arrayByAddingObjectsFromArray:insertedObjects];
  for (i = [newObjects count]; i > 0; i--)
  {
    EOCustomObject * eo = [newObjects objectAtIndex:i-1];
    EOEntity       * eoentity = [_database entityForObject:eo];
    NSDictionary   * updatedEOSnap = nil;
    NSDictionary   * currentCSnapDict = nil;

    NSArray      * relationships = nil;
    NSDictionary * dbSnapshotDict = nil;
    NSUInteger     relCount = 0;
    NSUInteger     idx = 0;
    
    if (!eoentity)
    {
      continue;
    }
    
    [self recordUpdateForObject:eo
                        changes:nil];
    
    updatedEOSnap = [eo snapshot];

    if (!updatedEOSnap)
    {
      updatedEOSnap = [NSDictionary dictionary];
    }
    
    currentCSnapDict = [self _currentCommittedSnapshotForObject:eo];

    if (!currentCSnapDict)
    {
      currentCSnapDict = [NSDictionary dictionary];
    }
    if ([self _shouldGeneratePrimaryKeyForEntityName:[eoentity name]])
    {
      NSDictionary * primaryKeyDict = [self _primaryKeyForObject:eo];
      if (primaryKeyDict)
      {
        [[[self databaseOperationForObject:eo] newRow] addEntriesFromDictionary:primaryKeyDict];
      }
    }

    relationships = [eoentity relationships];
    relCount = [relationships count];

    for (idx = 0; idx < relCount; idx++)
    {
      EORelationship * relationship = nil;
      EORelationship * substRelationship = nil;
      NSArray        * classProperties = nil;
      id               updatedSnapValue = nil;
      id               currentSnapValue = nil;
      
      if (!dbSnapshotDict)
      {
        dbSnapshotDict = [[self databaseOperationForObject:eo] dbSnapshot];
      }

      relationship = [relationships objectAtIndex:idx];
      substRelationship = [relationship _substitutionRelationshipForRow:dbSnapshotDict];

      if (!substRelationship)
      {
        continue;
      }
      
      classProperties = [eoentity classProperties];

      if (([classProperties indexOfObject:substRelationship] == NSNotFound))
      {
        continue;
      }
      
      updatedSnapValue = [updatedEOSnap objectForKey:[substRelationship name]];

      if ((updatedSnapValue == GDL2_EONull)) 
      {
        updatedSnapValue = nil;
      }
      
      currentSnapValue = [currentCSnapDict objectForKey:[substRelationship name]];

      if ((currentSnapValue == GDL2_EONull)) 
      {
        currentSnapValue = nil;
      }
      
      if ([substRelationship isToMany])
      {
        NSArray        * updatedSnapValues = (NSArray*) updatedSnapValue;
        NSArray        * currentSnapValues = (NSArray*) currentSnapValue;
        NSMutableArray * snapsToUse        = nil;
        
        if (((updatedSnapValues == currentSnapValues)) || 
            ([currentSnapValues isEqualToArray:updatedSnapValues])) // TODO: check if isEqual is ok too.
        {
          continue;
        }
        
        if (!updatedSnapValues) {
          snapsToUse = (NSMutableArray*) currentSnapValues;
        } else {
          if (currentSnapValues) {
            snapsToUse = [NSMutableArray arrayWithArray:currentSnapValues];
            [snapsToUse removeObjectsInArray:updatedSnapValues];
          }
        }
        
        if ((_useToManyCaching && (snapsToUse)) && ([snapsToUse count] > 0))
        {
          EODatabaseOperation * updatedEoDbOp = [self databaseOperationForObject:eo];
          NSUInteger            valCount = [updatedSnapValues count];
          NSMutableArray      * globalids = [NSMutableArray arrayWithCapacity:valCount];
          NSUInteger            x = 0;
          
          for (; x < valCount; x++) {
            EOCustomObject * updatedEo = [updatedSnapValues objectAtIndex:x];
            EOGlobalID     * globalid = [_editingContext globalIDForObject:updatedEo];
            
            if ((!globalid) || ([globalid isTemporary]))
            {
              globalids = nil;
              break;
            }
            [globalids addObject:globalid];
          } 
          
          [updatedEoDbOp recordToManySnapshot:globalids
                             relationshipName:[relationship name]];
        }
        [self nullifyAttributesInRelationship:substRelationship
                                 sourceObject:eo
                           destinationObjects:snapsToUse];        
        continue;
      }
      if (updatedSnapValue != currentSnapValue)
      {
        [self nullifyAttributesInRelationship:substRelationship
                                 sourceObject:eo
                           destinationObjects:currentSnapValue];                
      }
    }
    
  } // for updated objs
    
  for (i = [newObjects count]; i > 0; i--)
  {
    EOCustomObject * updatedEO = [newObjects objectAtIndex:i-1];
    EOEntity       * updatedEntity = [_database entityForObject:updatedEO];
    NSDictionary   * updateSnapDict = nil;
    NSDictionary   * comSnapUpdatedEO = nil;
    NSArray        * updatedEntityRelationships = nil;
    NSDictionary   * updatedEntitySnapshot = nil;
    NSUInteger       updatedEntityRelCount = 0;
    NSUInteger       relIdx = 0;
    
    if (updatedEntity == nil)
    {
      continue;
    }

    [self recordUpdateForObject:updatedEO
                        changes:nil];

    updateSnapDict = [updatedEO snapshot];

    if (!updateSnapDict)
    {
      updateSnapDict = [NSDictionary dictionary];
    }

    comSnapUpdatedEO = [self _currentCommittedSnapshotForObject:updatedEO];

    if (!comSnapUpdatedEO)
    {
      comSnapUpdatedEO = [NSDictionary dictionary];
    }

    updatedEntityRelationships = [updatedEntity relationships];

    updatedEntityRelCount = [updatedEntityRelationships count];
    
    for (relIdx = 0; relIdx < updatedEntityRelCount; relIdx++)
    {
      EORelationship * updatedEntityRel = nil;
      EORelationship * substitutionRel = nil;
      id               updatedSnapValue = nil;
      id               currentSnapValue = nil;
      
      if (!updatedEntitySnapshot)
      {
        updatedEntitySnapshot = [[self databaseOperationForObject:updatedEO] dbSnapshot];
      }
      
      updatedEntityRel = [updatedEntityRelationships objectAtIndex:relIdx];
      substitutionRel = [updatedEntityRel _substitutionRelationshipForRow:updatedEntitySnapshot];
      
      if ((!substitutionRel) || ([[updatedEntity classProperties] indexOfObject:substitutionRel] == NSNotFound))
      {
        continue;
      }
      
      updatedSnapValue = [updateSnapDict objectForKey:[substitutionRel name]];

      if ((updatedSnapValue == GDL2_EONull))
      {
        updatedSnapValue = nil;
      }
      
      currentSnapValue = [comSnapUpdatedEO objectForKey:[substitutionRel name]];

      if ((currentSnapValue == GDL2_EONull))
      {
        currentSnapValue = nil;
      }
      
      if ([substitutionRel isToMany])
      {
        NSArray        * updatedSnapValues = (NSArray*) updatedSnapValue;
        NSArray        * currentSnapValues = (NSArray*) currentSnapValue;
        NSMutableArray * snaps = nil;

        if (((updatedSnapValues == currentSnapValues)) || 
            ([currentSnapValues isEqualToArray:updatedSnapValues]))
        {
          continue;
        }

        if (!currentSnapValues) {
          snaps = (NSMutableArray*) updatedSnapValues;
        } else {
          snaps = [NSMutableArray arrayWithArray:updatedSnapValues];
          [snaps removeObjectsInArray:currentSnapValues];
        }
        
        if ((_useToManyCaching && (snaps)) && ([snaps count] > 0))
        {
          EODatabaseOperation * updatedEoDbOp = [self databaseOperationForObject:updatedEO];
          NSUInteger valCount = [updatedSnapValues count];
          NSUInteger y = 0;
          NSMutableArray * gidArray = [NSMutableArray arrayWithCapacity:valCount];

          for (; y < valCount; y++) 
          {
            EOGlobalID * gid = [_editingContext globalIDForObject:[updatedSnapValues objectAtIndex:y]];
            
            if ((!gid) || ([gid isTemporary]))
            {
              gidArray = nil;
              break;
            }
            [gidArray addObject:gid];
          }
          
          [updatedEoDbOp recordToManySnapshot:gidArray
                             relationshipName:[updatedEntityRel name]];

        }
        [self relayAttributesInRelationship:substitutionRel
                               sourceObject:updatedEO
                          destinationObject:snaps];
        continue;
      }
      if (updatedSnapValue != currentSnapValue)
      {
        [self relayAttributesInRelationship:substitutionRel
                               sourceObject:updatedEO
                          destinationObject:updatedSnapValue];
      }
    }
    
  }
  
  if (_checkPropagatedPKs)
  {
    NSUInteger pkCount = [_checkPropagatedPKs count];
    
    for (i = 0; i < pkCount; i++)
    {
      EOCustomObject * eo = [_checkPropagatedPKs objectAtIndex:i];
      [self _patchUpPK:[self databaseOperationForObject:eo]];
    }
    
  }
  _checkPropagatedPKs = nil;
}


/** Contructs a list of EODatabaseOperations for all changes in the EOEditingContext
that are owned by this context.  Forward any relationship changes discovered
but not owned by this context to the coordinator.
**/
- (void)recordUpdateForObject: (id)object
                      changes: (NSDictionary *)changes
{
  EODatabaseOperation *dbOpe = nil;
  
  NSAssert(object, @"No object");
  
  [self _assertValidStateWithSelector:
   @selector(recordUpdateForObject:changes:)];
  
  dbOpe = [self databaseOperationForObject: object];
    
  if (dbOpe) {
    [dbOpe setDatabaseOperator:EODatabaseUpdateOperator];
    if ((changes) && ([changes count]))
    {
      [[dbOpe newRow] addEntriesFromDictionary: changes];
    }
  } else {
    [[self coordinator] forwardUpdateForObject:object
                                       changes:changes];
  }
}

-(void)recordInsertForObject: (id)object
{
  NSDictionary *snapshot = nil;
  EODatabaseOperation *dbOpe = nil;

  dbOpe = [self databaseOperationForObject: object];
  [dbOpe setDatabaseOperator: EODatabaseInsertOperator];

  snapshot = [dbOpe dbSnapshot];

  if ([snapshot count] != 0)
  {
    [NSException raise:NSInternalInconsistencyException
                format:@"%s found a snapshot for EO with Global ID: %@ that has been inserted into %@."
     @"Cannot insert an object that is already in the database",
     __PRETTY_FUNCTION__, [dbOpe globalID], _editingContext];
  }

}

- (void) recordDeleteForObject: (id)object
{
  NSDictionary *snapshot = nil;
  EODatabaseOperation *dbOpe = nil;
  
  dbOpe = [self databaseOperationForObject: object];
  
  [dbOpe setDatabaseOperator: EODatabaseDeleteOperator];
  
  snapshot = [dbOpe dbSnapshot];
  
  if (([snapshot count] == 0))
  {
    [NSException raise:NSInternalInconsistencyException
                format:@"%s failed to find a snapshot for EO with Global ID: %@ that has been deleted from %@."
     @"Cannot delete an object that has not been fetched from the database",
     __PRETTY_FUNCTION__, [dbOpe globalID], _editingContext];
  }
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



  NSDebugMLLog(@"EODatabaseContext",
	       @"self=%p preparingForSave=%d beganTransaction=%d",
	       self,
	       (int)_flags.preparingForSave,
	       (int)_flags.beganTransaction);

  [self _assertValidStateWithSelector: @selector(performChanges)];

  dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);

  while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid, (void **)&dbOpe))
  {

    
    //REVOIR
    if ([dbOpe databaseOperator] == EODatabaseNothingOperator)
    {
      NSDebugMLLog(@"EODatabaseContext", @"Db Ope %@ for Nothing !!!",
                   dbOpe);
    }
    else
    {
      [self _verifyNoChangesToReadonlyEntity: dbOpe];
      //MIRKO snapshot = [op dbSnapshot];
      [self createAdaptorOperationsForDatabaseOperation: dbOpe];
    }
  }
  // avoid leaks! -- dw
  NSEndMapTableEnumeration(&dbOpeEnum);
  
  NSDebugMLLog(@"EODatabaseContext", @"orderedAdaptorOperations A=%@",
	       orderedAdaptorOperations);

  orderedAdaptorOperations = [self orderAdaptorOperations];

  NSDebugMLLog(@"EODatabaseContext", @"orderedAdaptorOperations B=%@",
	       orderedAdaptorOperations);
  NSDebugMLLog(@"EODatabaseContext",
	       @"self=%p preparingForSave=%d beganTransaction=%d",
	       self,
	       (int)_flags.preparingForSave,
	       (int)_flags.beganTransaction);

  if ([orderedAdaptorOperations count] > 0)
    {
      EOAdaptorChannel *adaptorChannel = nil;
      EODatabaseChannel *dbChannel = [self _obtainOpenChannel];

      NSDebugMLLog(@"EODatabaseContext",
		   @"self=%p preparingForSave=%d beganTransaction=%d",
		   self,
		   (int)_flags.preparingForSave,
		   (int)_flags.beganTransaction);                   

      if (_flags.beganTransaction == NO)//MIRKO
	{
          NSDebugMLLog(@"EODatabaseContext",
		       @"self=%p [_adaptorContext transactionNestingLevel]=%d",
		       self,
		       (int)[_adaptorContext transactionNestingLevel]);

          if ([_adaptorContext transactionNestingLevel] == 0) //??
            [_adaptorContext  beginTransaction];

          NSDebugMLLog(@"EODatabaseContext",
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
          NSDebugMLLog(@"EODatabaseContext",
		       @"performAdaptorOperations:");
          NSDebugMLLog(@"EODatabaseContext",
		       @"self=%p preparingForSave=%d beganTransaction=%d",
		       self,
		       (int)_flags.preparingForSave,
		       (int)_flags.beganTransaction);

          [adaptorChannel performAdaptorOperations: orderedAdaptorOperations];

          NSDebugMLLog(@"EODatabaseContext",
		       @"self=%p preparingForSave=%d beganTransaction=%d",
		       self,
		       (int)_flags.preparingForSave,
		       (int)_flags.beganTransaction);
          NSDebugMLLog(@"EODatabaseContext",
		       @"after performAdaptorOperations:");
        }
      NS_HANDLER
	{
          NSDebugMLLog(@"EODatabaseContext",
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
      NSDebugMLLog(@"EODatabaseContext",
		   @"self=%p preparingForSave=%d beganTransaction=%d",
		   self,
		   (int)_flags.preparingForSave,
		   (int)_flags.beganTransaction);
      NSDebugMLLog(@"EODatabaseContext",
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
              NSDebugMLLog(@"EODatabaseContext",
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



              object = [dbOpe object];
              adaptorOpe = [dbOpe adaptorOperations];
              databaseOperator = [dbOpe databaseOperator];
              entity = [dbOpe entity];
              dbSnapshotKeys = [entity dbSnapshotKeys];

              NSDebugMLLog(@"EODatabaseContext", @"dbSnapshotKeys=%@",
			   dbSnapshotKeys);

              newRow = [dbOpe newRow];


              values = [newRow valuesForKeys: dbSnapshotKeys];
              NSDebugMLLog(@"EODatabaseContext",
			   @"RECORDSNAPSHOT values=%@", values);
              //if update: forgetSnapshotForGlobalID:

              [self recordSnapshot: values
                    forGlobalID: gid];
              NSDebugMLLog(@"EODatabaseContext",
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
      // avoid leaks! -- dw
      NSEndMapTableEnumeration(&dbOpeEnum);
    }


}

- (void) commitChanges
{
  NSMapEnumerator dbOpeEnum;
  EOGlobalID *gid = nil;
  EODatabaseOperation *dbOpe = nil;  
  NSMutableArray *deletedObjects = [NSMutableArray array];
  NSMutableArray *insertedObjects = [NSMutableArray array];
  NSMutableArray *updatedObjects = [NSMutableArray array];
  NSMutableDictionary *gidChangedUserInfo = nil;
  NSMutableDictionary *gidChangedUserInfo2 = nil;
  
  [self _assertValidStateWithSelector: @selector(commitChanges)];
  
  // before we send new changes to the database,
  // make sure we have commited everything
  
  NS_DURING {
    if ([_adaptorContext hasOpenTransaction]) {
      [_adaptorContext commitTransaction];
      _flags.beganTransaction = NO;
    }
  } NS_HANDLER {
    [self rollbackChanges];
    [localException raise];
    
  } NS_ENDHANDLER;
  // useToManyCaching ?
  
  [EOObserverCenter suppressObserverNotification];
  dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);
  
  NS_DURING {
    while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
                                   (void **)&dbOpe))
    {
      EODatabaseOperator databaseOperator = EODatabaseNothingOperator;
      EOGlobalID *dbOpeGID = nil;
      EOGlobalID *newGID = nil;
      EOEntity *entity = nil;
      NSDictionary *newRowValues = nil;
      NSMutableDictionary *newRow = [dbOpe newRow];

      databaseOperator = [dbOpe databaseOperator];
      entity = [dbOpe entity];
      
      
      if ([gid isTemporary] || ([[dbOpe primaryKeyDiffs] count] > 0))
      {
        newGID = [entity globalIDForRow: newRow
                                isFinal: YES];
        if (!gidChangedUserInfo)
        {
          gidChangedUserInfo = [NSMutableDictionary dictionary];
        }
        [gidChangedUserInfo setObject: newGID
                               forKey: gid];
      }
      
      switch (databaseOperator)
      {
        case EODatabaseInsertOperator:
          
          newRowValues = [newRow valuesForKeys:[entity classPropertyAttributeNames]];
          break;
          
        case EODatabaseUpdateOperator:
          newRowValues = [dbOpe rowDiffsForAttributes: [entity _classPropertyAttributes]];
//          NSLog(@"%s %d _classPropertyAttributes %@",__PRETTY_FUNCTION__, __LINE__, [entity _classPropertyAttributes] );
//          NSLog(@"%s %d newRowValues %@",__PRETTY_FUNCTION__, __LINE__, newRowValues );
          break;
        default: 
          break;
      }
      id object = [dbOpe object];
      if (object)
      {
        if ((newRowValues) && ([newRowValues count] > 0))
        {
          [object takeStoredValuesFromDictionary:newRowValues];
        }
        if ((databaseOperator == EODatabaseInsertOperator))
        {
          [_database incrementSnapshotCountForGlobalID:dbOpeGID];
        }
      }
    } // while
  } NS_HANDLER {
    [EOObserverCenter enableObserverNotification];
    NSEndMapTableEnumeration(&dbOpeEnum);
    [localException raise];
  } NS_ENDHANDLER;
  
  [EOObserverCenter enableObserverNotification];
  NSEndMapTableEnumeration(&dbOpeEnum);

  if (gidChangedUserInfo)
  {    
    [[NSNotificationCenter defaultCenter] postNotificationName: EOGlobalIDChangedNotification
                                                        object: self
                                                      userInfo: gidChangedUserInfo];
  }

  dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);
  gidChangedUserInfo2 = [NSMutableDictionary dictionary];
  
  while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
                                 (void **)&dbOpe)) {
    EOGlobalID *dbOpeGID = nil;
    
    dbOpeGID = [dbOpe globalID]; 
    
    switch ([dbOpe databaseOperator])
    {
      case EODatabaseInsertOperator:
      {
        id newObj = nil;
        if (gidChangedUserInfo) {
          newObj = [gidChangedUserInfo objectForKey:dbOpeGID];
        }
        
        [insertedObjects addObject: (newObj == nil ? dbOpeGID : newObj)];
      } 
        break;
        
      case EODatabaseDeleteOperator:
        [deletedObjects addObject: dbOpeGID];
        break;
        
      case EODatabaseUpdateOperator: /* 2 */
        [updatedObjects addObject: dbOpeGID];
        break;
        
      case EODatabaseNothingOperator:
        break;
    }
  } 
  NSEndMapTableEnumeration(&dbOpeEnum);

  [gidChangedUserInfo2 setObject:deletedObjects
                          forKey:EODeletedKey];
  
  [gidChangedUserInfo2 setObject:insertedObjects
                          forKey:EOInsertedKey];
  
  [gidChangedUserInfo2 setObject:updatedObjects
                          forKey:EOUpdatedKey];
  
  [self _cleanUpAfterSave];
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName: @"EOObjectsChangedInStoreNotification"
   object: _database
   userInfo: gidChangedUserInfo2];
}

- (void)rollbackChanges
{ // TODO
//adaptorcontext transactionNestingLevel
//if 0 ? _cleanUpAfterSave


  if (_flags.beganTransaction == YES)
    {
      [_adaptorContext rollbackTransaction];



      _flags.beganTransaction = NO;

      if (_lockedObjects)
	{
	  NSResetHashTable(_lockedObjects);
	}

      NSResetMapTable(_dbOperationsByGlobalID);
/* //TODO
      [_snapshots removeAllObjects];
      [_toManySnapshots removeAllObjects];
*/
    }


}

- (NSDictionary *)valuesForKeys: (NSArray *)keys
                         object: (id)object
{
  //OK
  EOEntity *entity;
  EODatabaseOperation *dbOpe;
  NSDictionary *newRow;
  NSDictionary *values = nil;




  NSDebugMLLog(@"EODatabaseContext", @"object=%p (class=%@)",
	       object, [object class]);

  //NSAssert(object, @"No object");

  if (!_isNilOrEONull(object))
    {
      entity = [_database entityForObject: object];

      NSAssert1(entity, @"No entity for object %@", object);


      dbOpe = [self databaseOperationForObject: object];




      newRow = [dbOpe newRow];




      values = [newRow valuesForKeys: keys];
    }
  else
    {

      values = [NSDictionary dictionary];
    }

//



  return values;
}

-(void)nullifyAttributesInRelationship: (EORelationship*)relationship
                          sourceObject: (id)sourceObject
                     destinationObject: (id)destinationObject
{
  EODatabaseOperation *sourceDBOpe = nil;





  NSDebugMLLog(@"EODatabaseContext", @"destinationObject=%@",
	       destinationObject);

  if (destinationObject)
    {
      //Get SourceObject database operation
      sourceDBOpe = [self databaseOperationForObject: sourceObject]; //TODO: useIt



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

          NSDebugMLLog(@"EODatabaseContext", @"sourceToDestinationKeyMap=%@",
		       sourceToDestinationKeyMap);
          NSDebugMLLog(@"EODatabaseContext", @"foreignKeyInDestination=%d",
		       foreignKeyInDestination);

          if (foreignKeyInDestination)
            {
              NSArray *destinationKeys = [sourceToDestinationKeyMap
					   objectForKey: @"destinationKeys"];//(customerCode) 
              int i, destinationKeysCount = [destinationKeys count];
              NSMutableDictionary *changes = [NSMutableDictionary dictionaryWithCapacity: destinationKeysCount];

              if (destinationKeysCount>0)
                {
                  IMP oaiIMP=[destinationKeys methodForSelector: @selector(objectAtIndex:)];

                  for (i = 0 ;i < destinationKeysCount; i++)
                    {
                      id destinationKey = GDL2_ObjectAtIndexWithImp(destinationKeys,oaiIMP,i);
                      
                      [changes setObject: GDL2_EONull
                               forKey: destinationKey];
                    }
                }

              NSAssert1(destinationObject, 
                        @"No destinationObject for call of recordUpdateForObject:changes: changes: %@",
                        changes);

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


// private 

-(NSDictionary*) _primaryKeyForIntermediateRowFromSourceObject:(EOCustomObject*) srcObject
                                                  relationship:(EORelationship *) relationship
                                             destinationObject:(EOCustomObject *)destObject
{
	NSMutableDictionary * pkDict = nil;
	NSMutableDictionary * pkDict1 = nil;
  NSDictionary        * leftSideKeyDict = [relationship _leftSideKeyMap];
  EODatabaseOperation * op = [self databaseOperationForObject:srcObject];
  NSArray             * nsarray = [leftSideKeyDict objectForKey:@"sourceKeys"];
  
  pkDict = [NSMutableDictionary dictionaryWithDictionary:[op newRow]
                                                    keys:nsarray];
  
  if ([pkDict containsAnyNullObject])
  {
    NSDictionary * dict = [[self _entityForObject:srcObject] primaryKeyForGlobalID:(EOKeyGlobalID*)[op globalID]];

    pkDict = [NSMutableDictionary dictionaryWithDictionary:dict
                                                      keys:nsarray];
  }
  
  [pkDict translateFromKeys:nsarray
                     toKeys:(NSArray*) [leftSideKeyDict objectForKey:@"destinationKeys"]];
  
  leftSideKeyDict = [relationship _rightSideKeyMap];
  
  op = [self databaseOperationForObject:destObject];
  nsarray = (NSArray*)[leftSideKeyDict objectForKey:@"destinationKeys"];
  
  pkDict1 = [NSMutableDictionary dictionaryWithDictionary:[op newRow]
                                                     keys:nsarray];
  
  if ([pkDict1 containsAnyNullObject])
  {
    NSDictionary * destKeyDict = [[self _entityForObject:destObject] 
                                  primaryKeyForGlobalID:(EOKeyGlobalID*)[op globalID]];
    
    pkDict1 = [NSMutableDictionary dictionaryWithDictionary:destKeyDict
                                                       keys:nsarray];
  }
  [pkDict1 translateFromKeys:nsarray
                      toKeys:(NSArray*)[leftSideKeyDict objectForKey:@"sourceKeys"]];

  [pkDict addEntriesFromDictionary:pkDict1];
  
  return pkDict;
}

// private 

- (EODatabaseOperation*) _databaseOperationForIntermediateRowFromSourceObject:(EOCustomObject*) srcObject
                                                                 relationship:(EORelationship *) relationship
                                                            destinationObject:(EOCustomObject *)destObject
{
  EOEntity            * intermediateEntity = nil;
  NSDictionary        * pkDict = nil;
  EOGlobalID          * gid = nil;
  EODatabaseOperation * op = nil;
  
  pkDict = [self _primaryKeyForIntermediateRowFromSourceObject:srcObject
                                                  relationship:relationship
                                             destinationObject:destObject];
  
  intermediateEntity = [relationship intermediateEntity];
  
  gid = [intermediateEntity globalIDForRow:pkDict];
  
  if (!gid)
  {
    
    [NSException raise:NSInternalInconsistencyException
                format:@"A valid global ID could not be obtained for entity named '"
     @"%@' relationship named '%@' primary key dictionary %@.",
     [intermediateEntity name], [relationship name], pkDict];
  }
  
  op = [self databaseOperationForGlobalID:gid];
  
  if (!op)
  {
    op = [EODatabaseOperation databaseOperationWithGlobalID: gid
                                                     object: nil
                                                     entity: intermediateEntity];
    
    [op setDBSnapshot:pkDict];
    [op setNewRow:[NSMutableDictionary dictionaryWithDictionary:pkDict]];
    
    [self recordDatabaseOperation:op];
  }
  return op;
}

// private 
- (void) _recordDeleteForIntermediateRowFromSourceObject:(EOCustomObject*) sourceObject
                                            relationship:(EORelationship*) relationship
                                       destinationObject:(EOCustomObject*) destinationObject
{
  EODatabaseOperation * op;
  
  op = [self _databaseOperationForIntermediateRowFromSourceObject:sourceObject
                                                     relationship:relationship
                                                destinationObject:destinationObject];
  
  [op setDatabaseOperator:EODatabaseDeleteOperator];
}

- (void)nullifyAttributesInRelationship: (EORelationship*)relationship
                           sourceObject: (id)sourceObject
                     destinationObjects: (NSArray*)destinationObjects
{
  EODatabaseOperation * dbOpe = nil;

  if (!destinationObjects)
  {
    return;
  }
  
  dbOpe = [self databaseOperationForObject:sourceObject];
  
  if ([relationship isToManyToOne])
  {
    [self _recordDeleteForIntermediateRowFromSourceObject: sourceObject
                                             relationship:relationship
                                        destinationObject:(id)destinationObjects];
     
  } else {
    NSDictionary * mappingDict = [relationship _sourceToDestinationKeyMap];
    if ([relationship foreignKeyInDestination])
    {
      NSArray * destinationKeys = [mappingDict objectForKey:@"destinationKeys"];

      [self recordUpdateForObject:destinationObjects
                          changes:[NSDictionary dictionaryWithNullValuesForKeys:destinationKeys]];
    } else
    {
      NSArray * sourceKeys = [mappingDict objectForKey:@"sourceKeys"];
      
      [[dbOpe newRow] addEntriesFromDictionary:
       [NSDictionary dictionaryWithNullValuesForKeys:sourceKeys]];
    }
  }

}

- (void)relayAttributesInRelationship: (EORelationship*)relationship
			 sourceObject: (id)sourceObject
		   destinationObjects: (NSArray*)destinationObjects
{
  int destinationObjectsCount = 0;

  destinationObjectsCount = [destinationObjects count];

  if (destinationObjectsCount > 0)
    {
      int i;
      IMP oaiIMP=[destinationObjects methodForSelector: @selector(objectAtIndex:)];

      for (i = 0; i < destinationObjectsCount; i++)
        {
          id object = GDL2_ObjectAtIndexWithImp(destinationObjects,oaiIMP,i);

          [self relayAttributesInRelationship: (EORelationship*)relationship
                                 sourceObject: (id)sourceObject
                            destinationObject: object];
        }
    }


}

- (NSDictionary*)relayAttributesInRelationship: (EORelationship*)relationship
                                  sourceObject: (id)sourceObject
			     destinationObject: (id)destinationObject
{
  //OK
  NSMutableDictionary *relayedValues = nil;
  EODatabaseOperation *sourceDBOpe = nil;




  NSDebugMLLog(@"EODatabaseContext", @"sourceObject %p=%@ (class=%@)",
	       sourceObject, sourceObject, [sourceObject class]);
  NSDebugMLLog(@"EODatabaseContext", @"destinationObject %p=%@ (class=%@)",
	       destinationObject, destinationObject,
	       [destinationObject class]);

  //Get SourceObject database operation
  sourceDBOpe = [self databaseOperationForObject: sourceObject];



  if ([sourceDBOpe databaseOperator] == EODatabaseNothingOperator)
    {
      NSDebugMLLog(@"EODatabaseContext", @"Db Ope %@ for Nothing !!!", 
		   sourceDBOpe);
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


      NSDebugMLLog(@"EODatabaseContext", @"sourceToDestinationKeyMap=%@",
		   sourceToDestinationKeyMap);
      NSDebugMLLog(@"EODatabaseContext", @"destinationKeys=%@", 
		   destinationKeys);


      NSDebugMLLog(@"EODatabaseContext", @"foreignKeyInDestination=%s",
		   (foreignKeyInDestination ? "YES" : "NO"));

      NSAssert([destinationKeys count] == [sourceKeys count],
               @"destination keys count!=source keys count");

      if (foreignKeyInDestination || [relationship propagatesPrimaryKey])
        {
          IMP srcObjectAIndexIMP=[sourceKeys methodForSelector: @selector(objectAtIndex:)];
          IMP dstObjectAIndexIMP=[destinationKeys methodForSelector: @selector(objectAtIndex:)];

          relayedValues = AUTORELEASE([[sourceNewRow valuesForKeys: sourceKeys]
			     mutableCopy]);// {code = 0; }
          NSDebugMLLog(@"EODatabaseContext", @"relayedValues=%@",
		       relayedValues);

          count = [relayedValues count];

          for (i = 0; i < count; i++)
            {
              NSString *sourceKey = GDL2_ObjectAtIndexWithImp(sourceKeys,srcObjectAIndexIMP,i);
              NSString *destKey = GDL2_ObjectAtIndexWithImp(destinationKeys,dstObjectAIndexIMP,i);
              id sourceValue = [relayedValues objectForKey: sourceKey];

	
	
	      NSDebugMLLog(@"EODatabaseContext", @"sourceValue=%@",
			   sourceValue);

	      [relayedValues removeObjectForKey: sourceKey];
	      [relayedValues setObject: sourceValue
			     forKey: destKey];
            }

          NSDebugMLLog(@"EODatabaseContext", @"relayedValues=%@",
		       relayedValues);

          NSAssert1(destinationObject, 
                    @"No destinationObject for call of "
		    @"recordUpdateForObject:changes: relayedValues: %@",
                    relayedValues);

          [self recordUpdateForObject: destinationObject
                changes: relayedValues];
        }
      else
        {
          //Verify !!
          NSDictionary *destinationValues;
          IMP srcObjectAIndexIMP=[sourceKeys methodForSelector: @selector(objectAtIndex:)];
          IMP dstObjectAIndexIMP=[destinationKeys methodForSelector: @selector(objectAtIndex:)];

          NSDebugMLLog(@"EODatabaseContext",
		       @"Call valuesForKeys destinationObject (%p-<%@>)",
		       destinationObject, [destinationObject class]);
          NSDebugMLLog(@"EODatabaseContext", @"destinationKeys=%@",
		       destinationKeys);



          //Now take destinationKeys values
          destinationValues = [self valuesForKeys: destinationKeys
				    object: destinationObject];

          NSDebugMLLog(@"EODatabaseContext", @"destinationValues=%@",
		       destinationValues);
          //And put these values for source keys in the return object (sourceValues)

          count = [destinationKeys count];
          relayedValues = (NSMutableDictionary*)[NSMutableDictionary dictionary];

          NSDebugMLLog(@"EODatabaseContext", @"relayedValues=%@",
		       relayedValues);

          for (i = 0; i < count; i++)
            {
              NSString *sourceKey = GDL2_ObjectAtIndexWithImp(sourceKeys,srcObjectAIndexIMP,i);
              NSString *destinationKey = GDL2_ObjectAtIndexWithImp(destinationKeys,dstObjectAIndexIMP,i);
              id destinationValue = [destinationValues
				      objectForKey: destinationKey];

              NSDebugMLLog(@"EODatabaseContext", @"destinationKey=%@",
			   destinationKey);

              NSDebugMLLog(@"EODatabaseContext",
			   @"destinationValue=%@", destinationValue);

              if (!_isNilOrEONull(destinationValue))//?? or always
                [relayedValues setObject: destinationValue
                               forKey: sourceKey];
            }
          //Put these values in source object database ope new row
          NSDebugMLLog(@"EODatabaseContext", @"relayedValues=%@",
		       relayedValues);

          [sourceNewRow takeValuesFromDictionary: relayedValues];
        }
    }

  if ([sourceDBOpe databaseOperator] == EODatabaseNothingOperator)
    {
      NSDebugMLLog(@"EODatabaseContext",
		   @"Db Ope %@ for Nothing !!!", sourceDBOpe);
    }



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
				value = GDL2_EONull;

			      [row setObject:value
				   forKey:[[join sourceAttribute] name]];
			    }
#if 0
			  inverse = [property inverseRelationship];
			  if (inverse)
			    {
			      toManySnapshot = AUTORELEASE([[self snapshotForSourceGlobalID:gid
						       relationshipName:[inverse name]]
						  mutableCopy]);
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
				value = GDL2_EONull;

			      [row setObject:value
				   forKey:[[join sourceAttribute] name]];
			    }
			}
*/

};

- (void)recordDatabaseOperation: (EODatabaseOperation*)databaseOpe
{
  //OK
  EOGlobalID *gid = nil;



  NSAssert(databaseOpe, @"No database operation");


  NSDebugMLLog(@"EODatabaseContext", @"_dbOperationsByGlobalID=%p",
	       _dbOperationsByGlobalID);

  if (_dbOperationsByGlobalID)
    {
//
      NSDebugMLLog(@"EODatabaseContext", @"_dbOperationsByGlobalID=%@",
		   NSStringFromMapTable(_dbOperationsByGlobalID));

      /*
        // doesn't do this so some db operation are not recorded (when selecting objects)
        if (!_dbOperationsByGlobalID)
        _dbOperationsByGlobalID = NSCreateMapTable(NSObjectMapKeyCallBacks, 
        NSObjectMapValueCallBacks,
        32);
      */
      gid = [databaseOpe globalID];



      NSMapInsert(_dbOperationsByGlobalID, gid, databaseOpe);
      NSDebugMLLog(@"EODatabaseContext",
		   @"_dbOperationsByGlobalID=%p",
		   _dbOperationsByGlobalID);
      NSDebugMLLog(@"EODatabaseContext", @"_dbOperationsByGlobalID=%@",
		   NSStringFromMapTable(_dbOperationsByGlobalID));
    }
  else
    {
      NSDebugMLLog(@"EODatabaseContext",
		   @"No _dbOperationsByGlobalID");
    }


}

- (EODatabaseOperation*)databaseOperationForGlobalID: (EOGlobalID*)gid
{
  //OK
  EODatabaseOperation *dbOpe = nil;



  NSDebugMLLog(@"EODatabaseContext", @"_dbOperationsByGlobalID=%p",
	       _dbOperationsByGlobalID);

  if (_dbOperationsByGlobalID)
    {
//
      NSDebugMLLog(@"EODatabaseContext", @"_dbOperationsByGlobalID=%@",
		   NSStringFromMapTable(_dbOperationsByGlobalID));

      dbOpe = (EODatabaseOperation*)NSMapGet(_dbOperationsByGlobalID,
					     (const void*)gid);


    }



  return dbOpe;
}

- (EODatabaseOperation*)databaseOperationForObject: (id)object
{
   //OK
   EODatabaseOperation *databaseOpe = nil;
   EOGlobalID *gid = nil;

   NS_DURING // for trace purpose
     {


       if ([object isKindOfClass: [EOGenericRecord class]])
	 NSDebugMLLog(@"EODatabaseContext", @"dictionary=%@ ",
		      [object debugDictionaryDescription]);

       gid = EODatabaseContext_globalIDForObjectWithImpPtr(self,NULL,object);


       databaseOpe = [self databaseOperationForGlobalID: gid]; //OK


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
           NSDebugMLLog(@"EODatabaseContext", @"entity name=%@",
			[entity name]);

           primaryKeyAttributes = [entity primaryKeyAttributes]; //OK

           NSDebugMLLog(@"EODatabaseContext",
			@"primaryKeyAttributes=%@",
			primaryKeyAttributes);

           databaseOpe = [EODatabaseOperation
			   databaseOperationWithGlobalID: gid
			   object: object
			   entity: entity]; //OK

           NSDebugMLLog(@"EODatabaseContext",
			@"CREATED databaseOpe=%@\nfor object %p %@",
			databaseOpe, object, object);

           snapshot = EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,gid);//OK
           NSDebugMLLog(@"EODatabaseContext", @"snapshot %p=%@",
			snapshot, snapshot);

           if (!snapshot)
             snapshot = [NSDictionary dictionary];

           [databaseOpe setDBSnapshot: snapshot];
           NSDebugMLLog(@"EODatabaseContext",@"object=%p databaseOpe=%@",
			object,databaseOpe);

           classPropertyNames = [entity classPropertyNames]; //OK  (code, a3code, numcode, toLabel)
           NSDebugMLLog(@"EODatabaseContext",
			@"classPropertyNames=%@", classPropertyNames);

           propNamesCount = [classPropertyNames count];
           NSDebugMLLog(@"EODatabaseContext", @"propNamesCount=%d",
			(int)propNamesCount);

           //TODO: rewrite code: don't use temporary "row"
           row = (NSMutableDictionary*)[NSMutableDictionary dictionary];
           NSDebugMLLog(@"EODatabaseContext",@"object %p (class %@)=%@ ",
			object,[object class],object);

           /*if ([object isKindOfClass: [EOGenericRecord class]])
	     NSDebugMLLog(@"EODatabaseContext", @"dictionary=%@ ",
	     [object debugDictionaryDescription]);*/
           if (propNamesCount>0)
             {
               IMP oaiIMP=[classPropertyNames methodForSelector: @selector(objectAtIndex:)];

               for (i = 0; i < propNamesCount; i++)
                 {
                   id value = nil;
                   NSString *key = GDL2_ObjectAtIndexWithImp(classPropertyNames,oaiIMP,i);
                   

                   
                   /*NO !! 
                     if ([attribute isKindOfClass:[EOAttribute class]] == NO)
                     continue;
                     // if ([attribute isFlattened] == NO)
                     */
                   value = [object storedValueForKey: key]; //OK
                   NSDebugMLLog(@"EODatabaseContext", @"key=%@ value=%@",
                                key, value);
                   
                   if (!value)
                     {
                       value = GDL2_EONull;
                       
                       [[[entity attributeNamed: key] validateValue: &value]
                         raise];
                     }
                   
                   NSDebugMLLog(@"EODatabaseContext", @"key=%@ value=%@",
                                key, value);
                   
                   [row setObject: value
                        forKey: key];
                 }
             };

           newRow = [[NSMutableDictionary alloc]
		       initWithDictionary: snapshot
		       copyItems: NO];



           dbSnapshotKeys = [entity dbSnapshotKeys]; //OK (numcode, code, a3code)
           NSDebugMLLog(@"EODatabaseContext", @"dbSnapshotKeys=%@",
			dbSnapshotKeys);

           snapKeyCount = [dbSnapshotKeys count];

           if (snapKeyCount>0)
             {
               IMP oaiIMP=[dbSnapshotKeys methodForSelector: @selector(objectAtIndex:)];
               for (i = 0; i < snapKeyCount; i++)
                 {
                   id key = GDL2_ObjectAtIndexWithImp(dbSnapshotKeys,oaiIMP,i);
                   id value = [row objectForKey: key]; //Really this key ?
                   
                   NSDebugMLLog(@"EODatabaseContext", @"key=%@ value=%@",
                                key, value);
                   
                   //               NSAssert1(value,@"No value for %@",key);
                   
                   if (value)
                     [newRow setObject: value
                             forKey: key];
                 }
             };



           [databaseOpe setNewRow: newRow];
           [self recordDatabaseOperation: databaseOpe];
           RELEASE(newRow);
         }
    }
  NS_HANDLER
    {

      [localException raise];
    }
  NS_ENDHANDLER;



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
  
  
  
  NSAssert3(destObject, 
            @"No destinationObject. pk=%@ relationship=%@ sourceObject=%@",
            pk,relationship,sourceObject);
  
  destAttributes = [relationship destinationAttributes];
  
  
  destAttributeNames = [destAttributes resultsOfPerformingSelector:
                        @selector(name)];
  
  keyValues = [self valuesForKeys: destAttributeNames
                           object: destObject];
  
  
  values = [keyValues allValues];
  
  
  //Now test if null values
  count = [values count];
  
  if (count>0)
  {
    IMP oaiIMP=[values methodForSelector: @selector(objectAtIndex:)];
    
    for (i = 0; nullPKValues && i < count; i++)
      nullPKValues = _isNilOrEONull(GDL2_ObjectAtIndexWithImp(values,oaiIMP,i));
  };
  
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
  
  
}

- (void)relayPrimaryKey: (NSDictionary*)pk
		 object: (id)object
		 entity: (EOEntity*)entity
{
  //TODO check
  NSArray *relationships = nil;
  NSArray *classPropertyNames = nil;
  EODatabaseOperation *dbOpe = nil;
  NSDictionary *dbSnapshot = nil;
  int i, count=0;
  
  relationships = [entity relationships]; //OK
  classPropertyNames = [entity classPropertyNames];
  dbOpe = [self databaseOperationForObject: object];
  
  if (!dbOpe) {
    dbSnapshot = [NSDictionary dictionary];
  } else {
    dbSnapshot = [dbOpe dbSnapshot];
  }
  
  if (relationships) {
    count = [relationships count];
  }
  
  if (count>0)
  {
    IMP oaiIMP=[relationships methodForSelector: @selector(objectAtIndex:)];
    
    for (i = 0; i < count; i++)
    {
      EORelationship *relationship = GDL2_ObjectAtIndexWithImp(relationships,oaiIMP,i);
      EORelationship *substRelationship = nil;
      NSString       *relName;
      id              storedValue;
      id value = nil;
      id snapshot = nil;
      id comSnapshotValue = nil;
      
      substRelationship = [relationship _substitutionRelationshipForRow: dbSnapshot];
      
      if (!substRelationship) {
        continue;
      }
      
      relName = [substRelationship name];
      
      if ((![substRelationship propagatesPrimaryKey]) || 
          (![classPropertyNames containsObject:relName]))
      {
        continue;
      }
      
      storedValue = [object storedValueForKey:relName];
      if (!storedValue)
      {
        continue;
      }
      
      snapshot = [self _currentCommittedSnapshotForObject: object];                  
      comSnapshotValue = [snapshot objectForKey:relName];
      
      // or use == ?
      if ([storedValue isEqual:comSnapshotValue])
      {
        continue;
      }
      
      if ([substRelationship isToMany])
      {
        // or use == ?
        if ([comSnapshotValue isEqual: (NSArray*)storedValue] == NO)
        {
#warning check!!
          NSArray * storedValueArray = (NSArray*)storedValue;
          NSUInteger x;
          for (x = [storedValueArray count]; x > 0; x--)
          {            
            [self relayPrimaryKey: pk
                     sourceObject: object
                       destObject: [storedValueArray objectAtIndex:x-1]
                     relationship: substRelationship];
            
          }
          
        }
      }
      else
      {
        
        
        // 1:1 relationships may be optional so we may have no value here
        [self relayPrimaryKey: pk
                 sourceObject: object
                   destObject: value
                 relationship: substRelationship]; //this one ??
      }
    }
    
  }
}

- (void) createAdaptorOperationsForDatabaseOperation: (EODatabaseOperation*)dbOpe
                                          attributes: (NSArray*)attributes
{
  EOEntity           * entity = nil;
  EODatabaseOperator   dbOperator = EODatabaseNothingOperator;
  NSDictionary       * changedValues = nil;
  
  NSAssert(dbOpe, @"No operation");
  
  entity     = [dbOpe entity]; //OK
  dbOperator = [dbOpe databaseOperator]; //OK
  EOAdaptorOperation * lockOperation = nil;
  NSDictionary       * dbSnapshot = nil;

  EOQualifier *lockingQualifier = nil;
    
  switch (dbOperator)
  {
    case EODatabaseNothingOperator:
      break;
    case EODatabaseInsertOperator:
    {
      EOAdaptorOperation * insertOp = nil;
      EOStoredProcedure  * insertProc = nil;
      NSDictionary       * writeAttrValues = nil;

      changedValues = [dbOpe newRow];
      writeAttrValues = [self valuesToWriteForAttributes:attributes
                                                  entity:entity
                                           changedValues:changedValues];
      if ([writeAttrValues count] < 1)
      {
        break;
      }
      
      insertOp = [EOAdaptorOperation adaptorOperationWithEntity:entity];
      insertProc = [entity storedProcedureForOperation:EOInsertProcedureOperation];
      
      if (insertProc)
      {
        [insertOp setAdaptorOperator:EOAdaptorStoredProcedureOperator];
        [insertOp setStoredProcedure:insertProc];
      } else
      {
        [insertOp setAdaptorOperator:EOAdaptorInsertOperator];
      }
      [insertOp setChangedValues:writeAttrValues];
      [dbOpe addAdaptorOperation:insertOp];
      
      break;
    }
    case EODatabaseUpdateOperator:
    {
      NSArray            * lockNonQualAttrs = nil;
      NSArray            * pkAttributes = nil;
      NSArray            * lockingAttributes = nil;
      NSUInteger           changeCount, lockNonQualCount, lockAttrCount;
      
      changedValues = [dbOpe rowDiffsForAttributes:attributes];
      lockNonQualAttrs = [self lockingNonQualifiableAttributes:attributes];
      lockingAttributes = [self lockingAttributesForAttributes:attributes
                                                        entity:entity];
      
      changeCount = [changedValues count];
      lockNonQualCount = [lockNonQualAttrs count];
      lockAttrCount = [lockingAttributes count];
      
      // test if we have anything to do
      
      if (((changeCount == 0)) && ((lockNonQualCount == 0)) && ((lockAttrCount == 0))) {
        return;
      }
      
      pkAttributes = [self primaryKeyAttributesForAttributes:attributes
                                                      entity:entity];
      
      dbSnapshot = [dbOpe dbSnapshot];

      lockingQualifier = [self qualifierForLockingAttributes:lockingAttributes
                                        primaryKeyAttributes:pkAttributes
                                                      entity:entity
                                                    snapshot:dbSnapshot];
      
      if (((changeCount == 0)) || (lockNonQualCount > 0))
      {
        lockOperation = [EOAdaptorOperation adaptorOperationWithEntity:entity];
        [lockOperation setAdaptorOperator:EOAdaptorLockOperator];
        [lockOperation setQualifier:lockingQualifier];
        [lockOperation setChangedValues:dbSnapshot];
        
        if (lockNonQualCount > 0)
        {
          [lockOperation setAttributes:lockNonQualAttrs];
        } else {
          [lockOperation setAttributes:pkAttributes];
        }
        [dbOpe addAdaptorOperation:lockOperation];
      }
      if (changeCount > 0)
      {
        NSDictionary * writeAttrValues = nil;
        
        writeAttrValues = [self valuesToWriteForAttributes:attributes
                                                    entity:entity
                                             changedValues:changedValues];
        if ([writeAttrValues count] > 0)
        {
          EOAdaptorOperation * updateOperation = nil;
          
          updateOperation = [EOAdaptorOperation adaptorOperationWithEntity:entity];
          [updateOperation setAdaptorOperator:EOAdaptorUpdateOperator];
          [updateOperation setChangedValues:writeAttrValues];
          [updateOperation setQualifier:lockingQualifier];
          [dbOpe addAdaptorOperation:updateOperation];
        }
      }
      
    }
      break;
    case EODatabaseDeleteOperator: 
    {
      NSArray            * pkAttributes = nil;
      NSArray            * lockingAttributes = nil;
      NSArray            * lockNonQualAttrs = nil;
      EOAdaptorOperation * deleteOp = nil;
      EOStoredProcedure  * deleteProc = nil;
      
      pkAttributes = [self primaryKeyAttributesForAttributes:attributes
                                                      entity:entity];
      
      lockingAttributes = [self lockingAttributesForAttributes:attributes
                                                        entity:entity];
      
      dbSnapshot = [dbOpe dbSnapshot];
      
      lockingQualifier = [self qualifierForLockingAttributes:lockingAttributes
                                        primaryKeyAttributes:pkAttributes
                                                      entity:entity
                                                    snapshot:dbSnapshot];
      
      lockNonQualAttrs = [self lockingNonQualifiableAttributes:attributes];
      
      if ([lockNonQualAttrs count] > 0)
      {
        lockOperation = [EOAdaptorOperation adaptorOperationWithEntity:entity];
        [lockOperation setAdaptorOperator:EOAdaptorLockOperator]; /* 0  in EOF */
        [lockOperation setQualifier:lockingQualifier];
        [lockOperation setAttributes:lockNonQualAttrs];
        [lockOperation setChangedValues:dbSnapshot];
        [dbOpe addAdaptorOperation:lockOperation];
      }
      
      deleteOp = [EOAdaptorOperation adaptorOperationWithEntity:entity];
      deleteProc = [entity storedProcedureForOperation:EODeleteProcedureOperation];
      
      if (deleteProc)
      {
        [deleteOp setAdaptorOperator:EOAdaptorStoredProcedureOperator]; /* 4 */
        [deleteOp setStoredProcedure:deleteProc];
        [deleteOp setChangedValues:dbSnapshot];
      } else {
        [deleteOp setAdaptorOperator:EOAdaptorDeleteOperator]; /* 3 */
        [deleteOp setQualifier:lockingQualifier];
      }
      [dbOpe addAdaptorOperation:deleteOp];
      
    }
      break;
  }
  
}

- (void) createAdaptorOperationsForDatabaseOperation: (EODatabaseOperation*)dbOpe
{
  //OK for Update - Test for others
  NSArray *attributesToSave = nil;
  NSMutableArray *attributes = nil;
  NSUInteger count=0;
  EODatabaseOperator dbOperator = EODatabaseNothingOperator;
  EOEntity *entity = [dbOpe entity];
  NSDictionary *rowDiffs = nil;

  [self processSnapshotForDatabaseOperation: dbOpe];
  dbOperator = [dbOpe databaseOperator];

  if (dbOperator == EODatabaseUpdateOperator)
  {
    rowDiffs = [dbOpe rowDiffs];
    if ((!rowDiffs) || (([rowDiffs count] == 0))) 
    {
      return;
    }
  }
  
  attributesToSave = [entity _attributesToSave];
  attributes = [NSMutableArray array];

  count = [attributesToSave count];
  if (count>0)
    {
      int i=0;
      IMP attributesAddObjectIMP=[attributes methodForSelector:@selector(addObject:)];
      IMP attributesToSaveObjectAtIndexIMP=[attributesToSave methodForSelector:@selector(objectAtIndex:)];

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = 
            GDL2_ObjectAtIndexWithImp(attributesToSave,attributesToSaveObjectAtIndexIMP,i);


          
          if (![attribute isFlattened] && ![attribute isDerived]) //VERIFY
            {
              GDL2_AddObjectWithImp(attributes,attributesAddObjectIMP,attribute);
              
              if ([rowDiffs objectForKey: [attribute name]]
                  && [attribute isReadOnly])
                {
                  NSEmitTODO();
                  [self notImplemented: _cmd]; //TODO: excption ???
                }
            }
        }
    };




  [self createAdaptorOperationsForDatabaseOperation: dbOpe
        attributes: attributes];
}

static NSComparisonResult 
compareUsingEntityNames(id left, id right, void* vpSortOrders)
{
  NSArray            * sortOrders = (NSArray *)vpSortOrders;
  EOAdaptorOperation * leftOp = (EOAdaptorOperation*) left;
  EOAdaptorOperation * rightOp = (EOAdaptorOperation*) right;
  NSString           * leftName = [[leftOp entity] name];
  NSString           * rightName = [[rightOp entity] name];
  NSUInteger           leftIndex;
  NSUInteger           rightIndex;
    
  leftIndex = [sortOrders indexOfObject:leftName];
  rightIndex = [sortOrders indexOfObject:rightName];
  
  if (leftIndex < rightIndex) {
    return NSOrderedAscending;
  }
  if (leftIndex > rightIndex) {
    return NSOrderedDescending;
  } else {
    EOAdaptorOperator leftOperator = [leftOp adaptorOperator];
    EOAdaptorOperator rightOperator = [rightOp adaptorOperator];
    
    if (leftOperator < rightOperator) {
      return NSOrderedAscending;
    }
    if (leftOperator > rightOperator) {
      return NSOrderedDescending;
    }      
  }

  return NSOrderedSame;
}

- (NSArray*) orderAdaptorOperations
{
  NSMutableArray      * orderedAdaptorOpe = nil;
  
  if (_delegateRespondsTo.willOrderAdaptorOperations == YES) {
    orderedAdaptorOpe = (NSMutableArray*) [_delegate databaseContext: self
                    willOrderAdaptorOperationsFromDatabaseOperations:
                                           NSAllMapTableValues(_dbOperationsByGlobalID)];
    
  } else {
    NSMutableArray      * entities = [NSMutableArray array];
//    NSMutableArray      * adaptorOperations = [NSMutableArray array];
    NSMapEnumerator       dbOpeEnum;
    EOGlobalID          * gid = nil;
    EODatabaseOperation * dbOpe = nil;
    NSArray             * entityNameOrderingArray = nil;
//    NSHashTable         * entitiesHashTable = NSCreateHashTable(NSNonOwnedPointerHashCallBacks,32);
    
    orderedAdaptorOpe = (NSMutableArray*)[NSMutableArray array];
    
    dbOpeEnum = NSEnumerateMapTable(_dbOperationsByGlobalID);
    
    while (NSNextMapEnumeratorPair(&dbOpeEnum, (void **)&gid,
                                   (void **)&dbOpe))
    {
      NSArray *dbOpeAdaptorOperations = [dbOpe adaptorOperations];
      NSUInteger operCount = 0;
      NSUInteger idx = 0;
      
      if (dbOpeAdaptorOperations)
      {
        [orderedAdaptorOpe addObjectsFromArray:dbOpeAdaptorOperations];
        operCount = [dbOpeAdaptorOperations count];
      }      
      
      
      while (idx < operCount) 
      {
        EOEntity * entity = [[dbOpeAdaptorOperations objectAtIndex:idx] entity];
        if (([entities indexOfObject:entity] == NSNotFound))
        {
          [entities addObject:entity];
        }
        idx++;
      }
      
    }
    NSEndMapTableEnumeration(&dbOpeEnum);
    
    entityNameOrderingArray = [self entityNameOrderingArrayForEntities:entities];
    
    [orderedAdaptorOpe sortUsingFunction:compareUsingEntityNames
                                 context:entityNameOrderingArray];
  }
  
  return orderedAdaptorOpe;
}

- (NSArray*) entitiesOnWhichThisEntityDepends: (EOEntity*)entity
{
  NSMutableArray *entities = nil;
  NSArray *relationships = nil;
  int count;



  relationships = [entity relationships];
  count = [relationships count];

  if (count>0)
    {
      IMP oaiIMP=[relationships methodForSelector: @selector(objectAtIndex:)];
      int i=0;

      for (i = 0; i < count; i++)
        {
          EORelationship *relationship = GDL2_ObjectAtIndexWithImp(relationships,oaiIMP,i);
          

          
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
    }



  return entities;
}

/* this is private. it seems other implementations are doing much more
 * than this.
 */

- (NSArray*)entityNameOrderingArrayForEntities: (NSArray*)entities
{
  //TODO
  NSMutableArray *ordering = [NSMutableArray array];
  NSMutableSet *orderedEntities = [NSMutableSet set];
  /*EODatabase *database = [self database];
    NSArray *models = [database models];*/
  NSMutableDictionary *dependsDict = [NSMutableDictionary dictionary];
  int count = [entities count];

  //TODO NSArray* originalOrdering=...
  /*TODO for each mdoel:
    userInfo (ret nil)
  */

  if (count>0)
    {
      IMP oaiIMP=[entities methodForSelector: @selector(objectAtIndex:)];
      int i=0;

      for (i = 0; i < count; i++)
        {
          //OK
          EOEntity *entity=GDL2_ObjectAtIndexWithImp(entities,oaiIMP,i);
          NSArray *dependsEntities = [self
                                       entitiesOnWhichThisEntityDepends: entity];
          
          if ([dependsEntities count])
            [dependsDict setObject: dependsEntities
                         forKey: [entity name]];
        }
      
      ordering = [NSMutableArray array];
      for (i = 0; i < count; i++)
        {
          EOEntity *entity=GDL2_ObjectAtIndexWithImp(entities,oaiIMP,i);
          [self insertEntity: entity
                intoOrderingArray: ordering
                withDependencies: dependsDict
                processingSet: orderedEntities];
        }
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

  entity = [attribute entity];

  NSAssert1(entity, @"No entity for attribute %@", attribute);

  model = [entity model];
  database = [self database];
  adaptor = [database adaptor];
  externalType = [attribute externalType];
  isValid = [adaptor isValidQualifierType: externalType
		     model: model];

  return isValid;
}

- (NSArray*) lockingNonQualifiableAttributes: (NSArray*)attributes
{
  NSMutableArray * lockingAttrs = nil;
  NSArray        * attributesUsedForLocking = nil;
  NSUInteger       i = [attributes count];
  
  for (; i > 0; i--)
  {
    EOAttribute * attr = [attributes objectAtIndex:i-1];
    
    if (!attributesUsedForLocking)
    {
      attributesUsedForLocking = [[attr entity] attributesUsedForLocking];
    }
    
    if ([self isValidQualifierTypeForAttribute:attr] || 
        (![attributesUsedForLocking containsObject:attr]))
    {
      continue;
    }
    
    if (!lockingAttrs)
    {
      lockingAttrs = [NSMutableArray array];
    }
    [lockingAttrs addObject:attr];
  }
  
  if (!lockingAttrs) {
    lockingAttrs = [NSArray array];
  }
  
  return lockingAttrs;
}


- (NSArray*) lockingAttributesForAttributes: (NSArray*)attributes
                                     entity: (EOEntity*)entity
{
  //TODO
  NSArray *retAttributes = nil;
  int count = 0;
  NSArray *attributesUsedForLocking = nil;



  attributesUsedForLocking = [entity attributesUsedForLocking];
  count = [attributes count];

  if (count>0)
    {
      IMP oaiIMP=[attributes methodForSelector: @selector(objectAtIndex:)];
      int i=0;

      for (i = 0; i < count; i++)
        {
          id attribute = GDL2_ObjectAtIndexWithImp(attributes,oaiIMP,i);
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
    };



  return retAttributes; //TODO
}

- (NSArray*) primaryKeyAttributesForAttributes: (NSArray*)attributes
                                        entity: (EOEntity*)entity
{
  //TODO
  NSArray *retAttributes = nil;
  int count = 0;


//TODO

  count = [attributes count];

  if (count>0)
    {
      IMP oaiIMP=[attributes methodForSelector: @selector(objectAtIndex:)];
      int i=0;

      for (i = 0; i < count; i++)
        {
          id attribute = GDL2_ObjectAtIndexWithImp(attributes,oaiIMP,i);
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
    };



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
  
  //First use primaryKeyAttributes, next use attributes
  for (which = 0; which < 2; which++)
  {
    NSArray *array = (which == 0 ? primaryKeyAttributes : attributes);
    NSUInteger i,count = [array count];
    
    for (i = 0; i < count; i++)
    {
      EOAttribute *attribute = [array objectAtIndex: i];
      
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
          NSAssert2(snapName, @"no snapName for attribute %@ in entity %@",
                    attributeName, [entity name]);
          
          value = [snapshot objectForKey:snapName];
          
          NSAssert4(value != nil,
                    @"no value for snapshotKey '%@' in snapshot (address=%p) %@ for entity %@",
                    snapName, snapshot, snapshot, [entity name]);
          
          aQualifier 
          = [EOKeyValueQualifier qualifierWithKey: attributeName
                                 operatorSelector: @selector(isEqualTo:)
                                            value: value];
          
          if (!qualifiers)
            qualifiers = [NSMutableArray array];
          
          [qualifiers addObject: aQualifier];
        }
      }
    }
  }
  
  if ([qualifiers count] == 1)
  {
    qualifier = [qualifiers objectAtIndex: 0];
  }
  else
  {
    qualifier = [EOAndQualifier qualifierWithQualifierArray: qualifiers];
  }
  
  return qualifier;
}

- (void) insertEntity: (EOEntity*)entity
    intoOrderingArray: (NSMutableArray*)orderingArray
     withDependencies: (NSDictionary*)dependencies
        processingSet: (NSMutableSet*)processingSet
{
  NSString * entityName = [entity name];
  
  if ((([orderingArray indexOfObject:entityName] == NSNotFound)) && 
      (![processingSet containsObject:entityName]))
  {
    NSUInteger   depCount = 0;
    NSUInteger   idx = 0;
    NSArray    * dependenciesForEntity = [dependencies objectForKey:entityName];
    
    [processingSet addObject:entityName];
    
    if (dependenciesForEntity) {
      depCount = [dependenciesForEntity count];
    }
    
    for (; idx < depCount; idx++)
    {
      [self insertEntity:[dependenciesForEntity objectAtIndex:idx]
       intoOrderingArray:orderingArray
        withDependencies:dependencies
           processingSet:processingSet];
    }
    
    [orderingArray addObject:entityName];
  }
}

- (void) processSnapshotForDatabaseOperation: (EODatabaseOperation*)dbOpe
{
  //Near OK
  EOAdaptor *adaptor = [_database adaptor];//OK
  EOEntity *entity = [dbOpe entity];//OK
  NSMutableDictionary *newRow = nil;
  NSDictionary *dbSnapshot = nil;
  NSEnumerator *attrNameEnum = nil;
  id attrName = nil;
  IMP enumNO=NULL; // nextObject
  
  newRow = [dbOpe newRow]; //OK{a3code = Q77; code = Q7; numcode = 007; } //ALLOK

  dbSnapshot = [dbOpe dbSnapshot];
    
  // we need to make sure that we do not change an array while enumering it.
  attrNameEnum = [[NSArray arrayWithArray:[newRow allKeys]] objectEnumerator];
  enumNO=NULL;
  while ((attrName = GDL2_NextObjectWithImpPtr(attrNameEnum,&enumNO)))
  {
    EOAttribute *attribute = [entity attributeNamed: attrName];
    id newRowValue = nil;
    id dbSnapshotValue = nil;
    
    newRowValue = [newRow objectForKey:attrName];
    
    
    dbSnapshotValue = [dbSnapshot objectForKey: attrName];
    
    if (dbSnapshotValue && (![newRowValue isEqual: dbSnapshotValue]))
    {
      id adaptorValue = [adaptor fetchedValueForValue: newRowValue
                                            attribute: attribute];
      
      if ((!adaptorValue) || ((adaptorValue != dbSnapshotValue) && (![adaptorValue isEqual:dbSnapshotValue])))
      {
        if (!adaptorValue)
        {
          adaptorValue = GDL2_EONull;
        }
        [newRow setObject:adaptorValue
                   forKey:attrName];
      }
    }
  }
  
}


- (NSDictionary*) valuesToWriteForAttributes: (NSArray*)attributes
                                      entity: (EOEntity*)entity
                               changedValues: (NSDictionary*)changedValues
{
  //NEAR OK
  NSMutableDictionary *valuesToWrite = [NSMutableDictionary dictionary];
  BOOL isReadOnlyEntity = NO;

  isReadOnlyEntity = [entity isReadOnly];

  NSDebugMLLog(@"EODatabaseContext", @"isReadOnlyEntity=%s",
	       (isReadOnlyEntity ? "YES" : "NO"));

  if (isReadOnlyEntity)
    {
      NSEmitTODO();
      [self notImplemented: _cmd]; //TODO
    }
  else
    {
      int count = [attributes count];
      if (count>0)
        {
          IMP oaiIMP=[attributes methodForSelector: @selector(objectAtIndex:)];
          int i=0;

          for (i = 0; i < count; i++)
            {
              EOAttribute *attribute = GDL2_ObjectAtIndexWithImp(attributes,oaiIMP,i);
              BOOL isReadOnly = [attribute isReadOnly];
              

              NSDebugMLLog(@"EODatabaseContext", @"isReadOnly=%s",
                           (isReadOnly ? "YES" : "NO"));
              
              if (isReadOnly)
                {
                  NSEmitTODO();
                  NSDebugMLog(@"attribute=%@", attribute);
                  [self notImplemented: _cmd]; //TODO
                }
              else
                {
                  NSString *attrName = [attribute name];
                  NSString *snapName = nil;
                  id value = nil;
                  

                  
                  snapName = [entity snapshotKeyForAttributeName: attrName];

                  
                  value = [changedValues objectForKey: snapName];

                  
                  if (value)
                    [valuesToWrite setObject: value
                                   forKey: attrName];
                }
            }
        }
    }





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
  NSString* relationshipName = nil;
  IMP globalIDForObjectIMP=NULL;
  IMP toManySnapArrayObjectAtIndexIMP=NULL;
  IMP objsEnumNO=NULL;
  IMP objectsOAI=NULL;

  qualifierArray = AUTORELEASE([GDL2_alloc(NSMutableArray) init]);
  valuesArray = AUTORELEASE([GDL2_alloc(NSMutableArray) init]);
  toManySnapshotArray = AUTORELEASE([GDL2_alloc(NSMutableArray) init]);
  toManySnapArrayObjectAtIndexIMP=[toManySnapshotArray methodForSelector: @selector(objectAtIndex:)];
  relationshipName = [relationship name];

  objsEnum = [objects objectEnumerator];
  objsEnumNO=NULL;
  while ((object = GDL2_NextObjectWithImpPtr(objsEnum,&objsEnumNO)))
    {
      IMP joinsEnumNO=NO;
      values 
	= AUTORELEASE([GDL2_alloc(NSMutableDictionary) initWithCapacity: 4]);

      fault = [object valueForKey: relationshipName];
      [EOFault clearFault: fault];

      joinsEnum = [[relationship joins] objectEnumerator];
      while ((join = GDL2_NextObjectWithImpPtr(joinsEnum,&joinsEnumNO)))
	{
	  [values setObject: [object valueForKey: [[join sourceAttribute] name]]
		  forKey: [[join destinationAttribute] name]];
	}

      [valuesArray addObject: values];
      [toManySnapshotArray addObject:
			     AUTORELEASE([GDL2_alloc(NSMutableArray) init])];

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

  if (count>0)
    {
      IMP oaiIMP=[valuesArray methodForSelector: @selector(objectAtIndex:)];

      objsEnum = [array objectEnumerator];
      objsEnumNO=NULL;
      while ((object = GDL2_NextObjectWithImpPtr(objsEnum,&objsEnumNO)))
        {
          IMP objectVFK=NULL; // valueForKey:
          for (i = 0; i < count; i++)
            {
              IMP keyEnumNO=NULL; // nextObject
              IMP valuesOFK=NULL; // objectForKey:
              equal = YES;
              values = GDL2_ObjectAtIndexWithImp(valuesArray,oaiIMP,i);

              keyEnum = [values keyEnumerator];
              while ((key = GDL2_NextObjectWithImpPtr(keyEnum,&keyEnumNO)))
                {
                  if ([GDL2_ValueForKeyWithImpPtr(object,&objectVFK,key)
                        isEqual: GDL2_ObjectForKeyWithImpPtr(values,&valuesOFK,key)] == NO)
                    {
                      equal = NO;
                      break;
                    }
                }
              
              if (equal == YES)
                {
                  EOGlobalID* gid = nil;
                  id snapshot = GDL2_ObjectAtIndexWithImp(toManySnapshotArray,toManySnapArrayObjectAtIndexIMP,i);
                  
                  [[GDL2_ObjectAtIndexWithImpPtr(objects,&objectsOAI,i) valueForKey: relationshipName]
                    addObject: object];
                  
                  gid=EOEditingContext_globalIDForObjectWithImpPtr(editingContext,&globalIDForObjectIMP,object);
                  
                  [snapshot addObject: gid];
                  
                  break;
                }
            }
	}
    }

//==> see _registerSnapshot:forSourceGlobalID:relationshipName:editingContext:

  if (count>0)
    {
      for (i = 0; i < count; i++)
        {
          id snapshot = GDL2_ObjectAtIndexWithImp(toManySnapshotArray,toManySnapArrayObjectAtIndexIMP,i);
          EOGlobalID* gid=EOEditingContext_globalIDForObjectWithImpPtr(editingContext,
                                                                       &globalIDForObjectIMP,
                                                                       GDL2_ObjectAtIndexWithImpPtr(objects,&objectsOAI,i));
          [_database recordSnapshot: snapshot
                     forSourceGlobalID: gid
                     relationshipName: relationshipName];
        };
    }

}

@end

@implementation EODatabaseContext (EODatabaseContextPrivate)

- (void) _fireArrayFault: (id)object
{
  //OK ??
  BOOL fetchIt = YES;





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

      NSDebugMLLog(@"EODatabaseContext", @"relationshipName=%@",
		   relationshipName);


      objects = [context objectsForSourceGlobalID: gid
			 relationshipName: relationshipName
			 editingContext: context];

      [EOFault clearFault: object]; //??
      /* in clearFault 
         [handler faultWillFire:object];
         targetClass=[handler targetClass];
         extraData=[handler extraData];
         RELEASE(handler);
      */
      NSDebugMLLog(@"EODatabaseContext",
		   @"NEAR FINISHED 1 object count=%d %p %@",
		   [object count],
		   object,
		   object);
      NSDebugMLLog(@"EODatabaseContext",
		   @"NEAR FINISHED 1 objects count=%d %p %@",
		   [objects count],
		   objects,
		   objects);

      if (objects != object)
        {
          //No, not needed      [object removeObjectsInArray:objects];//Because some objects may be here. We don't want duplicate. It's a hack because I don't see why there's objects in object !
          NSDebugMLLog(@"EODatabaseContext",
		       @"NEAR FINISHED 1 object count=%d %p %@",
		       [object count],
		       object,
		       object);

          [object addObjectsFromArray: objects];

          NSDebugMLLog(@"EODatabaseContext",
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


}

- (void) _fireFault: (id)object
{
  //TODO
  BOOL fetchIt = YES;//MIRKO
  EOGlobalID *gid;
  
  
  
  //MIRKO
  NSDebugMLLog(@"EODatabaseContext",@"Fire Fault: object %p of class %@",
               object,[object class]);
  
  if (_delegateRespondsTo.shouldFetchObjectFault == YES)
  {
    fetchIt = [_delegate databaseContext: self
                  shouldFetchObjectFault: object];
  }
  
  if (fetchIt)
  {
    EOAccessFaultHandler *handler;
    EOEditingContext *context;
    NSDictionary *snapshot;
    EOEntity *entity = nil;
    NSString *entityName = nil;
    
    handler = (EOAccessFaultHandler *)[EOFault handlerForFault: object];
    context = [handler editingContext];
    gid = [handler globalID];
    snapshot = EODatabaseContext_snapshotForGlobalIDWithImpPtr(self,NULL,gid); //nil
    
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
      
      fetchSpecif = AUTORELEASE([EOFetchSpecification new]);
      [fetchSpecif setEntityName: entityName];
      
      qualifier = [EOOrQualifier qualifierWithQualifierArray: qualifiers];
      
      [fetchSpecif setQualifier: qualifier];
      
      objects = [self objectsWithFetchSpecification: fetchSpecif
                                     editingContext: context];
      
      NSDebugMLLog(@"EODatabaseContext", @"objects %p=%@ class=%@",
                   objects, objects, [objects class]);
    }
  }
  
  if (_isFault(object)) {
    [EOFault clearFault: object];
    
    if ((!_delegate) || (!_delegateRespondsTo.databaseContextFailedToFetchObject) ||
        (![_delegate databaseContext:self
                 failedToFetchObject:object
                            globalID:gid]))
    {
      [_missingObjectGIDs addObject:gid];
    }
  }
  
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

      qualifier = AUTORELEASE([[EOOrQualifier alloc]
		     initWithQualifierArray:qualifierArray]);
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





  if (fault)
    {
      EOAccessGenericFaultHandler *handler = nil;
      NSString *entityName = [globalID entityName];



      handler = [_batchFaultBuffer objectForKey: entityName];



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


  NSDebugMLLog(@"EODatabaseContext", @"self=%p database=%p",
	       self, _database);
  NSDebugMLLog(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
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

  NSDebugMLLog(@"EODatabaseContext", @"self=%p _uniqueStack %p=%@",
	       self, _uniqueStack, _uniqueStack);


}

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
{
  return [self snapshotForGlobalID: gid
	       after: EODistantPastTimeInterval];
}

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
                                after: (NSTimeInterval)ti
{
  //OK
  NSDictionary *snapshot = nil;



  NSDebugMLLog(@"EODatabaseContext", @"self=%p database=%p",
	       self, _database);


  snapshot = [self localSnapshotForGlobalID: gid];

  if (!snapshot)
    {
      NSAssert(_database, @"No database");
      snapshot = [_database snapshotForGlobalID: gid
			    after: ti];
    }

  NSDebugMLLog(@"EODatabaseContext", @"snapshot for gid %@: %p %@",
	       gid, snapshot, snapshot);



  return snapshot;
}

- (void)recordSnapshot: (NSArray *)gids
     forSourceGlobalID: (EOGlobalID *)gid
      relationshipName: (NSString *)name
{


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


}

- (NSArray *)snapshotForSourceGlobalID: (EOGlobalID *)gid
		      relationshipName: (NSString *)name
{
  NSArray *snapshot = nil;


  NSEmitTODO();

  [self notImplemented: _cmd]; //TODO
/*

  snapshot = [[_toManySnapshots objectForKey:gid] objectForKey:name];
  if (!snapshot)
    snapshot=[_database snapshotForSourceGlobalID:gid
                        relationshipName:name];
*/



  return snapshot;
}

- (NSDictionary *)localSnapshotForGlobalID: (EOGlobalID *)gid
{
  //OK
  NSDictionary *snapshot = nil;
  int snapshotsDictCount = 0;



  NSDebugMLLog(@"EODatabaseContext", @"self=%p database=%p",
	       self, _database);

  snapshotsDictCount = [_uniqueStack count];

  if (snapshotsDictCount>0)
    {
      int i = 0;
      IMP oaiIMP=[_uniqueStack methodForSelector: @selector(objectAtIndex:)];

      for (i = 0; !snapshot && i < snapshotsDictCount; i++)
        {
          NSDictionary *snapshots = GDL2_ObjectAtIndexWithImp(_uniqueStack,oaiIMP,i);
          snapshot = [snapshots objectForKey: gid];
        }
    };

  NSDebugMLLog(@"EODatabaseContext", @"snapshot for gid %@: %p %@",
	       gid, snapshot, snapshot);



  return snapshot;
}

- (NSArray *)localSnapshotForSourceGlobalID: (EOGlobalID *)gid
			   relationshipName: (NSString *)name
{
  NSArray *snapshot = nil;

  //TODO

  NSEmitTODO();

  [self notImplemented: _cmd]; //TODO
/*
  return [[_toManySnapshots objectForKey:gid] objectForKey:name];
*/



  return snapshot;
}

- (void)forgetSnapshotForGlobalID: (EOGlobalID *)gid
{
  //TODO-VERIFY deleteStack


  NSDebugMLLog(@"EODatabaseContext",
	       @"self=%p database=%p [_uniqueStack count]=%d",
	       self, _database,[_uniqueStack count]);

  if ([_uniqueStack count] > 0)
    {
      NSMutableDictionary *uniqueSS = [_uniqueStack lastObject];
      NSMutableDictionary *uniqArSS = [_uniqueArrayStack lastObject];
      NSMutableSet        *deleteSS = [_deleteStack lastObject];

      [deleteSS addObject: gid];
      [uniqueSS removeObjectForKey: gid];
      [uniqArSS removeObjectForKey: gid];
    }


}

- (void)forgetSnapshotsForGlobalIDs: (NSArray *)gids
{
  unsigned i, j, n, m;
  NSMutableDictionary *snapshots;
  NSMutableSet *deleteGIDs;
  EOGlobalID *gid;


  n = [_uniqueStack count];
  if (n>0)
    {
      IMP oaiIMP=[_uniqueStack methodForSelector: @selector(objectAtIndex:)];

      for (i=0; i<n; i++)
        {
          snapshots = GDL2_ObjectAtIndexWithImp(_uniqueStack,oaiIMP,i);
          [snapshots removeObjectsForKeys: gids];
        }
    };

  n = [_uniqueArrayStack count];
  if (n>0)
    {
      IMP oaiIMP
	= [_uniqueArrayStack methodForSelector: @selector(objectAtIndex:)];

      for (i=0; i<n; i++)
        {
          snapshots = GDL2_ObjectAtIndexWithImp(_uniqueArrayStack,oaiIMP,i);
          [snapshots removeObjectsForKeys: gids];
        }
    };

  n = [_deleteStack count];
  if (n>0)
    {
      IMP oaiIMP=[_deleteStack methodForSelector: @selector(objectAtIndex:)];
      IMP oaiIMP2=[gids methodForSelector: @selector(objectAtIndex:)];

      m = [gids count];
      for (i=0; i<n; i++)
        {
          deleteGIDs = GDL2_ObjectAtIndexWithImp(_deleteStack,oaiIMP,i);
	  for (j=0; j<m; j++)
	    {
	      gid = GDL2_ObjectAtIndexWithImp(gids, oaiIMP2, j);
	      [deleteGIDs removeObject: gid];
	    }
        }
    }

  [_database forgetSnapshotsForGlobalIDs: gids];

}

- (void)recordSnapshots: (NSDictionary *)snapshots
{


  NSEmitTODO();
  [self notImplemented: _cmd]; //TODO
/*
  [_snapshots addEntriesFromDictionary:snapshots];
*/


}

- (void)recordToManySnapshots: (NSDictionary *)snapshots
{

  //OK

  if ([_uniqueArrayStack count] > 0)
    {
      NSMutableDictionary *toManySnapshots = [_uniqueArrayStack lastObject];
      NSArray *keys = [snapshots allKeys];
      int count = [keys count];

      if (count>0)
        {
          IMP oaiIMP=[keys methodForSelector: @selector(objectAtIndex:)];
          int i = 0;

          for (i = 0; i < count; i++)
            {
              id key = GDL2_ObjectAtIndexWithImp(keys,oaiIMP,i);
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
        };
    }


}

- (void)registerLockedObjectWithGlobalID: (EOGlobalID *)globalID
{


  if (!_lockedObjects)
    {
      _lockedObjects 
	= NSCreateHashTable(NSNonOwnedPointerHashCallBacks, _LOCK_BUFFER);
    }

  NSHashInsert(_lockedObjects, globalID);


}

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)globalID
{
  BOOL result;



  result = (_lockedObjects && NSHashGet(_lockedObjects, globalID) != nil);



  return result;
}

- (void)initializeObject: (id)object
                     row: (NSDictionary*)row
                  entity: (EOEntity*)entity
          editingContext: (EOEditingContext*)context
{
  //really near ok
  NSArray *relationships = nil;
  NSArray *classPropertyAttributeNames = nil;
  NSUInteger count = 0;
  IMP rowObjectForKeyIMP=NULL;
  
  classPropertyAttributeNames = [entity classPropertyAttributeNames];
  count = [classPropertyAttributeNames count];
  
  //row is usuallly a EOMutableKnownKeyDictionary so will use EOMKKD_objectForKeyWithImpPtr
  
  if (count>0)
  {
    NSUInteger i=0;
    IMP oaiIMP=[classPropertyAttributeNames methodForSelector:@selector(objectAtIndex:)];
    
    NSAssert(!_isFault(object),
             @"Object is a fault. call -methodForSelector: on it is a bad idea");
    
    for (i = 0; i < count; i++)
    {
      id key = GDL2_ObjectAtIndexWithImp(classPropertyAttributeNames,oaiIMP,i);
      id value = nil;
      
      
      value = EOMKKD_objectForKeyWithImpPtr(row,&rowObjectForKeyIMP,key);
      
      if (value == GDL2_EONull)
        value = nil;
            
      [object takeStoredValue:value
                       forKey:key];
    }
  };
  
  relationships = [entity _relationshipsToFaultForRow: row];
  
  
  
  count = [relationships count];
  
  if (count>0)
  {
    NSUInteger i=0;
    IMP oaiIMP=[relationships methodForSelector:@selector(objectAtIndex:)];
    
    NSAssert(!_isFault(object),
             @"Object is a fault. call -methodForSelector: on it is a bad idea");
    
    
    for (i = 0; i < count; i++)
    {
      id relObject = nil;
      EORelationship *relationship = GDL2_ObjectAtIndexWithImp(relationships,oaiIMP,i);
      NSString *relName = [relationship name];
      
      
      if ([relationship isToMany])
      {
        EOGlobalID *gid = [entity globalIDForRow: row];
        
        relObject = [self arrayFaultWithSourceGlobalID: gid
                                      relationshipName: relName
                                        editingContext: context];
      }
      else if ([relationship isFlattened])
      {
        // to one flattened relationship like aRelationship.anotherRelationship...
        
        // I don't know how to handle this case.... May be we shouldn't treat this as real property ??
        NSEmitTODO();
        relObject = nil;          
      }
      else
      {          
        EOMutableKnownKeyDictionary *foreignKeyForSourceRow = nil;
                
        foreignKeyForSourceRow = [relationship _foreignKeyForSourceRow: row];
                
        if (![foreignKeyForSourceRow
              containsObjectsNotIdenticalTo: GDL2_EONull])
        {
          NSEmitTODO();//TODO: what to do if rel is mandatory ?
          relObject = nil;
        }
        else
        {
          EOEntity *destinationEntity = [relationship destinationEntity];
          EOGlobalID *relRowGid = [destinationEntity
                                   globalIDForRow: foreignKeyForSourceRow];
          
          
          
          if ([(EOKeyGlobalID*)relRowGid areKeysAllNulls])
            NSWarnLog(@"All key of relRowGid %p (%@) are nulls",
                      relRowGid,
                      relRowGid);
          
          relObject = [context faultForGlobalID: relRowGid
                                 editingContext: context];
          
          NSDebugMLLog(@"EODatabaseContext", @"relObject=%p (%@)",
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
      
      [object takeStoredValue:relObject
                       forKey:relName];
    }
  };
  
  
}

- (void)forgetAllLocks
{
  if (_lockedObjects)
    {
      NSResetHashTable(_lockedObjects);
    }
}

- (void)forgetLocksForObjectsWithGlobalIDs: (NSArray *)gids
{
  if (_lockedObjects)
    {
      unsigned n;
      EOGlobalID *gid;

      n = [gids count];

      if (n>0)
        {
          IMP oaiIMP=[gids methodForSelector: @selector(objectAtIndex:)];
          unsigned i = 0;

          for (i=0; i<n; i++)
            {
              gid = GDL2_ObjectAtIndexWithImp(gids,oaiIMP,i);
              NSHashRemove(_lockedObjects, gid);
            }
        };
    }
}

- (void)_rollbackTransaction
{


  if ([_uniqueStack count] > 0)
    {
      [self forgetAllLocks];

      [_uniqueStack removeLastObject];
      [_uniqueArrayStack removeLastObject];
      [_deleteStack removeLastObject];
    }


}

- (void)_commitTransaction
{
  
  if ([_uniqueStack count] > 0)
  {
    NSMutableDictionary *snapshotsDict = [_uniqueStack lastObject];
    NSMutableDictionary *toManySnapshotsDict = [_uniqueArrayStack lastObject];
    NSMutableSet *deleteSnapshotsSet = [_deleteStack lastObject];
    NSEnumerator *deletedGIDEnum = [deleteSnapshotsSet objectEnumerator];
    EOGlobalID *gid;
    
    while ((gid = [deletedGIDEnum nextObject]))
    {
      [_database forgetSnapshotForGlobalID: gid];
    }
    
    [_database recordSnapshots: snapshotsDict];
    [_database recordToManySnapshots: toManySnapshotsDict];
    
    [self forgetAllLocks];
    
    [_uniqueStack removeLastObject];
    [_uniqueArrayStack removeLastObject];
    [_deleteStack removeLastObject];
  }
  
}

- (void) _beginTransaction
{
  [_uniqueStack addObject: [NSMutableDictionary dictionary]];
  [_uniqueArrayStack addObject: [NSMutableDictionary dictionary]];
  [_deleteStack addObject: [NSMutableSet set]];
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



  entity = [dbOpe entity];



  if ([entity isReadOnly])
    {
      //?? exception I presume
    }
  else
    {
      [dbOpe databaseOperator]; //SoWhat
    }


}

- (void) _cleanUpAfterSave
{
  // TODO -- dw
  //EODatabase * eodatabase = [self database];

  _coordinator = nil; //realesae ?
  _editingContext = nil; //realesae ?

  if (_dbOperationsByGlobalID)
    {
      //Really free it because we don't want to record some db ope (select for exemple).
      NSFreeMapTable(_dbOperationsByGlobalID);
      _dbOperationsByGlobalID = NULL;
    }

  _flags.beganTransaction = NO;
  _flags.willPrepareForSave = NO;
  _flags.preparingForSave = NO;
  
  // TODO -- dw
//  if (eodatabase != nil)
//  {
//    [eodatabase _clearLastRecords];
//  }
  
}

- (EOGlobalID*)_globalIDForObject: (id)object
{
  EOEditingContext *objectEditingContext = nil;
  EOGlobalID *gid = nil;


  NSAssert(object, @"No object");

  NSDebugMLLog(@"EODatabaseContext",@"object=%p of class %@",
	       object,[object class]);
  NSDebugMLLog(@"EODatabaseContext", @"_editingContext=%p",
	       _editingContext);

  objectEditingContext = [object editingContext];
  NSAssert2(objectEditingContext, @"No editing context for object %p: %@", 
            object,object);

  gid=EOEditingContext_globalIDForObjectWithImpPtr(objectEditingContext,
                                                   NULL,
                                                   object);


  if (!gid)
    {
      NSEmitTODO();
      NSLog(@"TODO: no GID in EODatabaseContext _globalIDForObject:");
      //TODO exception ? ==> RollbackCh
    }



  return gid;
}

- (NSDictionary*)_primaryKeyForObject: (id)object
{
  //Ayers: Review
  return [self _primaryKeyForObject: object
               raiseException: YES];
}

- (NSDictionary*)_primaryKeyForObject: (id)object
                       raiseException: (BOOL)raiseException
{
  NSDictionary *pk = nil;
  EOEntity *entity = nil;
  NSArray *pkNames = nil;
  NSDictionary *pk2 = nil;
  
  NSAssert(!_isNilOrEONull(object), @"No object");
  
  entity = [_database entityForObject: object];
  
  EOGlobalID *gid = EODatabaseContext_globalIDForObjectWithImpPtr(self,NULL,object);
  
  pk = [entity primaryKeyForGlobalID: (EOKeyGlobalID*)gid]; //OK
  
  pkNames = [entity primaryKeyAttributeNames];
  
  pk2 = [self valuesForKeys: pkNames
                     object: object];
  
  if ([pk2 count] > 0) 
  {
    if (pk)
    {
      //merge pk2 into pk
      NSEnumerator *pk2Enum = [pk2 keyEnumerator];
      IMP pk2EnumNO=NULL; // nextObject
      NSMutableDictionary *realPK;
      
      realPK = [NSMutableDictionary dictionaryWithDictionary: pk];
      id key = nil;
      
      while ((key = GDL2_NextObjectWithImpPtr(pk2Enum,&pk2EnumNO)))
      {
        id value = [pk2 objectForKey: key];
        
        if (((value) && (value != GDL2_EONull)) &&
            (([value isKindOfClass:[NSNumber class]] == NO) || ([value intValue] != 0)))
        {
          [realPK setObject: value
                     forKey: key];
        }
      }
      
      pk = realPK;
    }
    else
      pk=pk2;
  }
  
  if (([entity isPrimaryKeyValidInObject: pk] == NO)) {
    pk = nil;
  }    
  
  // no PK? Ask the delegate to make one for us.
  if ((pk == nil))
  {      
    if (_delegateRespondsTo.newPrimaryKey == YES)
      pk = [_delegate databaseContext: self
               newPrimaryKeyForObject: object
                               entity: entity];
  }
  
  // still no PK?
  if ((pk == nil))
  {
    EOAdaptorChannel *channel = nil;
    EOStoredProcedure *nextPKProcedure = nil;
    
    nextPKProcedure = [entity storedProcedureForOperation:
                       EONextPrimaryKeyProcedureOperation];
    
    if (nextPKProcedure) 
    {      
      NS_DURING {
        
        channel = [[self _obtainOpenChannel] adaptorChannel];
        
        [channel executeStoredProcedure:nextPKProcedure
                             withValues:nil];
        
        pk = [channel returnValuesForLastStoredProcedureInvocation];
        
      } NS_HANDLER {
        // if the delegate took care about the exception
        // or we lost connection, try it again.
        if (([self _delegateHandledDatabaseException:localException]) ||
            ([[_database adaptor] isDroppedConnectionException:localException]))
        {
          channel = [[self _obtainOpenChannel] adaptorChannel];
          
          [channel executeStoredProcedure:nextPKProcedure
                               withValues:nil];
          
          pk = [channel returnValuesForLastStoredProcedureInvocation];
        } else {
          [localException raise];
        }
      }
    } NS_ENDHANDLER;
  }
  
  if (pk)
  {
    pk = [entity primaryKeyForRow:pk];
  }
  
  if (!pk) {
    EOAttribute * pkAttr = nil;
    NSArray     * pkAttributes = [entity primaryKeyAttributes];
    
    if ((pkAttributes) && ([pkAttributes count] == 1)) {
      pkAttr = [pkAttributes objectAtIndex: 0];
    }          
    if ((pkAttr) && (([pkAttr adaptorValueType] == EOAdaptorBytesType) && 
                     ([pkAttr width] == 24)))
    {
      unsigned char bytes[24];
      id            byteValue = nil;
      
      bzero(&bytes, sizeof(bytes));
      
      [EOTemporaryGlobalID assignGloballyUniqueBytes:&bytes[0]];
      
      byteValue = [pkAttr newValueForBytes: &bytes
                                    length:sizeof(bytes)];
      pk = [NSDictionary dictionaryWithObject:byteValue
                                       forKey:[pkAttr name]];
    }          
  }
  
  if (!pk) {
    EOAdaptorChannel *channel = nil;
    
    NS_DURING {
      channel = [[self _obtainOpenChannel] adaptorChannel];
      
      pk = [channel primaryKeyForNewRowWithEntity:entity];
      
    } NS_HANDLER {
      // if the delegate took care about the exception
      // or we lost connection, try it again.
      if (([self _delegateHandledDatabaseException:localException]) ||
          ([[_database adaptor] isDroppedConnectionException:localException]))
      {
        channel = [[self _obtainOpenChannel] adaptorChannel];
        
        pk = [channel primaryKeyForNewRowWithEntity:entity];
        
      } else {
        [localException raise];
      }
    } NS_ENDHANDLER;
  }
  // TODO: The reference does not raise here I suppose -- dw.
  //    if (!pk) {
  //      [NSException raise: NSInvalidArgumentException
  //                  format: @"%@ -- %@ 0x%x: cannot generate primary key for object '%@'",
  //       NSStringFromSelector(_cmd),
  //       NSStringFromClass([self class]),
  //       self, object];
  //    }
  
  
  return pk;
}

- (BOOL) _shouldGeneratePrimaryKeyForEntityName: (NSString*)entityName
{
  //OK
  BOOL shouldGeneratePK = YES;



  if (_nonPrimaryKeyGenerators)
    shouldGeneratePK = !NSHashGet(_nonPrimaryKeyGenerators, entityName);

  NSDebugMLLog(@"EODatabaseContext", @"shouldGeneratePK for %@: %s",
	       entityName,
	       (shouldGeneratePK ? "YES" : "NO"));
  NSAssert(![entityName isEqualToString: @"Country"]
	   || shouldGeneratePK, @"MGVALID: Failed");
  return shouldGeneratePK;
}

// private
- (EOEntity*) _entityForObject:(EOCustomObject*) eo
{
  EOEntity                 * entity = nil;
  EOObjectStoreCoordinator * coordinator = nil;
  NSArray                  * cooperatingObjectStores = nil;
  NSUInteger                 i = 0;
  NSUInteger                 count = 0;
  
  if (!eo)
  {
    [NSException raise: NSInvalidArgumentException
                format: @"%s -- Enterprise object cannot be nil", __PRETTY_FUNCTION__];    
  }
  
  entity = [_database entityForObject:eo];

  if (entity)
  {
    return entity;
  }
  
  coordinator = [self coordinator];
  if (!coordinator)
  {
    [NSException raise: NSInternalInconsistencyException
                format: @"%s -- Object store coordinator cannot be nil", __PRETTY_FUNCTION__];    
  }
  
  cooperatingObjectStores = [coordinator cooperatingObjectStores];

  count = [cooperatingObjectStores count];
  
  for (i = 0; i < count; i++)
  {
    id store = [cooperatingObjectStores objectAtIndex:i];
    if (!([store isKindOfClass:[EODatabaseContext class]]))
    {
      continue;
    }
    entity = [[(EODatabaseContext*)store database] entityForObject:eo];
    if (entity)
    {
      return entity;
    }
  }
  [NSException raise: NSInternalInconsistencyException
              format: @"%s -- Unable to find entity for object %@", __PRETTY_FUNCTION__, eo];
  // no warnings pls.
  return nil;
}

- (void)_buildPrimaryKeyGeneratorListForEditingContext: (EOEditingContext*)context
{
  NSArray *objects[3];
  NSHashTable *processedEntities = NULL;
  NSMutableArray *entityToProcess = nil;
  NSUInteger which;



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
      NSUInteger count = [objects[which] count];

      if (count>0)
        {
          IMP oaiIMP=[objects[which] methodForSelector: @selector(objectAtIndex:)];
          NSUInteger i = 0;
          
          for (i = 0; i < count; i++)
            {
              id object = GDL2_ObjectAtIndexWithImp(objects[which],oaiIMP,i);
              EOEntity *entity = [_database entityForObject: object];
              
              NSDebugMLLog(@"EODatabaseContext",
                           @"add entity to process: %@", [entity name]);
              
              if (entityToProcess)
                [entityToProcess addObject: entity];
              else
                entityToProcess = [NSMutableArray arrayWithObject: entity];
            }
        };
    }
  
  while ([entityToProcess count])
    {
      EOEntity *entity = [entityToProcess lastObject];



      [entityToProcess removeLastObject];

      if (!NSHashInsertIfAbsent(processedEntities, entity)) //Already processed ?
        {
          NSArray *relationships = [entity relationships];
          NSUInteger relationshipsCount = [relationships count];

          if (relationshipsCount>0)
            {
              IMP relObjectAtIndexIMP=[relationships methodForSelector: @selector(objectAtIndex:)];
              NSUInteger iRelationship = 0;
          
              for (iRelationship = 0;
                   iRelationship < relationshipsCount;
                   iRelationship++)
                {
                  EORelationship *relationship = GDL2_ObjectAtIndexWithImp(relationships,relObjectAtIndexIMP,iRelationship);
                  NSDebugMLLog(@"EODatabaseContext", 
                               @"test entity: %@ relationship=%@",
                               [entity name],
                               relationship);
                  
                  if ([relationship propagatesPrimaryKey])
                    {
                      EOEntity *destinationEntity = [relationship
                                                      destinationEntity];
                      NSDebugMLLog(@"EODatabaseContext", 
                                   @"test entity: %@ destinationEntity=%@",
                                   [entity name],
                                   [destinationEntity name]);
                      
                      if (destinationEntity)
                        {
                          NSArray *destAttrs;
                          NSArray *pkAttrs;
                          NSUInteger count;
                          BOOL destPK = NO;
                          
                          destAttrs = [relationship destinationAttributes];
                          pkAttrs = [destinationEntity primaryKeyAttributes];
                          count = [destAttrs count];

                          if (count>0)
                            {
                              IMP destAttrsObjectAtIndexIMP=[relationships methodForSelector: @selector(objectAtIndex:)];
                              NSUInteger i=0;
                              for (i = 0; i < count; i++)
                                {
                                  if ([pkAttrs containsObject:
                                                 GDL2_ObjectAtIndexWithImp(destAttrs,destAttrsObjectAtIndexIMP,i)])
                                    destPK = YES;
                                }
                            };
                          if (destPK)
                            {
                              NSDebugMLLog(@"EODatabaseContext",
                                           @"destination entity: %@ "
                                           @"No PK generation [Rel = %@]",
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
    }

  NSDebugMLLog(@"EODatabaseContext",
	       @"_nonPrimaryKeyGenerators=%@",
	       NSStringFromHashTable(_nonPrimaryKeyGenerators));
  


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



  gid = EOEditingContext_globalIDForObjectWithImpPtr(_editingContext,NULL,object);
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

  return snapshot;
}

- (void) _assertValidStateWithSelector: (SEL)sel
{
  if ((!_flags.preparingForSave) && (!_flags.willPrepareForSave))
  {
    [NSException raise: NSInternalInconsistencyException
                format: @"_assertValidStateWithSelector:%s %s is in invalid state, "
                         "call prepareForSaveWithCoordinator: before calling this method.",
     sel_getName(sel),
     object_getClassName(self)];
    
  }
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
