/* 
   EOAdaptorChannel.h

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

#ifndef __EOAdaptorChannel_h__
#define __EOAdaptorChannel_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSZone.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOAccess/EODefines.h>


@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSString;
@class NSMutableString;
@class NSCalendarDate;
@class NSException;

@class EOModel;
@class EOEntity;
@class EOAttribute;
@class EOAdaptorContext;
@class EOQualifier;
@class EOStoredProcedure;
@class EOAdaptorOperation;
@class EOSQLExpression;
@class EOFetchSpecification;


/* The EOAdaptorChannel class could be overriden for a concrete database
   adaptor. You have to override only those methods marked in this header
   with `override'.
*/

@interface EOAdaptorChannel : NSObject
{
  EOAdaptorContext *_context;
  id _delegate;	// not retained

  BOOL _debug;

  /* Flags used to check if the delegate responds to several messages */
  struct {
    unsigned willPerformOperations:1;
    unsigned didPerformOperations:1;
    unsigned shouldSelectAttributes:1;
    unsigned didSelectAttributes:1;
    unsigned willFetchRow:1;
    unsigned didFetchRow:1;
    unsigned didChangeResultSet:1;
    unsigned didFinishFetching:1;
    unsigned shouldEvaluateExpression:1;
    unsigned didEvaluateExpression:1;
    unsigned shouldExecuteStoredProcedure:1;
    unsigned didExecuteStoredProcedure:1;
    unsigned shouldConstructStoredProcedureReturnValues:1;
    unsigned shouldReturnValuesForStoredProcedure:1;
  } _delegateRespondsTo;
}

+ (EOAdaptorChannel *)adaptorChannelWithAdaptorContext: (EOAdaptorContext *)adaptorContext;

/* Initializing an adaptor context */
- initWithAdaptorContext: (EOAdaptorContext *)adaptorContext;

/* Getting the adaptor context */
- (EOAdaptorContext *)adaptorContext;

/* Opening and closing a channel */
- (BOOL)isOpen;
- (void)openChannel;
- (void)closeChannel;

/* Modifying rows */
- (void)insertRow: (NSDictionary *)row forEntity: (EOEntity *)entity;
- (void)updateValues: (NSDictionary *)values
inRowDescribedByQualifier: (EOQualifier *)qualifier
	      entity: (EOEntity *)entity;
- (unsigned)updateValues: (NSDictionary *)values
  inRowsDescribedByQualifier: (EOQualifier *)qualifier
		  entity: (EOEntity *)entity;
- (void)deleteRowDescribedByQualifier: (EOQualifier *)qualifier
			       entity: (EOEntity *)entity;
- (unsigned)deleteRowsDescribedByQualifier: (EOQualifier *)qualifier
				    entity: (EOEntity *)entity;

/* Fetching rows */
- (void)selectAttributes: (NSArray *)attributes
      fetchSpecification: (EOFetchSpecification *)fetchSpecification
		    lock: (BOOL)aLockFlag
		  entity: (EOEntity *)entity;

- (void)lockRowComparingAttributes: (NSArray *)atts
			    entity: (EOEntity *)entity
			 qualifier: (EOQualifier *)qualifier
			  snapshot: (NSDictionary *)snapshot;

- (void)evaluateExpression: (EOSQLExpression *)expression;

- (BOOL)isFetchInProgress;

- (NSArray *)describeResults;

- (NSMutableDictionary *)fetchRowWithZone: (NSZone *)zone;

- (void)setAttributesToFetch: (NSArray *)attributes;

- (NSArray *)attributesToFetch;

- (void)cancelFetch;

- (NSDictionary *)primaryKeyForNewRowWithEntity: (EOEntity *)entity;

- (NSArray *)describeTableNames;

- (NSArray *)describeStoredProcedureNames;

- (EOModel *)describeModelWithTableNames: (NSArray *)tableNames;

- (void)addStoredProceduresNamed: (NSArray *)storedProcedureNames
			 toModel: (EOModel *)model;

- (void)setDebugEnabled:(BOOL)yn;
- (BOOL)isDebugEnabled;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (NSMutableDictionary *)dictionaryWithObjects: (id *)objects
				 forAttributes: (NSArray *)attributes
					  zone: (NSZone *)zone;

@end


@interface EOAdaptorChannel (EOStoredProcedures)

- (void)executeStoredProcedure: (EOStoredProcedure *)storedProcedure
		    withValues: (NSDictionary *)values;
- (NSDictionary *)returnValuesForLastStoredProcedureInvocation;

@end


@interface EOAdaptorChannel (EOBatchProcessing)

- (void)performAdaptorOperation: (EOAdaptorOperation *)adaptorOperation;
- (void)performAdaptorOperations: (NSArray *)adaptorOperations;

@end


@interface NSObject (EOAdaptorChannelDelegation)

- (NSArray *)adaptorChannel: channel
      willPerformOperations: (NSArray *)operations;

- (NSException *)adaptorChannel: channel
	   didPerformOperations: (NSArray *)operations
		      exception: (NSException *)exception;

- (BOOL)adaptorChannel: channel
shouldSelectAttributes: (NSArray *)attributes
    fetchSpecification: (EOFetchSpecification *)fetchSpecification
		  lock: (BOOL)flag
		entity: (EOEntity *)entity;

- (void)adaptorChannel: channel
   didSelectAttributes: (NSArray *)attributes
    fetchSpecification: (EOFetchSpecification *)fetchSpecification
		  lock: (BOOL) flag
		entity: (EOEntity *)entity;

- (void)adaptorChannelWillFetchRow: channel;

- (void)adaptorChannel: channel didFetchRow: (NSMutableDictionary *)row;

- (void)adaptorChannelDidChangeResultSet: channel;

- (void)adaptorChannelDidFinishFetching: channel;

- (BOOL)adaptorChannel: channel
    shouldEvaluateExpression: (EOSQLExpression *)expression;

- (void)adaptorChannel: channel
    didEvaluateExpression: (EOSQLExpression *)expression;

- (NSDictionary *)adaptorChannel: channel
    shouldExecuteStoredProcedure: (EOStoredProcedure *)procedure
		      withValues: (NSDictionary *)values;

- (void)adaptorChannel: channel
didExecuteStoredProcedure: (EOStoredProcedure *)procedure
	    withValues: (NSDictionary *)values;

- (NSDictionary *)adaptorChannelShouldConstructStoredProcedureReturnValues: channel;

- (NSDictionary *)adaptorChannel: channel
shouldReturnValuesForStoredProcedure: (NSDictionary *)returnValues;

@end /* NSObject(EOAdaptorChannelDelegation) */


GDL2ACCESS_EXPORT NSString *EOAdaptorOperationsKey;
GDL2ACCESS_EXPORT NSString *EOFailedAdaptorOperationKey;
GDL2ACCESS_EXPORT NSString *EOAdaptorFailureKey;
GDL2ACCESS_EXPORT NSString *EOAdaptorOptimisticLockingFailure;


#endif /* __EOAdaptorChannel_h__ */
