/* -*-objc-*-
   EOEntity.h

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#ifndef __EOEntity_h__
#define __EOEntity_h__

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <GNUstepBase/GCObject.h>

#include <EOControl/EOClassDescription.h>

#include <EOAccess/EODefines.h>
#include <EOAccess/EOPropertyListEncoding.h>


@class EOModel;
@class EOAttribute;
@class EOQualifier;
@class EORelationship;
@class EOEntity;
@class EOStoredProcedure;
@class EOKeyGlobalID;


@class EOFetchSpecification;
@class EOGlobalID;

@class EOMutableKnownKeyDictionary;
@class EOMKKDInitializer;
@class EOMKKDSubsetMapping;


@interface EOEntity : GCObject <EOPropertyListEncoding>
{
  NSString *_name;
  NSString *_className;
  NSString *_externalName;
  NSString *_externalQuery;
  NSDictionary *_userInfo;
  NSString* _docComment;
  NSDictionary * _internalInfo;
  EOQualifier *_restrictingQualifier;
  NSMutableDictionary *_fetchSpecificationDictionary;
  NSArray *_fetchSpecificationNames;
  NSMutableDictionary *_storedProcedures;

  NSArray *_classPropertyNames;
  NSArray *_primaryKeyAttributeNames;
  NSArray *_classPropertyAttributeNames;
  NSArray *_classPropertyToOneRelationshipNames;
  NSArray *_classPropertyToManyRelationshipNames;
  EOClassDescription *_classDescription;
  NSMutableArray *_hiddenRelationships;
  unsigned int _batchCount;
  EOMKKDInitializer* _adaptorDictionaryInitializer;
  EOMKKDInitializer* _snapshotDictionaryInitializer;
  EOMKKDInitializer* _primaryKeyDictionaryInitializer;
  EOMKKDInitializer* _propertyDictionaryInitializer;
  EOMKKDInitializer* _instanceDictionaryInitializer;
  EOMKKDSubsetMapping* _snapshotToAdaptorRowSubsetMapping;

  Class _classForInstances;

  /* Garbage collectable objects */
  EOModel *_model;
  GCMutableArray *_attributes;
  GCMutableDictionary *_attributesByName;
  GCMutableArray *_relationships;
  GCMutableDictionary *_relationshipsByName;	  // name/EORelationship
  GCMutableArray *_primaryKeyAttributes;
  GCMutableArray *_classProperties; 	  // EOAttribute/EORelationship
  GCMutableArray *_attributesUsedForLocking;
  GCMutableArray *_attributesToFetch;
  GCMutableArray *_attributesToSave;
  GCMutableArray *_propertiesToFault;
  GCArray* _dbSnapshotKeys;

  GCMutableArray *_subEntities;
  EOEntity *_parent;

  struct {
    unsigned int attributesIsLazy:1;
    unsigned int relationshipsIsLazy:1;
    unsigned int classPropertiesIsLazy:1;
    unsigned int primaryKeyAttributesIsLazy:1;
    unsigned int attributesUsedForLockingIsLazy:1;
            
    unsigned int isReadOnly:1;
    unsigned int isAbstractEntity:1;
    unsigned int updating:1;
    unsigned int cachesObjects:1;

    unsigned int createsMutableObjects:1;

    unsigned int extraRefCount:22;
  } _flags;
}

- (NSString *)name;
- (EOModel *)model;

- (NSString *)externalName;
- (NSString *)externalQuery;

- (EOQualifier *)restrictingQualifier; /* see also: EOEntityEditing */

/* Caching */
- (BOOL)isReadOnly;
- (BOOL)cachesObjects;

/* EOClass name */
- (NSString *)className; 

- (NSDictionary *)userInfo;

/* Accessing attributes */
- (NSArray *)attributes;
- (EOAttribute *)attributeNamed: (NSString *)attributeName;
- (EOAttribute *)anyAttributeNamed: (NSString *)relationshipName;

/* Accessing relationships */
- (NSArray *)relationships;
- (EORelationship *)relationshipNamed: (NSString *)relationshipName;
- (EORelationship *)anyRelationshipNamed: (NSString *)relationshipName;

/* Accessing class properties */
- (NSArray *)classProperties;
- (NSArray *)classPropertyNames;

- (NSArray *)fetchSpecificationNames;
- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)fetchSpecName;
- (NSArray *)sharedObjectFetchSpecificationNames;

/* Accessing primary key attributes */
- (NSArray *)primaryKeyAttributes;
- (NSArray *)primaryKeyAttributeNames;

/* Accessing locking attributes */
- (NSArray *)attributesUsedForLocking;
- (NSArray *)attributesToFetch;

/* Getting primary keys and snapshot for row */
- (EOQualifier *)qualifierForPrimaryKey: (NSDictionary *)row;
- (BOOL)isQualifierForPrimaryKey: (EOQualifier *)qualifier;
- (NSDictionary *)primaryKeyForRow: (NSDictionary *)row;
- (BOOL)isValidAttributeUsedForLocking: (EOAttribute *)attribute;
- (BOOL)isValidPrimaryKeyAttribute: (EOAttribute *)attribute;
- (BOOL)isPrimaryKeyValidInObject: (id)object;
- (BOOL)isValidClassProperty: (id)property;

- (NSArray *)subEntities;
- (EOEntity *)parentEntity;
- (BOOL)isAbstractEntity;

- (unsigned int)maxNumberOfInstancesToBatchFetch;

- (EOGlobalID *)globalIDForRow: (NSDictionary *)row;
- (NSDictionary *)primaryKeyForGlobalID: (EOKeyGlobalID *)gid;
@end

@interface EOEntity (EOEntityEditing)

- (void)setName: (NSString *)name;
- (void)setExternalName: (NSString *)name;
- (void)setExternalQuery: (NSString *)query;
- (void)setRestrictingQualifier: (EOQualifier *)qualifier;
- (void)setReadOnly: (BOOL)flag;
- (void)setCachesObjects: (BOOL)flag;

- (void)addAttribute: (EOAttribute *)attribute;
- (void)removeAttribute: (EOAttribute *)attribute;

- (void)addRelationship: (EORelationship *)relationship;
- (void)removeRelationship: (EORelationship *)relationship;

- (void)addFetchSpecification: (EOFetchSpecification *)fetchSpec
                     withName: (NSString *)name;
- (void)removeFetchSpecificationNamed: (NSString *)name;

- (void)setSharedObjectFetchSpecificationsByName: (NSArray *)names;
- (void)addSharedObjectFetchSpecificationByName: (NSString *)name;
- (void)removeSharedObjectFetchSpecificationByName: (NSString *)name;

- (void)setClassName: (NSString *)name;
- (void)setUserInfo: (NSDictionary *)dictionary;

- (BOOL)setClassProperties: (NSArray *)properties;
- (BOOL)setPrimaryKeyAttributes: (NSArray *)keys;
- (BOOL)setAttributesUsedForLocking: (NSArray *)attributes;

- (NSException *)validateName: (NSString *)name;

- (void)addSubEntity: (EOEntity *)child;
- (void)removeSubEntity: (EOEntity *)child;

- (void)setIsAbstractEntity: (BOOL)flag;
- (void)setMaxNumberOfInstancesToBatchFetch: (unsigned int)size;

@end

@interface EOEntity (EOModelReferentialIntegrity)

- (BOOL)referencesProperty: (id)property;
- (NSArray *)externalModelsReferenced;

@end

@interface EOEntity (EOModelBeautifier)

- (void)beautifyName;

@end

@interface EOEntity (GDL2Extenstions)

- (NSString *)docComment;
- (void)setDocComment: (NSString *)docComment;

@end

GDL2ACCESS_EXPORT NSString *EOFetchAllProcedureOperation;
GDL2ACCESS_EXPORT NSString *EOFetchWithPrimaryKeyProcedureOperation;
GDL2ACCESS_EXPORT NSString *EOInsertProcedureOperation;
GDL2ACCESS_EXPORT NSString *EODeleteProcedureOperation;
GDL2ACCESS_EXPORT NSString *EONextPrimaryKeyProcedureOperation;

@interface EOEntity (EOStoredProcedures)

- (EOStoredProcedure *)storedProcedureForOperation: (NSString *)operation;
- (void)setStoredProcedure: (EOStoredProcedure *)storedProcedure
              forOperation: (NSString *)operation;

@end

@interface EOEntity (EOPrimaryKeyGeneration)

- (NSString *)primaryKeyRootName;

@end

@interface EOEntity (EOEntityClassDescription)

- (EOClassDescription *)classDescriptionForInstances;

@end

/** Useful  private methods made public in GDL2 **/
@interface EOEntity (EOEntityGDL2Additions)

/** Returns attribute (if any) for path **/
- (EOAttribute *)attributeForPath: (NSString *)path;

/** Returns relationship (if any) for path **/
- (EORelationship *)relationshipForPath: (NSString *)path;
@end

@interface EOEntityClassDescription : EOClassDescription
{
  EOEntity *_entity;
  unsigned int extraRefCount;
}

- (id)initWithEntity: (EOEntity *)entity;
- (EOEntity *)entity;
- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)name;
@end

@interface EOEntityClassDescription (GDL2Extenstions)
/** returns a new autoreleased mutable dictionary to store properties 
returns nil if there's no key in the instanceDictionaryInitializer
**/
- (EOMutableKnownKeyDictionary *)dictionaryForInstanceProperties;
@end

@interface NSString (EODatabaseNameConversion)

+ (NSString *)nameForExternalName: (NSString *)externalName
                  separatorString: (NSString *)separatorString
                      initialCaps: (BOOL)initialCaps;
+ (NSString *)externalNameForInternalName: (NSString *)internalName
                          separatorString: (NSString *)separatorString
                               useAllCaps: (BOOL)allCaps;

@end

@interface NSObject (EOEntity)
/** should returns an array of property names to exclude from entity 
instanceDictionaryInitializer **/
+ (NSArray *)_instanceDictionaryInitializerExcludedPropertyNames;
@end

#endif /* __EOEntity_h__ */
