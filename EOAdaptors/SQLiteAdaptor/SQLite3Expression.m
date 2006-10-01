
/* 
   SQLite3Expression.m

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@yahoo.com>
   Date: 2006

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

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif
#include "SQLite3Expression.h"
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOSchemaGeneration.h>
#include <EOControl/EONull.h>
#include <Foundation/NSData.h>

@implementation SQLite3Expression 
static NSString *escapeString(NSString *value)
{
  int length = 0, dif, i;
  NSMutableString *string = [NSMutableString stringWithFormat: @"%@", value];
  const char *tempString;
  
  length=[string cStringLength];
  tempString = [string cString];

  for (i = 0, dif = 0; i < length; i++)
    {
      switch (tempString[i])
        {
          case '\'':
            [string insertString: @"'" atIndex: dif + i];
            dif++;
            break;
          default:
            break;
        }
    } 
  return string;
}

+ (NSString *)formatValue: (id)value
             forAttribute: (EOAttribute *)attribute
{
  NSString *externalType = [attribute externalType];
  
  if (!value)
    {
      return @"NULL";
    }
  else if ([value isEqual: [EONull null]])
    {
      return [value sqlString];
    }
  else if ([externalType isEqual:@"TEXT"])
    {
      return [NSString stringWithFormat:@"'%@'", escapeString(value)];
    }
  else if ([externalType isEqual:@"BLOB"])
    {
      return [NSString stringWithFormat:@"X'%@'", [(NSData *)value hexadecimalRepresentation]];
    }
  else
    {
      return [NSString stringWithFormat:@"'%@'", escapeString(value)];
    }
}
- (NSString *)lockClause
{
  return @""; // does not support locking..
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
  NSMutableString *sqlString;
  
  sqlString = [NSMutableString stringWithFormat: @"%@ %@ FROM %@",
                               selectString,
                               columnList,
                               tableList];
  if (whereClause && joinClause)
    {
      [sqlString appendFormat: @" WHERE (%@) AND (%@)",
                  whereClause,
                  joinClause];
    }
  else if (whereClause || joinClause)
    {
      [sqlString appendFormat: @" WHERE %@",
               (whereClause ? whereClause : joinClause)];
    }

  if (orderByClause)
    [sqlString appendFormat: @" ORDER BY %@", orderByClause];

  return sqlString;
}

- (NSString *)columnTypeStringForAttribute:(EOAttribute *)attribute
{
  NSString *typeString = [super columnTypeStringForAttribute:attribute];
  if ([[[attribute entity] primaryKeyAttributes] containsObject:attribute])
    {
      return [NSString stringWithFormat:@"%@ %@", typeString, @"PRIMARY KEY"];
    }
  return typeString; 
}


+ (NSArray *)primaryKeySupportStatementsForEntityGroup: (NSArray *)entityGroup
{
  return [NSArray array];
}

+ (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup: (NSArray *)entityGroup
{
  return [NSArray array];
}

+ (NSArray *)createDatabaseStatementsForConnectionDictionary: (NSDictionary *)connDict
                          administrativeConnectionDictionary: (NSDictionary *)admConnDict
{
  return [NSArray array];
}
			  
// TODO find a better way to do this?
+ (NSArray *)primaryKeyConstraintStatementsForEntityGroup:(NSArray *)entityGroup
{
  NSString *keyTable;
  keyTable = @"CREATE TABLE IF NOT EXISTS 'SQLiteEOAdaptorKeySequences' (" \
	     @"seq_key INTEGER PRIMARY KEY AUTOINCREMENT, " \
	     @"tableName TEXT, " \
	     @"attributeName TEXT, " \
	     @"key INTEGER" \
	     @")";
  return [NSArray arrayWithObject:[self expressionForString:keyTable]];
}

+ (NSArray *)dropPrimaryKeyConstraintStatementsForEntityGroup:(NSArray *)entityGroup
{
  return [NSArray arrayWithObject:[self expressionForString:@"DROP TABLE 'SQLiteEOAdaptorKeySequences'"]];
}

@end
 
