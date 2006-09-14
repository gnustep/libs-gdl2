/** 
   EODatabaseDataSource.m <title>EODatabaseDataSource Class</title>

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: July 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: December 2001

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
#include <Foundation/NSCoder.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOEditingContext.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOKeyValueArchiver.h>
#include <EOControl/EODataSource.h>
#include <EOControl/EODetailDataSource.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EODatabaseDataSource.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EODatabase.h>
#include <EOAccess/EODatabaseContext.h>
#include <EOAccess/EOPrivate.h>

@interface EODatabaseDataSource(Private)
- (id)_partialInitWithEditingContext: (EOEditingContext*)editingContext
                          entityName: (NSString*)entityName
              fetchSpecificationName: (NSString*)fetchSpecificationName;
@end


@implementation EODatabaseDataSource

- (id)initWithEditingContext: (EOEditingContext *)editingContext
		  entityName: (NSString *)entityName
{
  return [self initWithEditingContext: editingContext
	       entityName: entityName
	       fetchSpecificationName: nil];
}

- (id)initWithEditingContext: (EOEditingContext *)editingContext
		  entityName: (NSString *)entityName
      fetchSpecificationName: (NSString *)fetchName
{
  NSArray *stores;
  EODatabaseContext *store = nil;
  NSEnumerator *storeEnum;
  EOModel *model;
  EOEntity *entity = nil;
  id rootStore;
  EOFetchSpecification *fetchSpec;

  if ((self = [super init]))
    {
      ASSIGN(_editingContext, editingContext);
      rootStore = [_editingContext rootObjectStore];

      if ([rootStore isKindOfClass: [EOObjectStoreCoordinator class]] == YES)
        {
          stores = [rootStore cooperatingObjectStores];

          storeEnum = [stores objectEnumerator];
          while ((store = [storeEnum nextObject]))
            {
              if ([store isKindOfClass: [EODatabaseContext class]] == YES)
                {
                  if ((entity = [[store database] entityNamed: entityName]))
                    break;
                }
            }
          
          if (store == nil)
            {
              entity = [[EOModelGroup defaultGroup] entityNamed: entityName];
              model  = [entity model];
              
              store = [EODatabaseContext databaseContextWithDatabase:
					   [EODatabase databaseWithModel:
							 model]];

              [rootStore addCooperatingObjectStore: store];
            }
        }
      else if ([rootStore isKindOfClass: [EODatabaseContext class]] == YES)
        {
          if ((entity = [[store database] entityNamed: entityName]) == nil)
            [NSException raise: NSInvalidArgumentException
                         format: @"%@ -- %@ 0x%x: editingContext (%@) cannot handler entity named '%@'",
                         NSStringFromSelector(_cmd),
                         NSStringFromClass([self class]),
                         self,
                         editingContext,
                         entityName];
        }
      else
        [NSException raise: NSInvalidArgumentException
                     format: @"%@ -- %@ 0x%x: editingContext (%@) cannot handler entity named '%@'",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self,
                     editingContext,
                     entityName];

      fetchSpec = [entity fetchSpecificationNamed: fetchName];
      if (fetchSpec == nil)
	{
	  fetchSpec = [EOFetchSpecification 
			fetchSpecificationWithEntityName: entityName
			qualifier: nil
			sortOrderings: nil];
	}
      ASSIGN(_fetchSpecification, fetchSpec);
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_bindings);
  DESTROY(_auxiliaryQualifier);
  DESTROY(_fetchSpecification);
  DESTROY(_editingContext);

  [super dealloc];
}

- (NSString *)description
{
  return [NSString stringWithFormat:
		     @"<%s %p : entity name=%@ editingContext=%p fetchSpecification=%@>",
		   object_get_class_name(self),
		   (void *)self,
                   [[self entity]name],
                   _editingContext,
                   _fetchSpecification];
}

- (EOEntity *)entity
{
  EOObjectStore *store;
  NSString *entityName = [_fetchSpecification entityName];
  static SEL modelGroupSel = @selector(modelGroup);
  EOModelGroup *modelGroup = nil;
  
  store = [_editingContext rootObjectStore];
  
  if ([store isKindOfClass: [EOObjectStoreCoordinator class]])
    {
      return [[(EOObjectStoreCoordinator *)store modelGroup] entityNamed: entityName];
    }
  else if ([store isKindOfClass:GDL2_EODatabaseContextClass])
    {
      EODatabase *database = [(EODatabaseContext *)store database];
      NSArray *models = [database models];
      int i, c;
      
      for (i = 0, c = [models count]; i < c; i++)
	{
	  EOEntity *entity;
	  
	  modelGroup = [[models objectAtIndex: i] modelGroup];
	  entity = [modelGroup entityNamed: entityName];
	  if (entity)
	    return entity;
	}
      return nil;
    }
  else if ([store respondsToSelector:modelGroupSel])
    {
      modelGroup = [store performSelector:modelGroupSel];
    }
  
  if (modelGroup != nil)
    {
      return [modelGroup entityNamed: entityName];
    }
  else
    {
      return [[EOModelGroup defaultModelGroup] entityNamed: entityName];
    }
}

- (EODatabaseContext *)databaseContext
{
  EOModel *model;

  model = [[self entity] model];
  return [EODatabaseContext registeredDatabaseContextForModel:model
				editingContext:_editingContext];
}

- (void)setFetchSpecification: (EOFetchSpecification *)fetchSpecification
{
  ASSIGN(_fetchSpecification, fetchSpecification);
}

- (EOFetchSpecification *)fetchSpecification
{
  return _fetchSpecification;
}

- (void)setAuxiliaryQualifier: (EOQualifier *)qualifier
{
  ASSIGN(_auxiliaryQualifier, qualifier);//OK
}

- (EOQualifier *)auxiliaryQualifier
{
  return _auxiliaryQualifier;
}

- (EOFetchSpecification *)fetchSpecificationForFetch 
{
  EOFetchSpecification *fetch = nil;
  EOQualifier *qualifier = nil;

  EOFLOGObjectLevelArgs(@"EODataSource", @"_auxiliaryQualifier=%@",
			_auxiliaryQualifier);
  EOFLOGObjectLevelArgs(@"EODataSource", @"_bindings=%@", _bindings);
  EOFLOGObjectLevelArgs(@"EODataSource", @"_fetchSpecification=%@",
			_fetchSpecification);

  qualifier = [_auxiliaryQualifier
		qualifierWithBindings: _bindings
		requiresAllVariables: [_fetchSpecification
					requiresAllQualifierBindingVariables]]; //ret same ? 

  EOFLOGObjectLevelArgs(@"EODataSource", @"qualifier=%@", qualifier);

//call _fetchSpecification qualifier //ret nil //TODO
  fetch = [[_fetchSpecification copy] autorelease];

  EOFLOGObjectLevelArgs(@"EODataSource", @"fetch=%@", fetch);

  [fetch setQualifier:qualifier];
/*
  fetch = [_fetchSpecification copy];
  [fetch setQualifier:[[[EOAndQualifier alloc]
			 initWithQualifiers:[fetch qualifier],
			 _auxiliaryQualifier, nil] autorelease]];
*/

  EOFLOGObjectLevelArgs(@"EODataSource", @"fetch=%@", fetch);

  return fetch;
}

- (void)setFetchEnabled: (BOOL)flag
{
  _flags.fetchEnabled = flag;
}

- (BOOL)isFetchEnabled
{
  return _flags.fetchEnabled;
}

- (EODataSource *)dataSourceQualifiedByKey: (NSString *)detailKey
{
  return [EODetailDataSource detailDataSourceWithMasterDataSource: self 
                             detailKey: detailKey];
}

/**
 * Overrides superclasses implementation but doesn't do anything
 * useful.  You must insert the object into the editing context
 * manually.
 */
- (void)insertObject: (id)object
{

}

- (void)deleteObject: (id)object
{
  [_editingContext deleteObject: object];
}

- (NSArray *)fetchObjects
{
  NSArray *objects = nil;

  EOFLOGObjectLevelArgs(@"EODataSource", @"_editingContext=%@",
			_editingContext);
  NSAssert(_editingContext, @"No Editing Context");

//call [self isFetchEnabled];
  NS_DURING//For trace purpose
    {        
      objects = [_editingContext objectsWithFetchSpecification:
				   [self fetchSpecificationForFetch]];//OK
    }
  NS_HANDLER
    {
      NSLog(@"%@ (%@)", localException, [localException reason]);
      NSDebugMLog(@"%@ (%@)", localException, [localException reason]);
      [localException raise];
    }
  NS_ENDHANDLER;

  EOFLOGObjectLevelArgs(@"EODataSource", @"objects=%p", objects);
  EOFLOGObjectLevelArgs(@"EODataSource", @"objects count=%d", [objects count]);
  EOFLOGObjectLevelArgs(@"EODataSource", @"objects=%@", objects);

  return objects;
}

- (EOClassDescription *)classDescriptionForObjects
{
  return [[self entity] classDescriptionForInstances];
}

- (NSArray *)qualifierBindingKeys
{
  return [_bindings allKeys]; // TODO resolve all bindings question
}

- (void)setQualifierBindings: (NSDictionary *)bindings
{
  ASSIGN(_bindings, bindings);
}

- (NSDictionary *)qualifierBindings
{
  return _bindings;
}

- (id)initWithCoder: (NSCoder *)coder
{
  self = [super init];

  ASSIGN(_editingContext, [coder decodeObject]);
  ASSIGN(_fetchSpecification, [coder decodeObject]);
  ASSIGN(_auxiliaryQualifier, [coder decodeObject]);
  ASSIGN(_bindings, [coder decodeObject]);

  // TODO flags

  return self;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeObject:_editingContext];
  [coder encodeObject:_fetchSpecification];
  [coder encodeObject:_auxiliaryQualifier];
  [coder encodeObject:_bindings];

  // TODO flags
}

- (id)_partialInitWithEditingContext: (EOEditingContext*)editingContext
                          entityName: (NSString*)entityName
              fetchSpecificationName: (NSString*)fetchSpecificationName
{
  if ((self = [self initWithEditingContext: editingContext
		    entityName: entityName
		    fetchSpecificationName: nil]))
    {
      //turbocat ASSIGN(_editingContext,editingContext);
      ASSIGN(_fetchSpecification, [EOFetchSpecification new]);
      [_fetchSpecification setEntityName: entityName];
    }

  return self;
}

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver
{
  NSString *entityName = nil;
  EOFetchSpecification *fetchSpecification = nil;
  EOQualifier *auxiliaryQualifier = nil;
  EOEditingContext *editingContext = nil;
  NSString *fetchSpecificationName = nil;

  EOFLOGObjectFnStart();

  entityName = [unarchiver decodeObjectForKey: @"entityName"];
  EOFLOGObjectLevelArgs(@"EODataSource",@"entityName=%@",entityName);

  fetchSpecification = [unarchiver decodeObjectForKey: @"fetchSpecification"];
  EOFLOGObjectLevelArgs(@"EODataSource", @"fetchSpecification=%@",
			fetchSpecification);

  auxiliaryQualifier = [unarchiver decodeObjectForKey: @"auxiliaryQualifier"];
  EOFLOGObjectLevelArgs(@"EODataSource", @"auxiliaryQualifier=%@",
			auxiliaryQualifier);

  editingContext = [unarchiver decodeObjectReferenceForKey: @"editingContext"];
  EOFLOGObjectLevelArgs(@"EODataSource", @"editingContext=%@", editingContext);

  fetchSpecificationName = [unarchiver decodeObjectForKey:
					 @"fetchSpecificationName"];
  EOFLOGObjectLevelArgs(@"EODataSource", @"fetchSpecificationName=%@",
			fetchSpecificationName);

  if (!entityName)
    {
      entityName = [fetchSpecification entityName];
      EOFLOGObjectLevelArgs(@"EODataSource", @"entityName=%@", entityName);
    }

  if ((self = [self _partialInitWithEditingContext: editingContext
		    entityName: entityName
		    fetchSpecificationName: fetchSpecificationName]))
    {
      [self setFetchSpecification: fetchSpecification];
    }

  return self;
}

- (void) encodeWithKeyValueArchiver: (EOKeyValueUnarchiver *)archiver
{
  [self notImplemented: _cmd];
}

- (EOEditingContext*)editingContext
{
  return _editingContext;
}

@end
