/* -*-objc-*-
   EOObjectStoreCoordinator.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef	__EOObjectStoreCoordinator_h__
#define	__EOObjectStoreCoordinator_h__


#include <EOControl/EOObjectStore.h>

#include <EOControl/EODefines.h>


@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSString;

@class EOCooperatingObjectStore;
@class EOQualifier;
@class EOModelGroup;


@interface EOObjectStoreCoordinator : EOObjectStore
{
  NSMutableArray *_stores;
  NSDictionary *_userInfo;
}

- (void)addCooperatingObjectStore: (EOCooperatingObjectStore *)store;

- (void)removeCooperatingObjectStore: (EOCooperatingObjectStore *)store;

- (NSArray *)cooperatingObjectStores;

- (void)forwardUpdateForObject: (id)object changes: (NSDictionary *)changes;

- (NSDictionary *)valuesForKeys: (NSArray *)keys object: (id)object;

- (EOCooperatingObjectStore *)objectStoreForGlobalID: (EOGlobalID *)globalID;

- (EOCooperatingObjectStore *)objectStoreForObject: (id)object;

- (EOCooperatingObjectStore *)objectStoreForFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (NSDictionary *)userInfo;
- (void)setUserInfo: (NSDictionary *)info;

+ (void)setDefaultCoordinator: (EOObjectStoreCoordinator *)coordinator;
+ (id)defaultCoordinator;

@end


/* Notifications */
GDL2CONTROL_EXPORT NSString *EOCooperatingObjectStoreWasAdded;
GDL2CONTROL_EXPORT NSString *EOCooperatingObjectStoreWasRemoved;

GDL2CONTROL_EXPORT NSString *EOCooperatingObjectStoreNeeded;


@interface EOCooperatingObjectStore : EOObjectStore

- (BOOL)ownsGlobalID: (EOGlobalID *)globalID;

- (BOOL)ownsObject: (id)object;

- (BOOL)ownsEntityNamed: (NSString *)entityName;

- (BOOL)handlesFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (void)prepareForSaveWithCoordinator: (EOObjectStoreCoordinator *)coordinator
		       editingContext: (EOEditingContext *)context;

- (void)recordChangesInEditingContext;

- (void)recordUpdateForObject: (id)object changes: (NSDictionary *)changes;

- (void)performChanges;

- (void)commitChanges;
- (void)rollbackChanges;

- (NSDictionary *)valuesForKeys: (NSArray *)keys object: (id)object;

@end


#endif
