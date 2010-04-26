/** 
   EOSchemaGeneration.m <title>EOSchemaGeneration Class</title>

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: David Ayers  <ayers@fsfe.org>
   Date: February 2006

   $Revision: 23653 $
   $Date: 2006-09-28 17:25:30 +0200 (Don, 28 Sep 2006) $

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
   </license>
**/

#include "config.h"

RCS_ID("$Id: EOSchemaGeneration.m 23653 2006-09-28 15:25:30Z ratmice $")

#include <string.h>

#ifdef GNUSTEP
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EOSchemaGeneration.h>

NSString *EOCreateTablesKey = @"EOCreateTablesKey";
NSString *EODropTablesKey = @"EODropTablesKey";
NSString *EOCreatePrimaryKeySupportKey = @"EOCreatePrimaryKeySupportKey";
NSString *EODropPrimaryKeySupportKey = @"EODropPrimaryKeySupportKey";
NSString *EOPrimaryKeyConstraintsKey = @"EOPrimaryKeyConstraintsKey";
NSString *EOForeignKeyConstraintsKey = @"EOForeignKeyConstraintsKey";
NSString *EOCreateDatabaseKey = @"EOCreateDatabaseKey";
NSString *EODropDatabaseKey = @"EODropDatabaseKey";


@implementation EOSQLExpression (EOSchemaGeneration)

+ (NSArray *)_administrativeDatabaseStatementsForSelector:(SEL) sel
					   forEntityGroup:(NSArray *)group
{
  EOEntity     *entity;
  EOModel      *model;
  NSDictionary *connDict;
  NSDictionary *admDict;
  NSArray      *stmts;
  NSString     *notifName;
  NSMutableDictionary  *notifDict;

  entity = [group lastObject];
  model = [entity model];
  connDict = [model connectionDictionary];

  notifDict = (id)[NSMutableDictionary dictionaryWithCapacity: 2];
  [notifDict setObject: model forKey: EOModelKey];
  notifName = EOAdministrativeConnectionDictionaryNeededNotification;
  [[NSNotificationCenter defaultCenter] postNotificationName: notifName
					object: notifDict];
  admDict = [notifDict objectForKey: EOAdministrativeConnectionDictionaryKey];
/* TODO: ayers 
  if (admDict == nil && [admDict count] == 0)
    {
      EOAdaptor    *adaptor;
      EOLoginPanel *panel;

      adaptor = [EOAdaptor adaptorWithModel: model];
      panel = [[adaptor class] sharedLoginPanelInstance];
      admDict = [panel administrativeConnectionDictionaryForAdaptor: adaptor];
    }
*/
  stmts = [self performSelector: sel 
		withObject: connDict 
		withObject: admDict];

  return stmts;
}

+ (NSArray *)_dropDatabaseStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *cumStmts;
  NSArray *stmts;
  NSArray *group;
  unsigned i,n;
  SEL sel;

  sel = @selector(dropDatabaseStatementsForConnectionDictionary:administrativeConnectionDictionary:);

  n = [entityGroups count];
  cumStmts = [NSMutableArray arrayWithCapacity: n];

  for (i=0; i<n; i++)
    {
      EOSQLExpression *expr;
      unsigned j,m;

      group = [entityGroups objectAtIndex: i];
      stmts = [self _administrativeDatabaseStatementsForSelector: sel
		    forEntityGroup: group];
      for (j=0, m=[stmts count]; j<m; j++)
	{
	  NSArray  *rawStmts;
	  NSString *stmt;

	  rawStmts = [cumStmts valueForKey:@"statement"];
	  expr = [stmts objectAtIndex: j];
	  stmt = [expr statement];

	  if ([rawStmts containsObject: stmt] == NO)
	    {
	      [cumStmts addObject: expr];
	    }
	}
    }

  return [NSArray arrayWithArray: cumStmts];
}

+ (NSArray *)_createDatabaseStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *cumStmts;
  NSArray *stmts;
  NSArray *group;
  unsigned i,n;
  SEL sel;

  sel = @selector(createDatabaseStatementsForConnectionDictionary:administrativeConnectionDictionary:);

  n = [entityGroups count];
  cumStmts = [NSMutableArray arrayWithCapacity: n];

  for (i=0; i<n; i++)
    {
      EOSQLExpression *expr;
      unsigned j,m;

      group = [entityGroups objectAtIndex: i];
      stmts = [self _administrativeDatabaseStatementsForSelector: sel
		    forEntityGroup: group];

      for (j=0, m=[stmts count]; j<m; j++)
	{
	  NSArray  *rawStmts;
	  NSString *stmt;

	  rawStmts = [cumStmts valueForKey:@"statement"];
	  expr = [stmts objectAtIndex: j];
	  stmt = [expr statement];

	  if ([rawStmts containsObject: stmt] == NO)
	    {
	      [cumStmts addObject: expr];
	    }
	}
    }

  return [NSArray arrayWithArray: cumStmts];
}

+ (NSArray *)foreignKeyConstraintStatementsForRelationship: (EORelationship *)relationship
{
  NSMutableArray *array, *sourceColumns, *destColumns;
  EOSQLExpression *sqlExpression;
  EOEntity *entity;
  NSEnumerator *joinEnum;
  EOJoin *join;
  unsigned num;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: 1];

  if ([[relationship entity] model]
      != [[relationship destinationEntity] model])
    {
      EOFLOGClassFnStopOrCond(@"EOSQLExpression");

      return array;
    }

  if ([relationship isToMany] == YES
      || ([relationship inverseRelationship] != nil
	  && [[relationship inverseRelationship] isToMany] == NO))
    {
      EOFLOGClassFnStopOrCond(@"EOSQLExpression");

      return array;
    }

  entity = [relationship entity];
  sqlExpression = [self sqlExpressionWithEntity: entity];

  num = [[relationship joins] count];

  sourceColumns = [NSMutableArray arrayWithCapacity: num];
  destColumns   = [NSMutableArray arrayWithCapacity: num];

  joinEnum = [[relationship joins] objectEnumerator];
  while ((join = [joinEnum nextObject]))
    {
      [sourceColumns addObject: [join sourceAttribute]];
      [destColumns   addObject: [join destinationAttribute]];
    }

  [sqlExpression prepareConstraintStatementForRelationship: relationship
		 sourceColumns: sourceColumns
		 destinationColumns: destColumns];

  [array addObject: sqlExpression];

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

+ (NSArray *)foreignKeyConstraintStatementsForEntityGroup:(NSArray *)entityGroup
{
  NSMutableArray *sqlExps;
  EORelationship *rel;
  EOEntity       *entity;
  EOEntity       *parentEntity;
  unsigned       i,j,n,m;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  sqlExps = [NSMutableArray array];

  for (i=0, n=[entityGroup count]; i<n; i++)
    {
      NSArray *rels;

      entity = [entityGroup objectAtIndex: i];
      parentEntity = [entity parentEntity];
      rels = [entity relationships];

      for (j=0, m=[rels count]; parentEntity == nil && j<m; j++)
	{
	  NSArray *stmts;

	  rel = [rels objectAtIndex: j];
	  stmts =[self foreignKeyConstraintStatementsForRelationship: rel];
	  [sqlExps addObjectsFromArray: stmts];
	}
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return sqlExps;
}

+ (NSArray *)foreignKeyConstraintStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *array;
  NSEnumerator   *groupsEnum;
  NSArray        *group;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: [entityGroups count]];

  groupsEnum = [entityGroups objectEnumerator];
  while ((group = [groupsEnum nextObject]))
    {
      NSArray *stmts;

      stmts = [self foreignKeyConstraintStatementsForEntityGroup: group];
      [array addObjectsFromArray: stmts];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

// default implementation verifies that relationship joins on foreign key
// of destination and calls
// prepareConstraintStatementForRelationship:sourceColumns:destinationColumns:

+ (NSArray *)createTableStatementsForEntityGroup: (NSArray *)entityGroup
{
  EOSQLExpression *sqlExp;
  NSEnumerator *entityEnum, *attrEnum;
  EOAttribute *attr;
  EOEntity *entity;
  NSString *tableName;
  NSString *stmt;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  if ([[entityGroup objectAtIndex:0] isAbstractEntity])
    return [NSArray array];

  sqlExp = [self sqlExpressionWithEntity:[entityGroup objectAtIndex: 0]];

  entityEnum = [entityGroup objectEnumerator];
  while ((entity = [entityEnum nextObject]))
    {
      attrEnum = [[entity attributes] objectEnumerator];

      while ((attr = [attrEnum nextObject]))
	[sqlExp addCreateClauseForAttribute: attr];
    }

  entity = [entityGroup objectAtIndex: 0];
  tableName = [entity externalName];
  tableName = [sqlExp sqlStringForSchemaObjectName: tableName];

  stmt = [NSString stringWithFormat: @"CREATE TABLE %@ (%@)",
		   tableName,
		   [sqlExp listString]];
  [sqlExp setStatement: stmt];

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return [NSArray arrayWithObject: sqlExp];
}

+ (NSArray *)dropTableStatementsForEntityGroup:(NSArray *)entityGroup
{
  NSArray *newArray;
  NSString *tableName;
  EOEntity *entity;
  NSString *stmt;
  EOSQLExpression *sqlExp;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  entity = [entityGroup objectAtIndex: 0];

  if ([entity isAbstractEntity])
    return [NSArray array];
  
  sqlExp = [self sqlExpressionWithEntity: entity];
  tableName = [entity externalName];
  tableName = [sqlExp sqlStringForSchemaObjectName: tableName];

  stmt = [NSString stringWithFormat: @"DROP TABLE %@", tableName];
  [sqlExp setStatement: stmt];
  newArray = [NSArray arrayWithObject: sqlExp];

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return newArray;
}

+ (NSArray *)primaryKeyConstraintStatementsForEntityGroup:(NSArray *)entityGroup
{
  EOSQLExpression *sqlExp;
  NSMutableString *listString;
  NSEnumerator    *attrEnum;
  EOAttribute     *attr;
  EOEntity        *entity;
  NSString        *tableName;
  NSString        *stmt;
  BOOL             first = YES;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  entity = [entityGroup objectAtIndex: 0];
  listString = [NSMutableString stringWithCapacity: 30];

  attrEnum = [[entity primaryKeyAttributes] objectEnumerator];
  while ((attr = [attrEnum nextObject]))
    {
      NSString *columnName = [attr columnName];

      if (!columnName || ![columnName length])
	continue;

      if (first == NO)
	[listString appendString: @", "];

      [listString appendString: columnName];
      first = NO;
    }

  if (first == YES)
    {
      EOFLOGClassFnStopOrCond(@"EOSQLExpression");

      return [NSArray array];
    }

  sqlExp = [self sqlExpressionWithEntity:[entityGroup objectAtIndex: 0]];
  tableName = [entity externalName];
  tableName = [sqlExp sqlStringForSchemaObjectName: tableName];

  stmt = [NSString stringWithFormat: @"ALTER TABLE %@ ADD PRIMARY KEY (%@)",
		   tableName, listString];
  [sqlExp setStatement: stmt];

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return [NSArray arrayWithObject: sqlExp];
}

+ (NSArray *)primaryKeySupportStatementsForEntityGroup: (NSArray *)entityGroup
{
  NSArray *newArray;
  NSString *seqName;
  EOEntity *entity;
  NSString *pkRootName;
  NSString *stmt;
  EOSQLExpression *sqlExp;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  entity = [entityGroup objectAtIndex: 0];
  
  if ([entity isAbstractEntity])
    return [NSArray array];
  
  pkRootName = [entity primaryKeyRootName];
  seqName = [NSString stringWithFormat: @"%@_SEQ", pkRootName];

  sqlExp = [self sqlExpressionWithEntity: nil];
  seqName = [sqlExp sqlStringForSchemaObjectName: seqName];

  stmt = [NSString stringWithFormat: @"CREATE SEQUENCE %@", seqName];
  [sqlExp setStatement: stmt];
  newArray = [NSArray arrayWithObject: sqlExp];
                                      
  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return newArray;
}

+ (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup: (NSArray *)entityGroup
{
  NSArray *newArray;
  NSString *seqName;
  EOEntity *entity;
  NSString *pkRootName;
  NSString *stmt;
  EOSQLExpression *sqlExp;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  entity = [entityGroup objectAtIndex: 0];

  if ([entity isAbstractEntity])
    return [NSArray array];
  
  pkRootName = [entity primaryKeyRootName];
  seqName = [NSString stringWithFormat: @"%@_SEQ", pkRootName];

  sqlExp = [self sqlExpressionWithEntity: nil];
  seqName = [sqlExp sqlStringForSchemaObjectName: seqName];

  stmt = [NSString stringWithFormat: @"DROP SEQUENCE %@", seqName];
  [sqlExp setStatement: stmt];
  newArray = [NSArray arrayWithObject: sqlExp];

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return newArray;
}

+ (NSArray *)createTableStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *array;
  NSEnumerator   *groupsEnum;
  NSArray        *group;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: [entityGroups count]];

  groupsEnum = [entityGroups objectEnumerator];
  while ((group = [groupsEnum nextObject]))
    {
      [array addObjectsFromArray:
	       [self createTableStatementsForEntityGroup: group]];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

+ (NSArray *)dropTableStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *array;
  NSEnumerator   *groupsEnum;
  NSArray        *group;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: [entityGroups count]];

  groupsEnum = [entityGroups objectEnumerator];
  while ((group = [groupsEnum nextObject]))
    {
      [array addObjectsFromArray:
	       [self dropTableStatementsForEntityGroup: group]];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

+ (NSArray *)primaryKeyConstraintStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *array;
  NSEnumerator   *groupsEnum;
  NSArray        *group;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: [entityGroups count]];

  groupsEnum = [entityGroups objectEnumerator];
  while ((group = [groupsEnum nextObject]))
    {
      [array addObjectsFromArray:
	       [self primaryKeyConstraintStatementsForEntityGroup: group]];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

+ (NSArray *)primaryKeySupportStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *array;
  NSEnumerator   *groupsEnum;
  NSArray        *group;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: [entityGroups count]];

  groupsEnum = [entityGroups objectEnumerator];
  while ((group = [groupsEnum nextObject]))
    {
      [array addObjectsFromArray:
	       [self primaryKeySupportStatementsForEntityGroup: group]];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

+ (NSArray *)dropPrimaryKeySupportStatementsForEntityGroups: (NSArray *)entityGroups
{
  NSMutableArray *array;
  NSEnumerator   *groupsEnum;
  NSArray        *group;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  array = [NSMutableArray arrayWithCapacity: [entityGroups count]];

  groupsEnum = [entityGroups objectEnumerator];
  while ((group = [groupsEnum nextObject]))
    {
      [array addObjectsFromArray:
	       [self dropPrimaryKeySupportStatementsForEntityGroup: group]];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

+ (void)appendExpression: (EOSQLExpression *)expression
		toScript: (NSMutableString *)script
{
  EOFLOGClassFnStartOrCond(@"EOSQLExpression");
  
  [script appendFormat:@"%@;\n", [expression statement]];
  
  EOFLOGClassFnStopOrCond(@"EOSQLExpression");
}


+ (NSString *)schemaCreationScriptForEntities: (NSArray *)entities
				      options: (NSDictionary *)options
{
  NSMutableString *script = [NSMutableString stringWithCapacity:50];
  NSEnumerator    *arrayEnum;
  EOSQLExpression *sqlExp;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  arrayEnum = [[self schemaCreationStatementsForEntities: entities
		     options: options] objectEnumerator];

  while ((sqlExp = [arrayEnum nextObject]))
    [self appendExpression: sqlExp toScript: script];

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return script;
}

struct _schema
{
  NSString *key;
  NSString *value;
  SEL       selector;
};

+ (NSArray *)schemaCreationStatementsForEntities: (NSArray *)entities
					 options: (NSDictionary *)options
{
  NSMutableArray *array = [NSMutableArray arrayWithCapacity: 5];
  NSMutableArray *groups = [NSMutableArray arrayWithCapacity: 5];
  NSMutableArray *group;
  NSString       *externalName;
  EOEntity       *entity;
  int             i, h, count;
  struct _schema  defaults[] = {
    {EODropPrimaryKeySupportKey  , @"YES",
     @selector(dropPrimaryKeySupportStatementsForEntityGroups:)},
    {EODropTablesKey             , @"YES",
     @selector(dropTableStatementsForEntityGroups:)},
    {EODropDatabaseKey , @"NO",
     @selector(_dropDatabaseStatementsForEntityGroups:)},
    {EOCreateDatabaseKey , @"NO",
     @selector(_createDatabaseStatementsForEntityGroups:)},
    {EOCreateTablesKey           , @"YES",
     @selector(createTableStatementsForEntityGroups:)},
    {EOCreatePrimaryKeySupportKey, @"YES",
     @selector(primaryKeySupportStatementsForEntityGroups:)},
    {EOPrimaryKeyConstraintsKey   , @"YES",
     @selector(primaryKeyConstraintStatementsForEntityGroups:)},
    {EOForeignKeyConstraintsKey  , @"NO",
     @selector(foreignKeyConstraintStatementsForEntityGroups:)},
    {nil, nil},
  }; // Order is important!

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  count = [entities count];

  for (i = 0; i < count; i++)
    {
      entity = [entities objectAtIndex: i];
      externalName = [entity externalName];

      group = [NSMutableArray arrayWithCapacity: 1];
      [groups addObject: group];
      [group addObject: entity];

      for (h = i + 1; h < count; h++)
	{
	  if ([[[entities objectAtIndex: h] externalName]
		isEqual: externalName])
	    [group addObject: [entities objectAtIndex: h]];
	}
    }

  for (i = 0; defaults[i].key != nil; i++)
    {
      NSString *value;

      value = [options objectForKey: defaults[i].key];

      if (!value)
	value = defaults[i].value;

      if ([value isEqual: @"YES"] == YES)
	{
	  NSArray *stmts;
	  stmts = [self performSelector: defaults[i].selector
			withObject: groups];
	  [array addObjectsFromArray: stmts];
	}
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return array;
}

- (NSString *)columnTypeStringForAttribute:(EOAttribute *)attribute
{
  NSString *extType = [attribute externalType];
  int precision = [attribute precision];

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  if (precision)
    {
      EOFLOGClassFnStopOrCond(@"EOSQLExpression");
      return [NSString stringWithFormat:@"%@(%d, %d)", extType, precision,
		       [attribute scale]];
    }
  else if ([attribute width])
    {
      EOFLOGClassFnStopOrCond(@"EOSQLExpression");
      return [NSString stringWithFormat: @"%@(%d)", 
		       extType, [attribute width]];
    }
  else
    {
      EOFLOGClassFnStopOrCond(@"EOSQLExpression");
      return [NSString stringWithFormat: @"%@", extType];
    }
}

- (NSString *)allowsNullClauseForConstraint: (BOOL)allowsNull
{
  if (allowsNull == NO)
    return @"NOT NULL";

  return nil;
}

- (void)addCreateClauseForAttribute: (EOAttribute *)attribute
{
  NSString *columnType;
  NSString *allowsNull;
  NSString *str;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  columnType = [self columnTypeStringForAttribute: attribute];
  allowsNull = [self allowsNullClauseForConstraint: [attribute allowsNull]];

  if (allowsNull)
    str = [NSString stringWithFormat: @"%@ %@ %@", [attribute columnName],
		    columnType, allowsNull];
  else
    str = [NSString stringWithFormat: @"%@ %@", [attribute columnName],
		    columnType];

  [self appendItem:str toListString: /*_listString*/[self listString]]; // Else no chance to get inited (lazy)

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");
}

- (void)prepareConstraintStatementForRelationship: (EORelationship *)relationship
				    sourceColumns: (NSArray *)sourceColumns
			       destinationColumns: (NSArray *)destinationColumns
{
  NSMutableString *sourceString, *destinationString;
  NSEnumerator    *attrEnum;
  EOAttribute     *attr;
  NSString        *name, *str, *tableName, *relTableName;
  BOOL             first = YES;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  name = [NSString stringWithFormat: @"%@_%@_FK", [_entity externalName],
		   [relationship name]];

  sourceString = [NSMutableString stringWithCapacity: 30];

  attrEnum = [sourceColumns objectEnumerator];
  while ((attr = [attrEnum nextObject]))
    {
      NSString *columnName = [attr columnName];

      if (!columnName || ![columnName length])
	continue;

      if (first == NO)
	[sourceString appendString: @", "];

      [sourceString appendString: columnName];
      first = NO;
    }

  first = YES;
  destinationString = [NSMutableString stringWithCapacity: 30];

  attrEnum = [destinationColumns objectEnumerator];
  while ((attr = [attrEnum nextObject]))
    {
      NSString *columnName = [attr columnName];

      if (!columnName || ![columnName length])
	continue;

      if (first == NO)
	[destinationString appendString: @", "];

      [destinationString appendString: columnName];
      first = NO;
    }

  tableName = [_entity externalName];
  tableName = [self sqlStringForSchemaObjectName: tableName];

  relTableName = [[relationship destinationEntity] externalName];
  relTableName = [self sqlStringForSchemaObjectName: relTableName];

  str = [NSString stringWithFormat: @"ALTER TABLE %@ ADD CONSTRAINT %@ "
		  @"FOREIGN KEY (%@) REFERENCES %@ (%@)",
		  tableName,
		  name,
		  sourceString,
		  relTableName,
		  destinationString];

  ASSIGN(_statement, str);

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");
}

// Assembles an adaptor specific constraint statement for relationship.

+ (NSArray *)createDatabaseStatementsForConnectionDictionary: (NSDictionary *)connectionDictionary
			  administrativeConnectionDictionary: (NSDictionary *)administrativeConnectionDictionary
{
  [self subclassResponsibility: _cmd];
  return nil;
}

+ (NSArray *)dropDatabaseStatementsForConnectionDictionary: (NSDictionary *)connectionDictionary
			administrativeConnectionDictionary: (NSDictionary *)administrativeConnectionDictionary
{
  [self subclassResponsibility: _cmd];
  return nil;
}

+ (EOSQLExpression *)selectStatementForContainerOptions
{
  [self notImplemented: _cmd];
  return nil;
}

@end
