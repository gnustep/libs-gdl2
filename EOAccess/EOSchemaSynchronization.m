/* -*-objc-*-
   EOSchemaSynchronization.m

   Copyright (C) 2007 Free Software Foundation, Inc.

   Date: July 2007

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

#include <Foundation/Foundation.h>

#include "EOSchemaSynchronization.h"

NSString *EOSchemaSynchronizationForeignKeyConstraintsKey = @"EOSchemaSynchronizationForeignKeyConstraintsKey";
NSString *EOSchemaSynchronizationPrimaryKeyConstraintsKey = @"EOSchemaSynchronizationPrimaryKeyConstraintsKey";
NSString *EOSchemaSynchronizationPrimaryKeySupportKey = @"EOSchemaSynchronizationPrimaryKeySupportKey";

NSString *EOAllowsNullKey = @"allowsNull";
NSString *EOColumnNameKey = @"columnName";
NSString *EOExternalNameKey = @"externalName";
NSString *EOExternalTypeKey = @"externalType";
NSString *EONameKey = @"name";
NSString *EOPrecisionKey = @"precision";
NSString *EORelationshipsKey = @"relationships";
NSString *EOScaleKey = @"scale";
NSString *EOWidthKey = @"width";

@implementation EOAdaptor (EOSchemaSynchronization)
- (NSDictionary *)objectStoreChangesFromAttribute:(EOAttribute *)schemaAttribute
				      toAttribute:(EOAttribute *)modelAttribute
{
  return nil;
}
@end

@implementation EOAdaptorChannel (EOSchemaSynchronization)
- (void)beginSchemaSynchronization
{
}
- (void)endSchemaSynchronization
{
}
@end

@implementation EOSQLExpression (EOSchemaSynchronization)
+ (BOOL)isCaseSensitive
{
  return NO;
}

+ (BOOL)isColumnType:(id <EOColumnTypes>)columnType1
equivalentToColumnType:(id <EOColumnTypes>)columnType2
	     options:(NSDictionary *)options
{
  return NO;
}
+ (NSArray *)logicalErrorsInChangeDictionary:(NSDictionary *)changes
				    forModel:(EOModel *)model
				     options:(NSDictionary *)options
{
  return nil;
}
+ (NSString *)phraseCastingColumnNamed:(NSString *)columnName
			      fromType:(id <EOColumnTypes>)type
				toType:(id <EOColumnTypes>)castType
			       options:(NSDictionary *)options
{
  return nil;
}

+ (id)schemaSynchronizationDelegate
{
  return nil;
}
+ (void)setSchemaSynchronizationDelegate:(id)delegate
{
}
+ (NSArray *)statementsToCopyTableNamed:(NSString *)tableName
		intoTableForEntityGroup:(NSArray *)entityGroup
		   withChangeDictionary:(NSDictionary *)changes
				options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToModifyColumnNamed:(NSString *)columnName
			      inTableNamed:(NSString *)tableName
				toNullRule:(BOOL)allowsNull
				   options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToConvertColumnNamed:(NSString *)columnName
			       inTableNamed:(NSString *)tableName
				   fromType:(id <EOColumnTypes>)type
				     toType:(id <EOColumnTypes>)newType
				    options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToDeleteColumnNamed:(NSString *)columnName
			      inTableNamed:(NSString *)tableName
				   options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToInsertColumnForAttribute:(EOAttribute *)attribute
					  options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToRenameColumnNamed:(NSString *)columnName
			      inTableNamed:(NSString *)tableName
				   newName:(NSString *)newName
				   options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToDropForeignKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
					    withChangeDictionary:(NSDictionary *)changes
							 options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToDropPrimaryKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
					    withChangeDictionary:(NSDictionary *)changes
							 options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToDropPrimaryKeySupportForEntityGroups:(NSArray *)entityGroups
					 withChangeDictionary:(NSDictionary *)changes
						      options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToImplementForeignKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
						 withChangeDictionary:(NSDictionary *)changes
							      options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToImplementPrimaryKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
						 withChangeDictionary:(NSDictionary *)changes
							      options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToImplementPrimaryKeySupportForEntityGroups:(NSArray *)entityGroups
					      withChangeDictionary:(NSDictionary *)changes
							   options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToRenameTableNamed:(NSString *)tableName
				  newName:(NSString *)newName
				  options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToUpdateObjectStoreForModel:(EOModel *)model
			      withChangeDictionary:(NSDictionary *)changes
					   options:(NSDictionary *)options
{
  return nil;
}
+ (NSArray *)statementsToUpdateObjectStoreForEntityGroups:(NSArray *)entityGroups
				     withChangeDictionary:(NSDictionary *)changes
						  options:(NSDictionary *)options
{
  return nil;
}
+ (BOOL)supportsDirectColumnNullRuleModification
{
  return NO;
}
+ (BOOL)supportsDirectColumnCoercion
{
  return NO;
}
+ (BOOL)supportsDirectColumnDeletion
{
  return NO;
}
+ (BOOL)supportsDirectColumnInsertion
{
  return NO;
}
+ (BOOL)supportsDirectColumnRenaming
{
  return NO;
}

+ (BOOL)supportsSchemaSynchronization
{
  return NO;
}

@end
