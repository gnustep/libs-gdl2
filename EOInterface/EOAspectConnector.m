/** -*-ObjC-*-
   EOAspectConnector.m

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@yahoo.com>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 2, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "EOAspectConnector.h"
#include <Foundation/NSCoder.h>
#include <EOInterface/EOAssociation.h>

@implementation EOAspectConnector : NSNibConnector
- (id) initWithAssociation:(EOAssociation *)association
	aspectName:(NSString *)name
{
  self = [super init];
  ASSIGN(_aspectName, name);
  ASSIGN(_association, association);
  ASSIGN(_dg, [association displayGroupForAspect:_aspectName]);
  ASSIGN(_destinationKey, [association displayGroupKeyForAspect:_aspectName]);
  return self;
}

- (NSString *)aspectName
{
  return _aspectName;
}

- (NSString *)destinationKey
{
  return _destinationKey;
}

- (EOAssociation *)association
{
  return _association;
}

- (id) initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  _association = RETAIN([coder decodeObject]);
  _aspectName = RETAIN([coder decodeObject]);
  _destinationKey = RETAIN([coder decodeObject]);
  _dg = RETAIN([coder decodeObject]);
  [_association bindAspect:_aspectName
	      displayGroup:_dg  
		       key:_destinationKey];
  return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:_association];
  [coder encodeObject:_aspectName];
  [coder encodeObject:[self destinationKey]];
  [coder encodeObject:[_association displayGroupForAspect:[self aspectName]]];
}

- (void) establishConnection
{
  [_association establishConnection];
}


@end
