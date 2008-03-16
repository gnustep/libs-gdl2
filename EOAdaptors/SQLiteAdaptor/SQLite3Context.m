
/* 
   SQLite3Context.m

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

#include  "SQLite3Adaptor.h"
#include  "SQLite3Context.h"
#include  "SQLite3Channel.h"

@implementation SQLite3Context

- (EOAdaptorChannel *)createAdaptorChannel
{
  return AUTORELEASE([[SQLite3Channel alloc] initWithAdaptorContext:self]);
}

- (void)beginTransaction
{
  int i, c;
  NSAssert(![self transactionNestingLevel], @"nested transactions unsupported");
  NSAssert([self hasOpenChannels], @"no open channels");
  NSAssert(![self hasBusyChannels], @"busy channels during commit.");
  
   
  if (_delegateRespondsTo.shouldBegin)
    {
      NSAssert([_delegate adaptorContextShouldBegin: self], 
	       @"delegate refuses");
    }
  
  for (i = 0, c = [_channels count]; i < c; i++)
    {
      id channel  = [[_channels objectAtIndex:i] nonretainedObjectValue];
      if ([channel isOpen])
        {
          [channel evaluateExpression:
		  [EOSQLExpression expressionForString:@"BEGIN TRANSACTION"]];
	  break;
	}
    }

  [self transactionDidBegin];

  if (_delegateRespondsTo.didBegin)
    [_delegate adaptorContextDidBegin: self];

}

- (void) commitTransaction
{
  int i, c;
  
  NSAssert([self hasOpenTransaction], @"No open transactions to commit");
  NSAssert(![self hasBusyChannels], @"busy channels during commit");
  
  if (_delegateRespondsTo.shouldCommit)
    NSAssert([_delegate adaptorContextShouldCommit:self], @"delegate refuses to commit");
  
  for (i = 0, c = [_channels count]; i < c; i++)
    {
      id channel  = [[_channels objectAtIndex:i] nonretainedObjectValue];
      if ([channel isOpen])
        {
          [channel evaluateExpression:
		  [EOSQLExpression expressionForString:@"COMMIT TRANSACTION"]];
	  break;
	}
    }
  [self transactionDidCommit];
  
  if (_delegateRespondsTo.didCommit)
    [_delegate adaptorContextDidCommit: self];

}
- (void) rollbackTransaction
{
  int i, c;
  
  NSAssert([self hasOpenTransaction], @"No open transactions to rollback");
  NSAssert(![self hasBusyChannels], @"busy channels during rollback");
  
  if (_delegateRespondsTo.shouldRollback)
    NSAssert([_delegate adaptorContextShouldRollback:self], @"delegate refuses to rollback");
  
  for (i = 0, c = [_channels count]; i < c; i++)
    {
      id channel  = [[_channels objectAtIndex:i] nonretainedObjectValue];
      if ([channel isOpen])
        {
          [channel evaluateExpression:
		  [EOSQLExpression expressionForString:@"ROLLBACK TRANSACTION"]];
	  break;
	}
    }
  [self transactionDidCommit];
  
  if (_delegateRespondsTo.didRollback)
    [_delegate adaptorContextDidRollback: self];

}

@end

