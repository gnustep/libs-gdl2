/**
   EOColumnAssociation.m

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

#include <AppKit/NSCell.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSText.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EODisplayGroup.h"
#include "EOColumnAssociation.h"
#include "SubclassFlags.h"

@implementation EOColumnAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
				@"value", @"enabled", nil];
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
                                @"A", @"A", nil];
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
      _keys = [[NSArray alloc] initWithObject: @"identifier"];
    }
  return _keys;
}
+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [NSTableColumn class]];
}

+ (NSString *)displayName
{
  return @"EOColumnAssoc";
}

+ (NSString *)primaryAspect
{
  return @"value";
}

- (id)initWithObject: (id)object
{
  if ((self = [super initWithObject: object]))
    {
      _sortingSelector = @selector(compareAscending:);
    }
  return self;
}

- (void)establishConnection
{
  EODisplayGroup *dg;
  
  [super establishConnection];
  dg = [self displayGroupForAspect:@"value"];

  if (dg) 
    {
      [EOTableViewAssociation bindToTableView: [[self object] tableView]
  			  	 displayGroup: dg];
      subclassFlags |= ValueAspectMask;
    }
  [[self object] setIdentifier: self];
  _enabledAspectBound = [self displayGroupForAspect:@"enabled"] != nil;
}

- (void)breakConnection
{
  [super breakConnection];
  _enabledAspectBound = NO;
}

- (void)subjectChanged
{
}

- (BOOL)endEditing
{
  BOOL flag = YES;

  if (subclassFlags & ValueAspectMask)
    {
      NSTableView *tv = [[self object] tableView];
      int row = tv ? [tv editedRow] : -1;
      
      if (row != -1)
        {
	  [[[self object] tableView] validateEditing];
	  [[self displayGroupForAspect:@"value"] associationDidEndEditing:self];

	} 
    }
  return flag;
}

- (void)setSortingSelector: (SEL)selector
{
  _sortingSelector = selector;
}

- (SEL)sortingSelector
{
  return _sortingSelector;
}


- (void)tableView: (NSTableView *)tableView
   setObjectValue: (id)object
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  [self setValue:object forAspect:@"value" atIndex:row];
}

- (id)tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
	    row: (int)row
{
  return [self valueForAspect:@"value" atIndex:row];
}

- (BOOL)tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  if (_enabledAspectBound)
    return [[self valueForAspect:@"enabled"] boolValue];
  
  return YES;
}

- (void)tableView: (NSTableView *)tableView
  willDisplayCell: (id)cell
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  if (_enabledAspectBound)
    [cell setEnabled:[[self valueForAspect:@"value" atIndex:row] boolValue]];
}

- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description
{
  return [self shouldEndEditingForAspect: @"value" 
  			    invalidInput: string
			errorDescription: description];;
}

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object
{
  BOOL flag;
  /* TODO selected != editing figure this out */
  flag = [self setValue:object forAspect:@"value"];
  
  if (flag)
    [[self displayGroupForAspect:@"value"] associationDidEndEditing:self];
    
  return flag;
}

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor
{
  BOOL flag = [[self object] isEditable];
  if (flag)
    {
      [[self displayGroupForAspect:@"value"] associationDidBeginEditing:self];
      return YES;
    }
  return NO;
}
@end
