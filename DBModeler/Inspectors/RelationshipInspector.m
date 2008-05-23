
/*
    RelationshipInspector.m
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006

    This file is part of DBModeler.

    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "RelationshipInspector.h"

#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>

#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerDocument.h>

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSArray.h>
#endif

@implementation RelationshipInspector

- (NSString *) displayName
{
  return @"Relationship inspector";
}

- (EOEntity *)selectedEntity
{
  int row = [destEntity_tableView selectedRow];
  NSArray *entities = [[[EOMApp activeDocument] model] entities];
  
  if (row == -1 || row == NSNotFound || row >= [entities count])
    return nil;
  
  return [[[[EOMApp activeDocument] model] entities] objectAtIndex:row];
}

- (EOAttribute *)selectedDestinationAttribute
{
  int row = [destAttrib_tableView selectedRow];
  NSArray *attribs = [[self selectedEntity] attributes];
  
  if (row == -1 || row == NSNotFound || row >= [attribs count])
    return nil;
  
  return [attribs objectAtIndex:[destAttrib_tableView selectedRow]];
}

- (EOAttribute *)selectedSourceAttribute
{
  int row = [srcAttrib_tableView selectedRow];
  NSArray *attribs = [[[self selectedObject] entity] attributes];
  
  if (row == -1 || row == NSNotFound || row >= [attribs count])
    return nil;
  
  return [attribs objectAtIndex:[srcAttrib_tableView selectedRow]];
}

- (int) indexOfSourceAttribute:(EOAttribute *)srcAttrib
{
  id tmp;
  int row;

  if (srcAttrib == nil) return NSNotFound;

  tmp = [self selectedObject];
  if (tmp == nil) return NSNotFound;
  
  tmp = [tmp entity];
  if (tmp == nil) return NSNotFound;
  
  tmp = [(EOEntity *)tmp attributes];
  if (tmp == nil) return NSNotFound;

  row = [tmp indexOfObject:srcAttrib];
  return row;
}

- (int) indexOfDestinationAttribute:(EOAttribute *)destAttrib
{
  id tmp;
  int row;

  if (destAttrib == nil) return NSNotFound;
  
  tmp = [self selectedObject];
  if (tmp == nil) return NSNotFound;

  tmp = [tmp destinationEntity];
  if (tmp == nil) return NSNotFound;
  
  tmp = [(EOEntity *)tmp attributes];
  if (tmp == nil) return NSNotFound;

  row = [tmp indexOfObject:destAttrib];
  return row;
}

- (EOJoin *) joinWithSource:(EOAttribute *)srcAttrib destination:(EOAttribute *)destAttrib
{
  NSArray *joins;
  int i,c;
  
  if (!srcAttrib && !destAttrib)
    return nil;

  joins = [[self selectedObject] joins];
  c = [joins count];
  for (i = 0; i < c; i++)
    {
      BOOL flag;
      id join = [joins objectAtIndex:i];
          
      /* if both arguments are non-nil, both must be equal,
       * if one argument is nil the non-nil argument must be equal */
      flag = ((srcAttrib 
               && destAttrib
               && [srcAttrib isEqual:[join sourceAttribute]]
               && [destAttrib isEqual:[join destinationAttribute]])
              || (srcAttrib
                  && (destAttrib ==  nil)
                  && [srcAttrib isEqual:[join sourceAttribute]])
              || (destAttrib
                  && (srcAttrib == nil)
                  && [destAttrib isEqual:[join destinationAttribute]]));
                          
      if (flag)  
        {
          return join;
        }
    }
  return nil;
}

- (EOJoin *) selectedJoin
{
  EOJoin *join = [self joinWithSource:[self selectedSourceAttribute]
                              destination:[self selectedDestinationAttribute]];
  return join;
}

- (void) awakeFromNib
{
  [destEntity_tableView setAllowsEmptySelection:NO];
  [srcAttrib_tableView setAllowsEmptySelection:NO];
  [destAttrib_tableView setAllowsEmptySelection:NO];
}

- (float) displayOrder
{
  return 0;
}

- (BOOL) canInspectObject:(id)anObject
{
  return [anObject isKindOfClass:[EORelationship class]];
}

- (void) updateConnectButton
{
  [connect_button setEnabled:([self selectedDestinationAttribute] != nil)];
  [connect_button setState: ([self selectedJoin] != nil) ? NSOnState : NSOffState];
}

- (void) refresh
{
  EOModel *activeModel = [[EOMApp activeDocument] model];
  EOEntity *destEntity;
  EOAttribute *srcAttrib, *destAttrib;
  NSArray *joins;
  unsigned int row = 0;
  [name_textField setStringValue:[(EORelationship *)[self selectedObject] name]];
  
  [srcAttrib_tableView reloadData];
  [destAttrib_tableView reloadData];
  [destEntity_tableView reloadData];
  
  destEntity = [[self selectedObject] destinationEntity];
  if (destEntity)
    {
      row = [[activeModel entities] indexOfObject:destEntity];
      if (row == NSNotFound)
        row = 0;
    }
  else if ([destEntity_tableView numberOfRows])
    row = 0;
  
  [destEntity_tableView selectRow:row byExtendingSelection:NO];
  
  joins = [[self selectedObject] joins];
  
  if ([joins count])
    {
      EOJoin *join = [joins objectAtIndex:0];
      srcAttrib = [join sourceAttribute];
      destAttrib = [join destinationAttribute];
      row = [self indexOfSourceAttribute:srcAttrib];
      if (row != NSNotFound)
        [srcAttrib_tableView selectRow:row byExtendingSelection:NO];
      row = [self indexOfDestinationAttribute:srcAttrib];
      if (row != NSNotFound)
        [destAttrib_tableView selectRow:row byExtendingSelection:NO];
    }
  else
    {
      if ([self numberOfRowsInTableView:srcAttrib_tableView])
        {
          [srcAttrib_tableView selectRow:0 byExtendingSelection:NO];
        }

      if ([self numberOfRowsInTableView:destAttrib_tableView])
        {
          [destAttrib_tableView selectRow:0 byExtendingSelection:NO];
        }
    }

  [self updateConnectButton]; 
  
  [joinCardinality_matrix selectCellWithTag:[[self selectedObject] isToMany]];
  [joinSemantic_popup selectItemAtIndex: [joinSemantic_popup indexOfItemWithTag: [[self selectedObject] joinSemantic]]];
}

- (int) numberOfRowsInTableView:(NSTableView *)tv
{
  EOModel *activeModel = [[EOMApp activeDocument] model];
  if (tv == destEntity_tableView)
    {
      return [[activeModel entities] count];
    }
  else if (tv == srcAttrib_tableView)
    return [[(EOEntity *)[[self selectedObject] entity] attributes] count];
  else if (tv == destAttrib_tableView)
    {
      int selectedRow = [destEntity_tableView selectedRow];
      if (selectedRow == -1 || selectedRow == NSNotFound)
        return 0;
      return [[(EOEntity *)[[activeModel entities] objectAtIndex:[destEntity_tableView selectedRow]] attributes] count]; 

    }
  return 0;
}

- (id) tableView:(NSTableView *)tv
objectValueForTableColumn:(NSTableColumn *)tc
row:(int)rowIndex
{
  EOModel *activeModel = [[EOMApp activeDocument] model];
  if (tv == destEntity_tableView)
    {
      return [(EOEntity *)[[activeModel entities] objectAtIndex:rowIndex] name];
    }
  else if (tv == srcAttrib_tableView)
    {
      return [(EOAttribute *)[[(EOEntity *)[[self selectedObject] entity] attributes] objectAtIndex:rowIndex] name];
    }
  else if (tv == destAttrib_tableView)
    {
      int selectedRow = [destEntity_tableView selectedRow];
      if (selectedRow == NSNotFound)
        [destEntity_tableView selectRow:0 byExtendingSelection:NO];
      return [(EOAttribute *)[[(EOEntity *)[[activeModel entities] objectAtIndex:[destEntity_tableView selectedRow]]
                                   attributes] objectAtIndex:rowIndex] name]; 
    } 

  return nil;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notif
{
  NSTableView *tv = [notif object];

  if (tv == destEntity_tableView)
    {
      [destAttrib_tableView reloadData];
    }
  else if (tv == destAttrib_tableView)
    {
      EOJoin *join = [self joinWithSource:nil destination:[self selectedDestinationAttribute]]; 
      int row = [self indexOfSourceAttribute:[join sourceAttribute]];
      
      if (row != NSNotFound)
        [srcAttrib_tableView selectRow:row byExtendingSelection:NO];
      
    }
  else if (tv == srcAttrib_tableView)
    {
      EOJoin *join = [self joinWithSource:[self selectedSourceAttribute] destination:nil];
      int row = [self indexOfDestinationAttribute:[join destinationAttribute]];
      
      if (row != NSNotFound)
        [destAttrib_tableView selectRow:row byExtendingSelection:NO];
    }

  [self updateConnectButton];
}

- (BOOL) tableView:(NSTableView *)tv shouldSelectRow:(int)rowIndex
{
  if (tv == destEntity_tableView)
    {
      return [[self selectedObject] destinationEntity] == nil;
    }
  else
    {
      return YES;
    }
}

- (void) tableView:(NSTableView *)tv willDisplayCell:(NSCell *)cell forTableColumn:(id)tc
row:(int)row
{
  if (tv == destEntity_tableView)
    {
      NSColor *enabledText = [NSColor controlTextColor];
      NSColor *disabledText = [NSColor disabledControlTextColor];
      BOOL flag = ([[self selectedObject] destinationEntity] == nil);
      
      [(NSTextFieldCell *)cell setTextColor:(flag == YES) ? enabledText : disabledText];
    }
}

- (void) connectionChanged:(id)sender
{
  EOAttribute *srcAttrib;
  EOAttribute *destAttrib;
  EOJoin *join;
  EOEntity *destEnt = [[self selectedObject] destinationEntity];
  destAttrib = [self selectedDestinationAttribute];
  srcAttrib = [self selectedSourceAttribute];

  if ([sender state] == NSOnState)
    {
      join = [[EOJoin alloc] initWithSourceAttribute:srcAttrib destinationAttribute:destAttrib];
      [[self selectedObject] addJoin:join];
      [join release];
    }
  else
    {
      join = [self joinWithSource:srcAttrib destination:destAttrib];
      [[self selectedObject] removeJoin:join];
    }
  
  if (destEnt != [[self selectedObject] destinationEntity])
    [destEntity_tableView reloadData];
}

- (void) nameChanged:(id)sender
{
  NSString *name = [name_textField stringValue];

  [(EORelationship *)[self selectedObject] setName:name];
}

- (void) semanticChanged:(id)sender
{
  /* the tag in the nib must match the values in the EOJoinSemantic enum */
  [[self selectedObject] setJoinSemantic: [[sender selectedItem] tag]];
  
}

- (void) cardinalityChanged:(id)sender
{
  /* the tag in the nib for to-one must be 0 to-many 1 */
  [[self selectedObject] setToMany: [[sender selectedCell] tag]];
}

@end

