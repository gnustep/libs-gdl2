/** 
   Postgres95Adaptor.m <title>Postgres95Adaptor</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   based on the Postgres95 adaptor written by
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>

#import <EOAccess/EOAccess.h>
#import <EOAccess/EOAttribute.h>
#import <EOAccess/EOExpressionArray.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EOModel.h>

#import <Postgres95EOAdaptor/Postgres95Adaptor.h>
#import <Postgres95EOAdaptor/Postgres95Context.h>
#import <Postgres95EOAdaptor/Postgres95Channel.h>
#import <Postgres95EOAdaptor/Postgres95SQLExpression.h>
#import <Postgres95EOAdaptor/Postgres95Values.h>


NSString *Postgres95Exception = @"Postgres95Exception";
static int pgConnTotalAllocated = 0;
static int pgConnCurrentAllocated = 0;


@implementation Postgres95Adaptor

- init
{
  return [self initWithName: @"Postgres95"];
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

  [_pgConnPool release];

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

static NSString *externalTypeNames[] = {
  @"bool", 
  @"char", @"char2", @"char4", @"char8", @"char16", @"filename", 
  @"date", @"reltime", @"time", @"tinterval", @"abstime", 
  @"float4", @"float8", 
  @"int4", @"int2", 
  @"oid", @"oid8", @"oidint2", @"oidint4", @"oidchar16",
  @"varchar", @"bpchar",
  @"cid", @"tid", @"xid",
  nil
};

static NSString *internalTypeNames[] = {
  @"NSNumber",
  @"NSNumber", @"NSNumber", @"NSNumber", @"NSNumber", @"NSNumber", @"NSNumber",
  @"NSCalendarDate", @"NSCalendarDate", @"NSCalendarDate", @"NSCalendarDate", @"NSCalendarDate",
  @"NSNumber", @"NSNumber",
  @"NSNumber", @"NSNumber",
  @"NSNumber", @"NSNumber", @"NSNumber", @"NSNumber", @"NSNumber",
  @"NSString", @"NSString",
  @"NSDecimalNumber", @"NSDecimalNumber", @"NSDecimalNumber",
  nil
};

+ (NSDictionary *)externalToInternalTypeMap
{
  static NSDictionary *externalToInternalTypeMap = nil;

  if (!externalToInternalTypeMap)
  {
    int i;

    for (i = 0; externalTypeNames[i]; i++);

    externalToInternalTypeMap = [[NSDictionary dictionaryWithObjects: internalTypeNames forKeys: externalTypeNames count: i] retain];
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

+ (void)assignExternalInfoForAttribute: (EOAttribute *)attribute
{
  // TODO
  EOAdaptorValueType value = [attribute adaptorValueType];

  [attribute setExternalType: externalTypeNames[value]];
}

+ (void)assignExternalInfoForEntity: (EOEntity *)entity
{
  NSEnumerator *attributeEnumerator = [[entity attributes] objectEnumerator];
  EOAttribute *attribute;

  while ((attribute = [attributeEnumerator nextObject]))
    [self assignExternalInfoForAttribute: attribute];
}

/* Inherited methods */

- (EOAdaptorContext *)createAdaptorContext
{
  //OK
  return [Postgres95Context adaptorContextWithAdaptor: self];
}

- (Class)defaultExpressionClass
{
  Class expressionClass;

  EOFLOGObjectFnStart();

  expressionClass = [Postgres95SQLExpression class];

  EOFLOGObjectFnStop();

  return expressionClass;
}

- (BOOL)isValidQualifierType: (NSString *)typeName
                       model: (EOModel *)model
{
  int i;
  
  for (i = 0; externalTypeNames[i]; i++)
    {
      //TODO REMOVE
      NSDebugMLog(@"externalTypeNames[i]=%@", externalTypeNames[i]);

      if ([externalTypeNames[i] isEqualToString: typeName])
        return YES;
    }
  //TODO REMOVE

  NSDebugMLog(@"typeName=%@", typeName);

  return NO;
}

- (void)assertConnectionDictionaryIsValid
{
  NSException *exception = nil;
  EOAdaptorContext *adaptorContext;
  EOAdaptorChannel *adaptorChannel;

  if (![self hasOpenChannels])
    {
      adaptorContext = [self createAdaptorContext];
      adaptorChannel = [adaptorContext createAdaptorChannel];

      NS_DURING
	[adaptorChannel openChannel];
      NS_HANDLER
	exception = localException;
      NS_ENDHANDLER;

      [adaptorChannel closeChannel];

      if (exception)
	[exception raise];
    }
}

/*
-(NSString *)formatValue:(id)value
            forAttribute:(EOAttribute*)attribute
{
    return [value stringValueForPostgres95Type:[attribute externalType] 
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

- (void)createDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)connectionDictionary
{
}

- (void)dropDatabaseWithAdministrativeConnectionDictionary: (NSDictionary *)connectionDictionary
{
}

/* Private methods for Postgres Adaptor */

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

  NSLog(@"%s %s %s %s %s", pg_host, pg_port, pg_database, pg_user, pg_pwd);
  NSDebugMLog(@"%s %s %s %s %s", pg_host, pg_port, pg_database, pg_user, pg_pwd);

  // Try to connect to the Postgres95 server
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
      //TODO: report error in an exception ?
      [self privateReportError: pgConn];
      PQfinish(pgConn);
      pgConn = NULL;
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

@end /* Postgres95Adaptor */

/*
//TODO
databaseEncoding
{
  self connectionDictionary
call dict obj for key databaseEncoding
    return 2 par defaut
};
*/

