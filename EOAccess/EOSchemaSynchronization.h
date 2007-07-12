/* -*-objc-*-
   EOSchemaSynchronization.h

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
#ifndef	__EOAccess_EOSchemaSynchronization_h__
#define	__EOAccess_EOSchemaSynchronization_h__

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOSQLExpression.h>


GDL2ACCESS_EXPORT NSString *EOSchemaSynchronizationForeignKeyConstraintsKey;
GDL2ACCESS_EXPORT NSString *EOSchemaSynchronizationPrimaryKeyConstraintsKey;
GDL2ACCESS_EXPORT NSString *EOSchemaSynchronizationPrimaryKeySupportKey;

GDL2ACCESS_EXPORT NSString *EOAllowsNullKey;
GDL2ACCESS_EXPORT NSString *EOColumnNameKey;
GDL2ACCESS_EXPORT NSString *EOExternalNameKey;
GDL2ACCESS_EXPORT NSString *EOExternalTypeKey;
GDL2ACCESS_EXPORT NSString *EONameKey;
GDL2ACCESS_EXPORT NSString *EOPrecisionKey;
GDL2ACCESS_EXPORT NSString *EORelationshipsKey;
GDL2ACCESS_EXPORT NSString *EOScaleKey;
GDL2ACCESS_EXPORT NSString *EOWidthKey;

@protocol EOColumnTypes
- (NSString *)name;
- (unsigned)precision;
- (int)scale;
- (unsigned)width;
@end

@interface EOAdaptor (EOSchemaSynchronization)
- (NSDictionary *)objectStoreChangesFromAttribute:(EOAttribute *)schemaAttribute
				      toAttribute:(EOAttribute *)modelAttribute;
@end

@interface EOAdaptorChannel (EOSchemaSynchronization)
- (void)beginSchemaSynchronization;
- (void)endSchemaSynchronization;
@end

@interface NSObject (EOSchemaSynchronizationDelegates)
- (BOOL)allowsNullForColumnNamed:(NSString *)columnName
	      inSchemaTableNamed:(NSString *)tableName;
- (BOOL)isSchemaTableNamed:(NSString *)tableName;
- (EOAdaptor *)schemaSynchronizationAdaptor;
- (EOAdaptorChannel *)schemaSynchronizationAdaptorChannelForModel:(EOModel *)model;
- (void)schemaSynchronizationStatements:(NSArray *)statements
		     willCopyTableNamed:(NSString *)tableName;
- (void)schemaSynchronizationStatements:(NSArray *)statements
		   willDeleteTableNamed:(NSString *)tableName;
@end

@interface EOSQLExpression (EOSchemaSynchronization)
+ (BOOL)isCaseSensitive;
+ (BOOL)isColumnType:(id <EOColumnTypes>)columnType1
equivalentToColumnType:(id <EOColumnTypes>)columnType2
	     options:(NSDictionary *)options;
+ (NSArray *)logicalErrorsInChangeDictionary:(NSDictionary *)changes
				    forModel:(EOModel *)model
				     options:(NSDictionary *)options;
+ (NSString *)phraseCastingColumnNamed:(NSString *)columnName
			      fromType:(id <EOColumnTypes>)type
				toType:(id <EOColumnTypes>)castType
			       options:(NSDictionary *)options;
+ (id)schemaSynchronizationDelegate;
+ (void)setSchemaSynchronizationDelegate:(id)delegate;
+ (NSArray *)statementsToCopyTableNamed:(NSString *)tableName
		intoTableForEntityGroup:(NSArray *)entityGroup
		   withChangeDictionary:(NSDictionary *)changes
				options:(NSDictionary *)options;
+ (NSArray *)statementsToModifyColumnNamed:(NSString *)columnName
			      inTableNamed:(NSString *)tableName
				toNullRule:(BOOL)allowsNull
				   options:(NSDictionary *)options;
+ (NSArray *)statementsToConvertColumnNamed:(NSString *)columnName
			       inTableNamed:(NSString *)tableName
				   fromType:(id <EOColumnTypes>)type
				     toType:(id <EOColumnTypes>)newType
				    options:(NSDictionary *)options;
+ (NSArray *)statementsToDeleteColumnNamed:(NSString *)columnName
			      inTableNamed:(NSString *)tableName
				   options:(NSDictionary *)options;
+ (NSArray *)statementsToInsertColumnForAttribute:(EOAttribute *)attribute
					  options:(NSDictionary *)options;
+ (NSArray *)statementsToRenameColumnNamed:(NSString *)columnName
			      inTableNamed:(NSString *)tableName
				   newName:(NSString *)newName
				   options:(NSDictionary *)options;
+ (NSArray *)statementsToDropForeignKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
					    withChangeDictionary:(NSDictionary *)changes
							 options:(NSDictionary *)options;
+ (NSArray *)statementsToDropPrimaryKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
					    withChangeDictionary:(NSDictionary *)changes
							 options:(NSDictionary *)options;
+ (NSArray *)statementsToDropPrimaryKeySupportForEntityGroups:(NSArray *)entityGroups
					 withChangeDictionary:(NSDictionary *)changes
						      options:(NSDictionary *)options;
+ (NSArray *)statementsToImplementForeignKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
						 withChangeDictionary:(NSDictionary *)changes
							      options:(NSDictionary *)options;
+ (NSArray *)statementsToImplementPrimaryKeyConstraintsOnEntityGroups:(NSArray *)entityGroups
						 withChangeDictionary:(NSDictionary *)changes
							      options:(NSDictionary *)options;
+ (NSArray *)statementsToImplementPrimaryKeySupportForEntityGroups:(NSArray *)entityGroups
					      withChangeDictionary:(NSDictionary *)changes
							   options:(NSDictionary *)options;
+ (NSArray *)statementsToRenameTableNamed:(NSString *)tableName
				  newName:(NSString *)newName
				  options:(NSDictionary *)options;
+ (NSArray *)statementsToUpdateObjectStoreForModel:(EOModel *)model
			      withChangeDictionary:(NSDictionary *)changes
					   options:(NSDictionary *)options;
+ (NSArray *)statementsToUpdateObjectStoreForEntityGroups:(NSArray *)entityGroups
				     withChangeDictionary:(NSDictionary *)changes
						  options:(NSDictionary *)options;
+ (BOOL)supportsDirectColumnNullRuleModification;
+ (BOOL)supportsDirectColumnCoercion;
+ (BOOL)supportsDirectColumnDeletion;
+ (BOOL)supportsDirectColumnInsertion;
+ (BOOL)supportsDirectColumnRenaming;
+ (BOOL)supportsSchemaSynchronization;

@end

#endif
