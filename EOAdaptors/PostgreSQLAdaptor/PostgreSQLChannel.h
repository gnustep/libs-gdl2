/* -*-objc-*-
   PostgreSQLChannel.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   based on the PostgreSQL adaptor written by
         Mircea Oancea <mircea@jupiter.elcom.pub.ro>

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

#ifndef __PostgreSQLChannel_h__
#define __PostgreSQLChannel_h__

#include <EOAccess/EOAdaptorChannel.h>

/* Include PostgreSQL Headers */

#undef Assert
#include <stdio.h>
#include <libpq-fe.h>
#include <libpq/libpq-fs.h>
#include <pg_config.h>
#undef Assert

@class NSString;
@class NSMutableDictionary;
@class NSMutableArray;
@class EOAttribute;

@class PostgreSQLContext;

@interface PostgreSQLChannel : EOAdaptorChannel
{
  PostgreSQLContext   *_adaptorContext;
  PGconn              *_pgConn;
  PGresult            *_pgResult;
  NSArray             *_attributes;
  NSArray             *_origAttributes;
  EOSQLExpression     *_sqlExpression;
  int                  _currentResultRow;
  NSMutableDictionary *_oidToTypeName;
  BOOL                 _isFetchInProgress;
  BOOL                 _evaluateExprInProgress;
  BOOL                 _fetchBlobsOid;
  NSArray             *_pkAttributeArray;
  int                  _pgVersion;
  NSStringEncoding     _encoding;

  struct {
    unsigned int postgresInsertedRowOid:1;
    unsigned int postgresNotification:1;
  } _postgresDelegateRespondsTo;
}

- (PGconn*)pgConn;
- (PGresult*)pgResult;
- (BOOL)advanceRow;
- (void)cleanupFetch;

- (void)_cancelResults;
- (void)_readServerVersion;

/* Extensions for login panel */
- (NSArray *)describeDatabaseNames;
- (BOOL)userNameIsAdministrative:(NSString*)userName;

/* Private methods */
- (char*)_readBinaryDataRow: (Oid)oid length: (int*)length zone: (NSZone*)zone;
- (Oid)_insertBinaryData: (NSData*)binaryData forAttribute: (EOAttribute*)attr;
- (Oid)_updateBinaryDataRow: (Oid)oid data: (NSData*)binaryData;
- (void)_describeDatabaseTypes;

- (NSUInteger)_evaluateExpression: (EOSQLExpression *)expression
                   withAttributes: (NSArray*)attributes;
@end

@interface NSObject (PostgreSQLChannelDelegate)

- (void)postgresChannel: (PostgreSQLChannel*)channel
       insertedRowWithOid: (Oid)oid;
- (void)postgresChannel: (PostgreSQLChannel*)channel
     receivedNotification: (NSString*)notification;

@end

#endif /* __PostgreSQLChannel_h__ */
