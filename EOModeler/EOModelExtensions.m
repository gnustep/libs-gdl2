/* 
   EOModelExtensions.m

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: January 2001

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

#include "config.h"

#include <EOModeler/EOModelExtensions.h>
#include <EOControl/EODebug.h>


@implementation EOEntity (EOModelExtensions)

- (NSArray *)classAttributes
{
  NSEnumerator *enumerator = [[self attributes] objectEnumerator];
  EOAttribute  *attr;
  NSMutableArray *array;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");

  array = [NSMutableArray arrayWithCapacity:10];

  while((attr = [enumerator nextObject]))
    {
      [array addObject:attr];
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");

  return array;
}

- (NSArray *)classScalarAttributes
{
  NSEnumerator *enumerator = [[self classProperties] objectEnumerator];
  EOAttribute  *attr;
  NSMutableArray *array;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");

  array = [NSMutableArray arrayWithCapacity:10];

  while((attr = [enumerator nextObject]))
    {
      if([attr isKindOfClass: [EOAttribute class]] && [attr isScalar] == YES)
	[array addObject:attr];
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");

  return array;
}

- (NSArray *)classNonScalarAttributes
{
  NSEnumerator *enumerator = [[self classProperties] objectEnumerator];
  EOAttribute  *attr;
  NSMutableArray *array;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");

  array = [NSMutableArray arrayWithCapacity:10];

  while((attr = [enumerator nextObject]))
    {
      if([attr isKindOfClass: [EOAttribute class]] && [attr isScalar] == NO)
	[array addObject:attr];
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");

  return array;
}

- (NSArray *)classToManyRelationships
{
  NSEnumerator *enumerator = [[self classProperties] objectEnumerator];
  EORelationship *relationship;
  NSMutableArray *array;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");

  array = [NSMutableArray arrayWithCapacity:10];

  while((relationship = [enumerator nextObject]))
    {
      if([relationship isKindOfClass: [EORelationship class]]
	 && [relationship isToMany] == YES)
	[array addObject:relationship];
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");

  return array;
}

- (NSArray *)classToOneRelationships
{
  NSEnumerator *enumerator = [[self classProperties] objectEnumerator];
  EORelationship *relationship;
  NSMutableArray *array;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");

  array = [NSMutableArray arrayWithCapacity:10];

  while((relationship = [enumerator nextObject]))
    {
      if([relationship isKindOfClass: [EORelationship class]]
	 && [relationship isToMany] == NO)
	[array addObject:relationship];
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");

  return array;
}

- (NSArray *)referencedClasses
{
  NSEnumerator *enumerator = [[self relationships] objectEnumerator];
  EORelationship *relationship;
  NSMutableArray *array;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");

  array = [NSMutableArray arrayWithCapacity:10];

  while((relationship = [enumerator nextObject]))
    {
      [array addObject:[[relationship destinationEntity] className]];
    }

  EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");

  return array;
}

- (NSString *)referenceClassName
{
  if([[self className] isEqual:@"EOGenericRecord"])
    return @"id";

  return [NSString stringWithFormat:@"%@ *", [self className]];
}

- (NSString *)referenceJavaClassName
{
  if([[self className] isEqual:@"EOGenericRecord"])
    return @"CustomObject";

  return [self className];
}

- (NSString *)parentClassName
{
  if([self parentEntity])
    return [[self parentEntity] className];

  return @"NSObject";
}

- (NSString *)javaParentClassName
{
  if([self parentEntity])
    return [[self parentEntity] className];

  return @"EOCustomObject";
}

- (NSArray *)arrayWithParentClassNameIfNeeded
{
  NSMutableArray *array;

  array = [NSMutableArray arrayWithCapacity:1];

  if([self parentEntity])
    [array addObject:[[self parentEntity] className]];

  return array;
}

- (NSString *)classNameWithoutPackage
{
  return [self className];
}

- (NSArray *)classPackage
{
  return [NSArray array];
}

@end


@implementation EOAttribute (EOModelExtensions)

- (BOOL)isScalar
{
  return NO;
}

- (NSString *)cScalarTypeString
{
  return nil;
}

- (BOOL)isDeclaredBySuperClass
{
  return NO;
}

- (NSString *)javaValueClassName
{
  [self notImplemented:_cmd];

  return nil;
}

@end


@implementation EORelationship (EOModelExtensions)

- (BOOL)isDeclaredBySuperClass
{
  return NO;
}

@end


@implementation NSMutableAttributedString (_EOModelerErrorConstruction)

+ (NSMutableAttributedString *)mutableAttributedStringWithBoldSubstitutionsWithFormat:(NSString *)format, ...
{
  [self notImplemented:_cmd];

  return nil;
}

@end
