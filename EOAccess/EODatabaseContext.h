/* -*-objc-*-
   EODatabaseContext.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: July 2000

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

#ifndef __EODatabaseContext_h__
#define __EODatabaseContext_h__


#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSHashTable.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSDate.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EOObjectStoreCoordinator.h>

#include <EOAccess/EODefines.h>


@class NSMutableSet;

@class EOAdaptorContext;
@class EOAdaptorChannel;
@class EOAdaptorOperation;
@class EOEntity;
@class EOModel;
@class EORelationship;
@class EOAttribute;
@class EODatabase;
@class EODatabaseChannel;
@class EODatabaseOperation;

typedef enum {
  EOUpdateWithOptimisticLocking,
  EOUpdateWithPessimisticLocking,
  EOUpdateWithNoLocking
} EOUpdateStrategy;

struct _EOTransactionScope;

@interface EODatabaseContext : EOCooperatingObjectStore
{
  EODatabase *_database;
  EOAdaptorContext *_adaptorContext;
  EOUpdateStrategy _updateStrategy;
/*TOADD
    NSMutableArray *_uniqueStack;
    NSMutableArray *_deleteStack;
    NSMutableArray *_modifiedObjects;
*/
  NSMutableArray *_registeredChannels;
  NSMapTable *_dbOperationsByGlobalID;
  EOObjectStoreCoordinator *_coordinator;	/* unretained */
  EOEditingContext *_editingContext;		/* unretained */
  id *_lockedObjects;//void*
/*TO ADD    unsigned int _currentGeneration;
    unsigned int _concurentFetches;
*/

  unsigned int _numLocked;//TO REMOVE
  NSMutableDictionary *_batchFaultBuffer;
  NSMutableDictionary *_batchToManyFaultBuffer;

//  NSMutableDictionary *_snapshots;
//  NSMutableDictionary *_toManySnapshots;

  EOEntity* _lastEntity;
/*TOADD  
    EOGlobalID *_currentGlobalID;
    NSDictionary *_currentSnapshot;
    objc_object *_currentBatch;
*/
  NSMutableArray *_uniqueStack;// snaps
  NSMutableArray *_uniqueArrayStack;//to many snaps
  NSMutableArray *_deleteStack;

  NSHashTable *_nonPrimaryKeyGenerators;

  struct {
    unsigned int preparingForSave:1;
    unsigned int beganTransaction:1;
    unsigned int ignoreEntityCaching:1;
    unsigned int _reserved:29;
  } _flags;
  id _delegate; /* unretained */
  struct {
    unsigned int willRunLoginPanelToOpenDatabaseChannel:1;
    unsigned int newPrimaryKey:1;
    unsigned int willPerformAdaptorOperations:1;
    unsigned int shouldInvalidateObject:1;
    unsigned int willOrderAdaptorOperations:1;
    unsigned int shouldLockObject:1;
    unsigned int shouldRaiseForLockFailure:1;
    unsigned int shouldFetchObjects:1;
    unsigned int didFetchObjects:1;
    unsigned int shouldFetchObjectFault:1;
    unsigned int shouldFetchArrayFault:1;
    unsigned int _reserved:21;
  } _delegateRespondsTo;

  NSRecursiveLock *_lock; //TODO: not lock object !
}

+ (EODatabaseContext *)databaseContextWithDatabase: (EODatabase *)database;

- (id)initWithDatabase: (EODatabase *)database;

+ (EODatabaseContext *)registeredDatabaseContextForModel: (EOModel *)model
                                          editingContext: (EOEditingContext *)editingContext;

+ (Class)contextClassToRegister;
+ (void)setContextClassToRegister: (Class)contextClass;

- (BOOL)hasBusyChannels;

- (NSArray *)registeredChannels;

- (void)registerChannel: (EODatabaseChannel *)channel;
- (void)unregisterChannel: (EODatabaseChannel *)channel;

- (EODatabaseChannel *)_availableChannelFromRegisteredChannels;
- (EODatabaseChannel *)availableChannel;

- (EODatabase *)database;

- (EOObjectStoreCoordinator *)coordinator;

- (EOAdaptorContext *)adaptorContext;

- (void)setUpdateStrategy: (EOUpdateStrategy)strategy;
- (EOUpdateStrategy)updateStrategy;

- (id)delegate;
- (void)setDelegate: (id)delegate;
- (void)handleDroppedConnection;
@end /* EODatabaseContext */


@interface EODatabaseContext (EOObjectStoreSupport)

- (id)faultForRawRow: (NSDictionary *)row
         entityNamed: (NSString *)entityName
      editingContext: (EOEditingContext *)editingContext;

- (id)entityForGlobalID: (EOGlobalID *)globalID;

- (id)faultForGlobalID: (EOGlobalID *)globalID
        editingContext: (EOEditingContext *)context;

- (NSArray *)arrayFaultWithSourceGlobalID: (EOGlobalID *)globalID
                         relationshipName: (NSString *)name
                           editingContext: (EOEditingContext *)context;

- (void)initializeObject: (id)object
            withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context;

- (NSArray *)objectsForSourceGlobalID: (EOGlobalID *)globalID
                     relationshipName: (NSString *)name
                       editingContext: (EOEditingContext *)context;
- (void)_registerSnapshot: (NSArray *)snapshot
        forSourceGlobalID: (EOGlobalID *)globalID
         relationshipName: (NSString *)name
           editingContext: (EOEditingContext *)context;

- (void)refaultObject: (id)object
         withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context;

- (void)saveChangesInEditingContext: (EOEditingContext *)context;

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
                            editingContext: (EOEditingContext *)context;

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)gid
                    editingContext: (EOEditingContext *)context;

- (void)lockObjectWithGlobalID: (EOGlobalID *)gid
                editingContext: (EOEditingContext *)context;

- (void)invalidateAllObjects;
- (void)invalidateObjectsWithGlobalIDs: (NSArray *)globalIDs;

@end


@interface EODatabaseContext (EOCooperatingObjectStoreSupport)

- (BOOL)ownsGlobalID: (EOGlobalID *)globalID;

- (BOOL)ownsObject: (id)object;

- (BOOL)ownsEntityNamed: (NSString *)entityName;

- (BOOL)handlesFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (void)prepareForSaveWithCoordinator: (EOObjectStoreCoordinator *)coordinator
                       editingContext: (EOEditingContext *)context;

/** The method overrides the inherited implementation to create a list of EODatabaseOperations for EOEditingContext objects changes (only objects owned by the receiver). 
It forwards any relationship changes found which are not owned by the receiver to the EOObjectStoreCoordinator. 
It's invoked during  EOObjectStoreCoordinator saving changes (saveChangesInEditingContext:) method. 
It's invoked after prepareForSaveWithCoordinator:editingContext: and before ownsGlobalID:. 
**/
- (void)recordChangesInEditingContext;

- (void)recordUpdateForObject: (id)object
                      changes: (NSDictionary *)changes;

- (void)performChanges;

- (void)commitChanges;

- (void)rollbackChanges;

- (NSDictionary *)valuesForKeys: (NSArray *)keys object: (id)object;

-(void)relayPrimaryKey: (NSDictionary *)pk
                object: (id)object
                entity: (EOEntity *)entity;

-(void)nullifyAttributesInRelationship: (EORelationship *)relationship
                          sourceObject: (id)sourceObject
                    destinationObjects: (NSArray *)destinationObjects;
-(void)nullifyAttributesInRelationship: (EORelationship *)relationship
                          sourceObject: (id)sourceObject
                     destinationObject: (id)destinationObject;
-(void)relayAttributesInRelationship: (EORelationship *)relationship
                        sourceObject: (id)sourceObject
                  destinationObjects: (NSArray *)destinationObjects;
-(NSDictionary *)relayAttributesInRelationship: (EORelationship *)relationship
				  sourceObject: (id)sourceObject
			     destinationObject: (id)destinationObject;

- (id)databaseOperationForObject: (id)param0;
- (id)databaseOperationForGlobalID: (id)param0;
- (void)recordDatabaseOperation: (id)param0;
- (void)recordDeleteForObject: (id)param0;
- (void)recordInsertForObject: (id)param0;

- (void)createAdaptorOperationsForDatabaseOperation: (EODatabaseOperation *)dbOpe
					 attributes: (NSArray *)attributes;
- (void)createAdaptorOperationsForDatabaseOperation: (EODatabaseOperation *)dbOpe;
- (NSArray *)orderAdaptorOperations;

- (NSArray *)entitiesOnWhichThisEntityDepends: (EOEntity *)entity;
- (NSArray *)entityNameOrderingArrayForEntities: (NSArray *)entities;

- (BOOL)isValidQualifierTypeForAttribute: (EOAttribute *)attribute;
- (id)lockingNonQualifiableAttributes: (NSArray *)attributes;
- (NSArray *)lockingAttributesForAttributes: (NSArray *)attributes
                                     entity: (EOEntity *)enity;
- (NSArray *)primaryKeyAttributesForAttributes: (NSArray *)attributes
                                        entity: (EOEntity *)entity;
- (EOQualifier *)qualifierForLockingAttributes: (NSArray *)attributes
			  primaryKeyAttributes: (NSArray *)primaryKeyAttributes
					entity: (EOEntity *)entity
				      snapshot: (NSDictionary *)snapshot;
- (void)insertEntity: (EOEntity *)entity
   intoOrderingArray: (NSMutableArray *)orderingArray
    withDependencies: (NSDictionary *)dependencies
       processingSet: (NSMutableSet *)processingSet;
- (void)processSnapshotForDatabaseOperation: (EODatabaseOperation *)dbOpe;

- (NSDictionary *)valuesToWriteForAttributes: (NSArray *)attributes
				      entity: (EOEntity *)entity
			       changedValues: (NSDictionary *)changedValues;

@end


@interface EODatabaseContext(EOBatchFaulting)

- (void)batchFetchRelationship: (EORelationship *)relationship
              forSourceObjects: (NSArray *)objects
                editingContext: (EOEditingContext *)editingContext;

@end


@interface EODatabaseContext (EODatabaseSnapshotting)

- (void)recordSnapshot: (NSDictionary *)snapshot
           forGlobalID: (EOGlobalID *)gid;


/** Returns snapshot for globalID.  (nil if there's no snapshot for the globalID or if the corresponding 
tsimestamp is less than ti). 
Searches first locally (in the transaction scope) and after in the EODatabase. **/

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
                                after: (NSTimeInterval)ti;

/** Returns snapshot for globalID by calling snapshotForGlobalID:after: with EODistantPastTimeInterval 
as time interval.
Searches first locally (in the transaction scope) and after in the EODatabase. **/
- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid;

- (void)recordSnapshot: (NSArray *)gids
     forSourceGlobalID: (EOGlobalID *)gid
      relationshipName: (NSString *)name;

- (NSArray *)snapshotForSourceGlobalID: (EOGlobalID *)gid
                      relationshipName: (NSString *)name;

/** Returns the snapshot for the globalID (nil if there's none). 
Only searches locally (in the transaction scope), not in the EODatabase. **/

- (NSDictionary *)localSnapshotForGlobalID: (EOGlobalID *)gid;

- (NSArray *)localSnapshotForSourceGlobalID: (EOGlobalID *)gid
                           relationshipName: (NSString *)name;

- (void)forgetSnapshotForGlobalID: (EOGlobalID *)gid;
- (void)forgetSnapshotsForGlobalIDs: (NSArray *)gids;

- (void)recordSnapshots: (NSDictionary *)snapshots;

- (void)recordToManySnapshots: (NSDictionary *)snapshots;

- (void)registerLockedObjectWithGlobalID: (EOGlobalID *)globalID;
- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)globalID;
- (void)forgetAllLocks;
- (void)forgetLocksForObjectsWithGlobalIDs: (NSArray *)gids;
- (void)_rollbackTransaction;
- (void)_commitTransaction;
- (void)_beginTransaction;
- (EODatabaseChannel *)_obtainOpenChannel;
- (BOOL)_openChannelWithLoginPanel: (id)param0;
- (void)_forceDisconnect;
- (void)initializeObject: (id)object
                     row: (NSDictionary *)row
                  entity: (EOEntity *)entity
          editingContext: (EOEditingContext *)context;

@end

@interface EODatabaseContext(EOMultiThreaded) <NSLocking>

- (void)lock;
- (void)unlock;

@end

GDL2ACCESS_EXPORT NSString *EODatabaseChannelNeededNotification;


@interface NSObject (EODatabaseContextDelegation)

- (BOOL)databaseContext: (EODatabaseContext *)context
willRunLoginPanelToOpenDatabaseChannel: (EODatabaseChannel *)channel;

- (NSDictionary *)databaseContext: (EODatabaseContext *)context
           newPrimaryKeyForObject: (id)object
                           entity: (EOEntity *)entity;

- (BOOL)databaseContext: (EODatabaseContext *)context
    failedToFetchObject: (id)object
               globalID: (EOGlobalID *)gid;

- (NSArray *)databaseContext: (EODatabaseContext *)context
willOrderAdaptorOperationsFromDatabaseOperations: (NSArray *)databaseOps;

- (NSArray *)databaseContext: (EODatabaseContext *)context
willPerformAdaptorOperations: (NSArray *)adaptorOps
              adaptorChannel: (EOAdaptorChannel *)adaptorChannel;

- (BOOL)databaseContext: (EODatabaseContext *)context
shouldInvalidateObjectWithGlobalID: (EOGlobalID *)globalId
               snapshot: (NSDictionary *)snapshot;

- (NSArray *)databaseContext: (EODatabaseContext *)context
shouldFetchObjectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
              editingContext: (EOEditingContext *)editingContext;

- (void)databaseContext: (EODatabaseContext *)context
        didFetchObjects: (NSArray *)objects
     fetchSpecification: (EOFetchSpecification *)fetchSpecification
         editingContext: (EOEditingContext *)editingContext;

- (BOOL)databaseContext: (EODatabaseContext *)context
shouldSelectObjectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
        databaseChannel: (EODatabaseChannel *)channel;

- (BOOL)databaseContext: (EODatabaseContext *)context
shouldUsePessimisticLockWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
        databaseChannel: (EODatabaseChannel *)channel;

- (void)databaseContext: (EODatabaseContext *)context
didSelectObjectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
        databaseChannel: (EODatabaseChannel *)channel;

- (NSDictionary *)databaseContext: (EODatabaseContext *)context
      shouldUpdateCurrentSnapshot: (NSDictionary *)currentSnapshot
		      newSnapshot: (NSDictionary *)newSnapshot
			 globalID: (EOGlobalID *)globalID
		  databaseChannel: (EODatabaseChannel *)channel;

- (BOOL)databaseContext: (EODatabaseContext *)databaseContext
shouldLockObjectWithGlobalID: (EOGlobalID *)globalID
               snapshot: (NSDictionary *)snapshot;

- (BOOL)databaseContext: (EODatabaseContext *)databaseContext
shouldRaiseExceptionForLockFailure: (NSException *)exception;

- (BOOL)databaseContext: (EODatabaseContext *)databaseContext
 shouldFetchObjectFault: (id)fault;

- (BOOL)databaseContext: (EODatabaseContext *)databaseContext
  shouldFetchArrayFault: (id)fault;

@end

GDL2ACCESS_EXPORT NSString *EOCustomQueryExpressionHintKey;
GDL2ACCESS_EXPORT NSString *EOStoredProcedureNameHintKey;

GDL2ACCESS_EXPORT NSString *EODatabaseContextKey;
GDL2ACCESS_EXPORT NSString *EODatabaseOperationsKey;
GDL2ACCESS_EXPORT NSString *EOFailedDatabaseOperationKey;

#endif /* __EODatabaseContext_h__ */
