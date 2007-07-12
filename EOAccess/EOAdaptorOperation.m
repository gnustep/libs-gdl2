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
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOAccess/EODatabaseOperation.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>

#include <EOControl/EOSortOrdering.h>
#include <EOControl/EODebug.h>


@implementation EOAdaptorOperation

+ (EOAdaptorOperation *)adaptorOperationWithEntity: (EOEntity *)entity
{
  return [[[self alloc] initWithEntity: entity] autorelease];
}

- (id) initWithEntity: (EOEntity *)entity
{
  if ((self = [self init]))
    {
      ASSIGN(_entity, entity);
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_entity);
  DESTROY(_qualifier);
  DESTROY(_changedValues);
  DESTROY(_attributes);
  DESTROY(_storedProcedure);
  DESTROY(_exception);

  [super dealloc];
}

- (EOAdaptorOperator)adaptorOperator
{
  return _adaptorOperator;
}

- (void)setAdaptorOperator: (EOAdaptorOperator)adaptorOperator
{
  NSDebugMLLog(@"gsdb", @"adaptorOperator=%d", adaptorOperator);

  _adaptorOperator = adaptorOperator;

  NSDebugMLLog(@"gsdb", @"_adaptorOperator=%d", _adaptorOperator);
}

- (EOEntity *)entity
{
  return _entity;
}

- (EOQualifier *)qualifier
{
  return _qualifier;
}

- (void)setQualifier: (EOQualifier *)qualifier
{
  ASSIGN(_qualifier, qualifier);
}

- (NSDictionary *)changedValues
{
  return _changedValues;
}

- (void)setChangedValues: (NSDictionary *)changedValues
{
  ASSIGN(_changedValues, changedValues);
}

- (NSArray *)attributes
{
  return _attributes;
}

- (void)setAttributes: (NSArray *)attributes
{
  ASSIGN(_attributes, attributes);
}

- (EOStoredProcedure *)storedProcedure
{
  return _storedProcedure;
}

- (void)setStoredProcedure: (EOStoredProcedure *)storedProcedure
{
  ASSIGN(_storedProcedure, storedProcedure);
}

- (NSException *)exception
{
  return _exception;
}

- (void)setException: (NSException *)exception
{
  ASSIGN(_exception, exception);
}

- (NSComparisonResult)compareAdaptorOperation: (EOAdaptorOperation *)adaptorOp
{
  NSComparisonResult res;
  EOAdaptorOperator otherOp = [adaptorOp adaptorOperator];

  res = [[_entity name] compare: [[adaptorOp entity] name]];

  if(res == NSOrderedSame)
    {
      if(_adaptorOperator == otherOp)
	res = NSOrderedSame;
      else if(_adaptorOperator < otherOp)
	res = NSOrderedAscending;
      else
	res = NSOrderedDescending;
    }

  return res;
}

- (NSString *)description
{
  //TODO revoir
  NSString *operatorString = nil;
  NSString *desc = nil;

  EOFLOGObjectFnStart();

  switch(_adaptorOperator)
    {
    case EOAdaptorUndefinedOperator:
      operatorString = @"EOAdaptorUndefinedOperator";
      break;
    case EOAdaptorLockOperator:
      operatorString = @"EOAdaptorLockOperator";
      break;
    case EOAdaptorInsertOperator:
      operatorString = @"EOAdaptorInsertOperator";
      break;
    case EOAdaptorUpdateOperator:
      operatorString = @"EOAdaptorUpdateOperator";
      break;
    case EOAdaptorDeleteOperator:
      operatorString = @"EOAdaptorDeleteOperator";
      break;
    case EOAdaptorStoredProcedureOperator:
      operatorString = @"EOAdaptorStoredProcedureOperator";
      break;
    default:
      operatorString = @"Unknwon";
      break;
    }

  desc = [NSString stringWithFormat: @"<%s %p : operator: %@ entity: %@ qualifier:%@\nchangedValues: %@\nattributes:%@\nstoredProcedure: %@\nexception: %@>",
		   object_get_class_name(self),
		   (void*)self,
		   operatorString,
		   [_entity name],
		   _qualifier,
		   _changedValues,
		   _attributes,
		   _storedProcedure,
		   _exception];

  EOFLOGObjectFnStop();

  return desc;
}

@end
