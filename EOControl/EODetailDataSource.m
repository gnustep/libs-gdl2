/** 
   EODetailDataSource.m <title>EODetailDataSource Class</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: July 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EODetailDataSource.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOKeyValueArchiver.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EODebug.h>


@implementation EODetailDataSource

+ (EODetailDataSource *)detailDataSourceWithMasterDataSource: (EODataSource *)master 
						   detailKey: (NSString *)detailKey
{
  return [[[self alloc] initWithMasterDataSource: master 
			detailKey: detailKey] autorelease];
}

- initWithMasterClassDescription: (EOClassDescription *)masterClassDescription
		       detailKey: (NSString *)detailKey
{
  if ((self = [super init]))
    {
      [self setMasterClassDescription: masterClassDescription];
      [self qualifyWithRelationshipKey: detailKey
            ofObject: nil];
    }

  return self;
}

- initWithMasterDataSource: (EODataSource *)master
		 detailKey: (NSString *)detailKey
{
  ASSIGN(_masterDataSource, master);

  return [self initWithMasterClassDescription: nil
	       detailKey: detailKey];
}

- (id)initWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver
{
  //OK
  EOFLOGObjectFnStart();

  if ((self = [self init]))
    {
      NSString* detailKey=nil;
      NSString* masterClassDescriptionName=nil;
      EOClassDescription* masterClassDescription=nil;

      EOFLOGObjectLevelArgs(@"EODataSource",@"EODetailDataSource %p",self);

      detailKey = [unarchiver decodeObjectForKey: @"detailKey"];
      masterClassDescriptionName = [unarchiver decodeObjectForKey:
						 @"masterClassDescription"];
      masterClassDescription = [EOClassDescription
				 classDescriptionForEntityName:
				   masterClassDescriptionName];

      [self setMasterClassDescription: masterClassDescription];
      [self qualifyWithRelationshipKey: detailKey
            ofObject: nil];

      EOFLOGObjectLevelArgs(@"EODataSource", @"EODetailDataSource %p : %@",
			    self, self);
    }

  EOFLOGObjectFnStop();

  return self;
}

- (void)dealloc
{
  DESTROY(_masterDataSource);
  DESTROY(_masterObject);
  DESTROY(_detailKey);
  DESTROY(_masterClassDescriptionName);

  [super dealloc];
}

- (EODataSource *)masterDataSource
{
  return _masterDataSource;
}

- (EOClassDescription *)masterClassDescription
{
  return [EOClassDescription classDescriptionForEntityName:
			       _masterClassDescriptionName];
}

- (void)setMasterClassDescription: (EOClassDescription *)classDescription
{
  EOFLOGObjectFnStart();

  ASSIGN(_masterClassDescriptionName, [classDescription entityName]);

  EOFLOGObjectFnStop();
}

- (EOClassDescription *)classDescriptionForObjects
{
  EOClassDescription *cd;
  EOClassDescription *masterCD;
  NSString *detailKey;

  detailKey = [self detailKey];
  NSAssert(detailKey, @"No detailKey");

  masterCD = [self masterClassDescription];
  NSAssert(masterCD, @"No masterClassDescription");

  cd = [masterCD classDescriptionForDestinationKey: detailKey];

  return cd;
}

- (void)qualifyWithRelationshipKey: (NSString *)key
			  ofObject: masterObject
{
  EOFLOGObjectFnStart();

  ASSIGN(_detailKey, key);
  ASSIGN(_masterObject, masterObject);

  EOFLOGObjectFnStop();
}

- (NSString *)detailKey
{
  return _detailKey;
}

- (void)setDetailKey:(NSString *)detailKey
{
  ASSIGN(_detailKey, detailKey);
};

- (id)masterObject
{
  return _masterObject;
}

- (EOEditingContext *)editingContext
{
  return [_masterObject editingContext];
}

- (NSArray *)fetchObjects
{
  id value=nil;

  EOFLOGObjectFnStart();

  if(!_masterObject)
    value = [NSArray array];
  else if(!_detailKey)
    value = [NSArray arrayWithObject: _masterObject];
  else
    {
      value = [_masterObject valueForKey: _detailKey];

      if (value)
        {
          if (![value isKindOfClass: [NSArray class]])
            value = [NSArray arrayWithObject: value];
        }
      else
        value = [NSArray array];
    }

  EOFLOGObjectFnStop();

  return value;
}

- (void)insertObject: (id)object
{
  EOFLOGObjectFnStart();

  if (!_masterObject)
    [NSException raise: NSInternalInconsistencyException
		 format: @"%@ -- %@ 0x%x: no masterObject", 
                 NSStringFromSelector(_cmd), NSStringFromClass([self class]),
		 self];

  if (!_detailKey)
    [NSException raise: NSInternalInconsistencyException
		 format: @"%@ -- %@ 0x%x: no detailKey", 
                 NSStringFromSelector(_cmd), NSStringFromClass([self class]),
		 self];

  [_masterObject addObject: object
		 toBothSidesOfRelationshipWithKey: _detailKey];

  EOFLOGObjectFnStop();
}

- (void)deleteObject: (id)object
{
  if (!_masterObject)
    [NSException raise: NSInternalInconsistencyException
		 format: @"%@ -- %@ 0x%x: no masterObject", 
                 NSStringFromSelector(_cmd), NSStringFromClass([self class]),
		 self];

  if (!_detailKey)
    [NSException raise: NSInternalInconsistencyException
		 format: @"%@ -- %@ 0x%x: no detailKey", 
                 NSStringFromSelector(_cmd), NSStringFromClass([self class]),
		 self];

  [_masterObject removeObject: object fromPropertyWithKey: _detailKey];
}

- (id)initWithCoder: (NSCoder *)coder
{
  if ((self = [super init]))
    {
      ASSIGN(_masterDataSource, [coder decodeObject]);
      ASSIGN(_masterObject, [coder decodeObject]);
      ASSIGN(_detailKey, [coder decodeObject]);
      ASSIGN(_masterClassDescriptionName, [coder decodeObject]);
    }

  return self;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeObject: _masterDataSource];
  [coder encodeObject: _masterObject];
  [coder encodeObject: _detailKey];
  [coder encodeObject: _masterClassDescriptionName];
}

- (NSString*) description
{
  return [NSString stringWithFormat: @"<%s %p : masterDataSource=%@ masterObject=%@ detailKey=%@ masterClassDescriptionName=%@>",
		   object_get_class_name(self),
		   (void*)self,
		   _masterDataSource,
                   _masterObject,
                   _detailKey,
                   _masterClassDescriptionName];
}
@end
