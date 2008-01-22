/**
   EOTableViewAssociation.m

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
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSText.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include "EOColumnAssociation.h"
#include "EODisplayGroup.h"
@implementation EOTableViewAssociation

static NSMapTable *tvAssociationMap; 
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

@class EOControlAssociation;
@class EOPickTextAssociation;
@class EOActionAssociation;
@class EOActionInsertionAssociation; 
+ (NSArray *) associationClassesSuperseded
{
  static NSArray *_superseded;

  if (!_superseded)
    _superseded = [[NSArray arrayWithObjects:[EOControlAssociation class],
					[EOPickTextAssociation class],
					[EOActionAssociation class],
					[EOActionInsertionAssociation class],
					nil] retain];
  return _superseded;
}

+ (NSString *)primaryAspect
{
  return @"source";
}

- (void)establishConnection
{
  [super establishConnection];
  _enabledAspectBound = [self displayGroupForAspect:@"enabled"] != nil;
  _italicAspectBound = [self displayGroupForAspect:@"italic"] != nil;
  _colorAspectBound = [self displayGroupForAspect:@"color"] != nil;
  _boldAspectBound = [self displayGroupForAspect:@"bold"] != nil;
}

- (void)breakConnection
{
  [super breakConnection];
  NSMapRemove(tvAssociationMap, _object);
  _enabledAspectBound = NO;
  _italicAspectBound = NO;
  _colorAspectBound = NO;
  _boldAspectBound = NO;
}

- (void)subjectChanged
{
  
  EODisplayGroup *dg = [self displayGroupForAspect:@"source"];
  
  /* this must be before selection changes in the case where the selected row 
     is not yet inserted */
  if ([dg contentsChanged])
    [[self object] reloadData];


  if ([dg selectionChanged])
    {
      if (!_extras)
        {
          NSArray *selectionIndexes = RETAIN([dg selectionIndexes]);
          unsigned int i, count;
          count = [selectionIndexes count];
          if (count)
    	    {
              for (i = 0; i < count; i++)
                {
	          int rowIndex = [[selectionIndexes objectAtIndex:i] intValue];
		  
		  /* don't extend the first selection */
	          [[self object] selectRow: rowIndex
		      byExtendingSelection: (i != 0)];
		  
	          [[self object] scrollRowToVisible:rowIndex];
	        }
	    }
          else
            {
	      /* hmm not sure what to do about it if it doesn't allow empty
	       * selection.  In that case NSTableView no-ops and the dg
	       * will think nothing is selected table view will leave
	       * whatever index was selected still selected.
	       */
	      if ([[self object] allowsEmptySelection])
		{
	          [[self object] deselectAll:self];
		}
	      else
		NSLog(@"attempting to clear selection when table view won't allow empty selection");
		
            }
          RELEASE(selectionIndexes);
        }
      _extras = 0;
    }
}

+ (void)bindToTableView: (NSTableView *)tableView
	   displayGroup: (EODisplayGroup *)displayGroup
{
  EOTableViewAssociation *assoc;

  if (!tvAssociationMap)
    {
      tvAssociationMap = NSCreateMapTableWithZone(NSNonRetainedObjectMapKeyCallBacks,
                                   NSNonRetainedObjectMapValueCallBacks,
                                   0, [self zone]);
      assoc = [[self allocWithZone:NSDefaultMallocZone()] initWithObject:tableView];
      NSMapInsert(tvAssociationMap, (void *)tableView, (void *)assoc);
      [assoc bindAspect:@"source" displayGroup:displayGroup key:@""];
      [tableView setDataSource:assoc];
      [tableView setDelegate:assoc];
      [assoc establishConnection];
      RELEASE(assoc);
      return;
    }
  
  assoc = (EOTableViewAssociation *)NSMapGet(tvAssociationMap, tableView);
  if (!assoc)
    {
      assoc = [[self allocWithZone:NSDefaultMallocZone()] initWithObject:tableView];
      [assoc bindAspect:@"source" displayGroup:displayGroup key:@""];
      [tableView setDataSource:assoc];
      [tableView setDelegate:assoc];
      [assoc establishConnection];
      RELEASE(assoc);
      NSMapInsert(tvAssociationMap, tableView, assoc);
    } 
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
  int editedColumn = [[self object] editedColumn];

  if (editedColumn == -1)
    {
      return nil;
    }
  else
    {
      return [[[[self object] tableColumns] objectAtIndex:editedColumn] identifier];
    }
}

- (int)numberOfRowsInTableView: (NSTableView *)tableView
{
  return [[[self displayGroupForAspect:@"source"] displayedObjects] count];
}

- (void)tableView: (NSTableView *)tableView
   setObjectValue: (id)object
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  [(EOColumnAssociation *)[tableColumn identifier] 
  			    tableView: tableView
  		       setObjectValue: object
		       forTableColumn: tableColumn
			          row: row];
}

- (id)tableView: (NSTableView *)tableView
objectValueForTableColumn: (NSTableColumn *)tableColumn
	    row: (int)row
{
  id object;
  object = [[tableColumn identifier] tableView: tableView 
  		   objectValueForTableColumn: tableColumn
			                 row: row];
  return object;
}

- (BOOL)tableView: (NSTableView *)tableView
shouldEditTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  if (_enabledAspectBound)
    if ([[self valueForAspect: @"enabled" atIndex:row] boolValue] == NO) 
      return NO;

  return [[tableColumn identifier] tableView:tableView shouldEditTableColumn:tableColumn row:row];
}

- (void)tableView: (NSTableView *)tableView
  willDisplayCell: (id)cell
   forTableColumn: (NSTableColumn *)tableColumn
	      row: (int)row
{
  if (_enabledAspectBound)
    [cell setEnabled: [[self valueForAspect:@"enabled" atIndex: row] boolValue]];
  /* maybe these should setup an attributed string */
  if (_italicAspectBound)
    ; /* TODO */
  if (_boldAspectBound)
    ; /* TODO */
  if (_colorAspectBound)
    {
      if ([cell respondsToSelector:@selector(setTextColor:)])
        [cell setTextColor: [self valueForAspect:@"color" atIndex:row]];
    }
}

- (void)tableViewSelectionDidChange: (NSNotification *)notification
{
  _extras = 1;
    {
      EODisplayGroup *dg = [self displayGroupForAspect:@"source"];
      NSMutableArray *selectionIndices = [[NSMutableArray alloc] init];
      NSTableView *tv = [notification object];
      NSEnumerator *selectionEnum = [tv selectedRowEnumerator];
      id index;
      
      while ((index = [selectionEnum nextObject]))
        {
	  [selectionIndices addObject:index];
	}
 
      [dg setSelectionIndexes: AUTORELEASE(selectionIndices)];
    }
}

- (BOOL)control: (NSControl *)control
didFailToFormatString: (NSString *)string
errorDescription: (NSString *)description
{
  return [[self editingAssociation] 
  			control: control 
	  didFailToFormatString: string
	       errorDescription: description];
}

- (BOOL)control: (NSControl *)control
  isValidObject: (id)object
{
  return [[self editingAssociation] control: control
  			      isValidObject: object];
}

- (BOOL)control: (NSControl *)control
textShouldBeginEditing: (NSText *)fieldEditor
{
  return [[self editingAssociation] control: control
  		     textShouldBeginEditing: fieldEditor];
}
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    [[self displayGroupForAspect:@"source"] endEditing];
}

- (void) dealloc
{
  [super dealloc];
}
@end
