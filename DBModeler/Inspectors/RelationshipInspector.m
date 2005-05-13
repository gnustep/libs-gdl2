#include "RelationshipInspector.h"

#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>

#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerDocument.h>

#include <Foundation/NSArray.h>

@implementation RelationshipInspector
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

- (void) refresh
{
  EOModel *activeModel = [[EOMApp activeDocument] model];
  EOEntity *destEntity;
  EOAttribute *srcAttrib, *destAttrib;
  NSArray *srcAttribs;
  NSArray *destAttribs;
  unsigned int row;


  [name_textField setStringValue:[(EORelationship *)[self selectedObject] name]];
  
  
  
  /* it is important that the destEntity has a selected row before the destAttrib tableview
   * reloads data */
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
  
  srcAttribs = [[self selectedObject] sourceAttributes];
  if (srcAttribs && [srcAttribs count]) 
    srcAttrib = [srcAttribs objectAtIndex:0];
  else
    srcAttrib = nil;

  [srcAttrib_tableView reloadData];
  if (srcAttrib)
    {
      // FIXME!!!! when there is no srcAttrib we segfault when calling isEqual: so we use indexOfObjectIdenticalTo:
      row = [[[[self selectedObject] entity] attributes] indexOfObject:srcAttrib];
      if (row == NSNotFound)
        row = 0;
    }
  else if ([srcAttrib_tableView numberOfRows])
    row = 0;
  [srcAttrib_tableView selectRow:row byExtendingSelection:NO];
  
  destAttribs = [[self selectedObject] destinationAttributes];
  if (destAttribs && [destAttribs count]) 
    destAttrib = [destAttribs objectAtIndex:0];
  else
    destAttrib = nil;
  [destAttrib_tableView reloadData];
  if (destAttrib)
    {
      // FIXME!!!! when there is no destAttrib we segfault when calling isEqual: so we use indexOfObjectIdenticalTo:
      row = [[[[self selectedObject] destinationEntity] attributes] indexOfObject:destAttrib];
      if (row == NSNotFound)
        row = 0;
    }
  else if ([destAttrib_tableView numberOfRows])
    row = 0;
  [destAttrib_tableView selectRow:row byExtendingSelection:NO];
  
  [connect_button setState: ([[self selectedObject] destinationEntity] == nil) ? NSOffState : NSOnState];
  
  [joinCardinality_matrix selectCellWithTag:[[self selectedObject] isToMany]];
  [joinSemantic_popup selectItemAtIndex: [joinSemantic_popup indexOfItemWithTag: [[self selectedObject] joinSemantic]]];
}

- (int) numberOfRowsInTableView:(NSTableView *)tv
{
  EOModel *activeModel = [[EOMApp activeDocument] model];
  if (tv == destEntity_tableView)
    return [[activeModel entities] count];
  else if (tv == srcAttrib_tableView)
    return [[(EOEntity *)[[self selectedObject] entity] attributes] count];
  else if (tv == destAttrib_tableView)
    {
      int selectedRow = [destEntity_tableView selectedRow];
      if (selectedRow == -1 || selectedRow == NSNotFound)
	return 0;
      return [[(EOEntity *)[[activeModel entities] objectAtIndex:[destEntity_tableView selectedRow]] attributes] count]; 

    }
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
}

- (void) tableViewSelectionDidChange:(NSNotification *)notif
{
  NSTableView *tv = [notif object];

  if (tv == destEntity_tableView)
    {
      [destAttrib_tableView reloadData];
    }
}
- (void) connectionChanged:(id)sender
{
  EOEntity *destEntity;
  EOAttribute *srcAttrib;
  EOAttribute *destAttrib;
  EOModel *model;
  EOJoin *newJoin;
  
  model = [[EOMApp activeDocument] model];

  destEntity = [[model entities] objectAtIndex:[destEntity_tableView selectedRow]];
  destAttrib = [[destEntity attributes] objectAtIndex:[destAttrib_tableView selectedRow]];
  srcAttrib = [[[[self selectedObject] entity] attributes] objectAtIndex:[srcAttrib_tableView selectedRow]];

  newJoin = [[EOJoin alloc] initWithSourceAttribute:srcAttrib destinationAttribute:destAttrib];
  [[self selectedObject] addJoin:newJoin];
  [newJoin release];
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

