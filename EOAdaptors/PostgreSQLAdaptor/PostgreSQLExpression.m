/** 
   PostgreSQLExpression.m <title>PostgreSQLExpression</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.
   This product includes software developed by Turbocat's Development.

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

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSUtilities.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <Foundation/NSDecimal.h>
#include <Foundation/NSDecimalNumber.h>

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EONull.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOSchemaGeneration.h>

#include "PostgreSQLExpression.h"
#include "PostgreSQLAdaptor.h"

#include "PostgreSQLCompatibility.h"
#include "PostgreSQLPrivate.h"

/* These methods are undocumented but exist in GDL2 and WO4.5. 
   Ayers: Review (Don't rely on them) */
@interface EOEntity (Undocumented)
- (EORelationship *)relationshipForPath: (NSString *)path;
@end

@interface EOSQLExpression (PrivatUndocumented)
- (NSString*) _aliasForRelatedAttribute: (EOAttribute *)attr
		       relationshipPath: (NSString *)keyPath;
@end


@implementation PostgreSQLExpression

+ (void) initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;
      PSQLA_PrivInit();
    };
};

+ (NSString *)formatValue: (id)value
             forAttribute: (EOAttribute *)attribute
{
  NSString *formatted = nil;
  NSString        *externalType;
  NSMutableString *string;
  const char      *tempString;
  int              i, dif;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"value=%@ class=%@", value,
			[value class]);
  EOFLOGObjectLevelArgs(@"EOSQLExpression",
			@"[EONull null] %p=%@ [EONull null] class=%@",
			[EONull null],
			[EONull null],
			[[EONull null] class]);
  EOFLOGObjectLevelArgs(@"EOSQLExpression",
			@"[value isEqual:[EONull null]]=%s",
			([value isEqual: [EONull null]] ? "YES" : "NO"));

  externalType = [attribute externalType];

  if (!value)
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"NULL case - value=%@ class=%@",
			    value, [value class]);      

      formatted = @"NULL";
    }
  else if ([value isEqual: [EONull null]])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"EONULL case - value=%@ class=%@",
			    value, [value class]);      

      formatted = [value sqlString];
    }
  else if ([externalType hasPrefix: @"int"]
           || [externalType hasPrefix: @"bigint"])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"int case - value=%@ class=%@",
			    value, [value class]);      

      formatted = [NSString stringWithFormat: @"%@", value];

      // value was for example 0 length string
      if ([formatted length] == 0)
        formatted = @"NULL";
    }
  else if ([externalType hasPrefix: @"float"])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"float case - value=%@ class=%@",
			    value, [value class]);

      if (_isNilOrEONull(value))
        formatted=@"NULL";
      else 
        {
          unsigned short precision=[attribute precision];
          short scale=[attribute scale];
          EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                @"float case - value=%@ class=%@ precision=%d scale=%d",
                                value, [value class],precision,scale);
          // As far as I understand, we need to try to do complex things if precision!=0 or scale!=0 
          if (precision==0 && scale==0)
            {
              // just convert it to string...
              formatted = [NSString stringWithFormat: @"%@", value];
            }
          else
            {
              NSDecimalNumber* decimalValue=nil;
              if ([value isKindOfClass: PSQLA_NSDecimalNumberClass] == NO)
                {
                  if ([value isKindOfClass: PSQLA_NSStringClass] == YES)
                    {
                      decimalValue
			= AUTORELEASE([PSQLA_alloc(NSDecimalNumber) initWithString:value]);
                      EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                            @"float case - value [%@]=%@ ==> decimalValue=%@",
                                            value,[value class],decimalValue);
                    }
                  else if ([value respondsToSelector: @selector(doubleValue)])
                    {
                      decimalValue
			= AUTORELEASE([PSQLA_alloc(NSDecimalNumber) initWithDouble:[value doubleValue]]);
                      EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                            @"float case - value [%@]=%@ ==> decimalValue=%@",
                                            value,[value class],decimalValue);
                    }
                  else if ([value respondsToSelector: @selector(floatValue)])
                    {
                      decimalValue
			= AUTORELEASE([PSQLA_alloc(NSDecimalNumber) initWithFloat:[value floatValue]]);
                      EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                            @"float case - value [%@]=%@ ==> decimalValue=%@",
                                            value,[value class],decimalValue);
                    }
                  else if ([value respondsToSelector: @selector(intValue)])
                    {
                      decimalValue
			= AUTORELEASE([PSQLA_alloc(NSDecimalNumber) initWithInt:[value intValue]]);
                      EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                            @"float case - value [%@]=%@ ==> decimalValue=%@",
                                            value,[value class],decimalValue);
                    };
                  if (decimalValue)
                    {
                      NSDecimal decimal;
                      NSDecimalNumberHandler* handler=[NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain // Is Plain OK ?
                                                                              scale:scale
                                                                              raiseOnExactness:YES
                                                                              raiseOnOverflow:YES
                                                                              raiseOnUnderflow:YES
                                                                              raiseOnDivideByZero:YES];
                      decimalValue=[decimalValue decimalNumberByRoundingAccordingToBehavior:handler];
                      decimal=[decimalValue decimalValue];
                      formatted=NSDecimalString(&decimal,nil);
                    }
                  else
                    {
                      // Not supported type: just convert it to string...
                      formatted = [NSString stringWithFormat: @"%@", value];
                    };
                };
            };
        };

      // value was for example 0 length string
      if ([formatted length] == 0)
        formatted=@"NULL";
    }
  else if ([externalType hasPrefix: @"bool"])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"BOOL case - value=%@ class=%@",
			    value, [value class]);          

      if ([value isKindOfClass: PSQLA_NSNumberClass] == YES)
        {
          BOOL boolValue = [value boolValue];

          if (boolValue == NO)
            formatted = @"'f'";
          else
            formatted = @"'t'";
        }
      else
        {
          EOFLOGObjectLevelArgs(@"EOSQLExpression",
				@"BOOL case/NSString - value=%@ class=%@",
				value, [value class]);      

	  formatted = [NSString stringWithFormat: @"'%@'", value];

	  // value was for example 0 length string
	  if ([formatted length] == 0)
	    formatted = @"NULL";
	}
    }
  else if ([externalType isEqualToString: @"oid"])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"OID case - value=%@ class=%@",
			    value, [value class]);      

      formatted = [NSString stringWithFormat: @"%@", value];

      // value was for example 0 length string
      if ([formatted length] == 0)
        formatted=@"NULL";
    }
  else if ([externalType isEqualToString: @"money"])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"Money case - value=%@ class=%@",
			    value, [value class]);      

      formatted = [NSString stringWithFormat: @"'$%@'", value];

      // value was for example 0 length string
      if ([formatted length] == 3) // only '$'
        formatted = @"NULL";
    }
  else if (([externalType isEqualToString: @"abstime"])
           /*|| ([externalType isEqualToString: @"datetime"])*//* stephane@sente.ch: datetime does not exist */
           || ([externalType isEqualToString: @"timestamp"]))
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"Time case - value=%@ class=%@",
			    value, [value class]);          

      if ([[value description] length] == 0)
        {
          NSWarnLog(@"empty description for %p %@ of class %@",
		    value, value, [value class]);
        }
      // Value can also be a string...
      if ([value isKindOfClass: PSQLA_NSDateClass])
        {
	  NSString *format;

	  format = [value descriptionWithCalendarFormat: 
			    PSQLA_postgresCalendarFormat
			  timeZone: nil
			  locale: nil];

          formatted = [NSString stringWithFormat: @"'%@'", format];
                                  
        }
      else
        formatted = [NSString stringWithFormat: @"'%@'",value];
    }
  else if ([externalType isEqualToString: @"bytea"]) 
    {
      unsigned char *escapedString;
      size_t newLength;

      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"bytea case - value=%@ class=%@",
			    value, [value class]);

      escapedString = PQescapeBytea ((unsigned char *)[value bytes],
				     [value length],
				     &newLength);

      /* Note that the value returned in newLength is unreliable.  */
      formatted = [NSString stringWithFormat: @"'%s'", escapedString];
      if (escapedString)
	{
	  PQfreemem (escapedString);
	}
    }
  else // String...
    {
      int length = 0;

      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"other case - value=%@ class=%@",
			    value, [value class]);      

      string = [NSMutableString stringWithFormat: @"%@", value];

      EOFLOGObjectLevelArgs(@"EOSQLExpression", @"string %p='%@'",
			    string, string);

      length=[string cStringLength];
      tempString = [string cString];
      EOFLOGObjectLevelArgs(@"EOSQLExpression", @"string '%@' tempString=%s",
			    string, tempString);

      for (i = 0, dif = 0; i < length; i++)
        {
          switch (tempString[i])
            {
            case '\\':
            case '\'':
              [string insertString: @"\\" atIndex: dif + i];
              dif++;
              break;
            case '_':
              [string insertString: @"\\" atIndex: dif + i];
              dif++;
              break;
            default:
              break;
            }
        }
      EOFLOGObjectLevelArgs(@"EOSQLExpression", @"string '%@' tempString=%s",
			    string, tempString);

      formatted = [NSString stringWithFormat: @"'%@'", string];      

      EOFLOGObjectLevelArgs(@"EOSQLExpression", @"formatted %p=%@",
			    formatted, formatted);
    }

  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"formatted=%@", formatted);

  EOFLOGObjectFnStop();

  return formatted;
}

- (NSString *)lockClause
{
  return @"FOR UPDATE";
}

- (NSString *)assembleSelectStatementWithAttributes: (NSArray *)attributes
                                               lock: (BOOL)lock
                                          qualifier: (EOQualifier *)qualifier
                                         fetchOrder: (NSArray *)fetchOrder
                                       selectString: (NSString *)selectString
                                         columnList: (NSString *)columnList
                                          tableList: (NSString *)tableList
                                        whereClause: (NSString *)whereClause
                                         joinClause: (NSString *)joinClause
                                      orderByClause: (NSString *)orderByClause
                                         lockClause: (NSString *)lockClause
{
  //OK
  NSMutableString *sqlString = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"selectString=%@", selectString);
  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"columnList=%@", columnList);
  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"tableList=%@", tableList);

  sqlString = [NSMutableString stringWithFormat: @"%@ %@ FROM %@",
			       selectString,
			       columnList,
			       tableList];

  if (whereClause && joinClause)
    [sqlString appendFormat: @" WHERE (%@) AND (%@)",
               whereClause,
               joinClause];
  else if (whereClause || joinClause)
    [sqlString appendFormat: @" WHERE %@",
               (whereClause ? whereClause : joinClause)];

  if (orderByClause)
    [sqlString appendFormat: @" ORDER BY %@", orderByClause];

  if (lockClause)
    [sqlString appendFormat: @" %@", lockClause];
  
  EOFLOGObjectFnStop();

  return sqlString;
}

+ (NSArray *)createDatabaseStatementsForConnectionDictionary: (NSDictionary *)connDict
                          administrativeConnectionDictionary: (NSDictionary *)admConnDict
{
  NSArray *newArray;
  NSString *databaseName;
  NSString *stmt;
  EOSQLExpression *expr;

  databaseName = [connDict objectForKey: @"databaseName"];
  
  expr = [self expressionForString: nil];
  databaseName = [expr sqlStringForSchemaObjectName: databaseName];
  stmt = [NSString stringWithFormat:@"CREATE DATABASE %@", databaseName];
  [expr setStatement: stmt];
  newArray = [NSArray arrayWithObject: expr];
  
  return newArray;
}

+ (NSArray *)dropDatabaseStatementsForConnectionDictionary: (NSDictionary *)connDict
			administrativeConnectionDictionary: (NSDictionary *)admConnDict
{
  NSArray *newArray;
  NSString *databaseName;
  NSString *stmt;
  EOSQLExpression *expr;

  databaseName = [connDict objectForKey: @"databaseName"];
  expr = [self expressionForString: nil];
  databaseName = [expr sqlStringForSchemaObjectName: databaseName];
  stmt = [NSString stringWithFormat:@"DROP DATABASE %@", databaseName];
  [expr setStatement: stmt];
  newArray = [NSArray arrayWithObject: expr];
  
  return newArray;
}

+ (NSArray *)dropTableStatementsForEntityGroup:(NSArray *)entityGroup
{
  EOEntity *entity;
  NSArray  *newArray;
  int       version;

  EOFLOGClassFnStartOrCond(@"EOSQLExpression");

  entity = [entityGroup objectAtIndex: 0];
  version = [[[[entity model] connectionDictionary]
	      objectForKey: @"databaseVersion"] parsedFirstVersionSubstring];
  if (version == 0)
    {
      version = postgresClientVersion();
    }

  if (version < 70300)
    {
      newArray = [super dropTableStatementsForEntityGroup: entityGroup];
    }
  else
    {
      EOSQLExpression *sqlExp;
      NSString *tableName;
      NSString *stmt;
      
      if ([entity isAbstractEntity])
        {
  	  return [NSArray array];
        }

      sqlExp = [self expressionForString: nil];
      tableName = [entity externalName];
      tableName = [sqlExp sqlStringForSchemaObjectName: tableName];
      stmt = [NSString stringWithFormat: @"DROP TABLE %@ CASCADE", tableName];
      [sqlExp setStatement: stmt];
      newArray = [NSArray arrayWithObject: sqlExp];
    }

  EOFLOGClassFnStopOrCond(@"EOSQLExpression");

  return newArray;
}

- (void)prepareConstraintStatementForRelationship: (EORelationship *)relationship
				    sourceColumns: (NSArray *)sourceColumns
			       destinationColumns: (NSArray *)destinationColumns
{
  // We redefine this method to add "DEFERRABLE INITIALLY DEFERRED": it is needed
  // to be able to insert rows into table related to other table rows, before these
  // other rows have been inserted (relationship might be bidirectional, or it might
  // simply be an operation order problem)
  // Q: shouldn't we move this into EOSQLExpression.m?
  [super prepareConstraintStatementForRelationship:relationship sourceColumns:sourceColumns destinationColumns:destinationColumns];
  ASSIGN(_statement, [_statement stringByAppendingString:@" DEFERRABLE INITIALLY DEFERRED"]);
}

/** Build join expression for all used relationships (call this) after all other query parts construction) **/
- (void)joinExpression
{
  int contextStackCount=0;

  EOFLOGObjectFnStart();

  contextStackCount=[_contextStack count];
  if (contextStackCount>1 && _flags.hasOuterJoin)
    {
      // No join clause in postgresql, joins are added in -tableList...
      if (_joinClauseString)
        DESTROY(_joinClauseString);
    }
  else
    [super joinExpression];

  EOFLOGObjectFnStop();
}

- (NSString *)tableListWithRootEntity: (EOEntity*)entity
{
  int contextStackCount=0;  
  NSString *finalEntitiesString=nil;

  EOFLOGObjectFnStart();
  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"entity=%@", entity);
  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"_aliasesByRelationshipPath=%@",
                        _aliasesByRelationshipPath);
  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"_flags.hasOuterJoin=%d",
                        _flags.hasOuterJoin);

  contextStackCount=[_contextStack count];
  if (contextStackCount>1 && _flags.hasOuterJoin)
    {      
      // joins are added here and not in join clause.
      NSMutableString *entitiesString = [NSMutableString string];
      NSString *relationshipPath = nil ;
      EOEntity *currentEntity = nil;
      int i = 0;
      int relPathIndex = 0;
      BOOL useAliases=[self useAliases];
      
      
      for(relPathIndex=0;relPathIndex<contextStackCount;relPathIndex++)
        {
          relationshipPath = [_contextStack objectAtIndex:relPathIndex];
          currentEntity = entity;
          
          if ([relationshipPath isEqualToString: @""])
            {
              NSString *tableName = [currentEntity externalName];

	      tableName = [self sqlStringForSchemaObjectName: tableName];
              EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                    @"entity %p named %@: "
				    @"externalName=%@ tableName=%@",
                                    currentEntity, [currentEntity name],
                                    [currentEntity externalName], tableName);
              
              NSAssert1([[currentEntity externalName] length]>0,
			@"No external name for entity %@",
                        [currentEntity name]);
              
              [entitiesString appendString: tableName];
              
              EOFLOGObjectLevelArgs(@"EOSQLExpression", 
				    @"entitiesString=%@", entitiesString);

              if (useAliases)
                [entitiesString appendFormat: @" %@",
                                [_aliasesByRelationshipPath
                                  objectForKey: relationshipPath]];
              EOFLOGObjectLevelArgs(@"EOSQLExpression", 
				    @"entitiesString=%@", entitiesString);
            }
          else
            {
              NSEnumerator *defEnum = nil;
              NSArray *defArray = nil;
              NSString *relationshipString;
              NSString *tableName = nil;
              EORelationship *rel = nil;
              EOQualifier *auxiliaryQualifier = nil;
              NSArray *joins = nil;
              int i, count=0;
              NSMutableString* joinOn=[NSMutableString string];
              EOJoinSemantic joinSemantic;
              NSString* joinOp = nil;
              
              defArray = [relationshipPath componentsSeparatedByString: @"."];
              defEnum = [defArray objectEnumerator];
              
              // Get the relationship for this path (non flattened by design)
              rel = [entity relationshipForPath: relationshipPath];
              
              EOFLOGObjectLevelArgs(@"EOSQLExpression", @"rel=%@", rel);
              NSAssert2(rel, @"No relationship for path %@ in entity %@",
                        relationshipPath,
                        [entity name]);
              
              //Get the auxiliary qualifier for this relationship
              auxiliaryQualifier = [rel auxiliaryQualifier];
              
              if (auxiliaryQualifier)
                {
                  NSEmitTODO();  //TODO
                  [self notImplemented:_cmd]; 
                }
	      
              while ((relationshipString = [defEnum nextObject]))
                {
                  // use anyRelationshipNamed: to find hidden relationship too
                  EORelationship *relationship=[currentEntity 
                                                 anyRelationshipNamed: relationshipString];
                  
                  NSAssert2(relationship,@"No relationship named %@ in entity %@",
                            relationshipString,
                            [currentEntity name]);
                  
                  NSAssert2(currentEntity,@"No destination entity. Entity %@ relationship = %@",
                            [currentEntity name],
                            relationship);
                  
                  currentEntity = [relationship destinationEntity];
                }
              
              tableName = [currentEntity externalName];
	      tableName = [self sqlStringForSchemaObjectName: tableName];

              EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                    @"entity %p named %@: "
				    @"externalName=%@ tableName=%@",
                                    currentEntity, [currentEntity name],
                                    [currentEntity externalName], tableName);
              
              NSAssert1([[currentEntity externalName] length]>0,
			@"No external name for entity %@",
                        [currentEntity name]);
              
              joinSemantic = [rel joinSemantic];
              switch (joinSemantic)
                {
                case EOInnerJoin:
                  joinOp = @"INNER JOIN";
                  break;
                case EOLeftOuterJoin:
                  joinOp = @"LEFT OUTER JOIN";
                  break;
                case EORightOuterJoin:
                  joinOp = @"RIGHT OUTER JOIN";
                  break;
                case EOFullOuterJoin:
                  joinOp = @"FULL OUTER JOIN";
                  break;
                }
              
              // Get relationship joins
              joins = [rel joins];
              count = [joins count];
              EOFLOGObjectLevelArgs(@"EOSQLExpression", @"joins=%@", joins);
              
              // Iterate on each join
              for (i = 0; i < count; i++)
                {
                  NSString *sourceRelationshipPath = nil;
                  NSArray *sourceRelationshipPathArray;
                  //Get the join
                  EOJoin *join=[joins objectAtIndex:i];
                  // Get source and destination attributes
                  EOAttribute *sourceAttribute = [join sourceAttribute];
                  EOAttribute *destinationAttribute = [join destinationAttribute];
                  NSString *sourceAttributeAlias = nil;
                  NSString *destinationAttributeAlias = nil;
                  
                  // Build the source relationshipPath
                  sourceRelationshipPathArray =
                    [relationshipPath componentsSeparatedByString: @"."];
                  sourceRelationshipPathArray =
                    [sourceRelationshipPathArray
                      subarrayWithRange:
                        NSMakeRange(0,[sourceRelationshipPathArray count] - 1)];  
                  sourceRelationshipPath = [sourceRelationshipPathArray
                                             componentsJoinedByString: @"."];
                  
                  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"sourceRelationshipPath=%@", sourceRelationshipPath);

                  // Get the alias for sourceAttribute
                  sourceAttributeAlias = [self
                                           _aliasForRelatedAttribute:
                                             sourceAttribute
                                           relationshipPath:
                                             sourceRelationshipPath];
                  
                  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"sourceAttributeAlias=%@", sourceAttributeAlias);
                  
                  // Get the alias for destinationAttribute
                  destinationAttributeAlias =
                    [self _aliasForRelatedAttribute: destinationAttribute
                          relationshipPath: relationshipPath];
                  
                  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"addJoin=%@ %d %@",
                                        sourceAttributeAlias,
                                        (int)joinSemantic,
                                        destinationAttributeAlias);
                  
                  
                  if (i>0)
                    [joinOn appendString:@", "];
                  joinOn = [NSString stringWithFormat: @"%@ = %@", 
                                     sourceAttributeAlias,
                                     destinationAttributeAlias];
                  
                  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"joinOn=%@", joinOn);
                }
              
              [entitiesString appendFormat:@" %@ %@",
                              joinOp,
                              tableName];
              
              EOFLOGObjectLevelArgs(@"EOSQLExpression", @"entitiesString=%@", entitiesString);
              
              if (useAliases)
                {
                  NSString *alias = [_aliasesByRelationshipPath
                                      objectForKey: relationshipPath];
                  
                  [entitiesString appendFormat: @" %@",alias];
                  
                  EOFLOGObjectLevelArgs(@"EOSQLExpression",
                                        @"appending alias %@ in entitiesString",
                                        alias);
                }
              EOFLOGObjectLevelArgs(@"EOSQLExpression", @"entitiesString=%@", entitiesString);
              
              [entitiesString appendFormat:@" on (%@) ",joinOn];
              
              EOFLOGObjectLevelArgs(@"EOSQLExpression", @"entitiesString=%@", entitiesString);
            }
          
          i++;
        }
      finalEntitiesString=entitiesString;
    }
  else
    finalEntitiesString=[super tableListWithRootEntity:entity];
    
  EOFLOGObjectLevelArgs(@"EOSQLExpression",
                        @"finalEntitiesString=%@",
                        finalEntitiesString);
  
  EOFLOGObjectFnStop();

  return finalEntitiesString;
}

// PostgreSQL like seems buggy:
// see http://www.postgresql.org/docs/7.4/interactive/functions-matching.html
// for exemple "ab" doesn't match [_]b

+ (NSString *)sqlPatternFromShellPattern: (NSString *)pattern
{
  NSString* sqlPattern=nil;
  int patternLength=[pattern length];
  if (patternLength==0)
    sqlPattern=pattern;
  else
    {
      const char *s, *p, *init = [pattern cString];
      NSString *tmp;
      NSMutableString *str = [NSMutableString stringWithCapacity:
                                                patternLength];
      IMP appendStringIMP = [str methodForSelector:@selector(appendString:)];
      
      for (s = p = init; *s; s++)
        {
          switch (*s)
            {
            case '*':
              if (s != p)
		{
		  tmp = [(PSQLA_alloc(NSString)) initWithCString: p
						 length: s-p];
		  PSQLA_AppendStringWithImp(str, appendStringIMP, tmp);
		  [tmp release];
		}
              [str appendString: @"%"];
              p = s+1;
              break;
            case '?':
              if (s != p)
		{
		  tmp = [(PSQLA_alloc(NSString)) initWithCString: p
						 length: s-p];
		  PSQLA_AppendStringWithImp(str, appendStringIMP, tmp);
		  [tmp release];
		}
              (*appendStringIMP)(str,@selector(appendString:),@"_");
              p = s+1;
              break;
            case '%':
              if (s != p)
		{
		  tmp = [(PSQLA_alloc(NSString)) initWithCString: p
						 length: s-p];
		  PSQLA_AppendStringWithImp(str, appendStringIMP, tmp);
		  [tmp release];
		}
              if (s != init && *(s-1) == '[' && *(s+1) == ']')
                {
                  (*appendStringIMP)(str,@selector(appendString:),@"%]");
                  p = s+2; s++;
                }
              else
                {
                  (*appendStringIMP)(str,@selector(appendString:),@"[%]");
                  p = s+1;
                }
              break;
/*PostgreSQLql doesn't want [_] but want _
            case '_':
              if (s != p)
                (*appendStringIMP)(str,@selector(appendString:),
                                   (*stringWithCString_lengthIMP)
                                   (PSQLA_NSStringClass,PSQLA_stringWithCString_lengthSEL,p,s-p));
              
              if (s != init && *(s-1) == '[' && *(s+1) == ']')
                {
                  (*appendStringIMP)(str,@selector(appendString:),@"_]");
                  p = s+2; p++;
                }
              else
                {
                  (*appendStringIMP)(str,@selector(appendString:),@"[_]");
                  p = s+1;
                }
              break;
*/
            }
        }
      
      if (*p)
        (*appendStringIMP)(str,@selector(appendString:),[NSString stringWithCString:p]);

      sqlPattern=str;
    };

  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"pattern=%@ => %@",
			pattern,sqlPattern);

  return sqlPattern;
}

+ (NSString *)sqlPatternFromShellPattern: (NSString *)pattern
                     withEscapeCharacter: (unichar)escapeCharacter
{
  const char *s, *p, *init = [pattern cString];
  NSString *tmp;
  NSMutableString *str = [NSMutableString stringWithCapacity:
					    [pattern length]];
  IMP appendStringIMP = [str methodForSelector:@selector(appendString:)];

  for (s = p = init; *s; s++)
    {
      switch (*s)
        {
	case '*':
	  if (s != p)
	    {
	      tmp = [(PSQLA_alloc(NSString)) initWithCString: p
					     length: s-p];
	      PSQLA_AppendStringWithImp(str, appendStringIMP, tmp);
	      [tmp release];
	    }
	  PSQLA_AppendStringWithImp(str,appendStringIMP,@"%");
	  p = s+1;
	  break;
	case '?':
	  if (s != p)
	    {
	      tmp = [(PSQLA_alloc(NSString)) initWithCString: p
					     length: s-p];
	      PSQLA_AppendStringWithImp(str, appendStringIMP, tmp);
	      [tmp release];
	    }
	  PSQLA_AppendStringWithImp(str,appendStringIMP,@"_");
	  p = s+1;
	  break;
	case '%':
	  if (s != p)
	    {
	      tmp = [(PSQLA_alloc(NSString)) initWithCString: p
					     length: s-p];
	      PSQLA_AppendStringWithImp(str, appendStringIMP, tmp);
	      [tmp release];
	    }
	  if (s != init && *(s-1) == '[' && *(s+1) == ']')
	    {
	      PSQLA_AppendStringWithImp(str,appendStringIMP,@"%]");
	      p = s+2; s++;
	    }
	  else
	    {
	      PSQLA_AppendStringWithImp(str,appendStringIMP,@"[%]");
	      p = s+1;
	    }
	  break;
/*PostgreSQLql doesn't want [_] but want _
	case '_':
	  if (s != p)
	    PSQLA_AppendStringWithImp(str,appendStringIMP,
            (*stringWithCString_lengthIMP)
            (PSQLA_NSStringClass,PSQLA_stringWithCString_lengthSEL,p,s-p));
	  
	  if (s != init && *(s-1) == '[' && *(s+1) == ']')
	    {
	      PSQLA_AppendStringWithImp(str,appendStringIMP,@"_]");
	      p = s+2; p++;
	    }
	  else
	    {
	      PSQLA_AppendStringWithImp(str,appendStringIMP,@"[_]");
	      p = s+1;
	    }
	  break;
*/
        }
    }

  if (*p)
    PSQLA_AppendStringWithImp(str,appendStringIMP,[NSString stringWithCString:p]);

  return str;
}

- (NSString *)columnTypeStringForAttribute:(EOAttribute *)attribute
{
  NSString *extType = [attribute externalType];
  NSString *columnTypeString = nil;

  if ([extType isEqualToString: @"text"])
    {
      columnTypeString = [NSString stringWithFormat: @"%@", extType];
    }
  else
    {
      columnTypeString = [super columnTypeStringForAttribute: attribute];
    }

  return columnTypeString;
}

@end
