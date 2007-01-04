/** 
   PostgreSQLAdaptor.m <title>PostgreSQLAdaptor</title>

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   based on the PostgreSQL adaptor written by
         Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAccess.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOExpressionArray.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>

#include "PostgreSQLAdaptor.h"
#include "PostgreSQLContext.h"
#include "PostgreSQLChannel.h"
#include "PostgreSQLExpression.h"

#include "PostgreSQLPrivate.h"

NSString *PostgreSQLException = @"PostgreSQLException";
static int pgConnTotalAllocated = 0;
static int pgConnCurrentAllocated = 0;

int
postgresClientVersion()
{
  static int version = 0;
  if (version == 0)
    {
      NSString *versionString = [NSString stringWithCString: PG_VERSION];
      version = [versionString parsedFirstVersionSubstring];
    }
  return version;
}


@implementation PostgreSQLAdaptor

- init
{
  return [self initWithName: @"PostgreSQL"];
}

- initWithName: (NSString *)name
{
  if ((self = [super initWithName: name]))
    {
      _pgConnPool = [NSMutableArray new];
    }

  return self;
}

- (void)dealloc
{
  NSEnumerator *enumerator;
  PGconn *pgConn;

  enumerator = [_pgConnPool objectEnumerator];

  while ((pgConn = [[enumerator nextObject] pointerValue]))
    [self releasePGconn: pgConn force: YES];

  DESTROY(_pgConnPool);

  [super dealloc];
}

- (void)privateReportError: (PGconn*)pgConn
{
  char *message = "NULL pgConn in privateReportError:";

  EOFLOGObjectFnStart();
  
  if (pgConn)
    message = PQerrorMessage(pgConn);
  
  NSLog(@"%s", message);

  EOFLOGObjectFnStop();
}

- (void)setCachePGconn: (BOOL)flag
{
  _flags.cachePGconn = flag;
}

- (BOOL)cachePGconn
{
  return _flags.cachePGconn;
}

- (void)setPGconnPoolLimit: (int)value
{
  _pgConnPoolLimit = value;
}

- (int)pgConnPoolLimit
{
  return _pgConnPoolLimit;
}

/*+ (NSDictionary *)defaultConnectionDictionary
{
    static NSDictionary *dict = nil;

    if (!dict)
        dict = [[NSDictionary dictionaryWithObjectsAndKeys:NSHomeDirectory(), FlatFilePathKey, [self defaultRowSeparator], FlatFileRowSeparatorKey, [self defaultColumnSeparator], FlatFileColumnSeparatorKey, @"Y", FlatFileUseHeadersKey, nil] retain];

    return dict;
    }*/


/* 
   The first 4 must correspond to EOAdaptorValueTypes.
   external type name	internal type name
 */
static NSString *typeNames[][2] = {
{@"numeric",		@"NSNumber"},		/* EOAdaptorNumberType */
{@"varchar",		@"NSString"}, 		/* EOAdaptorCharactersType */
{@"bytea",		@"NSData"},		/* EOAdaptorBytesType */
{@"date",		@"NSCalendarDate"},	/* EOAdaptorDateType */
{@"boolean",		@"NSNumber"},
{@"bool",		@"NSNumber"},
{@"char",		@"NSString"},
{@"char2",		@"NSString"},
{@"char4",		@"NSString"},
{@"char8",		@"NSString"},
{@"char16",		@"NSString"},
{@"filename",		@"NSString"},
{@"reltime",		@"NSCalendarDate"},
{@"time",		@"NSCalendarDate"},
{@"tinterval",		@"NSCalendarDate"},
{@"abstime",		@"NSCalendarDate"},
{@"timestamp",		@"NSCalendarDate"},
{@"real",		@"NSNumber"},
{@"double precision", 	@"NSNumber"},
{@"float4",		@"NSNumber"},
{@"float8",		@"NSNumber"},
{@"bigint", 		@"NSNumber"},
{@"int8",		@"NSNumber"},
{@"integer",		@"NSNumber"},
{@"int4",		@"NSNumber"},
{@"smallint",		@"NSNumber"},
{@"int2",		@"NSNumber"},
{@"oid",		@"NSNumber"},
{@"oid8",		@"NSNumber"},
{@"oidint2",		@"NSNumber"},
{@"oidint4",		@"NSNumber"},
{@"oidchar16",		@"NSNumber"},
{@"serial",		@"NSNumber"},
{@"serial8",		@"NSNumber"},
{@"decimal",		@"NSDecimalNumber"},
{@"cid",		@"NSDecimalNumber"},
{@"tid",		@"NSDecimalNumber"},
{@"xid",		@"NSDecimalNumber"},
{@"bpchar",		@"NSData"}
};

+ (NSDictionary *)externalToInternalTypeMap
{
  static NSDictionary *externalToInternalTypeMap = nil;

  if (!externalToInternalTypeMap)
  {
    int i, c;
    id *externalTypeNames;
    id *internalTypeNames;
    size_t size;

    c = sizeof(typeNames) / sizeof(typeNames[0]);
    size = sizeof(id) * c;
    externalTypeNames = (id *)NSZoneMalloc([self zone], size); 
    internalTypeNames = (id *)NSZoneMalloc([self zone], size); 

    for (i = 0; i < c; i++)
      {
	externalTypeNames[i] = typeNames[i][0];
	internalTypeNames[i] = typeNames[i][1];
      }

    externalToInternalTypeMap = [[NSDictionary alloc] initWithObjects: internalTypeNames forKeys: externalTypeNames count: i];
    NSZoneFree([self zone], externalTypeNames);
    NSZoneFree([self zone], internalTypeNames);
  }

  return externalToInternalTypeMap;
}

+ (NSString *)internalTypeForExternalType: (NSString *)extType
				    model: (EOModel *)model
{
  return [[self externalToInternalTypeMap] objectForKey: extType];
}

+ (NSArray *)externalTypesWithModel:(EOModel *)model
{
  return [[self externalToInternalTypeMap] allKeys];
}

+ (void)assignExternalTypeForAttribute: (EOAttribute *)attribute
{
  // TODO
  EOAdaptorValueType value = [attribute adaptorValueType];

  [attribute setExternalType: typeNames[value][0]];
}

/* Inherited methods */

- (EOAdaptorContext *)createAdaptorContext
{
  //OK
  return [PostgreSQLContext adaptorContextWithAdaptor: self];
}

- (Class)defaultExpressionClass
{
  Class expressionClass;

  EOFLOGObjectFnStart();

  expressionClass = [PostgreSQLExpression class];

  EOFLOGObjectFnStop();

  return expressionClass;
}

- (BOOL)isValidQualifierType: (NSString *)typeName
                       model: (EOModel *)model
{
  int i,c;
  
  for (i = 0, c = sizeof(typeNames) / sizeof(typeNames[0]); i < c; i++)
    {
      //TODO REMOVE
      NSDebugMLog(@"externalTypeNames[i]=%@", typeNames[i][0]);

      if ([typeNames[i][0] isEqualToString: typeName])
        return YES;
    }
  //TODO REMOVE

  NSDebugMLog(@"typeName=%@", typeName);

  return NO;
}

- (void)assertConnectionDictionaryIsValid
{

  if (![self hasOpenChannels])
    {
      EOAdaptorContext *adaptorContext;
      EOAdaptorChannel *adaptorChannel;
      volatile NSException *exception = nil;

      adaptorContext = [self createAdaptorContext];
      adaptorChannel = [adaptorContext createAdaptorChannel];

      NS_DURING
	[adaptorChannel openChannel];
      NS_HANDLER
	exception = localException;
      NS_ENDHANDLER;

      if ([adaptorChannel isOpen])
        [adaptorChannel closeChannel];

      if (exception)
	[exception raise];
    }
}

/*
-(NSString *)formatValue:(id)value
            forAttribute:(EOAttribute*)attribute
{
    return [value stringValueForPostgreSQLType:[attribute externalType] 
                  attribute:attribute];
}
*/

- (NSString *)fetchedValueForString: (NSString *)value
                          attribute: (EOAttribute *)attribute
{
  return value;
}


//TODO: don't need to be overriden ??
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

/* Private methods for PostgreSQL Adaptor */

- (PGconn *)createPGconn
{
  char *pg_host = NULL;
  char *pg_database = NULL;
  char *pg_port = NULL;
  char *pg_options = NULL;
  char *pg_tty = NULL;
  char *pg_user = NULL;
  char *pg_pwd = NULL;
  PGconn *pgConn = NULL;
  PGresult *pgResult = NULL;
  NSString *str = nil;

  EOFLOGObjectFnStart();
    
  //OK
  str = [_connectionDictionary objectForKey: @"databaseServer"]; 
  if (!str)
    str = [_connectionDictionary objectForKey: @"hostName"];

  pg_host = (char*)[str cString];

  pg_database = (char*)[[_connectionDictionary objectForKey: @"databaseName"]
                         cString]; 
  pg_port = (char*)[[_connectionDictionary objectForKey: @"port"] cString]; 
  if (!pg_port)
    pg_port = (char*)[[_connectionDictionary objectForKey: @"hostPort"]
		       cString]; 

  pg_options = (char*)[[_connectionDictionary objectForKey: @"options"]
                        cString]; 
  pg_tty = (char*)[[_connectionDictionary objectForKey: @"debugTTY"] cString]; 
  pg_user = (char*)[[_connectionDictionary objectForKey: @"userName"]
                     cString]; 
  pg_pwd = (char*)[[_connectionDictionary objectForKey: @"password"]
                    cString]; 

  NSDebugMLog(@"%s %s %s %s %s", pg_host, pg_port, pg_database, pg_user, pg_pwd);

  // Try to connect to the PostgreSQL server
  if (pg_user)
    pgConn = PQsetdbLogin(pg_host, pg_port, pg_options, pg_tty, 
                          pg_database,pg_user,pg_pwd);
  else
    pgConn = PQsetdb(pg_host, pg_port, pg_options, pg_tty, pg_database);

  NSDebugMLog(@"%s %s %s %s %s", pg_host, pg_port, pg_database, pg_user,
	      pg_pwd);

  // Check connection
  if (PQstatus(pgConn) == CONNECTION_BAD)
    {
      NSString *reason;

      reason = [NSString stringWithCString:PQerrorMessage(pgConn)];
      [self privateReportError: pgConn];
      PQfinish(pgConn);
      [[NSException exceptionWithName:@"InvalidConnection" 
		    reason: reason
		    userInfo:nil] raise]; 
    }

  if (pgConn)
    {
      pgResult = PQexec(pgConn, "SET DATESTYLE TO 'SQL'");
      PQclear(pgResult);
      pgResult = NULL;

      if (pgConn)
        {
          pgConnTotalAllocated++;
          pgConnCurrentAllocated++;
        }
    }

  EOFLOGObjectFnStop();

  return pgConn;
}

- (PGconn *)newPGconn
{
  PGconn *pgConn = NULL;

  if(_flags.cachePGconn && [_pgConnPool count])
    {
      NSDebugMLog(@"newPGconn cached %p (pgConn=%p) total=%d current=%d",
                  self,
                  pgConn,
                  pgConnTotalAllocated,
                  pgConnCurrentAllocated);

      pgConn = [[_pgConnPool lastObject] pointerValue];
      [_pgConnPool removeLastObject];
    }
  else
    {
      pgConn = [self createPGconn];

      NSDebugMLog(@"newPGconn not cached %p (pgConn=%p) total=%d current=%d",
                  self,
                  pgConn,
                  pgConnTotalAllocated,
                  pgConnCurrentAllocated);
    }

  return pgConn;
}

- (void)releasePGconn: (PGconn *)pgConn
                force: (BOOL)flag
{
  if (!flag 
      && _flags.cachePGconn 
      && (PQstatus(pgConn) == CONNECTION_OK)
      && [_pgConnPool count] < _pgConnPoolLimit)
    {
      NSDebugMLog(@"releasePGconn -> in pool %p (pgConn=%p) total=%d current=%d",
		  self,
		  pgConn,
		  pgConnTotalAllocated,
		  pgConnCurrentAllocated);

      [_pgConnPool addObject: [NSValue value: pgConn
				       withObjCType: @encode(PGconn*)]];
    }
  else
    {
      NSDebugMLog(@"releasePGconn really %p (pgConn=%p) total=%d current=%d",
		  self,
		  pgConn,
		  pgConnTotalAllocated,
		  pgConnCurrentAllocated);

      pgConnCurrentAllocated--;
      PQfinish(pgConn);
    }
}

// format is something like @"%@_SEQ" or @"EOSEQ_%@", "%@" is replaced by external table name
- (void)setPrimaryKeySequenceNameFormat: (NSString*)format
{
  ASSIGN(_primaryKeySequenceNameFormat, format);
}

- (NSString*)primaryKeySequenceNameFormat
{
  if (!_primaryKeySequenceNameFormat)
    _primaryKeySequenceNameFormat = [_connectionDictionary objectForKey: @"primaryKeySequenceNameFormat"];

  if (!_primaryKeySequenceNameFormat)
    _primaryKeySequenceNameFormat = @"%@_SEQ";

  return _primaryKeySequenceNameFormat;
}

@end /* PostgreSQLAdaptor */

/*
//TODO
databaseEncoding
{
  self connectionDictionary
call dict obj for key databaseEncoding
    return 2 par defaut
};
*/
