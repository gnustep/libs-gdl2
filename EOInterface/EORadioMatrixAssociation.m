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
#include <Foundation/NSValue.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSButtonCell.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOControlAssociation.h"
#include "EORadioMatrixAssociation.h"
#include "SubclassFlags.h"

/* GNUstep specific */
@interface NSMatrix (RadioMatrixTitle)
-(BOOL) _selectCellWithTitle:(NSString *)title;
@end

@implementation NSMatrix (RadioMatrixTitle)
-(BOOL) _selectCellWithTitle:(NSString *)title
{
  int i = _numRows;

  while (i-- > 0)
    {
      int j = _numCols;
   
      while (j-- > 0)
        {
          if ([[_cells[i][j] title] isEqual: title])
            {
              [self selectCellAtRow:i column:j];
              return YES;
            }
        }
    }
  return NO;
}
@end


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

- (id) initWithObject:(id)anObject
{
  self = [super initWithObject:anObject];
  _tagValueForOther = -1; 
  return self;
}

- (void)establishConnection
{
  if ([self displayGroupForAspect: @"enabled"])
    subclassFlags |= EnabledAspectMask;
  if ([self displayGroupForAspect: @"selectedTag"])
    subclassFlags |= SelectedTagAspectMask;
  if ([self displayGroupForAspect: @"selectedTitle"])
    subclassFlags |= SelectedTitleAspectMask;
  
  [super establishConnection];
  [_object setTarget: self];
  [_object setAction: @selector(_action:)];
  [_object setAllowsEmptySelection:YES];
}

- (void)breakConnection
{
  [_object setTarget: nil];
  [super breakConnection];
  subclassFlags = 0;
}

- (void)subjectChanged
{
  if (subclassFlags & EnabledAspectMask)
    [[self object] setEnabled: [[self valueForAspect:@"enabled"] boolValue]];
  
  if (subclassFlags & SelectedTagAspectMask)
    {
      NSCell *cell;
      
      cell = [_object cellWithTag:[[self valueForAspect:@"selectedTag"] intValue]];
      if (cell)
        {
          [_object selectCell:cell];
	}
      else
        {
	  [_object selectCellWithTag:_tagValueForOther]; 
	}
    }
  /* not sure if this is even supported in the original i suspect not */ 
  if (subclassFlags & SelectedTitleAspectMask)
    {
      if (![_object _selectCellWithTitle:[self valueForAspect:@"selectedTitle"]])
        [_object selectCellWithTag:_tagValueForOther];
    }
}

- (void)setTagValueForOther: (int)value
{
  _tagValueForOther = value;
}

- (int)tagValueForOther
{
  return _tagValueForOther;
}

- (void) _action:(id)sender
{
  if (subclassFlags & SelectedTagAspectMask)
    [self setValue: [NSNumber numberWithInt: [[_object selectedCell] tag]]
    	 forAspect: @"selectedTag"];
  if (subclassFlags & SelectedTitleAspectMask)
    {
      [self setValue: [[_object selectedCell] title]
	   forAspect: @"selectedTitle"];
    }
}
@end
