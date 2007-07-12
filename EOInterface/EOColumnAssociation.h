/** -*-ObjC-*-
   EOColumnAssociation.h

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

#ifndef __EOInterface_EOColumnAssociation_h__
#define __EOInterface_EOColumnAssociation_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOInterface/EOAssociation.h>

@class NSString;
@class NSArray;
@class NSNotification;

@class NSTableView;
@class NSTableColumn;
@class NSControl;
@class NSText;

@class EODisplayGroup;

@interface EOColumnAssociation : EOAssociation
{
  unsigned int _didChange:1;

  unsigned int _alreadySetObject:1;

  unsigned int _enabledAspectBound:1;
  unsigned int _colorAspectBound:1;
  unsigned int _boldAspectBound:1;
  unsigned int _italicAspectBound:1;

  unsigned _unused:26;

  SEL _sortingSelector;
}

/* Defining capabilities of concete class.  */
+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;

+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject: (id)object;

+ (NSString *)displayName;

+ (NSString *)primaryAspect;

/* Creation and configuration.  */
- (id)initWithObject: (id)object;

- (void)establishConnection;
- (void)breakConnection;

/* Display object value manipulation.  */
- (void)subjectChanged;
- (BOOL)endEditing;

/* EOColumnViewAssociation sort ordering.  */
- (void)setSortingSelector: (SEL)selector;
- (SEL)sortingSelector;


/* EOColumnViewAssociation table view delegate.  */
- (void)tableView: (NSTableView *)tableView
   setObjectValue: (id)object
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row;

- (id)tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
	    row: (int)row;

- (BOOL)tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row;

- (void)tableView: (NSTableView *)tableView
  willDisplayCell: (id)cell
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row;

/* EOColumnViewAssociation control delegate.  */
- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description;

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object;

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor;

@end

@interface EOTableViewAssociation : EOAssociation
{
  unsigned int _updating:1;

  unsigned int _enabledAspectBound:1;
  unsigned int _colorAspectBound:1;
  unsigned int _boldAspectBound:1;
  unsigned int _italicAspectBound:1;

  unsigned int _sortsByColumnOrder:1;
  unsigned int _didSetSortOrdering:1;

  unsigned int _autoCreated:1;

  unsigned int _unused:24;
}

/* Defining capabilities of concete class.  */
+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;

+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject: (id)object;

+ (NSString *)primaryAspect;

/* Creation and configuration.  */
- (void)establishConnection;
- (void)breakConnection;

/* Display object value manipulation.  */
- (void)subjectChanged;

/* Creation.  */
+ (void)bindToTableView: (NSTableView *)tableView
	   displayGroup: (EODisplayGroup *)displayGroup;

/* Configure sort ordering.  */
- (BOOL)sortsByColumnOrder;
- (void)setSortsByColumnOrder: (BOOL)flag;

/* Access to EOColumnAssociation.  */
- (EOColumnAssociation *)editingAssociation;

/* Providing table view data source.  */
- (int)numberOfRowsInTableView: (NSTableView *)tableView;

- (void)tableView: (NSTableView *)tableView
   setObjectValue: (id)object
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row;

- (id)tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
	    row: (int)row;

/* Delegate methods for table view.  */
- (BOOL)tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row;

- (void)tableView: (NSTableView *)tableView
  willDisplayCell: (id)cell
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row;

/* Notification methods for table view.  */
- (void)tableViewSelectionDidChange: (NSNotification *)notification;

/* Delegate methods for control.  */
- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description;

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object;

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor;

@end

#endif
