/* 
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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <gnustep/base/GCObject.h>

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

/** returns an autoreleased entity **/
+ (EOEntity *)entity;

/** returns an autoreleased entity owned by onwer and built from propertyList **/
+ (EOEntity *)entityWithPropertyList: (NSDictionary *)propertyList
                               owner: (id)owner;
- (NSString *)description;

/* Accessing the name */
- (NSString*)name;

/* Accessing the model */
- (EOModel*)model;

/* Accessing external information */
- (NSString*)externalName;

/* Accessing the external query */
- (NSString*)externalQuery;

/* Getting the qualifier */
- (EOQualifier *)restrictingQualifier;

- (BOOL)isQualifierForPrimaryKey: (EOQualifier *)qualifier;
- (EOQualifier *)qualifierForPrimaryKey: (NSDictionary *)row;

/* Accessing read-only status */
- (BOOL)isReadOnly;

- (BOOL)cachesObjects;

/* Accessing the enterprise object class */
- (NSString*)className; 

/* Accessing attributes */
- (EOAttribute *)attributeNamed: (NSString *)attributeName;
- (EOAttribute *)anyAttributeNamed: (NSString *)relationshipName;
- (NSArray *)attributes;

/* Accessing relationships */
- (EORelationship *)relationshipNamed: (NSString *)relationshipName;
- (EORelationship *)anyRelationshipNamed: (NSString *)relationshipName;
- (NSArray *)relationships;

/* Accessing class properties */
- (NSArray *)classProperties;
- (NSArray *)classPropertyNames;

- (NSArray *)fetchSpecificationNames;
- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)fetchSpecName;

/* Accessing primary key attributes */
- (NSArray *)primaryKeyAttributes;
- (NSArray *)primaryKeyAttributeNames;

/* Accessing locking attributes */
- (NSArray *)attributesUsedForLocking;
- (NSArray *)attributesToFetch;

/* Getting primary keys and snapshot for row */
- (NSDictionary *)primaryKeyForRow: (NSDictionary *)row;
- (BOOL)isValidAttributeUsedForLocking: (EOAttribute *)anAttribute;
- (BOOL)isValidPrimaryKeyAttribute: (EOAttribute *)anAttribute;
- (BOOL)isPrimaryKeyValidInObject: (id)object;
- (BOOL)isValidClassProperty: aProp;

/** Accessing the user dictionary **/
- (NSDictionary *)userInfo;

/** Accessing the documentation **/
- (NSString *)docComment;

- (NSArray *)subEntities;
- (EOEntity *)parentEntity;
- (BOOL)isAbstractEntity;


- (unsigned int)maxNumberOfInstancesToBatchFetch;
- (BOOL)isPrototypeEntity;

@end

@interface EOEntity (EOKeyGlobalID)
- (EOGlobalID *)globalIDForRow: (NSDictionary *)row;
- (id) globalIDForRow: (NSDictionary*)row
              isFinal: (BOOL)isFinal;
- (NSDictionary *)primaryKeyForGlobalID: (EOKeyGlobalID *)gid;
- (Class)classForObjectWithGlobalID: (EOKeyGlobalID*)globalID;
@end


@interface EOEntity (EOEntityEditing)

- (BOOL)setClassProperties: (NSArray*)properties;
- (BOOL)setPrimaryKeyAttributes: (NSArray*)keys;
- (BOOL)setAttributesUsedForLocking: (NSArray*)attributes;
- (NSException *)validateName: (NSString *) name;
- (void)setName: (NSString*)name;
- (void)setExternalName: (NSString*)name;
- (void)setExternalQuery: (NSString*)query;
- (void)setRestrictingQualifier: (EOQualifier *)qualifier;
- (void)setReadOnly: (BOOL)flag;
- (void)setCachesObjects: (BOOL)yn;

- (void)addAttribute: (EOAttribute *)attribute;
- (void)removeAttribute: (EOAttribute *)attribute;

- (void)addRelationship: (EORelationship *)relationship;
- (void)removeRelationship: (EORelationship *)relationship;

- (void)addFetchSpecification: (EOFetchSpecification *)fetchSpec
                        named: (NSString *)name;
- (void)removeFetchSpecificationNamed: (NSString *)name;

- (void)setClassName: (NSString*)name;
- (void)setUserInfo: (NSDictionary*)dictionary;
- (void) _setInternalInfo: (NSDictionary*)dictionary;
- (void) setDocComment:(NSString *)docComment;

- (void)addSubEntity: (EOEntity *)child;
- (void)removeSubEntity: (EOEntity *)child;

- (void)setIsAbstractEntity: (BOOL)f;
- (void)setMaxNumberOfInstancesToBatchFetch: (unsigned int)size;

@end


@interface EOEntity (EOModelReferentialIntegrity)

- (BOOL)referencesProperty:property;
- (NSArray *)externalModelsReferenced;

@end

@interface EOEntity (EOModelBeautifier)

- (void)beautifyName;

@end

GDL2ACCESS_EXPORT NSString *EOFetchAllProcedureOperation;
GDL2ACCESS_EXPORT NSString *EOFetchWithPrimaryKeyProcedureOperation;
GDL2ACCESS_EXPORT NSString *EOInsertProcedureOperation;
GDL2ACCESS_EXPORT NSString *EODeleteProcedureOperation;
GDL2ACCESS_EXPORT NSString *EONextPrimaryKeyProcedureOperation;

@interface EOEntity (MethodSet11)
- (NSException *)validateObjectForDelete: (id)object;
- (id) classPropertyAttributeNames;
- (id) classPropertyToManyRelationshipNames;
- (id) classPropertyToOneRelationshipNames;
- (id) qualifierForDBSnapshot: (id)param0;
- (EOAttribute*) attributeForPath: (NSString*)path;
- (EORelationship*) relationshipForPath: (NSString*)path;
- (void) _addAttributesToFetchForRelationshipPath: (NSString*)path
                                             atts: (NSMutableDictionary*)atts;
- (id) dbSnapshotKeys;
- (NSArray*) flattenedAttributes;
@end

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

@interface EOEntity (EOEntityHidden)
- (NSDictionary*)attributesByName;
- (NSDictionary*)relationshipsByName;
- (NSArray*) _allFetchSpecifications;
- (NSDictionary*) _fetchSpecificationDictionary;
- (void) _loadEntity;
- (id) parentRelationship;
- (int) _numberOfRelationships;
- (BOOL) _hasReadOnlyAttributes;
- (NSArray*) writableDBSnapshotKeys;
- (NSArray*) rootAttributesUsedForLocking;
- (BOOL) isSubEntityOf:(id)param0;
- (id) initObject: (id)param0
   editingContext: (id)param1
         globalID: (id)param2;
- (id) allocBiggestObjectWithZone:(NSZone*)zone;
- (Class) _biggestClass;
- (NSArray*) relationshipsPlist;
- (id) rootParent;
- (void) _setParent: (id)param0;
- (NSArray*) _hiddenRelationships;
- (NSArray*) _propertyNames;
- (id) _flattenAttribute: (id)param0
        relationshipPath: (id)param1
       currentAttributes: (id)param2;
- (NSString*) snapshotKeyForAttributeName: (NSString*)attributeName;
- (id) _flattenedAttNameToSnapshotKeyMapping;
- (EOMKKDSubsetMapping*) _snapshotToAdaptorRowSubsetMapping;
- (EOMutableKnownKeyDictionary*) _dictionaryForPrimaryKey;
- (EOMutableKnownKeyDictionary*) _dictionaryForProperties;
- (NSArray*) _relationshipsToFaultForRow: (NSDictionary*)row;
- (NSArray*) _classPropertyAttributes;
- (NSArray*) _attributesToSave;
- (NSArray*) _attributesToFetch;
- (EOMKKDInitializer*) _adaptorDictionaryInitializer;
- (EOMKKDInitializer*) _snapshotDictionaryInitializer;
- (EOMKKDInitializer*) _primaryKeyDictionaryInitializer;
- (EOMKKDInitializer*) _propertyDictionaryInitializer;
- (void) _setModel: (EOModel*)model;
- (void) _setIsEdited;
- (NSArray*) _classPropertyAttributes;
@end

@interface EOEntityClassDescription:EOClassDescription
{
    EOEntity *_entity;
    unsigned int extraRefCount;
}

/** returns an autoreleased entity class description for entity entity **/
+ (EOEntityClassDescription*)entityClassDescriptionWithEntity: (EOEntity *)entity;

/** initialize with entity **/
- initWithEntity: (EOEntity *)entity;

/** returns entity **/
- (EOEntity *)entity;

@end

@interface NSString (EODatabaseNameConversion)

+ (NSString *)nameForExternalName: (NSString *)externalName
                  separatorString: (NSString *)separatorString
                      initialCaps: (BOOL)initialCaps;
+ (NSString *)externalNameForInternalName: (NSString *)internalName
                          separatorString: (NSString *)separatorString
                               useAllCaps: (BOOL)allCaps;

@end

#endif /* __EOEntity_h__ */
