/* -*-objc-*-
   EOSchemaGeneration.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: April 2004

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

#ifndef __EOSchemaGeneration_h__
#define __EOSchemaGeneration_h__

#include <EOAccess/EOSQLExpression.h>


@interface EOSQLExpression (EOSchemaGeneration)

/**
 * Generates the statements to create a database.
 */
+ (NSArray *)createDatabaseStatementsForConnectionDictionary:(NSDictionary *)connectionDictionary
			  administrativeConnectionDictionary:(NSDictionary *)administrativeConnectionDictionary;

/**
 * Generates the statements to drop the database.
 */
+ (NSArray *)dropDatabaseStatementsForConnectionDictionary:(NSDictionary *)connectionDictionary
			administrativeConnectionDictionary:(NSDictionary *)administrativeConnectionDictionary;

/** Generates the statements necessary to implement the schema generation for
 *  an entityGroup like creating/dropping a table, a primary key constaint or
 *  a primary key generation support such as a sequence. 
 */
+ (NSArray *)createTableStatementsForEntityGroup: (NSArray *)entityGroup;
+ (NSArray *)dropTableStatementsForEntityGroup: (NSArray *)entityGroup;
+ (NSArray *)primaryKeyConstraintStatementsForEntityGroup: (NSArray *)entityGroup;
+ (NSArray *)primaryKeySupportStatementsForEntityGroup: (NSArray *)entityGroup;
+ (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup: (NSArray *)entityGroup;

/**
 * Generates statements to create/drop a specific schema generation for a
 *  list of entityGroups.
 */
+ (NSArray *)createTableStatementsForEntityGroups: (NSArray *)entityGroups;
+ (NSArray *)dropTableStatementsForEntityGroups: (NSArray *)entityGroups;
+ (NSArray *)primaryKeyConstraintStatementsForEntityGroups: (NSArray *)entityGroups;
+ (NSArray *)primaryKeySupportStatementsForEntityGroups: (NSArray *)entityGroups;
+ (NSArray *)dropPrimaryKeySupportStatementsForEntityGroups: (NSArray *)entityGroups;

/**
 * The default implementation verifies the relationship joins and calls
 * prepareConstraintStatementForRelationship:sourceColumns:destinationColumns:
 */
+ (NSArray *)foreignKeyConstraintStatementsForRelationship: (EORelationship *)relationship;

/**
 * Assembles an adaptor specific string for using in a create table
 *   statement.
 */
- (NSString *)columnTypeStringForAttribute: (EOAttribute *)attribute;

/**
 * Generates a string to be used in a create table statement 
 */
- (NSString *)allowsNullClauseForConstraint: (BOOL)allowsNull;

/**
 * Assembles the create table statement for the given attribute 
 */
- (void)addCreateClauseForAttribute: (EOAttribute *)attribute;

/**
 * Assembles an adaptor specific constraint statement for relationship and the
 * given source and destination columns 
 */
- (void)prepareConstraintStatementForRelationship: (EORelationship *)relationship
				    sourceColumns: (NSArray *)sourceColumns
			       destinationColumns: (NSArray *)destinationColumns;

/** 
 * Append expression statement to an executable script.
 * The default implementation appends the ';' 
 */
+ (void)appendExpression:(EOSQLExpression *)expression toScript:(NSMutableString *)script;

/**
 * Returns a script to create the schema for the given entities specific for
 * the target db. Options are the same as
 * [+schemaCreationStatementsForEntities:options:]
 */
+ (NSString *)schemaCreationScriptForEntities:(NSArray *)entities
				      options:(NSDictionary *)options;

/**
 * <p>
 * Returns an array of EOSQLExpression suitable to create the schema for the
 * given entities specific for the target db.
 * Possible options are:</p>
 * <list>
 * <item>Name                     Value   Default</item>
 * <item></item>
 * <item>createTables             YES/NO  YES</item>
 * <item>dropTables               YES/NO  YES</item>
 * <item>createPrimaryKeySupport  YES/NO  YES</item>
 * <item>dropPrimaryKeySupport    YES/NO  YES</item>
 * <item>primaryKeyConstraints    YES/NO  YES</item>
 * <item>foreignKeyConstraints    YES/NO  NO</item>
 * <item>createDatabase           YES/NO  NO</item>
 * <item>dropDatabase             YES/NO  NO</item>
 * </list>
 */
+ (NSArray *)schemaCreationStatementsForEntities: (NSArray *)entities
					 options: (NSDictionary *)options;

+ (EOSQLExpression *)selectStatementForContainerOptions;

@end


/** Keys to use the options dictionary for
 *  +schemaCreationScriptForEntities:options:
 *   and +schemaCreationStatementsForEntities:options:
 */
GDL2ACCESS_EXPORT NSString *EOCreateTablesKey;
GDL2ACCESS_EXPORT NSString *EODropTablesKey;
GDL2ACCESS_EXPORT NSString *EOCreatePrimaryKeySupportKey;
GDL2ACCESS_EXPORT NSString *EODropPrimaryKeySupportKey;
GDL2ACCESS_EXPORT NSString *EOPrimaryKeyConstraintsKey;
GDL2ACCESS_EXPORT NSString *EOForeignKeyConstraintsKey;
GDL2ACCESS_EXPORT NSString *EOCreateDatabaseKey;
GDL2ACCESS_EXPORT NSString *EODropDatabaseKey;

#endif
