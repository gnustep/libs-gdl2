/* 
   Postgres95Channel.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   based on the Postgres95 adaptor written by
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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __Postgres95Channel_h__
#define __Postgres95Channel_h__

#import <EOAccess/EOAdaptorChannel.h>
#import <Postgres95EOAdaptor/Postgres95Context.h>


@class NSMutableDictionary;
@class NSMutableArray;
@class EOAttribute;

@interface Postgres95Channel : EOAdaptorChannel
{
  Postgres95Context *_adaptorContext;
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

  struct {
    unsigned int postgres95InsertedRowOid:1;
    unsigned int postgres95Notification:1;
  } _postgres95DelegateRespondsTo;
}

- (PGconn*)pgConn;
- (PGresult*)pgResult;
- (BOOL)advanceRow;
- (void)cleanupFetch;

- (void)_cancelResults;
- (void)_describeResults;

/* Private methods */
- (char*)_readBinaryDataRow: (Oid)oid length: (int*)length zone: (NSZone*)zone;
- (Oid)_insertBinaryData: (NSData*)binaryData forAttribute: (EOAttribute*)attr;
- (Oid)_updateBinaryDataRow: (Oid)oid data: (NSData*)binaryData;
- (void)_describeDatabaseTypes;

- (BOOL)_evaluateExpression: (EOSQLExpression *)expression
	     withAttributes: attrs;

@end

@interface NSObject (Postgres95ChannelDelegate)

- (void)postgres95Channel: (Postgres95Channel*)channel
       insertedRowWithOid: (Oid)oid;
- (void)postgres95Channel: (Postgres95Channel*)channel
     receivedNotification: (NSString*)notification;

@end

#endif /* __Postgres95Channel_h__ */
