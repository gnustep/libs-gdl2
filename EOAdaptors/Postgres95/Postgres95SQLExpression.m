/** 
   Postgres95SQLExpression.m <title>Postgres95SQLExpression</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSUtilities.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EONull.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOSchemaGeneration.h>

#include <Postgres95EOAdaptor/Postgres95SQLExpression.h>
#include <Postgres95EOAdaptor/Postgres95Values.h>


@implementation Postgres95SQLExpression

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
  else if ([externalType hasPrefix: @"int"])
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

      formatted = [NSString stringWithFormat: @"%@", value];

      // value was for example 0 length string
      if ([formatted length] == 0)
        formatted=@"NULL";
    }
  else if ([externalType hasPrefix: @"bool"])
    {
      EOFLOGObjectLevelArgs(@"EOSQLExpression",
			    @"BOOL case - value=%@ class=%@",
			    value, [value class]);          

      if ([value isKindOfClass: [NSNumber class]] == YES)
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
      if ([value isKindOfClass:[NSDate class]])
        {
          formatted = [NSString stringWithFormat: @"'%@'",
                                [value
                                  descriptionWithCalendarFormat:
                                    [NSCalendarDate postgres95Format]//@"%d/%m/%Y %H:%M:%S"
                                  timeZone: nil
                                  locale: nil]];
        }
      else
        formatted = [NSString stringWithFormat: @"'%@'",value];
    }
  else
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

      for (i = 0, dif = 0; i < length; i++)
        {
          switch (tempString[i + dif])
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

      formatted = [NSString stringWithFormat: @"'%@'", string];      

      EOFLOGObjectLevelArgs(@"EOSQLExpression", @"formatted %p=%@",
			    formatted, formatted);
    }

  EOFLOGObjectLevelArgs(@"EOSQLExpression", @"formatted=%@", formatted);

  EOFLOGObjectFnStop();

  return formatted;
}

- (NSString *)externalNameQuoteCharacter
{
  if ([EOSQLExpression useQuotedExternalNames])
    return @"'";
  else
    return @"";
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
    [sqlString appendFormat: @" WHERE %@ AND %@",
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
      newArray = [NSArray arrayWithObject: [self expressionForString:
	[NSString stringWithFormat: @"DROP TABLE %@ CASCADE",
		  [entity externalName]]]];
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

@end
