/**
   EOArrayDataSource.m

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Stephane Corthesy <stephane@sente.ch>
   Date: March 2003

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCoder.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif


#include <EOControl/EOArrayDataSource.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EODetailDataSource.h>


@implementation EOArrayDataSource

- (id) initWithClassDescription: (EOClassDescription *)classDescription
		 editingContext: (EOEditingContext *)context
{
  // Either argument may be nil
  if ((self = [self init]))
    {
      _classDescription = RETAIN(classDescription);
      _context = RETAIN(context);
      _objects = [[NSMutableArray allocWithZone: [self zone]] init];
    }

  return self;
}

- (void) dealloc
{
  DESTROY(_objects);
  DESTROY(_context);
  DESTROY(_classDescription);

  [super dealloc];
}

- (void) encodeWithCoder: (NSCoder *)encoder
{
  /*
  [encoder encodeObject: _objects];
  [encoder encodeObject: _context];
  [encoder encodeObject: _classDescription];
   */
}

- (id) initWithCoder:(NSCoder *)decoder
{
  /*
  _objects = RETAIN([decoder decodeObject]);
  _context = RETAIN([decoder decodeObject]);
  _classDescription = RETAIN([decoder decodeObject]);
  */
  return self;
}

- (void) insertObject:(id)object
{
  [_objects addObject: object];
}

- (void) deleteObject:(id)object
{
  [[self editingContext] deleteObject: object];
  [_objects removeObject: object];
}

- (NSArray *) fetchObjects
{
  return [NSArray arrayWithArray: _objects];
}

- (EOEditingContext *) editingContext
{
  return _context;
}

- (void) qualifyWithRelationshipKey: (NSString *)key ofObject: (id)sourceObject
{
  // Do nothing
}

- (EODataSource *) dataSourceQualifiedByKey: (NSString *)key
{
  return [EODetailDataSource detailDataSourceWithMasterDataSource: self 
			     detailKey: key];
}

- (EOClassDescription *) classDescriptionForObjects
{
  return _classDescription;
}

- (NSArray *) qualifierBindingKeys
{
  // Don't know what to do
  return nil;
}

- (void) setQualifierBindings: (NSDictionary *)bindings
{
  // Don't know what to do
}

- (NSDictionary *) qualifierBindings
{
  // Don't know what to do
  return nil;
}

- (void) setArray:(NSArray *)array
{
  [_objects setArray: array];
}

@end 
