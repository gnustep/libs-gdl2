/* -*-objc-*-
   EOEntityPriv.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: July 2000

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

#ifndef __EOEntityPriv_h__
#define __EOEntityPriv_h__


@class NSString;

@class EORelationship;
@class EOExpressionArray;


@interface EOEntity (EOEntityPrivate)

- (void)setCreateMutableObjects: (BOOL)flag;
- (BOOL)createsMutableObjects;

- (void)setModel: (EOModel *)model;
- (void)setParentEntity: (EOEntity *)parent;

@end

@interface EOEntity (EOEntityRelationshipPrivate)
- (EORelationship *)_inverseRelationshipPathForPath: (NSString *)path;
- (id)_keyMapForRelationshipPath: (NSString *)path;
- (id)_keyMapForIdenticalKeyRelationshipPath: (id)param0;
- (id)_mapAttribute: (id)param0
toDestinationAttributeInLastComponentOfRelationshipPath: (NSString *)path;
- (BOOL)_relationshipPathIsToMany: (id)param0;
- (BOOL)_relationshipPathHasIdenticalKeys: (id)param0;
@end


@interface EOEntity (EOEntitySQLExpression)
- (id)valueForSQLExpression: (id)param0;
+ (id)valueForSQLExpression: (id)param0;
@end

@interface EOEntity (EOEntityPrivateXX)
- (EOExpressionArray *)_parseDescription: (NSString *)description
				isFormat: (BOOL)isFormat
			       arguments: (char *)param2;
- (EOExpressionArray *)_parseRelationshipPath: (NSString *)path;
- (id)_parsePropertyName: (id)param0;
//- (id)_newStringWithBuffer: (unsigned short *)param0
//                    length: (unsigned int *)param1;
@end

#endif
