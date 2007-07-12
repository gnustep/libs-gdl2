/* -*-objc-*-
   EOJoin.h

   Copyright (C) 1996,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>
   Date: August 1996

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

#ifndef __EOJoin_h__
#define __EOJoin_h__

@class NSString;

@class EOEntity;
@class EOAttribute;


@interface EOJoin : NSObject
{
  /* Garbage collectable objects */
  EOAttribute *_sourceAttribute;
  EOAttribute *_destinationAttribute;
}

+ (EOJoin *)joinWithSourceAttribute: (EOAttribute *)source
               destinationAttribute: (EOAttribute *)destination;

- (id)initWithSourceAttribute: (EOAttribute *)source
	 destinationAttribute: (EOAttribute *)destination;

- (NSString *)description;

- (EOAttribute *)sourceAttribute;
- (EOAttribute *)destinationAttribute;

- (BOOL)isReciprocalToJoin: (EOJoin *)otherJoin;

@end


@interface EOJoin (EOJoinPrivate)

//+ (EOJoin *)joinFromPropertyList: (id)propertyList;
//- (void)replaceStringsWithObjectsInRelationship: (EORelationship *)entity;
//- (id)propertyList;

@end /* EOJoin (EOJoinPrivate) */


#endif /* __EOJoin_h__ */
