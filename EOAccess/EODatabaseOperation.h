/* -*-objc-*-
   EODatabaseOperation.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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

#ifndef __EODatabaseOperation_h__
#define __EODatabaseOperation_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif


@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSException;
@class NSString;

@class EOStoredProcedure;
@class EOEntity;
@class EOQualifier;
@class EOGlobalID;


typedef enum {
  EOAdaptorUndefinedOperator = 0,
  EOAdaptorLockOperator,
  EOAdaptorInsertOperator,
  EOAdaptorUpdateOperator,
  EOAdaptorDeleteOperator,
  EOAdaptorStoredProcedureOperator
} EOAdaptorOperator;

/**
EOAdaptorOperation represent an adaptor 'elementaty' operation.
Instance objects are created by EODatabaseOperation
**/
@interface EOAdaptorOperation : NSObject
{
  EOAdaptorOperator _adaptorOperator; /** Database Adaptor **/
  EOEntity *_entity; /** Main concerned entity **/
  EOQualifier *_qualifier; /** qualifier **/
  NSDictionary *_changedValues; /** dictionary of changed fields/values **/
  NSArray *_attributes; 
  EOStoredProcedure *_storedProcedure; /** Stored Procedure **/
  NSException *_exception;
}

+ (EOAdaptorOperation *)adaptorOperationWithEntity: (EOEntity *)entity;

/** Init the instance with the main concerned entity **/
- (id)initWithEntity: (EOEntity *)entity;

/** returns adaptor operator **/
- (EOAdaptorOperator)adaptorOperator;

/** set adaptor operator **/
- (void)setAdaptorOperator: (EOAdaptorOperator)adaptorOperator;

/** returns entity **/
- (EOEntity *)entity;

/** returns qualifier **/
- (EOQualifier *)qualifier;

/** set Qualifier **/
- (void)setQualifier: (EOQualifier *)qualifier;

/** returns dictionary of changed values **/
- (NSDictionary *)changedValues;

/** set dictionary of changed values **/
- (void)setChangedValues: (NSDictionary *)changedValues;


- (NSArray *)attributes;
- (void)setAttributes: (NSArray *)attributes;

- (EOStoredProcedure *)storedProcedure;
- (void)setStoredProcedure: (EOStoredProcedure *)storedProcedure;

- (NSException *)exception;
- (void)setException: (NSException *)exception;

/** compare 2 adaptor operations **/
- (NSComparisonResult)compareAdaptorOperation: (EOAdaptorOperation *)adaptorOp;

@end

typedef enum {
  EODatabaseNothingOperator = 0,
  EODatabaseInsertOperator,
  EODatabaseUpdateOperator,
  EODatabaseDeleteOperator
} EODatabaseOperator;

/**
EODatabaseOperation represent a database high level operation on an object (record)
It creates EOAdaptorOperations.
You generally don't need to create such objects by yourself. They are created by EOEditingContext
**/
@interface EODatabaseOperation : NSObject
{
  EODatabaseOperator _databaseOperator; //** Database Operator **/
  NSMutableDictionary *_newRow; //** New Row (new state of the object) **/
  EOGlobalID *_globalID; /** global ID of the object **/
  EOEntity *_entity; /** entity **/
  NSMutableArray *_adaptorOps; /** EOAdaptorOperations generated to perfor this DatabaseOperation **/
  id _object; /** object (record) **/
  NSDictionary *_dbSnapshot; /** The last known database values for the object (i.e. values from last fetch or last commited operation) **/
  NSMutableDictionary *_toManySnapshots; /** **/
}

+ (EODatabaseOperation *)databaseOperationWithGlobalID: (EOGlobalID *)globalID
                                               object: (id)object
                                               entity: (EOEntity *)entity;

- (id)initWithGlobalID: (EOGlobalID *)globalID
                object: (id)object
                entity: (EOEntity *)entity;

/** Returns the database snapshot for the object. 
The snapshot contains the last known database values for the object.
If the object has just been inserted (i.e. not yet in database), the returned dictionary is empty
**/
- (NSDictionary *)dbSnapshot;

/** sets the snapshot for the object (should be empty if the object has just been inserted into an EOEditingContext **/
- (void)setDBSnapshot: (NSDictionary *)dbSnapshot;

/** Returns a dictionary with (new) values (properties+primary keys...) of the object.
The newRow dictionary is created when creating the database operation (in EODatabaseChannel -databaseOperationForObject: for exemple). Values come from object state in database and overrides by changes made on the object
**/
- (NSMutableDictionary *)newRow;
- (void)setNewRow: (NSMutableDictionary *)newRow;

- (EOGlobalID *)globalID;
- (id)object;
- (EOEntity *)entity;

- (EODatabaseOperator)databaseOperator;
- (void)setDatabaseOperator: (EODatabaseOperator)dbOpe;

- (NSDictionary *)rowDiffs;
- (NSDictionary *)rowDiffsForAttributes: (NSArray *)attributes;
- (NSDictionary *)primaryKeyDiffs;

/** returns array of EOAdaptorOperations to perform **/
- (NSArray *)adaptorOperations;

/** adds an Adaptor Operation 
Raises an exception if adaptorOperation is nil
**/
- (void)addAdaptorOperation: (EOAdaptorOperation *)adaptorOperation;

/** removes an Adaptor Operation **/
- (void)removeAdaptorOperation: (EOAdaptorOperation *)adaptorOperation;

- (void)recordToManySnapshot: (NSArray *)gids relationshipName: (NSString *)name;
- (NSDictionary *)toManySnapshots;

@end

#endif /* __EODatabaseOperation_h__ */
