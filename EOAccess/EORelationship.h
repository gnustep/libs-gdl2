/* -*-objc-*-
   EORelationship.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef __EORelationship_h__
#define __EORelationship_h__

#include <GNUstepBase/GCObject.h>

#include <EOControl/EOClassDescription.h>

#include <EOAccess/EOJoin.h>
#include <EOAccess/EOPropertyListEncoding.h>


@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSException;

@class EOEntity;
@class EOAttribute;
@class EOExpressionArray;
@class EOMutableKnownKeyDictionary;
@class EOMKKDSubsetMapping;
@class EOQualifier;


typedef enum {
  EOInnerJoin = 0,
  EOFullOuterJoin,
  EOLeftOuterJoin,
  EORightOuterJoin
} EOJoinSemantic;


@interface EORelationship : GCObject <EOPropertyListEncoding>
{
  NSString *_name;
  EOQualifier *_qualifier;
  NSMutableDictionary *_sourceNames;
  NSMutableDictionary *_destinationNames;
  NSDictionary *_userInfo;
  NSDictionary *_internalInfo;
  NSString *_docComment;
  NSDictionary *_sourceToDestinationKeyMap;
  unsigned int _batchCount;
  EOJoinSemantic _joinSemantic;

  struct {
    unsigned int isToMany:1;
    unsigned int useBatchFaulting:1;
    unsigned int deleteRule:2;
    unsigned int isMandatory:1;
    unsigned int ownsDestination:1;
    unsigned int propagatesPrimaryKey:1;
    unsigned int createsMutableObjects:1;
    unsigned int isBidirectional:1;
    unsigned int extraRefCount:23;
  } _flags;
  id _sourceRowToForeignKeyMapping;

  /* Garbage collectable objects */
  EOExpressionArray *_definitionArray;

  EORelationship *_inverseRelationship;
  EORelationship *_hiddenInverseRelationship;

  EOEntity *_entity;
  EOEntity *_destination;
  GCMutableArray *_joins;

  /* Computed values */
  GCArray *_sourceAttributes;
  GCArray *_destinationAttributes;
  GCMutableArray *_componentRelationships;//Used ????
}

+ (id)relationshipWithPropertyList: (NSDictionary *)propertyList
                              owner: (id)owner;

- (NSString *)name;

- (EOEntity *)entity;

- (EOEntity *)destinationEntity;

- (NSString *)definition;

- (BOOL)isFlattened;

- (BOOL)isToMany;

- (BOOL)isCompound;

- (BOOL)isParentRelationship;

- (NSArray *)sourceAttributes;

- (NSArray *)destinationAttributes;

- (NSArray *)joins;

- (EOJoinSemantic)joinSemantic;
- (NSString *)joinSemanticString;

- (NSArray *)componentRelationships;

- (NSDictionary *)userInfo;

- (BOOL)referencesProperty: (id)property;

- (EODeleteRule)deleteRule;

- (BOOL)isMandatory;

- (BOOL)propagatesPrimaryKey;

- (BOOL)isBidirectional;

- (EORelationship *)hiddenInverseRelationship;
- (EORelationship *)inverseRelationship;

- (EORelationship *)anyInverseRelationship;

- (unsigned int)numberOfToManyFaultsToBatchFetch;

- (BOOL)ownsDestination;
- (EOQualifier *)qualifierWithSourceRow: (NSDictionary *)sourceRow;

/** Accessing documentation comments **/
- (NSString *)docComment;
@end


@interface EORelationship(EORelationshipEditing)
- (NSException *)validateName: (NSString *)name;
- (void)setName: (NSString *)name;
- (void)setDefinition: (NSString *)definition;
- (void)setEntity: (EOEntity *)entity;
- (void)setToMany: (BOOL)yn;
- (void)setPropagatesPrimaryKey: (BOOL)yn;
- (void)setIsBidirectional: (BOOL)yn;
- (void)setOwnsDestination: (BOOL)yn;
- (void)addJoin: (EOJoin *)join;
- (void)removeJoin: (EOJoin *)join;
- (void)setJoinSemantic: (EOJoinSemantic)joinSemantic;
- (void)setUserInfo: (NSDictionary *)dictionary;
- (void)setInternalInfo: (NSDictionary *)dictionary;
- (void)beautifyName;
- (void)setNumberOfToManyFaultsToBatchFetch: (unsigned int)size;
- (void)setDeleteRule: (EODeleteRule)deleteRule;
- (void)setIsMandatory: (BOOL)isMandatory;
- (void)setDocComment: (NSString *)docComment;

@end


@interface EORelationship(EORelationshipValueMapping)

- (NSException *)validateValue: (id *)valueP;

@end


@interface EORelationship (EORelationshipPrivate)

/*+ (EORelationship *)relationshipFromPropertyList: (id)propertyList
	model: (EOModel *)model;
- (void)replaceStringsWithObjects;
- (void)initFlattenedRelationship;

- (id)propertyList;*/

- (void)setCreateMutableObjects: (BOOL)flag;
- (BOOL)createsMutableObjects;
- (void)setInverseRelationship: (EORelationship *)relationship;
@end /* EORelationship (EORelationshipPrivate) */

@interface EORelationship (EORelationshipXX)

- (NSArray *)_intermediateAttributes;
- (EORelationship *)lastRelationship;
- (EORelationship *)firstRelationship;
- (EOEntity*) intermediateEntity;
- (BOOL)isMultiHop;
- (void)_setSourceToDestinationKeyMap: (id)param0;
- (id)qualifierForDBSnapshot: (id)param0;
- (id)primaryKeyForTargetRowFromSourceDBSnapshot: (id)param0;
- (NSString *)relationshipPath;
- (BOOL)isToManyToOne;
- (NSDictionary *)_sourceToDestinationKeyMap;
- (BOOL)foreignKeyInDestination;
@end

@interface EORelationship (EORelationshipPrivate2)
- (BOOL)isPropagatesPrimaryKeyPossible;
- (id)qualifierOmittingAuxiliaryQualifierWithSourceRow: (id)param0;
- (id)auxiliaryQualifier;
- (void)setAuxiliaryQualifier: (id)param0;
- (EOMutableKnownKeyDictionary *)_foreignKeyForSourceRow: (NSDictionary *)row;
- (EOMKKDSubsetMapping *)_sourceRowToForeignKeyMapping;
- (NSArray *)_sourceAttributeNames;
- (EOJoin *)joinForAttribute: (EOAttribute *)attribute;
- (void)_flushCache;
- (EOExpressionArray *)_definitionArray;
- (NSString *)_stringFromDeleteRule: (EODeleteRule)deleteRule;
- (EODeleteRule)_deleteRuleFromString: (NSString *)deleteRuleString;
- (NSDictionary *)_rightSideKeyMap;
- (NSDictionary *)_leftSideKeyMap;
- (EORelationship *)_substitutionRelationshipForRow: (NSDictionary *)row;
- (void)_joinsChanged;
@end

#endif /* __EORelationship_h__ */
