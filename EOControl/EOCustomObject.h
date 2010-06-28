/* -*-objc-*-
 EOGenericRecord.h
 
 Copyright (C) 2010 Free Software Foundation, Inc.
 
 Author: David Wetzel <dave@turbocat.de>
 Date: April 2010
 
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

#ifndef __EOCustomObject_h__
#define __EOCustomObject_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSKeyValueCoding.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EOClassDescription.h>

@class EOEditingContext;


@interface EOCustomObject : NSObject <NSCoding>
{

}

- (id)initWithEditingContext: (EOEditingContext *)editingContext
            classDescription: (EOClassDescription *)classDescription
                    globalID: (EOGlobalID *)globalID;


// -----------------------------------------------
// those used to be EOClassDescriptionPrimitives

- (EOClassDescription *)classDescription;

- (NSString *)entityName;
- (NSArray *)attributeKeys;
- (NSArray *)toOneRelationshipKeys;
- (NSArray *)toManyRelationshipKeys;
- (NSString *)inverseForRelationshipKey: (NSString *)relationshipKey;
- (EODeleteRule)deleteRuleForRelationshipKey: (NSString *)relationshipKey;
- (BOOL)ownsDestinationObjectsForRelationshipKey: (NSString *)relationshipKey;
- (EOClassDescription *)classDescriptionForDestinationKey: (NSString *)detailKey;

- (NSString *)userPresentableDescription;

- (NSException *)validateValue: (id *)valueP forKey: (NSString *)key;
- (id)validateTakeValue:(id)value forKeyPath:(NSString *)path;

- (NSException *)validateForSave;

- (NSException *)validateForDelete;

- (void)awakeFromInsertionInEditingContext: (EOEditingContext *)editingContext;

- (void)awakeFromFetchInEditingContext: (EOEditingContext *)editingContext;

// -----------------------------------------------

// those used to be EOKeyRelationshipManipulation

- (void)addObject: (id)object toPropertyWithKey: (NSString *)key;

- (void)removeObject: (id)object fromPropertyWithKey: (NSString *)key;

- (void)addObject: (id)object toBothSidesOfRelationshipWithKey: (NSString *)key;

- (void)removeObject: (id)object fromBothSidesOfRelationshipWithKey: (NSString *)key;

// -----------------------------------------------

// those used to be NSObject (_EOValueMerging)

- (void)mergeValue: (id)value forKey: (id)key;
- (void)mergeChangesFromDictionary: (NSDictionary *)changes;
- (NSDictionary *)changesFromSnapshot: (NSDictionary *)snapshot;
- (void)reapplyChangesFromSnapshot: (NSDictionary *)changes;

// -----------------------------------------------

// those used to be NSObject (EOClassDescriptionExtras)

- (NSDictionary *)snapshot;

- (void)updateFromSnapshot: (NSDictionary *)snapshot;

- (BOOL)isToManyKey: (NSString *)key;

- (NSException *)validateForInsert;
- (NSException *)validateForUpdate;

- (NSArray *)allPropertyKeys;

- (void)clearProperties;

- (void)propagateDeleteWithEditingContext: (EOEditingContext *)editingContext;

- (NSString *)eoShallowDescription;
- (NSString *)eoDescription;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

#endif // __EOCustomObject_h__

