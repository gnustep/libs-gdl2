/** 
   EOModelGroup.m <title>EOModelGroup Class</title>

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: June 2000

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

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSBundle.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOStoredProcedure.h>

#include <EOControl/EODebug.h>


@implementation EOModelGroup


NSString *EOModelAddedNotification = @"EOModelAddedNotification";
NSString *EOModelInvalidatedNotification = @"EOModelInvalidatedNotification";


static id classDelegate = nil;
static int delegateDefaultModelGroup = 0;
static EOModelGroup *defaultModelGroup = nil;
static EOModelGroup *globalModelGroup = nil;


+ (EOModelGroup *)defaultGroup
{
  EOModelGroup *modelGroup = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"defaultModelGroup=%p",defaultModelGroup);

  if (defaultModelGroup)
    modelGroup = defaultModelGroup;
  else if (delegateDefaultModelGroup)
    modelGroup = [classDelegate defaultModelGroup];
  else
    modelGroup = [EOModelGroup globalModelGroup];

  if (!modelGroup)
    {
      NSLog(@"WARNING: No default Group");
    }

  NSDebugMLLog(@"gsdb", @"modelGroup=%p",modelGroup);

  EOFLOGObjectFnStop();

  return modelGroup;
}

+ (void)setDefaultGroup: (EOModelGroup *)group
{
  NSDebugMLLog(@"gsdb", @"group=%p defaultModelGroup=%p",
               group,defaultModelGroup);

  if (group != defaultModelGroup)
    {
      if (defaultModelGroup)
        DESTROY(defaultModelGroup);

      if (delegateDefaultModelGroup)
        group = [classDelegate defaultModelGroup];

      ASSIGN(defaultModelGroup, group);
    }
}

+ (EOModelGroup *)globalModelGroup
{
  EOFLOGObjectFnStart();

  if (globalModelGroup == nil)
    {
      NSMutableArray *bundles = [NSMutableArray arrayWithCapacity: 2];
      NSBundle *bundle = nil;
      NSMutableArray *paths = nil;
      NSEnumerator *pathsEnum = nil;
      NSEnumerator *bundleEnum = nil;
      NSString *path = nil;
      id tmp;

      globalModelGroup = [EOModelGroup new];

      NSDebugMLLog(@"gsdb", @"globalModelGroup=%p",globalModelGroup);
      
      [bundles addObjectsFromArray: [NSBundle allBundles]];
      [bundles addObjectsFromArray: [NSBundle allFrameworks]];

      bundleEnum = [bundles objectEnumerator];
      while ((bundle = [bundleEnum nextObject]))
	{
	  paths = (id)[NSMutableArray array];
	  tmp = [bundle pathsForResourcesOfType: @"eomodeld"
			inDirectory: nil];
	  [paths addObjectsFromArray: tmp];
	  tmp = [bundle pathsForResourcesOfType: @"eomodel"
			inDirectory: nil];
	  [paths addObjectsFromArray: tmp];

	  if (!paths)
	    {
	      NSLog(@"WARNING: paths for resource of type eomodeld"
		    @" in bundle %@",bundle);
	    }

	  pathsEnum = [paths objectEnumerator];
	  while ((path = [pathsEnum nextObject]))
	    {
	      [globalModelGroup addModelWithFile: path];
	    }
	}
    }

  EOFLOGObjectFnStop();

  return globalModelGroup;
}

/** returns a model group composed of all models in the resource directory
of the mainBundle, and all bundles and frameworks loaded into the app.
**/

+ (void)setDelegate: (id)delegate
{
  classDelegate = delegate;

  delegateDefaultModelGroup = [delegate respondsToSelector:
					  @selector(defaultModelGroup)];
}

+ (id)delegate
{
  return classDelegate;
}


- init
{
  if ((self = [super init]))
    {
      NSDebugMLLog(@"gsdb", @"model group=%p",self);

      _modelsByName = [NSMutableDictionary new];
    };
  return self;
}

- (void)dealloc
{
  DESTROY(_modelsByName);

  [super dealloc];
}

- (NSArray *)models
{
  return [_modelsByName allValues];
}

- (NSArray *)modelNames
{
  return [_modelsByName allKeys];
}

- (EOModel *)modelNamed: (NSString *)name
{
  return [_modelsByName objectForKey: name];
}

- (EOModel *)modelWithPath: (NSString *)path
{
  NSEnumerator *modelEnum;
  EOModel *model;

  modelEnum = [_modelsByName objectEnumerator];
  while ((model = [modelEnum nextObject]))
    if ([[path stringByStandardizingPath]
	  isEqual: [[model path] stringByStandardizingPath]] == YES)
      return model;

  return nil;
}

- (void)addModel: (EOModel *)model
{
  //OK
  //call model entityNames
  NSString *modelName;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"model=%p", model);

  modelName = [model name];
  [model setModelGroup: self];

  NSDebugMLLog(@"gsdb", @"model=%p name=%@", model, modelName);

  if (!modelName) 
    {
      [NSException raise: NSInvalidArgumentException
                   format: [NSString stringWithFormat:
				       @"The model name is emtpy"]];
    }

  NSAssert1(modelName, @"No name for model %@", model);

  if ([_modelsByName objectForKey: modelName]) 
    {
      [NSException raise: NSInvalidArgumentException
                   format: [NSString stringWithFormat: @"The modelname '%@' already exists in modelGroup",
				     modelName]];
    }

  [_modelsByName setObject: model
                 forKey: modelName];

  NSDebugMLLog(@"gsdb", @"Notification for model:%p", model);

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOModelAddedNotification
    object: model];

  EOFLOGObjectFnStop();
}

- (EOModel *)addModelWithFile: (NSString *)path
{
  EOModel *model;

  EOFLOGObjectFnStart();

  model = [EOModel modelWithContentsOfFile: path];

  NSDebugMLLog(@"gsdb", @"model=%p", model);

  if (model)
    [self addModel: model];

  EOFLOGObjectFnStop();

  return model;
}

- (void)removeModel: (EOModel *)model
{
  [_modelsByName removeObjectForKey: [model name]];
  [model setModelGroup: nil];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EOModelInvalidatedNotification
    object: model];
}

- (EOEntity *)entityNamed: (NSString *)entityName
{
  NSEnumerator *modelEnum;
  EOModel *model;
  EOEntity *entity;

  modelEnum = [_modelsByName objectEnumerator];
  while ((model = [modelEnum nextObject]))
    if ((entity = [model entityNamed: entityName]))
      return entity;

  return nil;
}

- (EOEntity *)entityForObject: (id)object
{
  NSEnumerator *modelEnum;
  EOModel *model;
  EOEntity *entity;

  modelEnum = [_modelsByName objectEnumerator];
  while ((model = [modelEnum nextObject]))
    if ((entity = [model entityForObject: object]))
      return entity;

  return nil;
}

- (NSArray *)availablePrototypesForAdaptorName: (NSString *)adaptorName
{
  [self notImplemented: _cmd];
  return nil;
}

- (EOAttribute *)prototypeAttributeForAttribute: (EOAttribute *)attribute
{
  [self notImplemented: _cmd];
  return nil;
}

- (void)loadAllModelObjects
{
  NSEnumerator *modelEnum;
  EOModel *model;

  modelEnum = [_modelsByName objectEnumerator];
  while ((model = [modelEnum nextObject]))
    [model loadAllModelObjects];
}

- (id)delegate
{
  return _delegate;
}

- (void)setDelegate: (id)delegate
{
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOModelGroup");

  ASSIGN(_delegate, delegate);

  _delegateRespondsTo.entityNamed =
    [_delegate respondsToSelector: @selector(modelGroup:entityNamed:)];
  _delegateRespondsTo.failedToLookupClassNamed =
    [_delegate respondsToSelector: @selector(entity:failedToLookupClassNamed:)];
  _delegateRespondsTo.classForObjectWithGlobalID =
    [_delegate respondsToSelector: @selector(entity:classForObjectWithGlobalID:)];
  _delegateRespondsTo.subEntityForEntity =
    [_delegate respondsToSelector: @selector(subEntityForEntity:primaryKey:isFinal:)];
  _delegateRespondsTo.relationshipForRow =
    [_delegate respondsToSelector: @selector(entity:relationshipForRow:relationship:)];
  
  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOModelGroup");
}

- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)fetchSpecName 
                                      entityNamed: (NSString *)entityName
{
  EOFetchSpecification *newFetchSpecification = nil;
  EOEntity             *anEntity;
  
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOModelGroup");

  if (fetchSpecName
      && entityName && (anEntity = [self entityNamed: entityName]))
    {
      newFetchSpecification = [anEntity fetchSpecificationNamed: fetchSpecName];
    }
  
  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOModelGroup");

  return newFetchSpecification;
}

- (EOStoredProcedure *)storedProcedureNamed: (NSString *)name
{
  EOStoredProcedure *newStoredProcedure = nil;
  NSEnumerator      *modelEnum;
  EOModel           *model;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOModelGroup");
  
  modelEnum = [_modelsByName objectEnumerator];
  while ((model = [modelEnum nextObject])) 
    {
      if ((newStoredProcedure = [model storedProcedureNamed: name])) 
        {
          EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOModelGroup");

          return newStoredProcedure;
        }
    }
  
  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOModelGroup");
  
  return nil;
}

@end

@implementation EOObjectStoreCoordinator (EOModelGroup)

- (EOModelGroup *)modelGroup
{
  //Seems OK
  EOModelGroup *modelGroup;
  NSDictionary *userInfo;

  EOFLOGObjectFnStart();

  userInfo = [self userInfo];
  modelGroup = [userInfo objectForKey: @"EOModelGroup"];

  if (!modelGroup)
    {
      modelGroup = [EOModelGroup defaultGroup];
      [self setModelGroup: modelGroup];
    }

  EOFLOGObjectFnStop();

  return modelGroup;
}

- (void)setModelGroup: (EOModelGroup *)modelGroup
{
  NSMutableDictionary *userInfo;

  EOFLOGObjectFnStart();

  userInfo = (NSMutableDictionary *)[self userInfo];

  if (userInfo)
    [userInfo setObject: modelGroup
              forKey: @"EOModelGroup"];
  else
    {
      userInfo = (id)[NSMutableDictionary dictionary];

      [userInfo setObject: modelGroup
                forKey: @"EOModelGroup"];
      [self setUserInfo: userInfo];
    }

  EOFLOGObjectFnStop();
}

@end

