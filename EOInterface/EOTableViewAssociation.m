/**
   EOTableViewAssociation.m

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
#include <Foundation/NSNotification.h>

#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSText.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOColumnAssociation.h"

@implementation EOTableViewAssociation
+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"source", @"enabled", @"textColor", 
			      @"bold", @"italic", nil];
      _aspects = RETAIN([[super aspects] arrayByAddingObjectsFromArray: arr]);
    }
  return _aspects;
}

+ (NSArray *)aspectSignatures
{
  static NSArray *_signatures = nil;
  if (_signatures == nil)
    {
      NSArray *arr = [NSArray arrayWithObjects:
                                @"", @"A", @"A", @"A", @"A", nil];
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
      _keys = [[NSArray alloc] initWithObjects:
				 @"target", @"delegate", @"dataSource", nil];
    }
  return _keys;
}
+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [NSTableView class]];
}

+ (NSString *)primaryAspect
{
  return @"source";
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

+ (void)bindToTableView: (NSTableView *)tableView
	   displayGroup: (EODisplayGroup *)displayGroup
{
}

- (BOOL)sortsByColumnOrder
{
  return _sortsByColumnOrder;
}
- (void)setSortsByColumnOrder: (BOOL)flag
{
  _sortsByColumnOrder = flag ? YES : NO;
}

- (EOColumnAssociation *)editingAssociation
{
  return nil;
}

- (int)numberOfRowsInTableView: (NSTableView *)tableView
{
  return 0;
}

- (void)tableView: (NSTableView *)tableView
   setObjectValue: (id)object
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
}

- (id)tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
	    row: (int)row
{
  return nil;
}

- (BOOL)tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  return NO;
}

- (void)tableView: (NSTableView *)tableView
  willDisplayCell: (id)cell
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
}

- (void)tableViewSelectionDidChange: (NSNotification *)notification
{
}

- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description
{
  return NO;
}

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object
{
  return NO;
}

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor
{
  return NO;
}

@end
