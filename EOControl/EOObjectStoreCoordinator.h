/* 
   EOObjectStoreCoordinator.h

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#ifndef	__EOObjectStoreCoordinator_h__
#define	__EOObjectStoreCoordinator_h__

#import <Foundation/Foundation.h>
#import <EOControl/EOObjectStore.h>

@class EOCooperatingObjectStore;
@class EOQualifier;
@class EOModelGroup;

@interface EOObjectStoreCoordinator:EOObjectStore
{
  NSMutableArray *_stores;
  NSDictionary *_userInfo;
}

- init;

- (void)addCooperatingObjectStore: (EOCooperatingObjectStore *)store;

- (void)removeCooperatingObjectStore: (EOCooperatingObjectStore *)store;

- (NSArray *)cooperatingObjectStores;

- (void)forwardUpdateForObject: object changes: (NSDictionary *)changes;

- (NSDictionary *)valuesForKeys: (NSArray *)keys object: object;

- (EOCooperatingObjectStore *)objectStoreForGlobalID: (EOGlobalID *)gloablID;

- (EOCooperatingObjectStore *)objectStoreForObject: object;

- (EOCooperatingObjectStore *)objectStoreForFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (NSDictionary *)userInfo;
- (void)setUserInfo: (NSDictionary *)info;

+ (void)setDefaultCoordinator: (EOObjectStoreCoordinator *)coordinator;
+ (id)defaultCoordinator;

@end

@interface EOObjectStoreCoordinator (EOModelGroup)

- (id) modelGroup;
- (void) setModelGroup: (EOModelGroup*)modelGroup;

@end

// Notifications:
extern NSString *EOCooperatingObjectStoreWasAdded;
extern NSString *EOCooperatingObjectStoreWasRemoved;

extern NSString *EOCooperatingObjectStoreNeeded;


@interface EOCooperatingObjectStore:EOObjectStore

- (BOOL)ownsGlobalID: (EOGlobalID *)globalID;

- (BOOL)ownsObject: (id)object;

- (BOOL)ownsEntityNamed: (NSString *)entityName;

- (BOOL)handlesFetchSpecification: (EOFetchSpecification *)fetchSpecification;

- (void)prepareForSaveWithCoordinator: (EOObjectStoreCoordinator *)coordinator editingContext:(EOEditingContext *)context;

- (void)recordChangesInEditingContext;

- (void)recordUpdateForObject:object changes: (NSDictionary *)changes;

- (void)performChanges;

- (void)commitChanges;
- (void)rollbackChanges;

- (NSDictionary *)valuesForKeys: (NSArray *)keys object: object;

@end


#endif
