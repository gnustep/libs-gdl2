/* -*-objc-*-
   EOModel.h

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOModel_h__
#define __EOModel_h__


#ifdef GNUSTEP
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOAccess/EODefines.h>
#include <EOAccess/EOPropertyListEncoding.h>

@class NSMutableArray;
@class NSArray;
@class NSDictionary;
@class NSNotification;

@class EOEntity;
@class EOAttribute;
@class EOModelGroup;
@class EOStoredProcedure;


@interface EOModel : NSObject
{
  NSString *_name;
  NSString *_path;
  NSString *_adaptorName;
  NSString *_adaptorClassName;
  float _version;
  NSDictionary *_connectionDictionary;
  NSDictionary *_userInfo;
  NSDictionary * _internalInfo;
  NSString *_docComment;
  void *_entitiesByClass;

  /* Garbage collectable objects */
  EOModelGroup *_group;

  NSArray *_entities;
  NSMutableDictionary *_entitiesByName;
  NSMutableArray *_storedProcedures;
  NSMutableDictionary *_subEntitiesCache;
  //NSMutableDictionary *_prototypesByName;
  struct
  {
    BOOL unused:1;
    BOOL errors:1;
  } _flags;
}

+ (EOModel *)model;

/** Getting the filename **/
- (NSString *)path;

/** Getting the name **/
- (NSString *)name;
- (NSString *)adaptorName;
- (NSString *)adaptorClassName;

/** Using entities **/
- (EOEntity *)entityNamed: (NSString *)name;
- (NSArray *)entities;
- (NSArray *)entityNames;

- (NSArray *)storedProcedureNames;
- (EOStoredProcedure *)storedProcedureNamed: (NSString *)name;
- (NSArray *)storedProcedures;

/** Getting an object's entity **/
- (EOEntity *)entityForObject: (id)object;

/** Accessing the connection dictionary **/
- (NSDictionary *)connectionDictionary;

/** Accessing the user dictionary **/
- (NSDictionary *)userInfo;

/** Accessing documentation comments **/ 
- (NSString *)docComment;

- (EOModelGroup *)modelGroup;

- (EOAttribute *)prototypeAttributeNamed: (NSString *)attributeName;

@end

@interface EOModel (EOModelFileAccess)

+ (EOModel *)modelWithContentsOfFile: (NSString *)path;
- (id)initWithContentsOfFile: (NSString *)path;
- (void)writeToFile: (NSString *)path;

@end

@interface EOModel (EOModelPropertyList) <EOPropertyListEncoding>

- (id)initWithTableOfContentsPropertyList: (NSDictionary *)tableOfContents
				     path: (NSString *)path;
- (void)encodeTableOfContentsIntoPropertyList: (NSMutableDictionary *)propertyList;

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList;
- (void)awakeWithPropertyList: (NSDictionary *)propertyList;
- (id)initWithPropertyList: (NSDictionary *)propertyList
                     owner: (id)owner;
@end

@interface EOModel (EOModelHidden)

- (void)_resetPrototypeCache;
- (BOOL)isPrototypesEntity: (id)param0;
- (NSMutableDictionary *) _loadFetchSpecificationDictionaryForEntityNamed:(NSString *) entName;
- (void)_classDescriptionNeeded: (NSNotification *)notification;
- (id)_instantiatedEntities;
- (void)_setPath: (NSString *)path;
- (EOEntity *)_entityForClass: (Class)aClass;
- (id)_childrenForEntityNamed: (id)param0;
- (void)_registerChild: (id)param0
             forParent: (id)param1;
- (void)_setInheritanceLinks: (id)param0;

/**
 * Before removing attributes we need to remove all references
 */

- (void) _removePropertiesReferencingProperty:(id) property;

- (void) _removePropertiesReferencingEntity:(EOEntity*) entity;
- (void)_removeEntity: (EOEntity *)entity;
- (EOEntity *)_addEntityWithPropertyList: (NSDictionary *)propertyList;
- (void)_addFakeEntityWithPropertyList: (NSDictionary *)propertyList;
- (id)_addEntity: (EOEntity *)entity;
- (void)_setEntity: (id)entity
     forEntityName: (NSString *)entityName
         className: (NSString *)className;
@end

@interface EOModel (EOModelEditing)

/* Accessing the adaptor bundle */
- (void)setName: (NSString *)name;
- (void)setAdaptorName: (NSString *)adaptorName;

- (void)setConnectionDictionary: (NSDictionary *)connectionDictionary;
- (void)setUserInfo: (NSDictionary *)userInfo;

- (void)addEntity: (EOEntity *)entity;
- (void)removeEntity: (EOEntity *)entity;
- (void)removeEntityAndReferences: (EOEntity *)entity;

- (void)addStoredProcedure: (EOStoredProcedure *)storedProcedure;
- (void)removeStoredProcedure: (EOStoredProcedure *)storedProcedure;

- (void)setModelGroup: (EOModelGroup *)group;
- (void)loadAllModelObjects;

/* Checking references */
- (NSArray *)referencesToProperty: (id)property; 
- (NSArray *)externalModelsReferenced;

@end

@interface EOModel (EOModelBeautifier)

- (void)beautifyNames;

@end

GDL2ACCESS_EXPORT NSString *EOEntityLoadedNotification;

#endif /* __EOModel_h__ */
