/* 
   EOAdaptorContext.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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

#ifndef __EOAdaptorContext_h__
#define __EOAdaptorContext_h__

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif


@class NSMutableArray;
@class NSString;

@class EOAdaptor;
@class EOAdaptorChannel;


typedef enum { 
    EODelegateRejects, 
    EODelegateApproves, 
    EODelegateOverrides
} EODelegateResponse;

/* The EOAdaptorContext class could be overriden for a concrete database
   adaptor. You have to override only those methods marked in this header
   with `override'.
*/

@interface EOAdaptorContext : NSObject
{
    EOAdaptor *_adaptor;
    NSMutableArray *_channels;	// values with channels
    id _delegate;	// not retained

    unsigned short _transactionNestingLevel;
    BOOL _debug;

    /* Flags used to check if the delegate responds to several messages */
    struct {
        unsigned shouldConnect:1;
        unsigned shouldBegin:1;
        unsigned didBegin:1;
        unsigned shouldCommit:1;
        unsigned didCommit:1;
        unsigned shouldRollback:1;
        unsigned didRollback:1;
    } _delegateRespondsTo;
}

+ (EOAdaptorContext *)adaptorContextWithAdaptor: (EOAdaptor *)adaptor;

- initWithAdaptor: (EOAdaptor *)adaptor;

- (EOAdaptor*)adaptor;

- (EOAdaptorChannel *)createAdaptorChannel;	// override

- (BOOL)hasOpenChannels;
- (BOOL)hasBusyChannels;

- delegate;
- (void)setDelegate:aDelegate;

- (void)handleDroppedConnection;

@end


@interface EOAdaptorContext (EOTransactions)

- (void)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;

- (void)transactionDidBegin;
- (void)transactionDidCommit;
- (void)transactionDidRollback;

- (BOOL)hasOpenTransaction;

- (BOOL)canNestTransactions;			// override
- (unsigned)transactionNestingLevel; 

+ (void)setDebugEnabledDefault: (BOOL)yn;
+ (BOOL)debugEnabledDefault;
- (void)setDebugEnabled: (BOOL)debugEnabled;
- (BOOL)isDebugEnabled;

@end /* EOAdaptorContext (EOTransactions) */


@interface EOAdaptorContext(Private)

- (void)_channelDidInit: aChannel;
- (void)_channelWillDealloc: aChannel;

@end


@interface NSObject (EOAdaptorContextDelegation)

- (BOOL)adaptorContextShouldConnect: context;
- (BOOL)adaptorContextShouldBegin: context;
- (void)adaptorContextDidBegin: context;
- (BOOL)adaptorContextShouldCommit: context;
- (void)adaptorContextDidCommit: context;
- (BOOL)adaptorContextShouldRollback: context;
- (void)adaptorContextDidRollback: context;

@end /* NSObject(EOAdaptorContextDelegate) */

GDL2ACCESS_EXPORT NSString *EOAdaptorContextBeginTransactionNotification;
GDL2ACCESS_EXPORT NSString *EOAdaptorContextCommitTransactionNotification;
GDL2ACCESS_EXPORT NSString *EOAdaptorContextRollbackTransactionNotification;

#endif /* __EOAdaptorContext_h__*/
