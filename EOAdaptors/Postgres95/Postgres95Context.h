/* 
   Postgres95Context.h

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

#ifndef __Postgres95Context_h__
#define __Postgres95Context_h__

#include <EOAccess/EOAdaptorContext.h>
#include <Postgres95EOAdaptor/Postgres95Adaptor.h>


@interface Postgres95Context : EOAdaptorContext
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


#endif /* __Postgres95Context_h__ */
