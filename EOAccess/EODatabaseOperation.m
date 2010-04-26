/** 
   EOAdaptorOperation.m <title>EOAdaptorOperation Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

#include <EOControl/EODebug.h>

#include <EOAccess/EODatabaseOperation.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>

#include "EOEntityPriv.h"


@implementation EODatabaseOperation

+ (EODatabaseOperation *)databaseOperationWithGlobalID: (EOGlobalID *)globalID
						object: (id)object
						entity: (EOEntity *)entity
{
  return [[[self alloc] initWithGlobalID: globalID
			object: object
			entity: entity] autorelease];
}

- (id) initWithGlobalID: (EOGlobalID *)globalID
		 object: (id)object
		 entity: (EOEntity *)entity
{
  if ((self = [super init]))
    {
      ASSIGN(_object, object);
      ASSIGN(_globalID, globalID);
      ASSIGN(_entity, entity);
      
      //_newRow = [NSMutableDictionary new];//still nil
      
      //_toManySnapshots = [NSMutableDictionary new];//TODO no: still nil
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_newRow);
  DESTROY(_globalID);
  DESTROY(_entity);
  DESTROY(_adaptorOps);
  DESTROY(_object);
  DESTROY(_dbSnapshot);
  DESTROY(_toManySnapshots);

  [super dealloc];
}

- (NSDictionary *)dbSnapshot
{
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"dbOpe %@ snapshot %p=%@", self, _dbSnapshot, _dbSnapshot);

  EOFLOGObjectFnStop();

  return _dbSnapshot;
}

- (void)setDBSnapshot: (NSDictionary *)dbSnapshot
{
  EOFLOGObjectFnStart();

  ASSIGN(_dbSnapshot, dbSnapshot);

  NSDebugMLLog(@"gsdb", @"dbOpe %@ snapshot %p=%@", self, _dbSnapshot, _dbSnapshot);

  if (dbSnapshot)
    [_newRow addEntriesFromDictionary: dbSnapshot];

  NSDebugMLLog(@"gsdb", @"dbOpe %@", self);

  EOFLOGObjectFnStop();
}

- (NSMutableDictionary *)newRow
{
  return _newRow;
}

- (void)setNewRow: (NSMutableDictionary *)newRow
{
  ASSIGN(_newRow, newRow);
}

- (EOGlobalID *)globalID
{
  return _globalID;
}

- (id)object
{
  return _object;
}

- (EOEntity *)entity
{
  return _entity;
}

- (EODatabaseOperator)databaseOperator
{
  return _databaseOperator;
}

- (void)setDatabaseOperator: (EODatabaseOperator)dbOpe
{
  BOOL setOpe = YES;

  //Don't set Update if it's alreay insert
  if (dbOpe == EODatabaseUpdateOperator)
    {
      if (_databaseOperator==EODatabaseInsertOperator
          || _databaseOperator==EODatabaseDeleteOperator)
         setOpe=NO;
    }
  else if (dbOpe == EODatabaseDeleteOperator)
    {
      // Don't Delete a not inserted object
      if (_databaseOperator==EODatabaseInsertOperator)
        {
          NSDebugMLog(@"Don't Delete a not inserted object: %p %@",
                      _object,_object);
          dbOpe=EODatabaseNothingOperator;
        };
    }

  if (setOpe)
    _databaseOperator = dbOpe;
}

- (NSDictionary *)rowDiffs
{
  //OK
  NSMutableDictionary *row = nil;
  NSEnumerator *newRowEnum = nil;
  NSString *key = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"self %p=%@", self, self);

  newRowEnum= [_newRow keyEnumerator];

  while ((key = [newRowEnum nextObject]))
    {
      if (![_entity anyRelationshipNamed: key]) //Don't care about relationships
        {
          id value = [_newRow objectForKey: key];

          if ([value isEqual: [_dbSnapshot objectForKey: key]] == NO)
            {
              if (!row)
                row = (NSMutableDictionary*)[NSMutableDictionary dictionary];

              [row setObject: value
                   forKey: key];
            }
        }
    }

  NSDebugMLLog(@"gsdb", @"diff row %p=%@", row, row);

  EOFLOGObjectFnStop();

  return row;
}

- (NSDictionary*)rowDiffsForAttributes: (NSArray*)attributes
{
  //OK
  NSMutableDictionary *row = nil;
  EOAttribute *attr = nil;
  NSEnumerator *attrsEnum = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"self %p=%@", self, self);

  attrsEnum = [attributes objectEnumerator];
  while ((attr = [attrsEnum nextObject]))
    {
      NSString *name = [attr name];
      NSString *snapname = [_entity snapshotKeyForAttributeName: name];
      id value = [_newRow objectForKey: name];

      if (value && [value isEqual: [_dbSnapshot objectForKey: snapname]] == NO)
        {
          if (!row)
            row = (NSMutableDictionary*)[NSMutableDictionary dictionary];

          [row setObject: value
               forKey: name];
        }
    }

  NSDebugMLLog(@"gsdb", @"diff row %p=%@", row, row);

  EOFLOGObjectFnStop();

  return row;
}

- (NSDictionary *)primaryKeyDiffs
{
  //OK
  NSDictionary *row = nil;

  if (_databaseOperator == EODatabaseUpdateOperator)
    {
      NSArray *pkAttributes = [_entity primaryKeyAttributes];

      row = [self rowDiffsForAttributes: pkAttributes];
    }

  return row;
}

- (NSArray *)adaptorOperations
{
  return _adaptorOps;
}

- (void)addAdaptorOperation: (EOAdaptorOperation *)adaptorOperation
{
  //OK
  if (!_adaptorOps)
    _adaptorOps = [NSMutableArray new];

  if (!adaptorOperation)
    {
      //TODO raise exception
    }
  else
    [_adaptorOps addObject: adaptorOperation];
}

- (void)removeAdaptorOperation: (EOAdaptorOperation *)adaptorOperation
{
  [_adaptorOps removeObject: adaptorOperation];
}

- (void)recordToManySnapshot: (NSArray *)gids
	    relationshipName: (NSString *)name
{
  //OK ??
  if (_toManySnapshots)
    [_toManySnapshots setObject: gids
                      forKey: name];//TODO VERIFY
  else
    {
      _toManySnapshots = [NSMutableDictionary dictionaryWithObject: gids
					      forKey: name];

      RETAIN(_toManySnapshots);
    }
}

- (NSDictionary *)toManySnapshots
{
  return _toManySnapshots;
}

- (NSString *)description
{
  //TODO revoir
  NSString *operatorString = nil;
  NSString *desc = nil;

  EOFLOGObjectFnStart();

  switch (_databaseOperator)
    {
    case EODatabaseNothingOperator:
      operatorString = @"EODatabaseNothingOperator";
      break;

    case EODatabaseInsertOperator:
      operatorString = @"EODatabaseInsertOperator";
      break;

    case EODatabaseUpdateOperator:
      operatorString = @"EODatabaseUpdateOperator";
      break;

    case EODatabaseDeleteOperator:
      operatorString = @"EODatabaseDeleteOperator";
      break;

    default:
      operatorString = @"Unknwon";
      break;
    }

  desc = [NSString stringWithFormat: @"<%s %p : operator: %@ entity: %@ globalID:%@\nnewRow %p: %@\nobject %p: %@\ndbSnapshot %p: %@>",
		   object_getClassName(self),
		   (void*)self,
		   operatorString,
		   [_entity name],
		   _globalID,
		   _newRow,
		   _newRow,
		   _object,
		   _object,
		   _dbSnapshot,
		   _dbSnapshot];

  EOFLOGObjectFnStop();

  return desc;
}

@end

//Mirko
@implementation EODatabaseOperation (private)

- (void)_setGlobalID: (EOGlobalID *)globalID
{
  ASSIGN(_globalID, globalID);
}

@end
