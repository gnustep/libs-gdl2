/* 
   EOModel.h

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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

#ifndef __EOModel_h__
#define __EOModel_h__


#import <Foundation/NSString.h>
#import <gnustep/base/GCObject.h>

#import <EOAccess/EOPropertyListEncoding.h>


@class NSArray;
@class NSDictionary;

@class EOEntity;
@class EOModelGroup;
@class EOStoredProcedure;


@interface EOModel : GCObject
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

  GCArray *_entities;
  GCMutableDictionary *_entitiesByName;
  GCMutableArray *_storedProcedures;
  GCMutableDictionary *_subEntitiesCache;
  //GCMutableDictionary *_prototypesByName;
  struct
  {
    BOOL createsMutableObjects:1;
    BOOL errors:1;
  } _flags;
}

+ (EOModel *)model;

/** Getting the filename **/
- (NSString*)path;

/** Getting the name **/
- (NSString *)name;
- (NSString *)adaptorName;
- (NSString *)adaptorClassName;

- (float)version;
+ (float)version;

/** Using entities **/
- (EOEntity *)entityNamed: (NSString*)name;
- (NSArray *)entities;
- (NSArray *)entityNames;

- (NSArray *)storedProcedureNames;
- (EOStoredProcedure *)storedProcedureNamed: (NSString *)name;
- (NSArray *)storedProcedures;

/** Getting an object's entity **/
- (EOEntity *)entityForObject: object;

/** Accessing the connection dictionary **/
- (NSDictionary *)connectionDictionary;

/** Accessing the user dictionary **/
- (NSDictionary *)userInfo;

/** Accessing documentation comments **/ 
- (NSString*)docComment;

- (EOModelGroup *)modelGroup;

@end

@interface EOModel (EOModelFileAccess)

+ (EOModel *)modelWithContentsOfFile: (NSString *)path;
- initWithContentsOfFile: (NSString *)path;
- (void)writeToFile: (NSString *)path;

@end

@interface EOModel (EOModelPropertyList) <EOPropertyListEncoding>

- (id) initWithTableOfContentsPropertyList: (NSDictionary *)tableOfContents
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
- (void)_classDescriptionNeeded: (id)param0;
- (id)_instantiatedEntities;
- (void)_setPath: (NSString *)path;
- (id)_entityForClass: (Class)param0;
- (id)_childrenForEntityNamed: (id)param0;
- (void)_registerChild: (id)param0
             forParent: (id)param1;
- (void)_setInheritanceLinks: (id)param0;
- (void)_removeEntity: (id)param0;
- (id)_addEntityWithPropertyList: (NSDictionary *)propertyList;
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
- (void)setUserInfo: (NSDictionary *)dictionary;

- (void)addEntity: (EOEntity *)entity;
- (void)removeEntity: (EOEntity *)entity;
- (void)removeEntityAndReferences: (EOEntity *)entity;

- (void)addStoredProcedure: (EOStoredProcedure *)storedProcedure;
- (void)removeStoredProcedure: (EOStoredProcedure *)storedProcedure;

- (void)setModelGroup: (EOModelGroup *)group;
- (void)loadAllModelObjects;

/* Checking references */
- (NSArray *)referencesToProperty: property; 
- (NSArray *)externalModelsReferenced;

@end

@interface EOModel (EOModelBeautifier)

- (void)beautifyNames;

@end

extern NSString *EOEntityLoadedNotification;

#endif /* __EOModel_h__ */
