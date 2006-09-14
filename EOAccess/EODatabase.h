/* -*-objc-*-
   EODatabase.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: Jun 2000

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

#ifndef __EODatabase_h__
#define __EODatabase_h__


#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOAccess/EODefines.h>

@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSString;

@class EOAdaptor;
@class EOModel;
@class EOEntity;

@class EODatabaseContext;
@class EOGlobalID;
@class EOEditingContext;


GDL2ACCESS_EXPORT NSString *EOGeneralDatabaseException;

GDL2ACCESS_EXPORT NSTimeInterval EODistantPastTimeInterval; 


@interface EODatabase : NSObject
{
  NSMutableArray *_registeredContexts;
  NSMutableDictionary *_snapshots;
  NSMutableArray *_models;
  NSMutableDictionary *_entityCache;
  EOAdaptor *_adaptor;
  NSMutableDictionary *_toManySnapshots;
}

+ (EODatabase *)databaseWithModel: (EOModel *)model;

- (id)initWithAdaptor: (EOAdaptor *)adaptor;

- (id)initWithModel: (EOModel *)model;

- (NSArray *)registeredContexts;

- (void)registerContext: (EODatabaseContext *)context;
- (void)unregisterContext: (EODatabaseContext *)context;

- (EOAdaptor *)adaptor;

- (void)addModel: (EOModel *)model;
- (void)removeModel: (EOModel *)model;
- (BOOL)addModelIfCompatible: (EOModel *)model;

- (NSArray *)models;

- (EOEntity *)entityNamed: (NSString *)entityName;

- (EOEntity *)entityForObject: (id)object;

- (NSArray *)resultCacheForEntityNamed: (NSString *)name;
- (void)setResultCache: (NSArray *)cache forEntityNamed: (NSString *)name;
- (void)invalidateResultCacheForEntityNamed: (NSString *)name;
- (void)invalidateResultCache;
- (void)handleDroppedConnection;
@end


@interface EODatabase (EOUniquing)

- (void)recordSnapshot: (NSDictionary *)snapshot forGlobalID: (EOGlobalID *)gid;

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
                                after: (NSTimeInterval)ti;
- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid;

- (void)recordSnapshot: (NSArray *)gids
     forSourceGlobalID: (EOGlobalID *)gid
      relationshipName: (NSString *)name;

- (NSArray *)snapshotForSourceGlobalID: (EOGlobalID *)gid
		      relationshipName: (NSString *)name;

- (void)forgetSnapshotForGlobalID: (EOGlobalID *)gid;

- (void)forgetSnapshotsForGlobalIDs: (NSArray *)array;

- (void)forgetAllSnapshots;

- (void)recordSnapshots: (NSDictionary *)snapshots;

- (void)recordToManySnapshots: (NSDictionary *)snapshots;

- (NSDictionary *)snapshots;

@end


#endif /* __EODatabase_h__ */
