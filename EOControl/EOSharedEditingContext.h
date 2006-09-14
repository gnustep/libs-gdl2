/* -*-objc-*-
   EOSharedEditingContext.h

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

#ifndef	__EOSharedEditingContext_h__
#define	__EOSharedEditingContext_h__

#include <EOControl/EOEditingContext.h>
#include <EOControl/EODefines.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSUndoManager;
@class EOMultiReaderLock;
@class EOFetchSpecification;
@class EOGlobalID;

GDL2CONTROL_EXPORT
NSString *EODefaultSharedEditingContextWasInitializedNotification;

GDL2CONTROL_EXPORT
NSString *EOSharedEditingContextInitializedObjectsNotification;

@interface EOSharedEditingContext : EOEditingContext
{
  NSRecursiveLock *_sharedLock; /* FIXME: Use EOMultiReaderLock.  */
  int _readerLockCount;
  int _readerLockCountSuspended;
  NSMutableArray *_initializedGlobalIDs;
  NSMutableDictionary *_objsByEntity;
  NSMutableDictionary *_objsByEntityFetchSpec;
}

+ (EOSharedEditingContext *)defaultSharedEditingContext;
+ (void)setDefaultSharedEditingContext: (EOSharedEditingContext *)context;

- (NSDictionary *)objectsByEntityName;
- (NSDictionary *)objectsByEntityNameAndFetchSpecificationName;
- (void)bindObjectsWithFetchSpecification: (EOFetchSpecification *)fetchSpec
				   toName: (NSString *)name;

- (void)lockForReading;
- (void)unlockForReading;
- (BOOL)tryLockForReading;
- (void)suspendReaderLocks;
- (void)retrieveReaderLocks;

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpec
			    editingContext: (EOEditingContext *)context;

- (EOSharedEditingContext *)sharedEditingContext;
- (void)setSharedEditingContext: (EOSharedEditingContext *)sharedContext;

- (void)reset;
- (void)setUndoManager: (NSUndoManager *)undoManager;

- (id)objectForGlobalID: (EOGlobalID *)globalID;
- (id)faultForGlobalID: (EOGlobalID *)globalID
	editingContext: (EOEditingContext *)context;
- (void)refaultObject: (id)object
	 withGlobalID: (EOGlobalID *)globalID 
       editingContext: (EOEditingContext *)context;

- (NSArray *)updatedObjects;
- (NSArray *)insertedObjects;
- (NSArray *)deletedObjects;

- (BOOL)hasChanges;
- (void)validateChangesForSave;

- (NSArray *)registeredObjects;

- (void)objectWillChange: (id)object;
- (void)insertObject: (id)object;
- (void)deleteObject: (id)object;
- (void)saveChanges;
@end

#endif
