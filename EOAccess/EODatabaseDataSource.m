/** 
   EODatabaseDataSource.m <title>EODatabaseDataSource Class</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

static char rcsId[] = "$Id$";

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>

#import <EOAccess/EODatabaseDataSource.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EOModel.h>
#import <EOAccess/EOModelGroup.h>
#import <EOAccess/EODatabase.h>
#import <EOAccess/EODatabaseContext.h>

#import <EOControl/EOEditingContext.h>
#import <EOControl/EOQualifier.h>
#import <EOControl/EOFetchSpecification.h>
#import <EOControl/EOKeyValueArchiver.h>
#import <EOControl/EODataSource.h>
#import <EOControl/EODetailDataSource.h>


@implementation EODatabaseDataSource

- initWithEditingContext: (EOEditingContext *)editingContext
	      entityName: (NSString *)entityName
{
  return [self initWithEditingContext: editingContext
	       entityName: entityName
	       fetchSpecificationName: nil];
}

- initWithEditingContext: (EOEditingContext *)editingContext
	      entityName: (NSString *)entityName
  fetchSpecificationName: (NSString *)fetchName
{
  NSArray *stores;
  EODatabaseContext *store = nil;
  NSEnumerator *storeEnum;
  EOModel *model;
  EOEntity *entity = nil;
  id rootStore;

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
      
      ASSIGN(_fetchSpecification, [entity fetchSpecificationNamed:fetchName]);
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
  return [[[self databaseContext] database]
	   entityNamed: [_fetchSpecification entityName]];
}

- (EODatabaseContext *)databaseContext
{
  NSArray *stores = nil;
  EODatabaseContext *store = nil;
  NSEnumerator *storeEnum = nil;
  NSString *entityName = nil;
  id rootStore = nil;

  entityName = [_fetchSpecification entityName];

  rootStore = [_editingContext rootObjectStore];
  if ([rootStore isKindOfClass: [EOObjectStoreCoordinator class]] == YES)
    {
      stores = [rootStore cooperatingObjectStores];

      storeEnum = [stores objectEnumerator];
      while ((store = [storeEnum nextObject]))
	{
	  if ([store isKindOfClass: [EODatabaseContext class]] == YES)
	    {
	      if ([[store database] entityNamed: entityName])
		break;
	    }
	}
    }
  else if ([rootStore isKindOfClass: [EODatabaseContext class]] == YES)
    {
      if ([[store database] entityNamed: entityName])
	store = rootStore;
    }

  return store;
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

- (void)insertObject: object
{
  [_editingContext insertObject: object];
}

- (void)deleteObject: object
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

- (EOEditingContext*)editingContext
{
  return _editingContext;
}

@end
