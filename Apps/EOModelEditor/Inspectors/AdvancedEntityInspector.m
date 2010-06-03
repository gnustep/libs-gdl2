/*
 AdvancedEntityInspector.m
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
 EOModelEditor is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 EOModelEditor is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with EOModelEditor; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "AdvancedEntityInspector.h"
#include <EOModeler/EOMInspector.h>
#import <EOAccess/EOAccess.h>

#include <AppKit/AppKit.h>

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#import "../TableViewController.h"


@implementation AdvancedEntityInspector

- (void) dealloc
{
  DESTROY(_tableViewController);
  DESTROY(_allEntites);
  DESTROY(_parentEntity);
  DESTROY(_currentEntity);
  
  [super dealloc];
}

- (float) displayOrder
{
  return 3;
}

- (void) buildAllEntities
{
  NSMutableArray * entArray = [NSMutableArray array];
  NSEnumerator   * enumer   = [[[[NSApp activeDocument] eomodel] entities] objectEnumerator];
  EOEntity       * entity;
  
  while ((entity = [enumer nextObject])) {
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[entity name], @"name",
                                  [entity className], @"className",
                                  [NSNumber numberWithInt:0], @"selected",
                                  nil];
    if ((_parentEntity) && ([_parentEntity isEqual:entity])) {
      [dict setObject:[NSNumber numberWithInt:1]
               forKey:@"selected"];
    }
    [entArray addObject:dict];
  }
  
  ASSIGN(_allEntites, entArray);
  [_tableViewController setRepresentedObject:_allEntites];
  [parentTableView reloadData];
}

- (NSButtonCell*) _cellWithImageNamed:(NSString*) aName
{
  NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];
  [cell setButtonType:NSSwitchButton];
  [cell setImagePosition:NSImageOnly];
  [cell setBordered:NO];
  [cell setBezeled:NO];
  [cell setAlternateImage:[NSImage imageNamed:aName]];
  [cell setControlSize: NSSmallControlSize];
  [cell setEditable:NO];
  
  return AUTORELEASE(cell);
}

- (void) initColums
{
  NSTableColumn * column;
  NSButtonCell  * cell;
  
  column = [parentTableView tableColumnWithIdentifier:@"selected"];
  if (column) {
    cell = [self _cellWithImageNamed:@"dimple"];
    [cell setEnabled:NO];
    [cell setImageDimsWhenDisabled:NO];
    [column setEditable: NO];
    [column setDataCell:cell];
    
  }
}

- (void) awakeFromGSMarkup
{
  [self initColums];
  _tableViewController = [TableViewController new];
  [parentTableView setDataSource:_tableViewController];
  [parentTableView setDelegate:_tableViewController];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewSelectionDidChange:) 
                                               name:NSTableViewSelectionDidChangeNotification 
                                             object:parentTableView];
  
  
}

- (NSString *)displayName
{
  return @"Advanced Entity";
}
- (BOOL) canInspectObject:(id)anObject
{
  return [anObject isKindOfClass:[EOEntity class]];
}

- (IBAction) readOnlyClicked:(id) sender
{
  [_currentEntity setReadOnly:[sender state]];
}

- (IBAction) cacheClicked:(id) sender
{
  [_currentEntity setCachesObjects:[sender state]];
}

- (IBAction) abstractClicked:(id) sender
{
  [_currentEntity setIsAbstractEntity:[sender state]];
}

- (IBAction) parentButtonClicked:(id) sender
{
  EOEntity *selectedParent;
  NSInteger selectedRow = [parentTableView selectedRow];
  
  selectedParent = [[[_currentEntity model] entities] objectAtIndex:selectedRow];
  if (_parentEntity)
  {
    [_parentEntity removeSubEntity:_currentEntity];
    DESTROY(_parentEntity);
  }
  else
  {
    [selectedParent addSubEntity:_currentEntity];
    ASSIGN(_parentEntity, selectedParent);
  }
  [self buildAllEntities];
}

- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id sender = [notif object];
  
  if (sender == batchFaultingSizeText) {
    int iValue = [sender intValue];
    [_currentEntity setMaxNumberOfInstancesToBatchFetch:(iValue >= 0) ? iValue:0];
    return;
  }
  if (sender == externalQueryText) {
    [_currentEntity setExternalQuery:[externalQueryText stringValue]];
    return;
  }
  if (sender == qualifierText) {
    // checkme!
    [_currentEntity setRestrictingQualifier:[externalQueryText stringValue]];
    return;
  }
}

- (IBAction) tableViewClicked:(id) sender
{
}

- (void) refresh
{
  NSString * tmpStr;
  EOModel *activeModel = [[NSApp activeDocument] eomodel];

  ASSIGN(_currentEntity, (EOEntity *) [self selectedObject]);

  [batchFaultingSizeText setIntValue:[_currentEntity maxNumberOfInstancesToBatchFetch]];
  
  tmpStr = [_currentEntity externalQuery];
  
  [externalQueryText setStringValue:(tmpStr != nil) ? tmpStr : @""];
  
  
  // I am not sure if this is correct. How to convert a Qualifier to / from a string?
  tmpStr = [_currentEntity restrictingQualifier];
  
  [qualifierText setStringValue:(tmpStr != nil) ? tmpStr : @""];
    
  [readOnlySwitch setState:[_currentEntity isReadOnly]];
  [cacheSwitch setState:[_currentEntity cachesObjects]];
  [abstactSwitch setState:[_currentEntity isAbstractEntity]];
  
  
  ASSIGN(_parentEntity,[_currentEntity parentEntity]);
  if (_parentEntity) {
    [parentButton setState: NSOnState];
    [parentButton setEnabled:NO];
  } else {
    [parentButton setState: NSOffState];
    [parentButton setEnabled:YES];
  }

  [self buildAllEntities];

}


- (void)tableViewSelectionDidChange:(NSNotification *) notification
{
  NSArray * selectedObjects = nil;
    selectedObjects = [_tableViewController selectedObjects];
    
    if ([selectedObjects count] > 0) {
      NSMutableDictionary * dict = [selectedObjects objectAtIndex:0];
      
      if ((_parentEntity) && ([[dict objectForKey:@"name"] isEqual:[_parentEntity name]])) {
        [parentButton setState: NSOnState];
        [parentButton setEnabled:YES];
        return;
      }
      
      if ((!_parentEntity)) {
        [parentButton setState: NSOffState];
        [parentButton setEnabled:YES];
      } else {
        [parentButton setEnabled:NO];
      }
      
    }
}

@end
