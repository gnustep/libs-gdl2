/** 
   EODatabase.m <title>EODatabase Class</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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

static char rcsId[] = "$Id$";

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSDebug.h>

#import <EOAccess/EOAccessFault.h>
#import <EOAccess/EOAdaptor.h>
#import <EOAccess/EOModel.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EODatabase.h>
#import <EOAccess/EODatabaseContext.h>

#import <EOControl/EOObjectStore.h>
#import <EOControl/EOKeyGlobalID.h>
#import <EOControl/EODebug.h>


/* TODO

   Controllare il resultCache, ad ogni forget/invalidate deve essere
   updatato.
 */

NSString *EOGeneralDatabaseException = @"EOGeneralDatabaseException";


@implementation EODatabase

/*
 *  Database Global Methods
 */

static NSMutableArray *databaseInstances;

+ (void)initialize
{
  // THREAD
  databaseInstances = [NSMutableArray new];
}

+ (void)makeAllDatabasesPerform: (SEL)aSelector withObject: anObject
{
  int i;
    
  // THREAD
  for (i = [databaseInstances count] - 1; i >= 0; i--)
    [[[databaseInstances objectAtIndex: i] nonretainedObjectValue] 
      performSelector: aSelector withObject: anObject];
}

/*
 * Initializing new instances
 */
//OK
- initWithAdaptor: (EOAdaptor *)adaptor
{
  EOFLOGObjectFnStart();

  if (!adaptor)
    {
      [self autorelease];
      return nil;
    }

  if ((self = [super init]))
    {
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_globalIDChanged:)
        name: @"EOGlobalIDChangedNotification"
        object: nil];
      //  [databaseInstances addObject:[NSValue valueWithNonretainedObject:self]];
      ASSIGN(_adaptor,adaptor);

      _registeredContexts = [NSMutableArray new];
      _snapshots = [NSMutableDictionary new];
      _models = [NSMutableArray new];
      _entityCache = [NSMutableDictionary new];
      _toManySnapshots = [NSMutableDictionary new];
    }

  EOFLOGObjectFnStop();

  return self;
}

+ (EODatabase *)databaseWithModel: (EOModel *)model
{
  return [[[self alloc] initWithModel: model] autorelease];
}

- (id)initWithModel: (EOModel *)model
{
  EOAdaptor *adaptor = [EOAdaptor adaptorWithModel:model]; //Handle exception to deallocate self ?

  if ((self = [self initWithAdaptor: adaptor]))
    {
      [self addModel: model];
    }

  return self;
}

- (void)dealloc
{
  [_adaptor release];
  [_registeredContexts release];
  [_snapshots release];
  [_models release];
  [_entityCache release];
  [_toManySnapshots release];

  [super dealloc];
}

- (NSArray *)registeredContexts
{
  NSMutableArray *array = [NSMutableArray array];
  int i, n;
  
  for (i = 0, n = [_registeredContexts count]; i < n; i++)
    [array addObject: [[_registeredContexts objectAtIndex: i]
			nonretainedObjectValue]];
    
  return array;
}

- (unsigned int) _indexOfRegisteredContext: (EODatabaseContext *)context
{
  int i;

  for( i = [_registeredContexts count]-1; i >= 0; i--)
    if ([[_registeredContexts objectAtIndex: i]
	  nonretainedObjectValue] == context)
      {
	return i;
      }

  return -1;
}

- (void)registerContext: (EODatabaseContext *)context
{
  unsigned int index=0;

  //OK

  NSAssert(([context database] == self),@"Database context is not me");

  index = [self _indexOfRegisteredContext:context];

  NSAssert(index == (unsigned int) -1 , @"DatabaseContext already registred");

  [_registeredContexts addObject:
			 [NSValue valueWithNonretainedObject: context]];
}

- (void)unregisterContext: (EODatabaseContext *)context
{
  //OK
  unsigned int index = [self _indexOfRegisteredContext:context];

  NSAssert(index != (unsigned int) -1, @"DatabaseContext wasn't registred");

  [_registeredContexts removeObjectAtIndex:index];
}

- (EOAdaptor *)adaptor
{
  return _adaptor;
}

- (void)addModel: (EOModel *)model
{
  [_models addObject: model];
}

- (void)removeModel: (EOModel *)model
{
  [_models removeObject: model];
}

- (BOOL)addModelIfCompatible: (EOModel *)model;
{
  BOOL modelOk = NO;

  NSAssert(model, @"No model");//WO simply return NO (doesn't handle this case).

  if ([_models containsObject:model] == YES)
    modelOk = YES;
  else
    {
      EOAdaptor *adaptor = [self adaptor];

      if ([[model adaptorName] isEqualToString: [adaptor name]] == YES
         || [_adaptor canServiceModel: model] == YES)
        {
          [_models addObject: model];
          modelOk = YES;
        }
    }

  return modelOk;
}

- (NSArray *)models
{
  return _models;
}

- (EOEntity *)entityNamed: (NSString *)entityName
{
  //OK
  EOEntity *entity=nil;
  int i = 0;
  int count = 0;

  NSAssert(entityName, @"No entity name");

  count = [_models count];

  for(i = 0; !entity && i < count; i++)
    {
      EOModel *model = [_models objectAtIndex: i];

      entity = [model entityNamed: entityName];
    }

  return entity;
}

- (EOEntity *)entityForObject: (id)object
{
  //OK
  EOEntity *entity = nil;
  NSString *entityName = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"object=%p (of class %@)",
			object, [object class]);
  NSAssert(!isNilOrEONull(object), @"No object");

  if ([EOFault isFault: object])
    {
      EOFaultHandler *faultHandler = [EOFault handlerForFault: object];
      EOKeyGlobalID *gid;

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"faultHandler=%p (of class %@)",
			    faultHandler, [faultHandler class]);      

      gid = [(EOAccessFaultHandler *)faultHandler globalID];

      NSAssert3(gid, @"No gid for fault handler %p for object %p of class %@",
                faultHandler, object, [object class]);
      entityName = [gid entityName];
    }
  else
    entityName = [object entityName];

  NSAssert2(entityName, @"No object entity name for object %@ of class %@",
	    object, [object class]);

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entityName=%@", entityName);

  entity = [self entityNamed: entityName];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"entity=%p", entity);
  EOFLOGObjectFnStop();

  return entity;
}

- (NSArray *)resultCacheForEntityNamed: (NSString *)name
{
  return [_entityCache objectForKey: name];
}

- (void)setResultCache: (NSArray *)cache
        forEntityNamed: (NSString *)name
{
  EOFLOGObjectFnStart();

  [_entityCache setObject: cache
                forKey: name];

  EOFLOGObjectFnStop();
}

- (void)invalidateResultCacheForEntityNamed: (NSString *)name
{
  [_entityCache removeObjectForKey: name];//??
}

- (void)invalidateResultCache
{
  [_entityCache removeAllObjects];
}

- (void)handleDroppedConnection
{
  NSArray	    *dbContextArray;
  NSEnumerator	    *contextEnum;
  EODatabaseContext *dbContext;
  
  EOFLOGObjectFnStartOrCond2(@"DatabaseLevel", @"EODatabase");
  
  [_adaptor handleDroppedConnection];
  
  dbContextArray = [self registeredContexts];
  contextEnum = [dbContextArray objectEnumerator];
 
  while ((dbContext = [contextEnum nextObject]))
    [dbContext handleDroppedConnection];
  
  EOFLOGObjectFnStopOrCond2(@"DatabaseLevel", @"EODatabase");
}

@end


@implementation EODatabase (EOUniquing)

- (void)recordSnapshot: (NSDictionary *)snapshot
           forGlobalID: (EOGlobalID *)gid
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshot %p %@", snapshot, snapshot);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

  NSAssert(gid, @"No gid");
  NSAssert(snapshot, @"No snapshot");
  NSAssert(_snapshots, @"No _snapshots");

  [_snapshots setObject: snapshot
              forKey: gid];

  NSAssert([_snapshots objectForKey: gid], @"SNAPSHOT not save !!");

  EOFLOGObjectFnStop();
}

//"Receive EOGlobalIDChangedNotification notification"
- (void)_globalIDChanged: (NSNotification *)notification
{
  NSDictionary *snapshot = nil;
  NSDictionary *userInfo = nil;
  NSEnumerator *enumerator = nil;
  EOGlobalID *tempGID = nil;
  EOGlobalID *gid = nil;

  EOFLOGObjectFnStart();

  userInfo = [notification userInfo];
  enumerator = [userInfo keyEnumerator];

  while ((tempGID = [enumerator nextObject]))
    {
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"tempGID=%@", tempGID);

      gid = [userInfo objectForKey: tempGID];

      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

      //OK ?
      snapshot = [_snapshots objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_snapshots snapshot=%@", snapshot);

      if (snapshot)
	{
	  [_snapshots removeObjectForKey: tempGID];
	  [_snapshots setObject: snapshot
                      forKey: gid];
	}

      //OK ?
      snapshot = [_toManySnapshots objectForKey: tempGID];
      EOFLOGObjectLevelArgs(@"EODatabaseContext", @"_toManySnapshots snapshot=%@",
			    snapshot);

      if (snapshot)
	{
	  [_toManySnapshots removeObjectForKey: tempGID];
	  [_toManySnapshots setObject: snapshot
                            forKey: gid];
	}
    }

  EOFLOGObjectFnStop();
}

- (NSDictionary *)snapshotForGlobalID: (EOGlobalID *)gid
{
  //seems OK
  NSDictionary *snapshot = nil;

  EOFLOGObjectFnStart();

  NSAssert(gid, @"No gid");

  snapshot = [_snapshots objectForKey: gid];

  EOFLOGObjectFnStop();

  return snapshot;
}

- (void)recordSnapshot: (NSArray*)gids
     forSourceGlobalID: (EOGlobalID *)gid
      relationshipName: (NSString *)name
{
  //OK
  NSMutableDictionary *toMany = nil;

  EOFLOGObjectFnStart();

  NSAssert(gid,@"No snapshot");
  NSAssert(gid,@"No Source Global ID");
  NSAssert(name,@"No relationship name");

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p snapshot gids=%@", self, gids);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"SourceGlobalID gid=%@", gid);
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"relationshipName=%@", name);

  toMany = [_toManySnapshots objectForKey: gid];

  if (!toMany)
    {
      toMany = [NSMutableDictionary dictionaryWithCapacity: 10];
      [_toManySnapshots setObject: toMany
			forKey: gid];
    }

  [toMany setObject: gids
          forKey: name];

  EOFLOGObjectFnStop();
}

- (NSArray *)snapshotForSourceGlobalID: (EOGlobalID *)gid
		      relationshipName: (NSString *)name
{
  NSAssert(gid, @"No Source Global ID");
  NSAssert(name, @"No relationship name");

  return [[_toManySnapshots objectForKey: gid] objectForKey: name];
}

- (void)forgetSnapshotForGlobalID: (EOGlobalID *)gid
{
  //Seems OK
  EOFLOGObjectFnStart();

  NSAssert(gid,@"No Global ID");

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"gid=%@", gid);

  [_snapshots removeObjectForKey: gid];
  [_toManySnapshots removeObjectForKey: gid];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOObjectsChangedInStoreNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObject:
			      [NSArray arrayWithObject: gid]
			    forKey: EOInvalidatedKey]];

  EOFLOGObjectFnStop();
};

- (void)forgetSnapshotsForGlobalIDs: (NSArray*)ids
{
  NSEnumerator *gidEnum = nil;
  id gid = nil;

  EOFLOGObjectFnStart();

  NSAssert(ids, @"No Global IDs");
  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"ids=%@", ids);

  gidEnum = [ids objectEnumerator];

  while ((gid = [gidEnum nextObject]))
    {
      [_snapshots removeObjectForKey: gid];
      [_toManySnapshots removeObjectForKey: gid];
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOObjectsChangedInStoreNotification
    object: self
    userInfo: [NSDictionary dictionaryWithObject: ids
			    forKey: EOInvalidatedKey]];

  EOFLOGObjectFnStop();
}

- (void)forgetAllSnapshots
{
   NSMutableSet	  *gidSet = [NSMutableSet new];
   NSMutableArray *gidArray = [NSMutableArray array];
 
   EOFLOGObjectFnStartOrCond2(@"DatabaseLevel", @"EODatabase");
 
   [gidSet addObjectsFromArray: [_snapshots allKeys]];
   [gidSet addObjectsFromArray: [_toManySnapshots allKeys]];
   [gidArray addObjectsFromArray: [gidSet allObjects]];
   [gidSet release];
   [_snapshots removeAllObjects];
   [_toManySnapshots removeAllObjects];

   [[NSNotificationCenter defaultCenter]
     postNotificationName: EOObjectsChangedInStoreNotification
     object:self
     userInfo: [NSDictionary dictionaryWithObject: gidArray
                             forKey: EOInvalidatedKey]];

   EOFLOGObjectFnStopOrCond2(@"DatabaseLevel", @"EODatabase");
}

- (void)recordSnapshots: (NSDictionary *)snapshots
{
  //OK
  //VERIFY: be sure to replace all anapshot entries if any !
  EOFLOGObjectFnStart();

  [_snapshots addEntriesFromDictionary: snapshots];

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"self=%p _snapshots=%@",
			self, _snapshots);

  EOFLOGObjectFnStop();
}

- (void)recordToManySnapshots: (NSDictionary *)snapshots
{
//Seems OK
  NSEnumerator *keyEnum = nil;
  id key = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshots=%@", snapshots);
  NSAssert(snapshots, @"No snapshots");

  keyEnum = [snapshots keyEnumerator];

  while ((key = [keyEnum nextObject]))
    {
      NSMutableDictionary *toMany = nil;

      toMany = [_toManySnapshots objectForKey: key]; // look if already exists

      if (!toMany)
	{
	  toMany = [NSMutableDictionary dictionaryWithCapacity: 10];
	  [_toManySnapshots setObject: toMany
			    forKey: key];
	}

      [toMany addEntriesFromDictionary: [snapshots objectForKey: key]];
    }

  EOFLOGObjectLevelArgs(@"EODatabaseContext", @"snapshots=%@", snapshots);

  EOFLOGObjectFnStop();
}

- (NSDictionary *)snapshots
{
  return _snapshots;
}

@end /* EODatabase (EOUniquing) */

