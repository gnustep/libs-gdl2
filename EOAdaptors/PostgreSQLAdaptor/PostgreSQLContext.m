/** 
   PostgreSQLContext.m <title>PostgreSQLContext</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

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
   version 3 of the License, or (at your option) any later version.

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
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EODebug.h>

#include "PostgreSQLAdaptor.h"
#include "PostgreSQLContext.h"
#include "PostgreSQLChannel.h"
#include "PostgreSQLExpression.h"


@implementation PostgreSQLContext

- (id)initWithAdaptor: (EOAdaptor *)adaptor
{
  if ((self = [super initWithAdaptor: adaptor]))
    {
      if (adaptor)
        [self setPrimaryKeySequenceNameFormat:
		[(PostgreSQLAdaptor*)adaptor primaryKeySequenceNameFormat]];
    }

  return self;
}

- (void)beginTransaction
{
  PostgreSQLChannel *channel = nil;

  EOFLOGObjectFnStart();

  if ([self transactionNestingLevel])
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x: attempted to begin a transaction within a transaction",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if (_delegateRespondsTo.shouldBegin)
    {
      if (![_delegate adaptorContextShouldBegin: self])
	[NSException raise: PostgreSQLException
                     format: @"%@ -- %@ 0x%x: delegate refuses",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self];
    }

  channel = [[_channels objectAtIndex: 0] nonretainedObjectValue];

  if ([channel isOpen] == NO)
    [NSException raise: PostgreSQLException
		 format: @"cannot execute SQL expression. Channel is not opened."];

  _flags.didBegin = YES;

  [channel _evaluateExpression: [EOSQLExpression
				  expressionForString: @"BEGIN TRANSACTION"]
	   withAttributes: nil];

  [self transactionDidBegin];

  if (_delegateRespondsTo.didBegin)
    [_delegate adaptorContextDidBegin: self];

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  EOFLOGObjectFnStop();
}

- (void)commitTransaction
{
//channel conn
//self transactionNestingLevel
//self transactionDidCommit
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  if ([self transactionNestingLevel] == 0)
    [NSException raise: NSInternalInconsistencyException
                 format: @"%@ -- %@ 0x%x:illegal attempt to commit a transaction when there are none in progress", 
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if (_delegateRespondsTo.shouldCommit)
    {
      if (![_delegate adaptorContextShouldCommit: self])
	[NSException raise: PostgreSQLException
                     format: @"%@ -- %@ 0x%x: delegate refuses",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self];
    }
//???
  [[[_channels objectAtIndex: 0] nonretainedObjectValue]
    _evaluateExpression: [EOSQLExpression
			   expressionForString: @"END TRANSACTION"]
    withAttributes: nil];

  _flags.didBegin = NO;

  [self transactionDidCommit];

  if (_delegateRespondsTo.didCommit)
    [_delegate adaptorContextDidCommit: self];

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  EOFLOGObjectFnStop();
}

- (void)rollbackTransaction
{
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  if (![self transactionNestingLevel])
    {
      [NSException raise: NSInternalInconsistencyException
                   format: @"%@ -- %@ 0x%x:illegal attempt to commit a transaction when there are none in progress",
                   NSStringFromSelector(_cmd),
                   NSStringFromClass([self class]),
                   self];
    }

  if (_delegateRespondsTo.shouldRollback)
    {
      if (![_delegate adaptorContextShouldRollback: self])
	[NSException raise: PostgreSQLException
                     format: @"%@ -- %@ 0x%x: delegate refuses",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self];
    }

  [[[_channels objectAtIndex: 0] nonretainedObjectValue]
    _evaluateExpression: [EOSQLExpression
			   expressionForString: @"ABORT TRANSACTION"]
    withAttributes: nil];

  _flags.didBegin = NO;

  [self transactionDidRollback];

  if (_delegateRespondsTo.didRollback)
    [_delegate adaptorContextDidRollback: self];

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  EOFLOGObjectFnStop();
}

- (BOOL)canNestTransactions
{
  return NO;
}

- (EOAdaptorChannel *)createAdaptorChannel
{
  //OK
  EOAdaptorChannel *adaptorChannel;

  adaptorChannel = [PostgreSQLChannel adaptorChannelWithAdaptorContext: self];

  return adaptorChannel;
}

- (BOOL)autoBeginTransaction: (BOOL)force
{
  //seems OK
  BOOL ok = NO;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"force=%d _flags.didBegin=%s [self transactionNestingLevel]=%d",
               force,
               (_flags.didBegin ? "YES" : "NO"),
               [self transactionNestingLevel]);

  if (!_flags.didBegin && [self transactionNestingLevel] == 0)
    {
      if (force == YES)
	[self beginTransaction];

      _flags.didAutoBegin = YES;
      _flags.forceTransaction = force;

      ok = YES;
    }

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  EOFLOGObjectFnStop();

  return ok;
}

- (BOOL)autoCommitTransaction
{
//seems ok
  BOOL ok = NO;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  if (_flags.didAutoBegin)
    {
      NSDebugMLLog(@"gsdb", @"_flags.forceTransaction=%s",
		   (_flags.forceTransaction ? "YES" : "NO"));

      if (_flags.forceTransaction == YES)
        {
          [self commitTransaction];
        }

      _flags.didAutoBegin = NO;
      _flags.forceTransaction = NO;

      ok = YES;
    }

  NSDebugMLLog(@"gsdb", @"_flags.didBegin=%s",
	       (_flags.didBegin ? "YES" : "NO"));
  NSDebugMLLog(@"gsdb", @"_flags.didAutoBegin=%s",
	       (_flags.didAutoBegin ? "YES" : "NO"));

  EOFLOGObjectFnStop();

  return ok;
}

/** format is something like @"%@_SEQ" or @"EOSEQ_%@", "%@" is replaced by external table name **/
- (void)setPrimaryKeySequenceNameFormat: (NSString*)format
{
  ASSIGN(_primaryKeySequenceNameFormat, format);
}

- (NSString*)primaryKeySequenceNameFormat
{
  return _primaryKeySequenceNameFormat;
}

@end /* PostgreSQLContext */
/*
//TODO
autoCommitTransaction
{
self commitTransaction
};
*/
