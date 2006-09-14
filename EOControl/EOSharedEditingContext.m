/* -*-objc-*-
   EOSharedEditingContext.m

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>
   Date: November 2005

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"

RCS_ID("$Id$")

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>
#endif

#include <GNUstepBase/GSLock.h>

#include "EOSharedEditingContext.h"
#include "EOFault.h"
#include "EOFetchSpecification.h"
#include "EOGlobalID.h"
#include "EOObjectStoreCoordinator.h"
#include "EOUndoManager.h"


NSString *EODefaultSharedEditingContextWasInitializedNotification
      = @"EODefaultSharedEditingContextWasInitializedNotification";

NSString *EOSharedEditingContextInitializedObjectsNotification
      = @"EOSharedEditingContextInitializedObjectsNotification";

@interface EOEditingContext (Private)
- (BOOL)_processRecentChanges;
@end

/**
 * <p>Immutable Enterprise Objects can be shared among EOEditingContexts
 * via EOSharedEditingContext.  Normally EOs belong to a specific
 * EOEditingContext and this editing context tracks the changes of this
 * object.  Yet sometimes immutable objects are often referenced by many
 * objects and they would have to fetched and tracked within many
 * EOEditingContexts.  EOSharedEditingContext is intended to address this
 * by supplying an shared context for immutable objects which can be shared
 * among instances of EOEditingContext.  An EO that is registered with an
 * EOSharedEditingContext may not be contained in an other EOEditingContext
 * which uses the EOSharedEditingContext.</p>
 * <p>The only valid way to modify an
 * object that is contained in a shared context is by changing it in an
 * unreladed EOEditingContext (i.e. one which does not use the 
 * EOSharedEditingContext), commit those changes to the object store which
 * would post a EOObjectsChangedInStoreNotification which in turn will
 * cause the EOSharedEditingContext to invalidate an subsequently refetch
 * the values of the EO from its object store.</p>
 * <p>Objects are fetched with [-objectsWithFetchSpecification:] or
 * [-bindObjectsWithFetchSpecification:toName:] into an EOSharedEditingContext.
 * If the later method is used, the objects can be later retrieved via
 * [-objectsByEntityNameAndFetchSpecificationName].</p>
 */
@implementation EOSharedEditingContext
static NSArray *emptyArray = nil;
static Class EOFaultClass = NULL;
static NSRecursiveLock *llock = nil;
+ (void)initialize
{
  if (emptyArray==nil)
    {
      emptyArray = [NSArray new];
      EOFaultClass = [EOFault class];
      llock = [GSLazyRecursiveLock new];
    }
}

static EOSharedEditingContext *dfltSharedEditingContext = nil;

/**
 * Returns the current default shared editing context.
 * This method will create one if none currently exists.
 * The first time this method implicitly creates a shared
 * editing context it will post a
 * <code>EODefaultSharedEditingContextWasInitializedNotification</code>.
 */
+ (EOSharedEditingContext *)defaultSharedEditingContext
{
  [llock lock];

  /* The reference implementatin seems to have a private 
     dfltSharedEditingContext method which would be called here.
     Yet if the this method is not public for custom subclasses
     it doesn't seem to make sense to avoid the static variable directly.  */
  if (!dfltSharedEditingContext)
    {
      static BOOL posted = NO;
      dfltSharedEditingContext = [[[self class] alloc] init];

      if (!posted)
	{
	  [[NSNotificationCenter defaultCenter] postNotificationName:
			EODefaultSharedEditingContextWasInitializedNotification
						object: nil];
	  posted = YES;
	}
    }

  [llock unlock];
  return dfltSharedEditingContext;
}

/*
 * This privat method is intended for EOEditingContext to
 * retrieve the default shared editing context without
 * creating one implicitly.
 * This seems to be broken by design as it breaks subclassing
 * of both EOEditingContext and EOSharedEditingContext.
 */
+ (EOSharedEditingContext *)_defaultSharedEditingContext
{
  return dfltSharedEditingContext;
}


/**
 * Explicity sets the default shared editing context.
 * If CONTEXT is not an EOSharedEditingContext this method raises an
 * NSInternalInconsistency exception.
 */
+ (void)setDefaultSharedEditingContext: (EOSharedEditingContext *)context
{
  if (![context isKindOfClass: [EOEditingContext class]])
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"+[EOSharedEditingContext setDefaultSharedEditingContext:] attempted to set non-shared editing context as default shared editing context:%@",context];

    }
  [llock lock];
  ASSIGN(dfltSharedEditingContext,context);
  [llock unlock];
}

- (id)initWithParentObjectStore: (EOObjectStore *)parentObjectStore
{
  if (![parentObjectStore isKindOfClass: [EOObjectStoreCoordinator class]])
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"EOSharedEditingContext must be initialized with an EOObjectStoreCoordinator"];
    }
  if ((self = [super initWithParentObjectStore: parentObjectStore]))
    {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      _sharedLock = [GSLazyRecursiveLock new];
      _initializedGlobalIDs = [NSMutableArray new];
      _objsByEntity = [NSMutableDictionary new];
      _objsByEntityFetchSpec = [NSMutableDictionary new];

      /* Now adjust EOEditingContext initializations.  */
      _flags.retainsAllRegisteredObjects = YES;
      [super setSharedEditingContext: nil];
      [nc removeObserver: self
	  name: NSUndoManagerCheckpointNotification
	  object: nil];
      [nc removeObserver: self
	  name: EOSharedEditingContextInitializedObjectsNotification
	  object: nil];
      [nc removeObserver: self
	  name: EOGlobalIDChangedNotification
	  object: nil];

      DESTROY(_undoManager);
      DESTROY(_lock);
    }
  return self;
}

- (void)dealloc
{
  /* TODO Maybe we should add some sanity checks.  */
  DESTROY(_sharedLock);
  DESTROY(_initializedGlobalIDs);
  DESTROY(_objsByEntity);
  DESTROY(_objsByEntityFetchSpec);
  [super dealloc];
}

/**
 * Returns all object currently maintained the the EOSharedEditingContext
 * in an NSDictionary associated with the corresponding entity name.
 */
- (NSDictionary *)objectsByEntityName
{
  NSDictionary *oben;
  [self lockForReading];
  NS_DURING
    {
      oben = AUTORELEASE([_objsByEntity copy]);
    }
  NS_HANDLER
    {
      [self unlockForReading];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlockForReading];
  return oben;
}

/**
 * Returns all object currently maintained the the EOSharedEditingContext
 * in an NSDictionary associated with the corresponding name supplied by
 * previous [-bindObjectsWithFetchSpecification:toName:] each containing
 * a dictionary in which the objects are assicated with the entity name. 
 */
- (NSDictionary *)objectsByEntityNameAndFetchSpecificationName
{
  NSDictionary *oben;
  [self lockForReading];
  NS_DURING
    {
      oben = AUTORELEASE([_objsByEntityFetchSpec copy]);
    }
  NS_HANDLER
    {
      [self unlockForReading];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlockForReading];
  return oben;
}

/**
 * Invokes [-objectsWithFetchSpecification:] and registers the objects
 * to be retrieved with [-objectsByEntityName] and 
 * [-objectsByEntityNameAndFetchSpecificationName];
 */
- (void)bindObjectsWithFetchSpecification: (EOFetchSpecification *)fetchSpec
				   toName: (NSString *)name
{
  NSArray *objects;
  NSString *entityName;
  NSMutableDictionary *obefsn;

  if (!name)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"called bindObjectsWithFetchSpecification:toName: without name"];
    }
  entityName = [fetchSpec entityName];

  [self lock];
  NS_DURING
    {
      objects = [self objectsWithFetchSpecification: fetchSpec
		  editingContext: self];
      obefsn = [_objsByEntityFetchSpec objectForKey: name];
      if (obefsn == nil)
	{
	  obefsn = [NSMutableDictionary dictionaryWithObject: objects 
					forKey: entityName];
	  [_objsByEntityFetchSpec setObject: obefsn forKey: name];
	}
      else
	{
	  /* TODO: Verify preliminary tests inidcate that previous 
	     fetch results get replaced, not merged.  */
	  [obefsn setObject: objects forKey: entityName];
	}
    }
  NS_HANDLER
    {
      [self unlock];
      [localException raise];
    }
  NS_ENDHANDLER;

  [self unlock];
}

/**
 * Increases the recievers lock count for reading.
 */
- (void)lockForReading
{
  /* FIXME: actually this blocks if another thread is reading.
     This should be fixed once we have EOMultiReaderLock.  */
  [_sharedLock lock];
  _readerLockCount++;
  [_sharedLock unlock];
}

/**
 * Decreases the recievers lock count for reading.
 */
- (void)unlockForReading
{
  /* FIXME: actually this blocks if another thread is reading.
     This should be fixed once we have EOMultiReaderLock.  */
  [_sharedLock lock];
  _readerLockCount--;
  [_sharedLock unlock];
}

/**
 * Attempts to increases the recievers lock count for reading.
 * Returns NO if the lock cannot be retrieved.
 */
- (BOOL)tryLockForReading
{
  BOOL flag;
  /* FIXME: actually this blocks if another thread is reading.
     This should be fixed once we have EOMultiReaderLock.  */
  flag = [_sharedLock tryLock];
  if (flag)
    {
      _readerLockCount++;
      [_sharedLock unlock];
    }
  return flag;
}

/**
 * Suspends the reader lock count until retrieveReaderLocks is called.
 */
- (void)suspendReaderLocks
{
  [_sharedLock lock];
  _readerLockCountSuspended = _readerLockCount;
  _readerLockCount = 0;
  [_sharedLock unlock];
}

/**
 * Retrieve suspended reader lock count.
 */
- (void)retrieveReaderLocks
{
  [_sharedLock lock];
  _readerLockCount = _readerLockCountSuspended;
  _readerLockCountSuspended = 0;
  [_sharedLock unlock];
}

/**
 * Fetches the objects with the FETCHSPEC and registers them
 * for retrieval with [-objectsByEntityName].
 */
- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpec
			    editingContext: (EOEditingContext *)context
{
  NSArray *objs = [super objectsWithFetchSpecification: fetchSpec
			 editingContext: context];
  NSString *entityName = [fetchSpec entityName];
  NSArray *obe = [_objsByEntity objectForKey: entityName];

  if (obe == nil)
    {
      obe = AUTORELEASE([objs mutableCopy]);
    }
  else
    {
      NSMutableSet *set=[NSMutableSet setWithArray: obe];
      [set addObjectsFromArray: objs];
      obe = [set allObjects];
    }
  [_objsByEntity setObject: obe forKey: entityName];

  return objs;
}

/**
 * EOSharedEditingContexts cannot have shared editing contexts.
 * This methos allways returns nil.
 */
- (EOSharedEditingContext *)sharedEditingContext
{
  return nil;
}

/**
 * Raises an NSInternalInconsistencyException
 * unless SHAREDCONTEXT is nil.
 */
- (void)setSharedEditingContext: (EOSharedEditingContext *)sharedContext
{
  if (sharedContext)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"+[%@ %@] illegal operation for in shared editing context", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
}

/**
 * Overriden to do nothing.
 */
- (void)reset
{
}

/**
 * Raises an NSInternalInconsistencyException
 * unless SHAREDCONTEXT is nil.
 */
- (void)setUndoManager: (NSUndoManager *)undoManager
{
  if (undoManager)
    {
      [NSException raise: NSInternalInconsistencyException
		   format: @"+[%@ %@] illegal operation for in shared editing context", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
}

/**
 * Returns the object of the superclass implementation but insures that
 * the returned object is valid in autoreleased in the current autorelease
 * pool of the calling thread.
 */
- (id)objectForGlobalID: (EOGlobalID *)globalID
{
  id obj;
  [self lockForReading];
  NS_DURING
    {
      obj = AUTORELEASE(RETAIN([super objectForGlobalID: globalID]));
    }
  NS_HANDLER
    {
      [self unlockForReading];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlockForReading];
  return obj;
}

/**
 * Returns the fault of the superclass implementation but insures that
 * the returned object is valid in autoreleased in the current autorelease
 * pool of the calling thread.
 */
- (id)faultForGlobalID: (EOGlobalID *)globalID
	editingContext: (EOEditingContext *)context
{
  id obj;
  [self lockForReading];
  NS_DURING
    {
      obj = AUTORELEASE(RETAIN([super faultForGlobalID: globalID
				      editingContext: context]));
    }
  NS_HANDLER
    {
      [self unlockForReading];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlockForReading];
  return obj;
}

/**
 * This method is invoked if the objects have been modified
 * in an unrelated EOEditingContext and therefor needs to
 * be invalidated and refetched here.
 */
- (void)refaultObject: (id)object
	 withGlobalID: (EOGlobalID *)globalID 
       editingContext: (EOEditingContext *)context
{
  if (object && [EOFaultClass isFault: object] == NO)
    {
      [self lock];
      NS_DURING
	{
	  [super refaultObject: object
		 withGlobalID: globalID
		 editingContext: context];
	}
      NS_HANDLER
	{
	  [self unlock];
	  [localException raise];
	}
      NS_ENDHANDLER;
      [self unlock];
    }
}

/**
 * Returns an empty array since a shared editing context 
 * may not insert objects.
 */
- (NSArray *)updatedObjects
{
  return emptyArray;
}

/**
 * Returns an empty array since a shared editing context 
 * may not insert objects.
 */
- (NSArray *)insertedObjects
{
  return emptyArray;
}

/**
 * Returns an empty array since a shared editing context 
 * may not delete objects.
 */
- (NSArray *)deletedObjects
{
  return emptyArray;
}

/**
 * Always returns NO since a shared editing context may not have changes.
 */
- (BOOL)hasChanges
{
  return NO;
}

/**
 * Overriden to do nothing.
 */
- (void)validateChangesForSave
{
}

/**
 * Returns the registered objects of the superclass implementation
 * but insures that that the returned objects are valid 
 * in autoreleased in the current autorelease pool of the calling thread.
 */
- (NSArray *)registeredObjects
{
  NSArray *objs;
  [self lockForReading];
  NS_DURING
    {
      objs = AUTORELEASE(RETAIN([super registeredObjects]));
    }
  NS_HANDLER
    {
      [self unlockForReading];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlockForReading];
  return objs;
}

/**
 * Raises an NSInternalInconsistencyException
 * since objects in a shared editing context may not be modified.
 */
- (void)objectWillChange: (id)object;
{
  [NSException raise: NSInternalInconsistencyException
	       format: @"+[%@ deleteObject:] attempted to delete object in shared editing context", [self class]];
}

/**
 * Raises an NSInternalInconsistencyException
 * since a shared editing context may not delete objects.
 */
- (void)insertObject: (id)object
{
  [NSException raise: NSInternalInconsistencyException
	       format: @"+[%@ %@] illegal operation for in shared editing context", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
}

/**
 * Raises an NSInternalInconsistencyException
 * since a shared editing context may not delete objects.
 */
- (void)deleteObject: (id)object
{
  [NSException raise: NSInternalInconsistencyException
	       format: @"+[%@ %@] illegal operation for in shared editing context", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
}

/**
 * Raises an NSInternalInconsistencyException
 * since objects in a shared editing context may not be modified.
 */
- (void)saveChanges
{
  [NSException raise: NSInternalInconsistencyException
	       format: @"+[%@ %@] illegal operation for in shared editing context", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
}

- (void)lock
{
  unsigned int timeout=1024;
  [_sharedLock lock];
  while (_readerLockCount && timeout)
    {
      [_sharedLock unlock];
      timeout--;
      [_sharedLock lock];
    }
  if (timeout==0) NSLog(@"FIXME: ignoring lock to aviod deadlock!");
  [super lock];
  [_sharedLock unlock];
}
- (void)unlock
{
  [_sharedLock lock];
  [super unlock];
  [_sharedLock unlock];
}

/**
 * Invokes the super class implementation and recordes the object
 * for the next EOSharedEditingContextInitializedObjectsNotification
 * if the CONTEXT is the receiver which will be processed during
 * explicit or implicit processRecentChanges.
 */
- (void)initializeObject: (id)object
	    withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context
{
  [self lock];
  NS_DURING
    {
      [super initializeObject: object 
	     withGlobalID: globalID 
	     editingContext: context];
      if (context == self)
	{
	  [_initializedGlobalIDs addObject: globalID];
	}
    }
  NS_HANDLER
    {
      [self unlock];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlock];
}

/*
 * Overriding a private method indicates the mechanism is broken by design.
 * We need to need to notify obeserving EOEditingContexts of
 * objects which have been initialized.
 */
- (BOOL)_processRecentChanges
{
  BOOL flag = NO;
  if ([_initializedGlobalIDs count])
    {
      NSDictionary *userInfo 
	= [NSDictionary dictionaryWithObject: _initializedGlobalIDs
			forKey: @"initialized"];
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName: EOSharedEditingContextInitializedObjectsNotification
	  object: self
	  userInfo: userInfo];
      ASSIGN(_initializedGlobalIDs, [NSMutableArray arrayWithCapacity: 32]);
    }
  [self lock];
  NS_DURING
    {
      flag = [super _processRecentChanges];
    }
  NS_HANDLER
    {
      [self unlock];
      [localException raise];
    }
  NS_ENDHANDLER;
  [self unlock];

  return flag;
}
@end
