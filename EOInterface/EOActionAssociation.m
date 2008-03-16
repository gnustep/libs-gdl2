/**
   EOActionAssociation.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 3, 
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

#include <AppKit/NSControl.h>
#include <AppKit/NSActionCell.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include <GNUstepBase/GNUstep.h>
#include "EOActionAssociation.h"
#include "SubclassFlags.h"
#include "EODisplayGroup.h"

@implementation EOActionAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects: 
				@"action", @"argument", @"enabled", nil];
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
				@"A1M", @"", @"A", nil];
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
      _keys 
	= RETAIN ([[super objectKeysTaken] arrayByAddingObject: @"target"]);
    }
  return _keys;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return ([object isKindOfClass: [NSControl class]]
	  || [object isKindOfClass: [NSActionCell class]]);
}

+ (NSString *)primaryAspect
{
  return @"action";
}

- (void)establishConnection
{
  [super establishConnection];
  if ([self displayGroupForAspect: @"enabled"] != nil)
    subclassFlags |= EnabledAspectMask;

  if ([self displayGroupForAspect: @"argument"] != nil)
    subclassFlags |= ArgumentAspectMask;

  if ([self displayGroupForAspect: @"action"] != nil)
    subclassFlags |= ActionAspectMask;

  [_object setTarget:self];
  [_object setAction: @selector(action:)];
}
- (void)breakConnection
{
  subclassFlags = 0;
  [super breakConnection];
}

- (void)subjectChanged
{
  if (subclassFlags & EnabledAspectMask)
    {
      EODisplayGroup *dg = [self displayGroupForAspect:@"enabled"];
      if ([dg contentsChanged] || [dg selectionChanged])
	{	  
	  BOOL isEnabled;
	  isEnabled = [[self valueForAspect:@"enabled"] boolValue];
          [_object setEnabled: isEnabled];
	}
    } 
}

- (void)action: (id)sender
{
  if (subclassFlags & ActionAspectMask)
    {
      id target = [[self displayGroupForAspect:@"action"] selectedObject];
      SEL action;
      
      action = NSSelectorFromString([self displayGroupKeyForAspect:@"action"]);
      if (subclassFlags & ArgumentAspectMask)
        { 
	  id arg = [self displayGroupForAspect:@"argument"];
          [target performSelector: action withObject: arg];
        }
      else
        {
          [target performSelector:action];
	}
    }
}

@end

