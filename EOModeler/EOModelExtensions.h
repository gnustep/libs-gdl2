/* -*-objc-*-
   EOModelExtensions.h

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2001

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

#ifndef	__EOModelExtensions_h__
#define	__EOModelExtensions_h__

#ifdef GNUSTEP
#include <Foundation/NSAttributedString.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>


@interface EOEntity (EOModelExtensions)

- (NSArray *)classAttributes;
- (NSArray *)classScalarAttributes;
- (NSArray *)classNonScalarAttributes;
- (NSArray *)classToManyRelationships;
- (NSArray *)classToOneRelationships;
- (NSArray *)referencedClasses;
- (NSString *)referenceClassName;
- (NSString *)referenceJavaClassName;

- (NSString *)parentClassName;
- (NSString *)javaParentClassName;

- (NSArray *)arrayWithParentClassNameIfNeeded;

- (NSString *)classNameWithoutPackage;
- (NSArray *)classPackage;

@end

@interface EOAttribute (EOModelExtensions)

- (BOOL)isScalar;
- (NSString *)cScalarTypeString;
- (BOOL)isDeclaredBySuperClass;
- (NSString *)javaValueClassName;

@end

@interface EORelationship (EOModelExtensions)

- (BOOL)isDeclaredBySuperClass;

@end

@interface NSMutableAttributedString (_EOModelerErrorConstruction)

+ (NSMutableAttributedString *)mutableAttributedStringWithBoldSubstitutionsWithFormat: (NSString *)format, ...;

@end


#endif /* __EOModelExtensions_h__ */
