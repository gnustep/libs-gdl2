/* 
   EOEditingContext.h

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

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

#ifndef	__EOEditingContext_h__
#define	__EOEditingContext_h__

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSHashTable.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSLock.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EOObjectStore.h>
#include <EOControl/EOObserver.h>


@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSAutoreleasePool;
@class NSUndoManager;


@interface EOEditingContext : EOObjectStore <EOObserving>
{
  EOObjectStore *_objectStore;
  NSUndoManager *_undoManager;
  NSHashTable *_unprocessedChanges;
  NSHashTable *_unprocessedDeletes;
  NSHashTable *_unprocessedInserts;
  NSHashTable *_insertedObjects; 
  NSHashTable *_deletedObjects;
  NSHashTable *_changedObjects;

  NSMapTable *_objectsById;
  NSMapTable *_objectsByGID;
  NSMutableDictionary *_snapshotsByGID;
  NSMutableDictionary *_eventSnapshotsByGID;

  id _delegate;
  NSMutableArray *_editors;
  id _messageHandler;
  unsigned short _undoTransactionID;
  struct {
    unsigned registeredForCallback:1;
    unsigned propagatesDeletesAtEndOfEvent:1;
    unsigned ignoreChangeNotification:1;
    unsigned exhaustiveValidation:1;//    unsigned stopsValidation:1;
    unsigned autoLocking:1;
    unsigned processingChanges:1;//    unsigned savingChanges:1;
    unsigned skipInvalidateOnDealloc:1;
    unsigned useCommittedSnapshot:1;
    unsigned registeredUndoTransactionID:1;
    unsigned retainsAllRegisteredObjects:1;
    unsigned lockUsingParent:1;
    unsigned unused:5;
  } _flags;
  struct {
    unsigned willRunLoginPanel:1;
    unsigned shouldFetchObjects:1;
    unsigned shouldInvalidateObject:1;
    unsigned shouldMergeChanges:1;
    unsigned shouldPresentException:1;
    unsigned shouldUndoUserActions:1;
    unsigned shouldValidateChanges:1;
    unsigned willSaveChanges:1;
  } _delegateRespondsTo;
  
  NSRecursiveLock*_lock;
  int _lockCount;
  id _notificationQueue;
  NSAutoreleasePool * _lockPool;
}

+ (void)setInstancesRetainRegisteredObjects: (BOOL)flag;
+ (BOOL)instancesRetainRegisteredObjects;

- initWithParentObjectStore:(EOObjectStore *)parentObjectStore;

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (void)insertObject: (id)object;
- (void)insertObject: object
        withGlobalID: (EOGlobalID *)gid;
- (void)_insertObject: (id)object
         withGlobalID: (EOGlobalID *)gid;

-(void)setLevelsOfUndo:(int)levels;

- (void)deleteObject: (id)object;

- (void)lockObject: (id)object;

- (BOOL)hasChanges;

- (void)saveChanges;

- (void)revert;

- (id)objectForGlobalID: (EOGlobalID *)globalID;
- (EOGlobalID *)globalIDForObject: object;

- (void)setDelegate: (id)delegate;
- (id)delegate;

- (EOObjectStore *)parentObjectStore;

- (EOObjectStore *)rootObjectStore;


- (void)setUndoManager: (NSUndoManager *)undoManager;
- (NSUndoManager *)undoManager;

- (void) _observeUndoManagerNotifications;

- (void)objectWillChange: (id)object;

- (void)recordObject: (id)object
            globalID: (EOGlobalID *)globalID;

- (void)forgetObject: (id)object;

- (void) registerUndoForModifiedObject: (id)object;

- (NSArray *)registeredObjects;

- (NSArray *)updatedObjects;
- (NSArray *)insertedObjects;
- (NSArray *)deletedObjects;

- (void) _processDeletedObjects;
- (void) _processOwnedObjectsUsingChangeTable: (NSHashTable*)changeTable
                                  deleteTable: (NSHashTable*)deleteTable;
- (void) propagatesDeletesUsingTable: (NSHashTable*)deleteTable;
- (void) validateDeletesUsingTable: (NSHashTable*)deleteTable;
- (BOOL) validateTable: (NSHashTable*)table
          withSelector: (SEL)sel
        exceptionArray: (NSMutableArray**)exceptionArray
  continueAfterFailure: (BOOL)continueAfterFailure;


- (void)processRecentChanges;
- (void) _registerClearStateWithUndoManager;

- (BOOL)propagatesDeletesAtEndOfEvent;
- (void)setPropagatesDeletesAtEndOfEvent: (BOOL)propagatesDeletesAtEndOfEvent;

- (BOOL)stopsValidationAfterFirstError;
- (void)setStopsValidationAfterFirstError: (BOOL)yn;

- (BOOL)locksObjectsBeforeFirstModification;
- (void)setLocksObjectsBeforeFirstModification: (BOOL)yn;

/** Returns a dictionary containing a snapshot of object 
that reflects its committed values (last values putted in 
the database; i.e. values before changes were made on the 
object).
It is updated after commiting new values.
**/
- (NSDictionary *)committedSnapshotForObject: (id)object;

/** Returns a dictionary containing a snapshot of object 
with its state as it was at the beginning of the current 
event loop. 
After the end of the current event, upon invocation of 
processRecentChanges, the snapshot is updated to hold the 
modified state of the object.**/
- (NSDictionary *)currentEventSnapshotForObject: (id)object;

- (NSDictionary *)uncommittedChangesForObject: (id)object;

- (void)refaultObjects;

- (void)setInvalidatesObjectsWhenFreed: (BOOL)yn;
- (BOOL)invalidatesObjectsWhenFreed;
    
- (void)addEditor: (id)editor;
- (void)removeEditor: (id)editor;
- (NSArray *)editors;

- (void)setMessageHandler: (id)handler;
- (id)messageHandler;


- (id)faultForGlobalID: (EOGlobalID *)globalID
        editingContext: (EOEditingContext *)context;

- (id)faultForRawRow: (NSDictionary *)row
         entityNamed: (NSString *)entityName
      editingContext: (EOEditingContext *)context;

- (id)faultForRawRow: (NSDictionary *)row
         entityNamed: (NSString *)entityName;

- (NSArray *)arrayFaultWithSourceGlobalID: (EOGlobalID *)globalID
                         relationshipName: (NSString *)name
                           editingContext: (EOEditingContext *)context;

- (void)initializeObject: (id)object
	    withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context;

- (NSArray *)objectsForSourceGlobalID: (EOGlobalID *)globalID
                     relationshipName: (NSString *)name
                       editingContext: (EOEditingContext *)context;

- (void)refaultObject: object
	 withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context;

- (void)saveChangesInEditingContext: (EOEditingContext *)context;

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
                            editingContext: (EOEditingContext *)context;

- (void)lockObjectWithGlobalID: (EOGlobalID *)gid
                editingContext: (EOEditingContext *)context;

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)gid
                    editingContext: (EOEditingContext *)context;

- (void) clearOriginalSnapshotForObject: (id)object;

@end

// used with NSRunLoop's performSelector:target:argument:order:modes:
enum {
    EOEditingContextFlushChangesRunLoopOrdering	= 300000
};

extern NSString *EOObjectsChangedInEditingContextNotification;

extern NSString *EOEditingContextDidSaveChangesNotification;


@interface NSObject (EOEditingContext)

- (EOEditingContext *)editingContext;

@end

//
// Delegation methods
//
@interface NSObject (EOEditingContextDelegation)

- (BOOL)editingContext: (EOEditingContext *)editingContext
shouldPresentException: (NSException *)exception;

- (BOOL)editingContextShouldValidateChanges: (EOEditingContext *)editingContext;

- (void)editingContextWillSaveChanges: (EOEditingContext *)editingContext;

- (BOOL)editingContext: (EOEditingContext *)editingContext
shouldInvalidateObject: (id)object
	      globalID: (EOGlobalID *)gid;

- (BOOL)editingContextShouldUndoUserActionsAfterFailure: (EOEditingContext *)context;

- (NSArray *)editingContext: (EOEditingContext *)editingContext
shouldFetchObjectsDescribedByFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (BOOL) editingContext: (EOEditingContext *)editingContext
shouldMergeChangedObject: (id)object;

- (void)didMergeChangedObjectsInEditingContext: (EOEditingContext *)editingContext;

@end

//
// EOEditors informal protocol
//
@interface NSObject (EOEditors)

- (BOOL)editorHasChangesForEditingContext: (EOEditingContext *)editingContext;

- (void)editingContextWillSaveChanges: (EOEditingContext *)editingContext;

@end

//
// EOMessageHandler informal protocol
//
@interface NSObject (EOMessageHandlers)

- (void)editingContext: (EOEditingContext *)editingContext
   presentErrorMessage: (NSString *)message;

- (BOOL)editingContext: (EOEditingContext *)editingContext
shouldContinueFetchingWithCurrentObjectCount: (unsigned)count
         originalLimit: (unsigned)limit
           objectStore: (EOObjectStore *)objectStore;

@end


@interface EOEditingContext (EORendezvous)

+ (void)setSubstitutionEditingContext: (EOEditingContext *)ec;
+ (EOEditingContext *)substitutionEditingContext;

+ (void)setDefaultParentObjectStore: (EOObjectStore *)store;
+ (EOObjectStore *)defaultParentObjectStore;

@end

@interface EOEditingContext (EOStateArchiving)

+ (void)setUsesContextRelativeEncoding: (BOOL)yn;
+ (BOOL)usesContextRelativeEncoding;
+ (void)encodeObject: (id)object withCoder: (NSCoder *)coder;
+ (id)initObject: (id)object withCoder: (NSCoder *)coder;


@end

@interface EOEditingContext (EOTargetAction)

- (void)saveChanges: (id)sender;
- (void)refault: (id)sender;
- (void)revert: (id)sender;
- (void)refetch: (id)sender;

- (void)undo: (id)sender;
- (void)redo: (id)sender;

//Private
-(NSString*)objectsDescription;
-(NSString*)unprocessedDescription;

@end

@interface EOEditingContext(EOMultiThreaded) <NSLocking>

+ (void)setEOFMultiThreadedEnabled: (BOOL)flag;
- (void)lock;
- (void)unlock;
- (BOOL) tryLock;

@end

// Informations
@interface EOEditingContext(EOEditingContextInfo)

- (NSDictionary*)unprocessedInfo;
- (NSDictionary*)pendingInfo;

@end

#endif
