/**
   EODetailSelectionAssociation.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#else
#include <Foundation/Foundation.h>
#endif

#include "EODisplayGroup.h"
#include "EODetailSelectionAssociation.h"

@implementation EODetailSelectionAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      _aspects 
	= RETAIN ([[super aspects] arrayByAddingObject: @"selectedObjects"]);
    }
  return _aspects;
}
+ (NSArray *)aspectSignatures
{
  static NSArray *_signatures = nil;
  if (_signatures == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"1M", @"A", nil];
      /* TODO: Check if there is any good reason why we only have
	 one aspect but two signatures.  */
      arr = [[super aspectSignatures] arrayByAddingObjectsFromArray: arr];
      _signatures = RETAIN(arr);
    }
  return _signatures;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [EODisplayGroup class]];
}

+ (NSString *)displayName
{
  return @"EODetailSelection";
}

+ (NSString *)primaryAspect
{
  return @"selectedObjects";
}

- (void)establishConnection
{
}
- (void)breakConnection
{
}

- (void)subjectChanged
{
}

@end
