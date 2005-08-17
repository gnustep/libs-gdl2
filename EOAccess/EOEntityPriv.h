/* -*-objc-*-
   EOEntityPriv.h

   Copyright (C) 2000,2002,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: July 2000

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
*/

#ifndef __EOEntityPriv_h__
#define __EOEntityPriv_h__


@class NSString;

@class EORelationship;
@class EOExpressionArray;


@interface EOEntity (EOEntityPrivate)

- (BOOL)isPrototypeEntity;

- (void)setCreateMutableObjects: (BOOL)flag;
- (BOOL)createsMutableObjects;

- (void)_setModel: (EOModel *)model;
- (void)setParentEntity: (EOEntity *)parent;

-(Class)_classForInstances;
- (void)_setInternalInfo: (NSDictionary *)dictionary;

- (NSDictionary *)attributesByName;
- (NSDictionary *)relationshipsByName;
- (NSArray *)_allFetchSpecifications;
- (NSDictionary *)_fetchSpecificationDictionary;
- (void)_loadEntity;
- (id)parentRelationship;
- (int)_numberOfRelationships;
- (BOOL)_hasReadOnlyAttributes;
- (NSArray *)writableDBSnapshotKeys;
- (NSArray *)rootAttributesUsedForLocking;
- (BOOL)isSubEntityOf: (id)param0;
- (id)initObject: (id)param0
  editingContext: (id)param1
	globalID: (id)param2;
- (id)allocBiggestObjectWithZone: (NSZone *)zone;
- (Class)_biggestClass;
- (NSArray *)relationshipsPlist;
- (id)rootParent;
- (void)_setParent: (id)param0;
- (NSArray *)_hiddenRelationships;
- (NSArray *)_propertyNames;
- (id)_flattenAttribute: (id)param0
       relationshipPath: (id)param1
      currentAttributes: (id)param2;
- (NSString *)snapshotKeyForAttributeName: (NSString *)attributeName;
- (id)_flattenedAttNameToSnapshotKeyMapping;
- (EOMKKDSubsetMapping *)_snapshotToAdaptorRowSubsetMapping;
- (EOMutableKnownKeyDictionary *)_dictionaryForPrimaryKey;
- (EOMutableKnownKeyDictionary *)_dictionaryForProperties;
- (EOMutableKnownKeyDictionary *)_dictionaryForInstanceProperties;
- (NSArray *)_relationshipsToFaultForRow: (NSDictionary *)row;
- (NSArray *)_classPropertyAttributes;
- (NSArray *)_attributesToSave;
- (NSArray *)_attributesToFetch;
- (EOMKKDInitializer *)_adaptorDictionaryInitializer;
- (EOMKKDInitializer *)_snapshotDictionaryInitializer;
- (EOMKKDInitializer *)_primaryKeyDictionaryInitializer;
- (EOMKKDInitializer *)_propertyDictionaryInitializer;
- (EOMKKDInitializer *)_instanceDictionaryInitializer;
- (void)_setIsEdited;
- (void)_attributeNameChangedFrom: (NSString *)oldName to: (NSString *)newName;
- (NSArray *)_classPropertyAttributes;

- (Class)classForObjectWithGlobalID: (EOKeyGlobalID *)globalID;
- (id)globalIDForRow: (NSDictionary *)row
	     isFinal: (BOOL)isFinal;
@end

@interface EOEntity (EOEntityRelationshipPrivate)
- (EORelationship *)_inverseRelationshipPathForPath: (NSString *)path;
- (id)_keyMapForRelationshipPath: (NSString *)path;
- (id)_keyMapForIdenticalKeyRelationshipPath: (id)param0;
- (id)_mapAttribute: (id)param0
toDestinationAttributeInLastComponentOfRelationshipPath: (NSString *)path;
- (BOOL)_relationshipPathIsToMany: (id)param0;
- (BOOL)_relationshipPathHasIdenticalKeys: (id)param0;
@end


@interface EOEntity (EOEntitySQLExpression)
- (id)valueForSQLExpression: (id)param0;
+ (id)valueForSQLExpression: (id)param0;
@end

@interface EOEntity (EOEntityPrivateXX)
- (EOExpressionArray *)_parseDescription: (NSString *)description
				isFormat: (BOOL)isFormat
			       arguments: (char *)param2;
- (EOExpressionArray *)_parseRelationshipPath: (NSString *)path;
- (id)_parsePropertyName: (id)param0;
//- (id)_newStringWithBuffer: (unsigned short *)param0
//                    length: (unsigned int *)param1;
@end

@interface EOEntity (MethodSet11)
- (NSException *)validateObjectForDelete: (id)object;
- (id)classPropertyAttributeNames;
- (id)classPropertyToManyRelationshipNames;
- (id)classPropertyToOneRelationshipNames;
- (id)qualifierForDBSnapshot: (id)param0;
- (void)_addAttributesToFetchForRelationshipPath: (NSString *)path
					    atts: (NSMutableDictionary *)atts;
- (id)dbSnapshotKeys;
- (NSArray *)flattenedAttributes;
@end

#endif
