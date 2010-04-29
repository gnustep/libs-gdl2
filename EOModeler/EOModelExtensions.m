/* 
   EOModelExtensions.m

   Copyright (C) 2001,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: January 2001

   This file is part of the GNUstep Database Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA 
   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "config.h"

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSString.h>
#endif

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSFont.h>
#include <AppKit/NSAttributedString.h>
#endif

#include <EOControl/EODebug.h>

#include "EOModeler/EOModelExtensions.h"

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
  NSString * vType = [self valueType];
  unichar  myChar;
  
  if ([vType length] < 1) {
    return nil;
  }
  
  myChar = [vType characterAtIndex:0];
  
  switch (myChar) {
    case 'c': return @"char";
      break;
    case 'C': return @"unsigned char";
      break;
    case 's': return @"short";
      break;
    case 'S': return @"unsigned short";
      break;
    case 'i': return @"int";
      break;
    case 'I': return @"unsigned int";
      break;
    case 'l': return @"long";
      break;
    case 'L': return @"unsigned long";
      break;
    case 'u': return @"long long";
      break;
    case 'U': return @"unsigned long long";
      break;
    case 'f': return @"float";
      break;
    case 'd': return @"double";
      break;
    default:
      break;
  }
  
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
  va_list ap;
  NSMutableAttributedString *s = [[NSMutableAttributedString alloc] init];
  NSScanner *scanner = [NSScanner scannerWithString:format];
  NSString *tmp;
  NSDictionary *boldAttributes;
  
  boldAttributes =
    [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:[NSFont systemFontSize]],
	  	NSFontAttributeName,
		nil];
 
  [scanner setCharactersToBeSkipped:nil];
  if (format == nil)
    return nil;
  
  va_start(ap, format);
  [scanner scanUpToString:@"%@" intoString:&tmp];
  [s appendAttributedString:AUTORELEASE([[NSAttributedString alloc]
		  				initWithString:tmp])];
  while ([scanner scanString:@"%@" intoString:NULL])
    {
      NSAttributedString *boldStr;
      
      boldStr = [[NSAttributedString alloc]
	      		initWithString:(NSString *)va_arg(ap, NSString *)
	      		    attributes: boldAttributes];
      [s appendAttributedString:AUTORELEASE(boldStr)];
      if ([scanner scanUpToString:@"%@" intoString:&tmp])
        [s appendAttributedString:AUTORELEASE([[NSAttributedString alloc]
							initWithString:tmp])];
    }
  
  va_end(ap);
  RELEASE(boldAttributes);
  return AUTORELEASE(s); 
}

@end
