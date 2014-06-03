/** 
   EODatabaseChannel.m <title>EODatabaseChannel</title>

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#endif

#include <EOControl/EOEditingContext.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOObjectStore.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EODatabaseChannel.h>
#include <EOAccess/EODatabaseContext.h>
#include <EOAccess/EODatabaseContextPriv.h>
#include <EOAccess/EODatabase.h>

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOAccessFault.h>
#include <EOAccess/EOSQLExpression.h>
#include <EOAccess/EOSQLExpressionFactory.h>
#include <EOAccess/EOSQLQualifier.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"
#include "EODatabaseContextPriv.h"
#include "EODatabaseChannelPriv.h"

@implementation EODatabaseChannel

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;
      GDL2_EOAccessPrivateInit();
      [[NSNotificationCenter defaultCenter]
        addObserver: self
        selector: @selector(_registerDatabaseChannel:)
        name: EODatabaseChannelNeededNotification
        object: nil];
    }
}

+ (void)_registerDatabaseChannel: (NSNotification *)notification
{
  // TODO who release it ?
  [[EODatabaseChannel alloc] initWithDatabaseContext: [notification object]];
}

+ (EODatabaseChannel*)databaseChannelWithDatabaseContext: (EODatabaseContext *)databaseContext
{
  return [[[self alloc] initWithDatabaseContext: databaseContext] autorelease];
}

- (id) init
{
  [NSException raise: NSInvalidArgumentException
              format: @"Use initWithDatabaseContext to init an instance of class %@",
                      NSStringFromClass([self class])];
  
  return nil;
}

- (id) initWithDatabaseContext:(EODatabaseContext *)databaseContext
{
  if ((self = [super init]))
    {
      ASSIGN(_adaptorChannel, [[databaseContext adaptorContext]
				createAdaptorChannel]);
      
      if (!_adaptorChannel)
      {
        [NSException raise: NSInternalInconsistencyException
                    format: @"EODatabaseChannel is unable to obtain new channel from %@",
                            [databaseContext adaptorContext]];      
      } else {
        ASSIGN(_databaseContext, databaseContext);
      }
    }

  return self;
}

- (void)dealloc
{
  [_databaseContext unregisterChannel: self];

  DESTROY(_databaseContext);
  [_adaptorChannel closeChannel];

  DESTROY(_adaptorChannel);
  DESTROY(_currentEntity);
  DESTROY(_currentEditingContext);
  DESTROY(_fetchProperties);
  DESTROY(_fetchSpecifications);
  DESTROY(_refreshedGIDs);

  [super dealloc];
}

//MG2014: OK
- (void)setCurrentEntity: (EOEntity *)entity
{
  if (entity != _currentEntity)
    {
      DESTROY(_fetchProperties);
      ASSIGN(_currentEntity, entity);
      [self setEntity: entity];
    }
}

//MG2014: OK
- (void) setEntity: (EOEntity *)entity
{
  NSArray *relationships = [entity relationships];
  NSUInteger relCount = [relationships count];
  if (relCount>0)
    {
      Class databaseContextClass=[[self databaseContext] class];
      NSUInteger i=0;
      for(i=0;i<relCount;i++)
	{
	  EORelationship* relationship = [relationships objectAtIndex:i];
	  EOModel* model = [[relationship destinationEntity] model];
	  if ([[relationship entity]model] != model)
	    {
	      [databaseContextClass registeredDatabaseContextForModel:model
				    editingContext:[self currentEditingContext]];
	    }
	}
    }
}

//MG2014: OK
- (void)setCurrentEditingContext: (EOEditingContext*)context
{
  ASSIGN(_currentEditingContext,context);
  if(_currentEditingContext != nil)
    {
      _currentEditingContextTimestamp = [_currentEditingContext fetchTimestamp];
      [(EOObjectStoreCoordinator*)[_currentEditingContext rootObjectStore] 
				  addCooperatingObjectStore:[self databaseContext]];
    }
}

- (void)selectObjectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
			     editingContext: (EOEditingContext *)context
{
  //should be OK
  NSString *entityName = nil;
  EODatabase *database = nil;
  EOEntity *entity = nil;
  EOQualifier *qualifier = nil;
  EOQualifier *schemaBasedQualifier = nil;



  entityName = [fetchSpecification entityName];
  database = [_databaseContext database];

  EOFLOGObjectLevelArgs(@"gsdb", @"database=%@", database);

  entity = [database entityNamed: entityName];

  EOFLOGObjectLevelArgs(@"gsdb", @"entity name=%@", [entity name]);

  qualifier=[fetchSpecification qualifier];

  EOFLOGObjectLevelArgs(@"gsdb", @"qualifier=%@", qualifier);

  schemaBasedQualifier =
    [(id<EOQualifierSQLGeneration>)qualifier
				   schemaBasedQualifierWithRootEntity: entity];

  EOFLOGObjectLevelArgs(@"gsdb", @"schemaBasedQualifier=%@", schemaBasedQualifier);
  EOFLOGObjectLevelArgs(@"gsdb", @"qualifier=%@", qualifier);

  if (schemaBasedQualifier && schemaBasedQualifier != qualifier)
    {
      EOFetchSpecification *newFetch = nil;

      EOFLOGObjectLevelArgs(@"gsdb", @"fetchSpecification=%@", fetchSpecification);
      //howto avoid copy of uncopiable qualifiers (i.e. those who contains uncopiable key or value)

      EOFLOGObjectLevelArgs(@"gsdb", @"fetchSpecification=%@", fetchSpecification);

      newFetch = [[fetchSpecification copy] autorelease];
      EOFLOGObjectLevelArgs(@"gsdb", @"newFetch=%@", newFetch);

      [newFetch setQualifier: schemaBasedQualifier];
      EOFLOGObjectLevelArgs(@"gsdb", @"newFetch=%@", newFetch);

      fetchSpecification = newFetch;
    }

  EOFLOGObjectLevelArgs(@"gsdb", @"%@ -- %@ 0x%x: isFetchInProgress=%s",
	       NSStringFromSelector(_cmd),
	       NSStringFromClass([self class]),
	       self,
	       ([self isFetchInProgress] ? "YES" : "NO"));

  [self _selectWithFetchSpecification:fetchSpecification
        editingContext:context];

  [database setTimestampToNow];
}

//MG2014: OK
- (id)fetchObject
{
  EODatabase* database=[_databaseContext database];
  id object = nil;
  
  if (![self isFetchInProgress])
    {
      //Exception or just return nil ?
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ -- %@ 0x%p: no fetch in progress",
		   NSStringFromSelector(_cmd),
		   NSStringFromClass([self class]),
		   self];      
    }
  else
    {
      NSDictionary *row =nil;
      EOEntity* entity = nil;
      
      NSAssert(_currentEditingContext, @"No current editing context");
      NSAssert(_adaptorChannel,@"No adaptor channel");
      
      [self _propertiesToFetch];
    
      for (row = [_adaptorChannel fetchRowWithZone: NULL]; row == nil;)
	{
	  if (_fetchSpecifications != nil)
	    {
	      [self _cancelInternalFetch];
	      [self _selectWithFetchSpecification:nil
		    editingContext:_currentEditingContext];
	      [self _propertiesToFetch];
	      row = [_adaptorChannel fetchRowWithZone: NULL];
	    }
	  else
	    {
	      _isLocking = NO;
	      return nil; // End
	    }
	}
      NSLog(@"MG-OXYMIUM-TMP %s:%d row=%@",__PRETTY_FUNCTION__,__LINE__,row);
      
      if (_isFetchingSingleTableEntity)
	{
	  entity = [_currentEntity _singleTableSubEntityForRow:row];
	  if (entity == nil)
	    {
	      [NSException raise: @"NSIllegalStateException"
			   format: @"%s Unable to determine subentity of '%@' for row: %@. Check that the attribute '%@' is marked as a class property in the EOModel and that the value satisfies some subentity's restricting qualifier.",
			   __PRETTY_FUNCTION__,
			   [_currentEntity name],
			   row,
			   [_currentEntity _singleTableSubEntityKey]];
	    }
	}
      else
	{
	  entity = _currentEntity;
	}
      EOKeyGlobalID* gid = (EOKeyGlobalID*)[entity _globalIDForRow:row
						   isFinal:YES];
      if (gid == nil)
	{
	  [NSException raise: @"NSIllegalStateException"
		       format: @"%s Cannot determine primary key for entity '%@' from row: %@",
		       __PRETTY_FUNCTION__,
		       [_currentEntity name],
		       row];
	}
      else
	{
	  NSDictionary* dbxSnapshot = nil;
	  NSDictionary* snapshot = nil;
	  NSDictionary* newSnapshot = nil;
	  BOOL  respondsTo_shouldUpdateCurrentSnapshot = [_databaseContext _respondsTo_shouldUpdateCurrentSnapshot];
	  object = [_currentEditingContext objectForGlobalID:gid];
	  NSLog(@"MG-OXYMIUM-TMP %s:%d gid=%@ object=%@",__PRETTY_FUNCTION__,__LINE__,gid,object);

	  snapshot = [database snapshotForGlobalID:gid
			       after: (respondsTo_shouldUpdateCurrentSnapshot ? 
				       EODistantPastTimeInterval : _currentEditingContextTimestamp)];
	  NSLog(@"MG-OXYMIUM-TMP %s:%d gid=%@ snapshot=%@",__PRETTY_FUNCTION__,__LINE__,gid,snapshot);
	  if (snapshot != nil)
	    {
	      if (respondsTo_shouldUpdateCurrentSnapshot
		  && (newSnapshot = [_databaseContext _shouldUpdateCurrentSnapshot:snapshot
						      newSnapshot:row 
						      globalID: gid
						      databaseChannel:self])!=nil)
                {
		  NSLog(@"MG-OXYMIUM-TMP %s:%d gid=%@ newSnapshot=%@",__PRETTY_FUNCTION__,__LINE__,gid,newSnapshot);
		  if (newSnapshot != snapshot)
		    {
		      snapshot = newSnapshot;
		      [database recordSnapshot:snapshot
				forGlobalID:gid];
		    }
		  else
                    {
		      newSnapshot = nil;
                    }
                }
	      else if ((_isLocking || _isRefreshingObjects)
		       && ![_databaseContext isObjectLockedWithGlobalID:gid]
		       && ![snapshot isEqual:row])
                {
		  if(_isLocking && !_isRefreshingObjects)
		    {
		      [NSException raise: @"NSIllegalStateException"
				   format: @"%s attempt to lock object that has out of date snapshot: %@",
				   __PRETTY_FUNCTION__,
				   gid];
		    }
		  NSLog(@"MG-OXYMIUM-TMP %s:%d gid=%@ row=%@",__PRETTY_FUNCTION__,__LINE__,gid,row);
		  snapshot = newSnapshot = row;
		  [database recordSnapshot:snapshot
			    forGlobalID:gid];
                }
	      dbxSnapshot = snapshot;
            }
	  else
            {
	      NSDictionary* aSnapshot = [database snapshotForGlobalID:gid];
	      NSLog(@"MG-OXYMIUM-TMP %s:%d gid=%@ aSnapshot=%@",__PRETTY_FUNCTION__,__LINE__,gid,aSnapshot);
	      [database recordSnapshot:row
			forGlobalID:gid];
	      if (aSnapshot != nil
		  && ![aSnapshot isEqualToDictionary:row])
		newSnapshot = row;
	      dbxSnapshot = row;
            }

	  if (_isLocking)
	    [_databaseContext registerLockedObjectWithGlobalID:gid];

	  if (newSnapshot != nil)
            {
	      if (_refreshedGIDs == nil)
		_refreshedGIDs = [NSMutableArray new];
	      [_refreshedGIDs addObject:gid];
            }
	  if (object != nil
	      && !_isFault(object))
	    {
	      return object; //End
	    }
	  else
	    {
	      if (object == nil
		  && newSnapshot != nil)
		{
		  object = [_currentEditingContext faultForGlobalID:gid
					    editingContext:_currentEditingContext];
		  return object; // End
		}
	      else
		{
		  if (object == nil)
		    {
		      EOClassDescription *entityClassDescripton = [entity classDescriptionForInstances];
		      
		      object = [entityClassDescripton createInstanceWithEditingContext: _currentEditingContext
						      globalID: gid
						      zone: NULL];
		      [_currentEditingContext recordObject:object
					      globalID: gid];
		    }
		  else
		    {
		      EOAccessFaultHandler* handler = 
			(EOAccessFaultHandler *)[EOFault handlerForFault: object];
		      if ([(EOKeyGlobalID*)[handler globalID] isFinal])
			{
			  [EOFault clearFault: object];
			}
		      else
			{
			  [EOFault clearFault: object];
			  [entity initObject:object
				  editingContext:_currentEditingContext
				  globalID:gid];
			}
		    }
		  [EOObserverCenter suppressObserverNotification];
		  NS_DURING
		    {          
		      ASSIGN(_databaseContext->_lastEntity,entity);
		      //TODO
		      /*
		      _databaseContext->_currentGlobalID = gid;
		      _databaseContext->_currentSnapshot = dbxSnapshot;
		      */
		      [_currentEditingContext initializeObject:object
					      withGlobalID: gid
					      editingContext: _currentEditingContext];
		      //TODO
		      /*
		      _databaseContext->_currentGlobalID = nil;
		      */
		    }
		  NS_HANDLER
		    {
		      [EOObserverCenter enableObserverNotification];
		      [localException raise];
		    }
		  NS_ENDHANDLER;
	      
		  [EOObserverCenter enableObserverNotification];
		  [object awakeFromFetchInEditingContext:_currentEditingContext];
		}
	    }
	}
    }
  return object;
}

- (BOOL)isFetchInProgress
{
  return [_adaptorChannel isFetchInProgress];
}

//MG2014: Near OK (See TODO)
- (void)cancelFetch
{
  [self _cancelInternalFetch];

  if (_fetchSpecifications != nil)
    DESTROY(_fetchSpecifications);

  [self _cancelInternalFetch];

  if (_refreshedGIDs != nil)
    {
      IMP oaiIMP=NULL;
      EOEditingContext* editingContext = _currentEditingContext;
      NSMutableArray* refreshedGIDs = _refreshedGIDs;
      EODatabase* database = [_databaseContext database];
      NSUInteger  refreshedGIDsCount = [refreshedGIDs count];
      NSUInteger i=0;
      _refreshedGIDs = nil;

      for(i=0; i<refreshedGIDsCount; i++)
	[database incrementSnapshotCountForGlobalID:GDL2_ObjectAtIndexWithImpPtr(refreshedGIDs,&oaiIMP,i)];

      
      [editingContext lock];
      NS_DURING
	{          
	  [[NSNotificationCenter defaultCenter]
	    postNotificationName: @"EOObjectsChangedInStoreNotification"
	    object: _databaseContext
	    userInfo: [NSDictionary dictionaryWithObject:refreshedGIDs
				    forKey:@"updated"]];
	  for(i=0; i<refreshedGIDsCount; i++)
	    {
	      EOKeyGlobalID* gid = GDL2_ObjectAtIndexWithImpPtr(refreshedGIDs,&oaiIMP,i);
	      //TODO [[editingContext objectForGlobalID:gid] willRead];
	      [database decrementSnapshotCountForGlobalID:gid];
	    }
	}
      NS_HANDLER
	{
	  [editingContext unlock];	
	  DESTROY(refreshedGIDs);//was retained as _refreshedGIDs
	  [localException raise];
	}
      NS_ENDHANDLER;

      [editingContext unlock];	
      DESTROY(refreshedGIDs);//was retained as _refreshedGIDs
    }  
}

- (EODatabaseContext *)databaseContext
{
  return _databaseContext;
}

- (EOAdaptorChannel *)adaptorChannel
{
  return _adaptorChannel;
}

- (BOOL)isRefreshingObjects
{
  return _isRefreshingObjects;
}

- (void)setIsRefreshingObjects: (BOOL)yn
{
  _isRefreshingObjects = yn;
}

- (BOOL)isLocking
{
  return _isLocking;
}

- (void)setIsLocking: (BOOL)isLocking
{
  _isLocking = isLocking;
}

@end

@implementation EODatabaseChannel (EODatabaseChannelPrivate)
- (NSArray*) _propertiesToFetch
{
  //OK
  NSArray *attributesToFetch=nil;
  if(_currentEntity == nil)
    attributesToFetch= [_adaptorChannel describeResults];
  else
    attributesToFetch = [_currentEntity _attributesToFetch];

  return attributesToFetch;
}

-(void)_setCurrentEntityAndRelationshipWithFetchSpecification: (EOFetchSpecification *)fetch
{
  //OK
  NSString *entityName = [fetch entityName];
  EODatabase *database = [_databaseContext database];
  EOEntity *entity = [database entityNamed: entityName];

  NSAssert1(entity, @"No Entity named %@", entityName);

  [self setCurrentEntity: entity];
}

- (void) _buildNodeList:(id) param0
             withParent:(id) param1
{
  //TODO
  [self notImplemented: _cmd];
}

- (id) currentEditingContext
{
  return _currentEditingContext;
}

//MG2014: OK
- (void) _cancelInternalFetch
{
  if ([_adaptorChannel isFetchInProgress])
    [_adaptorChannel cancelFetch];
}

//MG2014: OK
- (void) _closeChannel
{
  [_adaptorChannel closeChannel];
}

//MG2014: OK
- (void) _openChannel
{
  if (![_adaptorChannel isOpen])
    [_adaptorChannel openChannel];
}

- (void)_selectWithFetchSpecification: (EOFetchSpecification *)fetchSpec
		       editingContext: (EOEditingContext *)editingContext
{
  EOSQLExpression* sqlExpression = nil;
  _isFetchingSingleTableEntity = NO;

  if (_fetchSpecifications != nil)
    {
      fetchSpec = [_fetchSpecifications lastObject];
      [_fetchSpecifications removeLastObject];
      [self setCurrentEntity:[[_databaseContext database]entityNamed:[fetchSpec entityName]]];
      _isFetchingSingleTableEntity = [_currentEntity _isSingleTableEntity];
      if ([_fetchSpecifications count] == 0)
	DESTROY(_fetchSpecifications);
    }
  else
    {
      if (fetchSpec == nil)
	{
	  [NSException raise: @"NSIllegalArgumentException"
		       format:@"%s invoked with nil fetchSpecification",
		       __PRETTY_FUNCTION__];
	}
      else
	{
	  NSDictionary* hints = [fetchSpec hints];
	  id customQueryExpressionHint = [hints objectForKey:@"EOCustomQueryExpressionHintKey"];
	  if (customQueryExpressionHint != nil)
	    {
	      if ([customQueryExpressionHint isKindOfClass:[NSString class]])
		{
		  sqlExpression = [[[[_databaseContext adaptorContext]adaptor]
				       expressionFactory]
				      expressionForString:customQueryExpressionHint];
		}
	      else
		sqlExpression = (EOSQLExpression*)customQueryExpressionHint;
	    }
	  [self setCurrentEditingContext:editingContext];
	  [self _setCurrentEntityAndRelationshipWithFetchSpecification:fetchSpec];

	  if ([fetchSpec isDeep]
	      && sqlExpression == nil)
            {
	      _isFetchingSingleTableEntity = [_currentEntity _isSingleTableEntity];
	      if (!_isFetchingSingleTableEntity
		  && [[_currentEntity subEntities]count]>0)
                {
		  NSMutableArray* nodes = [NSMutableArray array];
		  NSUInteger nodesCount = 0;		  
		  [self _buildNodeList:nodes
			withParent:_currentEntity];
		  nodesCount = [nodes count];
		  ASSIGN(_fetchSpecifications,([NSMutableArray arrayWithCapacity:nodesCount]));
		  if (nodesCount>0)
		    {
		      NSUInteger i=0;
		      for(i=0;i<nodesCount;i++)
			{
			  EOFetchSpecification* aFetchSpec = AUTORELEASE([fetchSpec copy]);
			  [aFetchSpec setEntityName:[nodes objectAtIndex:i]];
			  [_fetchSpecifications addObject:aFetchSpec];
			}
		    }
		  
		  [self _selectWithFetchSpecification:nil
			editingContext:editingContext];
		  return; //Finished !
                }
            }
        }
    }
  NSArray* propertiesToFetch = [self _propertiesToFetch];

  if ([_databaseContext _performShouldSelectObjectsWithFetchSpecification:fetchSpec
			databaseChannel:self])
    {
      _isLocking = [_databaseContext _usesPessimisticLockingWithFetchSpecification:fetchSpec
				     databaseChannel:self];
      _isRefreshingObjects = [fetchSpec refreshesRefetchedObjects];

      if(_isLocking
	 && ![[_adaptorChannel adaptorContext] hasOpenTransaction])
	{
	  [[_adaptorChannel adaptorContext] beginTransaction];
	}

      if ([[_currentEntity primaryKeyAttributes]count]==0)
	{
	  [NSException raise: @"NSIllegalStateException"
		       format:@"%s attempt to select EOs from entity '%@' which has no primary key defined. All entities must have a primary key specified. You should run the EOModeler consistency checker on the model containing this entity and perform whatever actions are necessary to ensure that the model is in a consistent state.",
		       __PRETTY_FUNCTION__,
		       [_currentEntity name]];
	}
      else
	{
	  NSDictionary* hints = [fetchSpec hints];
	  EOStoredProcedure* storedProcedure = nil;
	  NSString* storedProcedureName = [hints objectForKey:@"EOStoredProcedureNameHintKey"];
	  if (storedProcedureName != nil)
	    {
	      storedProcedure = [[[_currentEntity model]modelGroup]storedProcedureNamed:storedProcedureName];
	    }
	  if(storedProcedure != nil)
	    {
	      [_adaptorChannel executeStoredProcedure:storedProcedure
			       withValues:nil];
	      [_adaptorChannel setAttributesToFetch:propertiesToFetch];
	    }
	  else if(sqlExpression != nil)
	    {
	      [_adaptorChannel evaluateExpression:sqlExpression];
	      [_adaptorChannel setAttributesToFetch:propertiesToFetch];
	    }
	  else
	    {
	      EOQualifier* qualifier = [fetchSpec qualifier];
	      if (qualifier == nil
		  && (storedProcedure = [_currentEntity storedProcedureForOperation:@"EOFetchAllProcedure"]) != nil)
		{
		  [_adaptorChannel executeStoredProcedure:storedProcedure
				   withValues:nil];
		  [_adaptorChannel setAttributesToFetch:propertiesToFetch];
		}
	      else
		{
		  storedProcedure = [_currentEntity storedProcedureForOperation:@"EOFetchWithPrimaryKeyProcedure"];
		  if (qualifier != nil
		      && storedProcedure != nil
		      && [_currentEntity isQualifierForPrimaryKey:qualifier])
		    {
		      NSMutableDictionary* keyValues = nil;
		      if ([qualifier isKindOfClass:[EOKeyValueQualifier class]])
			{
			  keyValues = [NSMutableDictionary dictionaryWithObject:[(EOKeyValueQualifier*)qualifier value]
							   forKey:[(EOKeyValueQualifier*)qualifier key]];
			}
		      else
			{
			  NSArray* qualifiers = [(EOAndQualifier*)qualifier qualifiers];
			  NSUInteger qualifiersCount = [qualifiers count];
			  NSUInteger i = 0;
			  keyValues = [NSMutableDictionary dictionaryWithCapacity:qualifiersCount];
			  for (i=0;i<qualifiersCount;i++)
			    {
			      EOKeyValueQualifier* kvQualifier = [qualifiers objectAtIndex:i];
			      [keyValues setObject:[kvQualifier value]
					 forKey:[kvQualifier key]];
			    }
			  
			}
		      [_adaptorChannel executeStoredProcedure:storedProcedure
				       withValues:keyValues];
		      [_adaptorChannel setAttributesToFetch:propertiesToFetch];
		    }
		  else
		    {
		      [_adaptorChannel selectAttributes: propertiesToFetch
				       fetchSpecification: fetchSpec
				       lock: _isLocking
				       entity: _currentEntity];

		    }
		}
	    }
	  [_databaseContext _performDidSelectObjectsWithFetchSpecification:fetchSpec
			    databaseChannel:self];
	}
    }
}

@end /* EODatabaseChannel */
