/** 
   EOUtilities.m

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Sep 2000

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EONull.h>
#include <EOControl/EOGenericRecord.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EODatabase.h>
#include <EOAccess/EODatabaseContext.h>
#include <EOAccess/EODatabaseChannel.h>
#include <EOAccess/EOSQLExpression.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOStoredProcedure.h>

#include <EOAccess/EOUtilities.h>

#include "EOPrivate.h"

NSString *EOMoreThanOneException = @"EOMoreThanOneException";
NSString *NSObjectNotAvailableException = @"NSObjectNotAvailableException";


@implementation EOEditingContext (EOUtilities)

- (NSArray *)objectsForEntityNamed: (NSString *)entityName
{
  NSArray *objects;
  EOFetchSpecification *fetchSpecif;

  NSAssert([entityName length] > 0, @"No entity name");

  fetchSpecif = [EOFetchSpecification
		  fetchSpecificationWithEntityName: entityName
		  qualifier: nil
		  sortOrderings: nil];
  objects = [self objectsWithFetchSpecification: fetchSpecif];

  return objects;
}

- (NSArray *)objectsOfClass: (Class)classObject
{
  EOEntity *entity;
  NSArray *objects;
  
  EOFLOGObjectFnStartOrCond(@"EOEditingContext");
  
  entity = [self entityForClass: classObject];
  objects = [self objectsForEntityNamed: [entity name]];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");
  
  return objects;
}

- (NSArray *)objectsWithFetchSpecificationNamed: (NSString *)fetchSpecName
				    entityNamed: (NSString *)entityName
				       bindings: (NSDictionary *)bindings
{
  EOModelGroup *modelGroup;
  EOFetchSpecification *unboundFetchSpec;
  EOFetchSpecification *boundFetchSpec;
  NSArray *results;
  
  modelGroup = [self modelGroup];
  unboundFetchSpec = [modelGroup fetchSpecificationNamed: fetchSpecName
				 entityNamed: entityName];

  if ( !unboundFetchSpec ) 
    {
      [NSException raise: NSObjectNotAvailableException
                   format: @"%@: Fetch specification '%@' not found in entity named '%@'", 
                   NSStringFromSelector(_cmd), fetchSpecName, entityName];
    }

  boundFetchSpec = [unboundFetchSpec fetchSpecificationWithQualifierBindings:
				       bindings];
  results = [self objectsWithFetchSpecification: boundFetchSpec];

  return results;
}

- (NSArray *)objectsForEntityNamed: (NSString *)entityName
		   qualifierFormat: (NSString *)format,...
{
  EOQualifier *qualifier;
  EOFetchSpecification *fetchSpec;
  NSArray *results;
  va_list args;
  
  va_start(args, format);
  qualifier = [EOQualifier qualifierWithQualifierFormat: format
			   varargList: args];
  va_end(args);

  fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:
				      entityName 
                                    qualifier: qualifier
                                    sortOrderings: nil];
  results = [self objectsWithFetchSpecification: fetchSpec];

  return results;
}

- (NSArray *)objectsMatchingValue: (id)value
			   forKey: (NSString *)key
		      entityNamed: (NSString *)entityName
{
  //OK
  NSArray *objects;

  EOFLOGObjectFnStart();
  NSDebugMLLog(@"gsdb", @"START value=%@ key=%@ entityName=%@",
	       value, key, entityName);

  if (!value)
    value=GDL2_EONull;

  NSAssert(value, @"No Value"); //Transform it to EONull ?
  NSAssert(key, @"No Key");
  NSAssert([entityName length] > 0, @"No entity name");

  objects = [self objectsMatchingValues:
		    [NSDictionary dictionaryWithObject: value
				  forKey: key]
		  entityNamed: entityName];

  EOFLOGObjectFnStop();

  return objects;
//TC:
/*
  EOKeyValueQualifier  *qualifier;
  EOFetchSpecification *fetch;
  NSArray	*newArray;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  qualifier = [[EOKeyValueQualifier alloc]
		initWithKey:key
		operatorSelector:EOQualifierOperatorEqual
		value:value];

  fetch = [EOFetchSpecification fetchSpecificationWithEntityName:name
				qualifier:[qualifier autorelease]
				sortOrderings:nil];

  newArray = [self objectsWithFetchSpecification:fetch];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return newArray;
*/
}

- (NSArray *)objectsMatchingValues: (NSDictionary *)values
		       entityNamed: (NSString *)entityName
{
  //OK
  NSArray *objects = nil;
  EOFetchSpecification *fetchSpec;
  EOQualifier *qualifier;
  NSEnumerator *valuesEnum;
  id key=nil;
  NSMutableArray* kvQualifiers=nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"START values=%@ entityName=%@", values, entityName);

  NS_DURING
    {
      NSAssert([entityName length] > 0, @"No entity name");

      valuesEnum = [values keyEnumerator];  
      kvQualifiers = [NSMutableArray array];

      while ((key = [valuesEnum nextObject]))
        {
          id value = [values objectForKey: key];
          EOKeyValueQualifier *tmpQualifier = [EOKeyValueQualifier
						qualifierWithKey: key
						operatorSelector:
						  @selector(isEqualTo:)
						value: value];

          [kvQualifiers addObject: tmpQualifier];
        }

      qualifier = [EOAndQualifier qualifierWithQualifierArray: kvQualifiers];
      fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:
					  entityName
					qualifier: qualifier
					sortOrderings: nil];

      NSDebugMLLog(@"gsdb", @"fetchSpec=%@", fetchSpec);
      objects = [self objectsWithFetchSpecification: fetchSpec];
    }
  NS_HANDLER
    {
      NSDebugMLog(@"exception in EOEditingContext (EOUtilities) objectsMatchingValues:entityNamed:", "");
      NSLog(@"exception in EOEditingContext (EOUtilities) objectsMatchingValues:entityNamed:");
      NSDebugMLog(@"exception=%@", localException);
      NSLog(@"exception=%@", localException);
/*      localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                              @"In EOEditingContext (EOUtilities) objectsMatchingValues:entityNamed:");
*/
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  EOFLOGObjectFnStop();

  return objects;
//TC:
/*
    EOQualifier *qualifier;
    EOFetchSpecification *fetchSpec;
    NSArray *results;

    qualifier = [EOQualifier qualifierToMatchAllValues:values];
    fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:name qualifier:qualifier sortOrderings:nil];
    results = [self objectsWithFetchSpecification:fetchSpec];
    return results;

*/
}

- (id)objectWithFetchSpecificationNamed: (NSString *)fetchSpecName
			    entityNamed: (NSString *)entityName
			       bindings: (NSDictionary *)bindings
{  
  id object = nil;
  int count;
  NSArray *objects;

  NSAssert([entityName length] > 0, @"No entity name");

  objects = [self objectsWithFetchSpecificationNamed:fetchSpecName
                entityNamed:entityName
                bindings:bindings];
  count = [objects count];

  switch (count) 
    {
    case 0:
      [NSException raise: NSInvalidArgumentException
                   format: @"%@: No item selected for fetch specification %@ in entity %@ with bindings %@",
                   NSStringFromSelector(_cmd),
                   fetchSpecName,
                   entityName,
                   bindings];
      break;
    case 1:
      object = [objects objectAtIndex: 0];
      break;
    default:
      [NSException raise: EOMoreThanOneException
                   format: @"%@: Selected more than one item for fetch specification %@ in entity %@ with bindings %@",
                   NSStringFromSelector(_cmd),
                   fetchSpecName, 
                   entityName, 
                   bindings];
      break;
    }

  return object;
}

- (id)objectForEntityNamed: (NSString *)entityName
	   qualifierFormat: (NSString *)format,...
{
  id object = nil;
  int count;
  EOQualifier *qualifier;
  EOFetchSpecification *fetchSpec;
  NSArray *objects;
  va_list args;

  va_start(args, format);
  qualifier = [EOQualifier qualifierWithQualifierFormat: format
                           varargList: args];
  va_end(args);

  fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:
				      entityName
                                    qualifier: qualifier
                                    sortOrderings: nil];
  objects = [self objectsWithFetchSpecification: fetchSpec];

  count = [objects count];

  switch (count) 
    {
    case 0:
      [NSException raise: NSInvalidArgumentException
                   format: @"%@: No item selected for entity %@ qualified by %@",
                   NSStringFromSelector(_cmd), 
                   entityName, 
                   format];
      break;
    case 1:
      object = [objects objectAtIndex: 0];
      break;
    default:
      [NSException raise: EOMoreThanOneException
                   format: @"%@: Selected more than one item for entity %@ qualified by %@",
                   NSStringFromSelector(_cmd), 
                   entityName, 
                   format];
    }

  return object;
}

- (id)objectMatchingValue: (id)value
		   forKey: (NSString *)key
	      entityNamed: (NSString *)entityName
{
  //OK
  id object = nil;
  int count;
  NSArray *objects;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"START value=%@ key=%@ entityName=%@",
	       value, key, entityName);

  NS_DURING //Debugging Purpose
    {
      NSAssert([entityName length] > 0, @"No entity name");

      objects = [self objectsMatchingValue: value
		      forKey: key
		      entityNamed: entityName];

      NSDebugMLLog(@"gsdb", @"objects count=%d", [objects count]);
      NSDebugMLLog(@"gsdb", @"objects=%@", objects);

      count = [objects count];

      switch (count)
        {
        case 0:
          [NSException raise: NSObjectNotAvailableException
		       format: @"%@: No %@ found with key %@ matching %@",
                       NSStringFromSelector(_cmd),
                       entityName,
                       key,
                       value];
          break;
        case 1:
          object = [objects objectAtIndex: 0];
          break;
        default:
           [NSException raise: EOMoreThanOneException
			format: @"%@: Selected more than one %@ with key %@ matching %@", 
                        NSStringFromSelector(_cmd), 
                        entityName, 
                        key, 
                        value];
           break;
        }
    }
  NS_HANDLER
    {
      NSLog(@"exception in EOEditingContext (EOUtilities) objectMatchingValue:forKey:entityNamed:");
      NSLog(@"exception=%@", localException);
/*      localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                              @"In EOEditingContext (EOUtilities) objectMatchingValue:forKey:entityNamed:");
*/
      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  NSDebugMLLog(@"gsdb", @"object=%@", object);

  EOFLOGObjectFnStop();

  return object;
}

- (id)objectMatchingValues: (NSDictionary *)values
	       entityNamed: (NSString *)entityName
{
  id object = nil;
  int count;
  NSArray *objects;

  EOFLOGObjectFnStart();

  NSAssert([entityName length] > 0, @"No entity name");

  objects = [self objectsMatchingValues: values
		  entityNamed: entityName];
  count = [objects count];

  switch(count)
    {
    case 0:
      [NSException raise: NSInvalidArgumentException
		   format: @"%@: No %@ found matching %@",
                   NSStringFromSelector(_cmd),
                   entityName,
                   values];
      break;
    case 1:
      object = [objects objectAtIndex: 0];
      break;
    default:
      [NSException raise: EOMoreThanOneException
		   format: @"%@: Selected more than one %@ matching %@", 
                   NSStringFromSelector(_cmd), 
                   entityName, 
                   values];
           break;
    }

  EOFLOGObjectFnStop();

  return object;
}

- (id)objectWithPrimaryKeyValue: (id)value
		    entityNamed: (NSString *)entityName
{
  //OK
  id object = nil;
  EOEntity *entity;

  NSAssert([entityName length] > 0, @"No entity name");

  entity = [self entityNamed: entityName];

  if (!entity)
    [NSException raise: NSInvalidArgumentException
                 format: @"objectWithPrimaryKeyValue:%@ entityNamed:%@; no entity",
                 value,
                 entityName];
  else
    {
      NSArray *primaryKeyAttributes = [entity primaryKeyAttributes];

      if ([primaryKeyAttributes count] != 1)
        {
          [NSException raise: NSInvalidArgumentException
                       format: @"objectWithPrimaryKeyValue:%@ entityNamed:%@ may only be called for entities with one primary key attribute. For entities with compound primary keys, use objectWithPrimaryKey:entityNamed and provide a dictionary for the primary key.",
                       value,
                       entityName];
        }
      else
        {
          NSDictionary* pk;
          if (!value)
            value=GDL2_EONull;

          pk = [NSDictionary dictionaryWithObject: value
                             forKey: [(EOAttribute*)[primaryKeyAttributes
                                                      objectAtIndex: 0]
                                                    name]];

          object = [self objectWithPrimaryKey: pk
			 entityNamed: entityName];
        }
    }

  return object;
}

- (id)objectWithPrimaryKey: (NSDictionary *)pkDict
	       entityNamed: (NSString *)entityName
{
  //OK
  id object = nil;
  EOEntity *entity;

  NSAssert([pkDict count] > 0, @"Empty primary key.");
  NSAssert([entityName length] > 0, @"No entity name");

  entity = [self entityNamed: entityName];

  if (!entity)
    [NSException raise: NSInvalidArgumentException
                 format: @"objectWithPrimaryKeyValue:%@ entityNamed:%@; no entity",
                 pkDict,
                 entityName];
  else
    {
      EOGlobalID *gid = [entity globalIDForRow: pkDict];

      object = [self faultForGlobalID: gid
		     editingContext: self];
    }

  return object;
}

- (NSArray *)rawRowsForEntityNamed: (NSString *)entityName
		   qualifierFormat: (NSString *)format,...
{
  EOQualifier *qualifier;
  EOFetchSpecification *fetchSpec;
  NSArray *results;
  va_list args;
  
  va_start(args, format);
  qualifier = [EOQualifier qualifierWithQualifierFormat: format
			   varargList: args];
  va_end(args);

  NSAssert([entityName length] > 0, @"No entity name");

  fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:
				      entityName
                                    qualifier: qualifier
                                    sortOrderings: nil];
  [fetchSpec setFetchesRawRows: YES];

  results = [self objectsWithFetchSpecification: fetchSpec];

  return results;
}

- (NSArray *)rawRowsMatchingValue: (id)value
			   forKey: (NSString *)key
		      entityNamed: (NSString *)entityName
{
  NSDictionary *valueDict;
  NSArray *results;

  NSAssert([entityName length]>0,@"No entity name");

  if (!value)
    value=GDL2_EONull;

  valueDict = [NSDictionary dictionaryWithObject: value
                            forKey: key];
  results = [self rawRowsMatchingValues: valueDict
                  entityNamed: entityName];

  return results;
}

- (NSArray *)rawRowsMatchingValues: (NSDictionary *)values
		       entityNamed: (NSString *)entityName
{
  EOQualifier *qualifier;
  EOFetchSpecification *fetchSpec;
  NSArray *results;
  
  NSAssert([entityName length] > 0, @"No entity name");

  qualifier = [EOQualifier qualifierToMatchAllValues: values];
  fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:
				      entityName
                                    qualifier: qualifier
                                    sortOrderings: nil];
  [fetchSpec setFetchesRawRows: YES];

  results = [self objectsWithFetchSpecification: fetchSpec];

  return results;
}

- (NSArray *)rawRowsWithSQL: (NSString *)sqlString
		 modelNamed: (NSString *)name
{
  EODatabaseContext *databaseContext;
  EODatabaseChannel *databaseChannel;
  EOAdaptorChannel *adaptorChannel;
  NSMutableArray *results = nil;
  NSDictionary *row;
  
  databaseContext = [self databaseContextForModelNamed: name];

  [databaseContext lock];

  NS_DURING
    {
      databaseChannel = [databaseContext availableChannel];
      adaptorChannel = [databaseChannel adaptorChannel];

      if (![adaptorChannel isOpen])
        [adaptorChannel openChannel];
        
      [adaptorChannel evaluateExpression:
			[EOSQLExpression expressionForString: sqlString]];
      [adaptorChannel setAttributesToFetch:[adaptorChannel describeResults]];

      results = [NSMutableArray array];

      while ((row = [adaptorChannel fetchRowWithZone: [self zone]]))
        [results addObject: row];

      [databaseContext unlock];
    }
  NS_HANDLER
    {
      [databaseContext unlock];
      [localException raise];
    }
  NS_ENDHANDLER;

  return results;
}

- (NSArray *)rawRowsWithStoredProcedureNamed: (NSString *)name
				   arguments: (NSDictionary *)args
{
  EODatabaseContext *databaseContext;
  EODatabaseChannel *databaseChannel;
  EOAdaptorChannel *adaptorChannel;
  EOStoredProcedure *storedProcedure;
  NSMutableArray *results;
  NSDictionary *row;
  
  storedProcedure = [[self modelGroup] storedProcedureNamed: name];
  databaseContext = [self databaseContextForModelNamed:
			    [[storedProcedure model] name]];
  [databaseContext lock];

  NS_DURING
    {
      databaseChannel = [databaseContext availableChannel];
      adaptorChannel = [databaseChannel adaptorChannel];

      if (![adaptorChannel isOpen])
        [adaptorChannel openChannel];
        
      [adaptorChannel executeStoredProcedure: storedProcedure
		      withValues: args];
      [adaptorChannel setAttributesToFetch: [adaptorChannel describeResults]];

      results = [NSMutableArray array];

      while ((row = [adaptorChannel fetchRowWithZone: [self zone]])) 
        [results addObject: row];

      [databaseContext unlock];
    }
  NS_HANDLER
    {
      [databaseContext unlock];
      [localException raise];
    }
  NS_ENDHANDLER;

  return results;
}

- (NSDictionary *)executeStoredProcedureNamed: (NSString *)name
				    arguments: (NSDictionary *)args
{
  EODatabaseContext *databaseContext;
  EODatabaseChannel *databaseChannel;
  EOAdaptorChannel *adaptorChannel;
  EOStoredProcedure *storedProcedure;
  NSDictionary *returnValues = nil;
  
  storedProcedure = [[self modelGroup] storedProcedureNamed: name];
  databaseContext = [self databaseContextForModelNamed:
			    [[storedProcedure model] name]];
  [databaseContext lock];

  NS_DURING
    {
      databaseChannel = [databaseContext availableChannel];
      adaptorChannel = [databaseChannel adaptorChannel];

      if (![adaptorChannel isOpen]) 
        [adaptorChannel openChannel];
        
      [adaptorChannel executeStoredProcedure: storedProcedure
                      withValues: args];
      returnValues = [adaptorChannel
		       returnValuesForLastStoredProcedureInvocation];

      [databaseContext unlock];
    }
  NS_HANDLER
    {
      [databaseContext unlock];
      [localException raise];
    }
  NS_ENDHANDLER;

  return returnValues;
}

- (id)objectFromRawRow: (NSDictionary *)row
	   entityNamed: (NSString *)entityName
{
  NSAssert([entityName length] > 0, @"No entity name");

  return [self faultForRawRow: row
               entityNamed: entityName];
}

- (EODatabaseContext *)databaseContextForModelNamed: (NSString *)name
{
  EOModelGroup *modelGroup;
  EOModel *model;
  EODatabaseContext *databaseContext;
  
  modelGroup = [self modelGroup];
  model = [modelGroup modelNamed: name];

  if ( !model )
    [NSException raise: NSInvalidArgumentException
                 format: @"%@: cannot find model named %@ associated with this EOEditingContext", 
                 NSStringFromSelector(_cmd), 
                 name];

  databaseContext = [EODatabaseContext registeredDatabaseContextForModel: model
                                       editingContext: self];

  return databaseContext;
}

- (void)connectWithModelNamed: (NSString *)name
connectionDictionaryOverrides: (NSDictionary *)overrides
{
  EOModel *model;

  model = [[self modelGroup] modelNamed: name];

  [self notImplemented: _cmd];
}


- (id)createAndInsertInstanceOfEntityNamed: (NSString *)entityName
{
  id object;
  EOClassDescription *classDescription;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  classDescription = [EOClassDescription classDescriptionForEntityName:
					   entityName];

  if (!classDescription)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ could not find class description for entity named %@",
                 NSStringFromSelector(_cmd),
                 entityName];

  object = [classDescription createInstanceWithEditingContext: self
                             globalID: nil
                             zone: [self zone]];
  [self insertObject: object];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return object;
}

- (NSDictionary *)primaryKeyForObject: (id)object
{
  EOKeyGlobalID *gid;
  EOEntity *entity;
  NSDictionary *newDict;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  gid = (EOKeyGlobalID *)[self globalIDForObject: object];
  entity = [self entityForObject: object];

  newDict = [entity primaryKeyForGlobalID: gid];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return newDict;
}

- (NSDictionary *)destinationKeyForSourceObject: (id)object
			      relationshipNamed: (NSString*)name
{
  EODatabaseContext *databaseContext;
  EODatabase *database;
  EOEntity *sourceEntity;
  EORelationship *relationship;
  NSArray *joins;
  EOJoin *join;
  NSString *sourceAttributeName;
  NSString *destinationAttributeName;
  NSDictionary *snapshot;
  NSMutableDictionary *result = nil;
  int i, count;
  
  sourceEntity = [self entityForObject: object];
  relationship = [sourceEntity relationshipNamed: name];

  if (!relationship)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@: entity %@ does not have relationship named %@",
                 NSStringFromSelector(_cmd),
                 [sourceEntity name],
                 name];

  databaseContext = [self databaseContextForModelNamed:
			    [[sourceEntity model] name]];
  [databaseContext lock];

  NS_DURING
    {
      database = [databaseContext database];
      snapshot = [database snapshotForGlobalID:[self globalIDForObject:
						       object]];
      joins = [relationship joins];
      count = [joins count];
      result = (NSMutableDictionary *)[NSMutableDictionary dictionary];

      for (i = 0 ; i < count ; i++)
        {
          join = [joins objectAtIndex: i];
          sourceAttributeName = [[join sourceAttribute] name];
          destinationAttributeName = [[join destinationAttribute] name];

          [result setObject: [snapshot objectForKey: sourceAttributeName] 
                  forKey: destinationAttributeName];
        }

      [databaseContext unlock];
    }
  NS_HANDLER
    {
      [databaseContext unlock];
      [localException raise];
    }
  NS_ENDHANDLER;

  return result;
}

- (id)localInstanceOfObject: (id)object
{
  EOGlobalID *gid;
  id	newInstance;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  gid = [[object editingContext] globalIDForObject:object];
  
  newInstance = [self faultForGlobalID: gid
                      editingContext: self];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return newInstance;
}

- (NSArray *)localInstancesOfObjects: (NSArray *)objects
{
  NSMutableArray *array;
  int i, count = [objects count];
  id obj;
  
  EOFLOGObjectFnStartOrCond(@"EOEditingContext");
  
  array = [NSMutableArray arrayWithCapacity: count];

  for (i = 0; i < count; i++)
    {
      obj = [self localInstanceOfObject: [objects objectAtIndex: i]];
      [array addObject: obj];
    }
  
  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return array;
}

- (EOModelGroup *)modelGroup
{
  EOObjectStore *rootObjectStore;
  EOObjectStoreCoordinator *objectStoreCoordinator;
  EOModelGroup *modelGroup;
  
  EOFLOGObjectFnStartOrCond(@"EOEditingContext");
  
  rootObjectStore = [self rootObjectStore];

  if (![rootObjectStore isKindOfClass: [EOObjectStoreCoordinator class]])
    [NSException raise: NSInvalidArgumentException
		 format: @"%@: an EOEditingContext's root object store must be an EOObjectStoreCoordinator for this method to function.",
                 NSStringFromSelector(_cmd)];

  objectStoreCoordinator = (EOObjectStoreCoordinator *)rootObjectStore;
  modelGroup = [objectStoreCoordinator modelGroup];
  
  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return modelGroup;
}

- (EOEntity *)entityNamed: (NSString *)entityName
{
  EOEntity *entity;
  EOModelGroup *modelGroup;

  EOFLOGObjectFnStart();

  NSAssert([entityName length] > 0, @"No entity name");

  modelGroup = [self modelGroup];
  NSAssert(modelGroup, @"No model group");

  entity = [modelGroup entityNamed: entityName];

  if (!entity)
    [NSException raise: NSInvalidArgumentException
		 format: @"%@: could not find entity named:%@",
                 NSStringFromSelector(_cmd),
                 entityName];

  EOFLOGObjectFnStop();

  return entity;
}

- (EOEntity *)entityForClass: (Class)classObject
{
  EOModelGroup *modelGroup;
  NSArray *models;
  EOModel *model;
  int modelCount;
  NSArray *entities;
  EOEntity *entity;
  NSString *className;
  NSString *entityClassName;
  int i, j, entityCount;
  EOEntity *result = nil;
  BOOL matchesClassName;
  
  EOFLOGObjectFnStartOrCond(@"EOEditingContext");
  
  className = NSStringFromClass(classObject);

  modelGroup = [self modelGroup];
  models = [modelGroup models];
  modelCount = [models count];

  for (i = 0 ; i < modelCount ; i++)
    {
      model = [models objectAtIndex: i];
      entities = [model entities];
      entityCount = [entities count];

      for (j = 0 ; j < entityCount ; j++)
        {
          entity = [entities objectAtIndex: j];
          entityClassName = [entity className];
          matchesClassName = [className isEqualToString: entityClassName];

          // Java class names in the Objective-C run-time system use '/' instead of '.' to separate package names, so we also check for a class name in which we replaced '.' with '/'.

          if (!matchesClassName
	      && ([entityClassName rangeOfString:@"."].length != 0))
            matchesClassName = [className
				 isEqualToString:
				   [[entityClassName componentsSeparatedByString: @"."] 
				     componentsJoinedByString: @"/"]];

          if (matchesClassName)
            {
              if (result)
                [NSException raise: EOMoreThanOneException
                             format: @"%@ found more than one entity for class named %@", 
                             NSStringFromSelector(_cmd), 
                             className];
              else
                result = entity;
            }
        }
    }

  if (!result)
    [NSException raise: NSObjectNotAvailableException
                 format: @"%@ could not find entity for class named %@",
                 NSStringFromSelector(_cmd), className];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return result;
}

- (EOEntity *)entityForObject: (id)object
{
  EOClassDescription *classDesc;
  EOEntity *newEntity;

  EOFLOGObjectFnStartOrCond(@"EOEditingContext");

  classDesc = [(EOGenericRecord *)object classDescription];

  if ([classDesc isKindOfClass: [EOEntityClassDescription class]] == NO)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ - %@: the object's class description must be an EOEntityClassDescription", 
                 NSStringFromSelector(_cmd), 
                 object];

  newEntity = [(EOEntityClassDescription *)classDesc entity];

  EOFLOGObjectFnStopOrCond(@"EOEditingContext");

  return newEntity;
}

@end


@implementation EOFetchSpecification (EOAccess)

+ (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)name
                                      entityNamed: (NSString *)entityName
{
  EOFetchSpecification *newEOFetchSpecification = nil;
  EOModelGroup	       *anModelGroup;

  EOFLOGClassFnStartOrCond(@"EOFetchSpecification");

  anModelGroup = [EOModelGroup defaultGroup];

  if (anModelGroup)
    newEOFetchSpecification = [anModelGroup fetchSpecificationNamed: name
                                            entityNamed: entityName];

  EOFLOGObjectFnStopOrCond(@"EOFetchSpecification");

  return newEOFetchSpecification;
}

@end

