/* -*-objc-*-
   PostgresChannel.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   based on the Postgres adaptor written by
         Mircea Oancea <mircea@jupiter.elcom.pub.ro>

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

#ifndef __PostgresChannel_h__
#define __PostgresChannel_h__

#include <EOAccess/EOAdaptorChannel.h>
#include <PostgresEOAdaptor/PostgresContext.h>


@class NSString;
@class NSMutableDictionary;
@class NSMutableArray;
@class EOAttribute;

@interface PostgresChannel : EOAdaptorChannel
{
  PostgresContext *_adaptorContext;
  PGconn *_pgConn;
  PGresult *_pgResult;
  NSArray *_attributes;
  NSArray *_origAttributes;
  EOSQLExpression *_sqlExpression;
  int _currentResultRow;
  NSMutableDictionary *_oidToTypeName;
  BOOL _isFetchInProgress;
  BOOL _fetchBlobsOid;
  NSArray *_pkAttributeArray;
  int _pgVersion;

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
- (void)_describeResults;
- (void)_readServerVersion;

/* Extensions for login panel */
- (NSArray *)describeDatabaseNames;
- (BOOL)userNameIsAdministrative:(NSString*)userName;

/* Private methods */
- (char*)_readBinaryDataRow: (Oid)oid length: (int*)length zone: (NSZone*)zone;
- (Oid)_insertBinaryData: (NSData*)binaryData forAttribute: (EOAttribute*)attr;
- (Oid)_updateBinaryDataRow: (Oid)oid data: (NSData*)binaryData;
- (void)_describeDatabaseTypes;

- (BOOL)_evaluateExpression: (EOSQLExpression *)expression
	     withAttributes: (NSArray*)attributes;
@end

@interface NSObject (PostgresChannelDelegate)

- (void)postgresChannel: (PostgresChannel*)channel
       insertedRowWithOid: (Oid)oid;
- (void)postgresChannel: (PostgresChannel*)channel
     receivedNotification: (NSString*)notification;

@end

#endif /* __PostgresChannel_h__ */
