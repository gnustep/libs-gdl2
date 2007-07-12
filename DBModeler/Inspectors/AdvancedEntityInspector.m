/*
    AdvancedEntityInspector.m

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

#include "AdvancedEntityInspector.h"
#include <EOModeler/EOMInspector.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTableView.h>
#include <Foundation/NSValue.h>

@implementation AdvancedEntityInspector
- (NSString *)displayName
{
  return @"Adv Entity";
}
- (BOOL) canInspectObject:(id)anObject
{
  return [anObject isKindOfClass:[EOEntity class]];
}

- (void) setReadOnlyAction:(id)sender
{
  [(EOEntity *)[self selectedObject] setReadOnly:[readOnly state] == NSOnState ? YES : NO];
}

- (void) setAbstractAction:(id)sender
{
  [(EOEntity *)[self selectedObject] setIsAbstractEntity:[abstract state] == NSOnState ? YES : NO];
}

- (void) setCachesObjectsAction:(id)sender
{
  [(EOEntity *)[self selectedObject] setCachesObjects:[cachesObjects state] == NSOnState ? YES : NO];
}

- (IBAction) parentAction:(id)sender;
{
  EOEntity *selObj;
  EOEntity *selectedParent;
  int selectedRow;

  selectedRow = [entities selectedRow];
  if (selectedRow == -1) return;

  selObj = [self selectedObject];
  selectedParent = [[[selObj model] entities]
	  			objectAtIndex:[entities selectedRow]];
  
  if ([selObj parentEntity] == selectedParent)
    {
      [selectedParent removeSubEntity:selObj];
    }
  else
    {
      [[selObj parentEntity] removeSubEntity:selObj];
      [selectedParent addSubEntity:selObj];
    }
}

- (void) refresh
{
  [abstract setState:[(EOEntity *)[self selectedObject] isAbstractEntity] ? NSOnState : NSOffState];
  [readOnly setState:[(EOEntity *)[self selectedObject] isReadOnly] ? NSOnState : NSOffState];
  [cachesObjects setState:[(EOEntity *)[self selectedObject] cachesObjects] ? NSOnState : NSOffState];
  [entities reloadData];
  [entities deselectAll:self];
  [parent setEnabled:NO];
  [parent setState:NSOnState];
}

- (void) entityAction:(id)sender
{
  EOEntity *selObj;
  EOEntity *selectedParent;
  int selectedRow = [sender selectedRow]; 

  selObj = [self selectedObject];
  if (selectedRow == -1) return;

  selectedParent = [[[selObj model] entities]
	  			objectAtIndex:selectedRow];
  [parent setEnabled:YES];
  [parent setState: ([selObj parentEntity] == selectedParent) ? NSOnState : NSOffState];
}

- (int) numberOfRowsInTableView:(NSTableView *)tv
{
  return [[[[self selectedObject] model] entities] count];
}

- (id) tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)row
{
  return [[[[[self selectedObject] model] entities] objectAtIndex:row] name];
}

@end
