/**
   EORadioMatrixAssociation.m

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: David Ayers <d.ayers@inode.at>

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
*/

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSMatrix.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOControlAssociation.h"
#include "EORadioMatrixAssociation.h"

@implementation EORadioMatrixAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"selectedTitle", @"selectedTag",
                              @"enabled", nil];
      _aspects = RETAIN ([[super aspects] arrayByAddingObjectsFromArray: arr]);
    }
  return _aspects;
}

+ (NSArray *)aspectSignatures
{
  static NSArray *_signatures = nil;
  if (_signatures == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"A", @"A", @"A", nil];
      arr = [[super aspectSignatures] arrayByAddingObjectsFromArray: arr];
      _signatures = RETAIN(arr);
    }
  return _signatures;
}

+ (NSArray *)objectKeysTaken
{
  static NSArray *_keys = nil;
  if (_keys == nil)
    {
      _keys = [[NSArray alloc] initWithObject: @"target"];
    }
  return _keys;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [NSMatrix class]];
}

+ (NSArray *)associationClassesSuperseded
{
  static NSArray *_classes = nil;
  if (_classes == nil)
    {
      _classes
        = RETAIN ([[super associationClassesSuperseded]
                    arrayByAddingObject: [EOControlAssociation class]]);
    }
  return _classes;
}

+ (NSString *)displayName
{
  return @"EORadioAssoc";
}

+ (NSString *)primaryAspect
{
  return @"selectedTitle";
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

- (void)setTagValueForOther: (int)value
{
  _tagValueForOther = value;
}

- (int)tagValueForOther
{
  return _tagValueForOther;
}

@end
