/**
   EOComboBoxAssociation.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSComboBox.h>
#else
#include <Foundation/Foundation.h>
#endif

#include "EOControlAssociation.h"
#include "EOComboBoxAssociation.h"


@implementation EOComboBoxAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"titles", @"selectedTitle", @"selectedObject",
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
                                @"A", @"A", @"1", @"A", nil];
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
      NSArray *arr = [NSArray arrayWithObjects:
				@"target", @"dataSource", @"delegate", nil];
      arr = [[super objectKeysTaken] arrayByAddingObjectsFromArray: arr];
      _keys = RETAIN (arr);
    }
  return _keys;
}
+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [NSComboBox class]];
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
  return @"EOComboAssoc";
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
- (BOOL)endEditing
{
  return NO;
}

- (int)numberOfItemsInComboBox: (NSComboBox *)comboBox
{
  return 0;
}
- (id)comboBox: (NSComboBox *)comboBox objectValueForItemAtIndex: (int)index
{
  return nil;
}
- (unsigned int)comboBox: (NSComboBox *)comboBox
indexOfItemWithStringValue: (NSString *)stringValue
{
  return 0;
}
- (NSString *)comboBox: (NSComboBox *)comboBox
       completedString: (NSString *)string
{
  return nil;
}

- (void)comboBoxWillPopUp: (NSNotification *)notification
{
}
- (void)comboBoxWillDismiss: (NSNotification *)notification
{
}
- (void)comboBoxSelectionDidChange: (NSNotification *)notification
{
}
- (void)comboBoxSelectionIsChanging: (NSNotification *)notification
{
}

@end

