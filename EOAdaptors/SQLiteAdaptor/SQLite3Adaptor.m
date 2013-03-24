
/* 
   SQLite3Adaptor.m

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@gmail.com>
   Date: 2006

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

#include <GNUstepBase/GNUstep.h>

#include "SQLite3Adaptor.h"
#include "SQLite3Context.h"
#include "SQLite3Expression.h"

#include <Foundation/NSDictionary.h>

NSString *SQLite3AdaptorExceptionName = @"SQLite3AdaptorException";

@implementation SQLite3Adaptor
- (id) init
{
  return [self initWithName:@"SQLite3Adaptor"];
}

static NSString *types[][2] =
{ 
  {@"INTEGER",	@"NSDecimalNumber"},
  {@"TEXT",	@"NSString"},
  {@"BLOB",	@"NSData"},
  {@"DATE",	@"NSCalendarDate"},
  {@"REAL",	@"NSNumber"},
  {@"VARCHAR",	@"NSString"},
  {@"DOUBLE",	@"NSNumber"},
  {@"NULL",	@"EONull"},
};

+ (NSDictionary *)externalToInternalTypeMap
{
    static NSDictionary *externalToInternalTypeMap = nil;

    if (!externalToInternalTypeMap)
      {
        int i;
        NSString *external[sizeof(types)/sizeof(types[0])];
        NSString *internal[sizeof(types)/sizeof(types[0])];
	
	for (i = 0; i < sizeof(types)/sizeof(types[0]); i++)
	   {
	     external[i] = types[i][0];
	     internal[i] = types[i][1];
	   }
        externalToInternalTypeMap = [[NSDictionary dictionaryWithObjects:internal forKeys:external count:i] retain];
      }

    return externalToInternalTypeMap;
}

+ (NSString *)internalTypeForExternalType:(NSString *)extType model:(EOModel *)model
{
    return [[self externalToInternalTypeMap] objectForKey:extType];
}

+ (NSString *)defaultExternalType
{
    return types[1][0];
}

+ (void)assignExternalTypeForAttribute:(EOAttribute *)attribute
{
  [attribute setExternalType:types[[attribute adaptorValueType]][0]];
}

- (EOAdaptorContext *)createAdaptorContext
{
  return AUTORELEASE([[SQLite3Context alloc] initWithAdaptor: self]);
}

- (Class)defaultExpressionClass
{
  return [SQLite3Expression class];
}

- (Class)expressionClass
{
  return [SQLite3Expression class];
}

- (BOOL)isValidQualifierType:(NSString *)typeName model:(EOModel *)model
{
  return ![typeName isEqualToString:@"BLOB"];
}

- (void)assertConnectionDictionaryIsValid
{
  NSString *dbPath = [[self connectionDictionary] objectForKey:@"databasePath"];
  // don't check if it exists because might be creating it.
  NSAssert(dbPath, @"invalid connection dictionary");
}

- (NSString *)fetchedValueForString: (NSString *)value
                          attribute: (EOAttribute *)attribute
{
  return value;
}

- (NSNumber *)fetchedValueForNumberValue: (NSNumber *)value
                               attribute: (EOAttribute *)attribute
{
  return value; // TODO scale and precision
}

- (NSCalendarDate *)fetchedValueForDateValue: (NSCalendarDate *)value
                                   attribute: (EOAttribute *)attribute
{
  return value;
}

- (NSData *)fetchedValueForDataValue: (NSData *)value
                           attribute: (EOAttribute *)attribute
{
  return value;
}

@end

