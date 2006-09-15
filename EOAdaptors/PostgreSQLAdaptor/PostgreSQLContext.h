/* 
   PostgreSQLContext.h

   Copyright (C) 2000,2002,2003,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   based on the PostgreSQL adaptor written by
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

#ifndef __PostgreSQLContext_h__
#define __PostgreSQLContext_h__

#include <EOAccess/EOAdaptorContext.h>
#include <PostgreSQLEOAdaptor/PostgreSQLAdaptor.h>


@interface PostgreSQLContext : EOAdaptorContext
{
  NSString* _primaryKeySequenceNameFormat;
  struct
  {
    unsigned int didAutoBegin:1;
    unsigned int didBegin:1;
    unsigned int forceTransaction:1;
  } _flags;
}

- initWithAdaptor: (EOAdaptor *)adaptor;

- (void)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;

- (BOOL)canNestTransactions;

- (EOAdaptorChannel *)createAdaptorChannel;

- (BOOL)autoBeginTransaction: (BOOL)force;
- (BOOL)autoCommitTransaction;

// format is something like @"%@_SEQ" or @"EOSEQ_%@", "%@" is replaced by external table name
- (void)setPrimaryKeySequenceNameFormat: (NSString*)format;
- (NSString*)primaryKeySequenceNameFormat;

- (BOOL)autoBeginTransaction: (BOOL)force;
- (BOOL)autoCommitTransaction;

@end


#endif /* __PostgreSQLContext_h__ */
