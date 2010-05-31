
/*
 RelationshipInspector.m
 
 Author: Matt Rice <ratmice@gmail.com>
 Date: 2005, 2006
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

#include "RelationshipInspector.h"

#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>

#include <EOModeler/EOModelerApp.h>
#include "../EOMEDocument.h"
#include "../EOMEEOAccessAdditions.h"

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSArray.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

@implementation RelationshipInspector

- (NSString *) displayName
{
  return @"Relationship";
}

- (void) dealloc
{
  DESTROY(_attributes);
  DESTROY(_dimpleImg);
  DESTROY(_noDimpleImg);
  DESTROY(_currentRelation);

  [super dealloc];
}

//- (EOEntity *)selectedEntity
//{
//  NSInteger row;
//  return nil;
//  
//  if ((row == -1))
//    return nil;
//  
//  return [[[[NSApp activeDocument] eomodel] entities] objectAtIndex:row];
//}
//


- (void) awakeFromGSMarkup
{
  [destinationEntityBrowser setAllowsEmptySelection:NO];
  [sourceBrowser setAllowsEmptySelection:NO];
//  [destAttrib_tableView setAllowsEmptySelection:NO];
  ASSIGN(_dimpleImg, [NSImage imageNamed:@"dimple"]);
  ASSIGN(_noDimpleImg, [NSImage imageNamed:@"nodimple"]);
  
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
  EOModel *activeModel = [[NSApp activeDocument] eomodel];
//  EORelationship * relation = (EORelationship *) [self selectedObject];
  EOEntity *destEntity;
  EOAttribute *srcAttrib, *destAttrib;
  NSArray *joins;
  NSInteger row = 0;
  
  if (_attributes) {
    DESTROY(_attributes);
  }  

  ASSIGN(_currentRelation, (EORelationship *) [self selectedObject]);

  [name_textField setStringValue:[_currentRelation name]];

  [sourceBrowser loadColumnZero];
  [destBrowser loadColumnZero];
  [destinationEntityBrowser loadColumnZero];
  
  destEntity = [[self selectedObject] destinationEntity];
  if (destEntity)
  {
    NSUInteger idx = [[activeModel entities] indexOfObject:destEntity];
    if (idx != NSNotFound) {
      [destinationEntityBrowser selectRow:idx
                                 inColumn:0];         

      [destinationEntityBrowser setEnabled:NO];
    }
  } else {
    [destinationEntityBrowser setEnabled:YES];
  }

  
  joins = [_currentRelation joins];
  
  if ([joins count])
  {
    EOJoin *join = [joins objectAtIndex:0];
    srcAttrib = [join sourceAttribute];
    destAttrib = [join destinationAttribute];
    
    [connectButton setEnabled:NO];
    
    [joinCardinality_matrix selectCellWithTag:[[self selectedObject] isToMany]];
    [joinSemantic_popup selectItemWithTag: [_currentRelation joinSemantic]];
  }
}

- (IBAction) connectButtonClicked:(id)sender
{
  NSString    *srcName   = [[sourceBrowser selectedCell] title];
  EOJoin *join;

  if ([sender state] == NSOnState)
    {
      EOModel     *activeModel   = [[NSApp activeDocument] eomodel];
      NSString    *dstName       = [[destBrowser selectedCell] title];
      NSString    *dstEntityName = [[destinationEntityBrowser selectedCell] title];
      EOAttribute *srcAttrib     = [[_currentRelation entity] attributeNamed:srcName];
      EOAttribute *destAttrib    = [[activeModel entityNamed:dstEntityName] attributeNamed:dstName];
      
      join = [[EOJoin alloc] initWithSourceAttribute:srcAttrib 
                                destinationAttribute:destAttrib];

      [_currentRelation addJoin:join];
      
      [join release];
    } else {
      // disconnect

      join = [_currentRelation joinFromAttributeNamed:srcName];
      [_currentRelation removeJoin:join];
    }
  
  [destBrowser loadColumnZero];
  [sourceBrowser loadColumnZero];

}

- (void) nameChanged:(id)sender
{
  NSString *name = [name_textField stringValue];

  [(EORelationship *)[self selectedObject] setName:name];
}

- (void) joinChanged:(id)sender
{
  /* the tag in the nib must match the values in the EOJoinSemantic enum */
  [(EORelationship *)[self selectedObject] setJoinSemantic: [[sender selectedItem] tag]];
  
}

- (void) cardinalityChanged:(id)sender
{
  /* the tag in the nib for to-one must be 0 to-many 1 */
  [(EORelationship *) [self selectedObject] setToMany: [[sender selectedCell] tag]];
}

- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id sender = [notif object];

  if (sender == name_textField)
    [self nameChanged:sender];
}

- (NSArray*) attributes
{
  if (!_attributes) {
    _attributes = [[[[self selectedObject] entity] attributes] retain];
  }
  
  return _attributes;
}

#pragma mark -
#pragma mark browser

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
  NSInteger intVal = 0;
  EOModel *activeModel = nil;

  if ((sender == destinationEntityBrowser)) {
    activeModel = [[NSApp activeDocument] eomodel];
    return [[activeModel entityNames] count];
  } 

  if ((sender == sourceBrowser)) {
    EOEntity  * selectedEntity = [_currentRelation entity];
    NSArray   * attributes = [selectedEntity attributes];

    return [attributes count];
  } 

  if ((sender == destBrowser)) {
    EOEntity  * destinationEntity = [_currentRelation destinationEntity];
    NSArray   * dstAttributes = nil;
    
    
    if (!destinationEntity) {
      NSString * name = [[destinationEntityBrowser selectedCell] title];
      activeModel = [[NSApp activeDocument] eomodel];

      destinationEntity = [activeModel entityNamed:name];
    }
    
    dstAttributes = [destinationEntity attributes];
    return [dstAttributes count];
  } 
  
  return 0;
  
}


- (void)browser:(NSBrowser *)sender willDisplayCell:(NSBrowserCell *)cell atRow:(NSInteger)row column:(NSInteger)column
{
  EOModel     * activeModel = nil;
  EOEntity    * selectedEntity = nil;
  EOEntity    * destinationEntity = nil;
  
  if ((sender == destinationEntityBrowser)) {
    activeModel = [[NSApp activeDocument] eomodel];

    [cell setLeaf:YES];
    //entityNames is better
    [cell setTitle:[[activeModel entityNames] objectAtIndex:row]];
    //[cell setTitle:[(EOEntity *)[[activeModel entities] objectAtIndex:row] name]];
    
    return;
  }
  
  selectedEntity = [_currentRelation entity];
  
  if (((sender == sourceBrowser)) && (selectedEntity)) {
    NSArray  * attributes = [selectedEntity attributes];
    NSString * name = [[attributes objectAtIndex:row] name];
    NSUInteger idx;
    
    
    [cell setLeaf:YES];
    [cell setTitle:name];
    
    idx = [[_currentRelation sourceAttributeNames] indexOfObject: name];
    
    if ((idx != NSNotFound)) {
      [cell setImage:_dimpleImg];
    } else {
      [cell setImage:_noDimpleImg];
    }
    return;
  } 
  
  destinationEntity = [_currentRelation destinationEntity];

  if (!destinationEntity) {
    NSString * name = [[destinationEntityBrowser selectedCell] title];
    activeModel = [[NSApp activeDocument] eomodel];
    
    destinationEntity = [activeModel entityNamed:name];
  }
  

  if (((sender == destBrowser)) && (destinationEntity)) {
    NSArray  * dstAttributes = [destinationEntity attributes];
    NSString * name = [[dstAttributes objectAtIndex:row] name];
    NSUInteger idx;
    
    
    [cell setLeaf:YES];
    [cell setTitle:name];
    
    idx = [[_currentRelation destinationAttributeNames] indexOfObject: name];
    
    if ((idx != NSNotFound)) {
      [cell setImage:_dimpleImg];
    } else {
      [cell setImage:_noDimpleImg];
    }
    
  } 
  
}

- (IBAction)sourceBrowserClicked:(NSBrowser *)sender
{
  NSString * name = [[sender selectedCell] title];
  EOEntity * destinationEntity = nil;
  EOJoin   * join = nil;
  NSInteger  row = NSNotFound;
  
  destinationEntity = [_currentRelation destinationEntity];
  
  join = [_currentRelation joinFromAttributeNamed:name];
  
  if (join) {
    row = [[destinationEntity attributeNames] indexOfObject:[[join destinationAttribute] name]];
  }
  
  if ((row != NSNotFound)) {
    
    [destBrowser selectRow:row 
                  inColumn:0];
    
    
    [destBrowser scrollRowToVisible:row 
                           inColumn:0];
    
    [connectButton setState: NSOnState];
    [connectButton setEnabled:YES];
    
  } else {
    NSString * otherName = [[destBrowser selectedCell] title];
    EOJoin * otherJoin = [_currentRelation joinToAttributeNamed:otherName];
    
    if (otherJoin) {
      [connectButton setEnabled:NO];
    } else {
      [connectButton setEnabled:YES];
    }
    
    [connectButton setState: NSOffState];
  }
  
}

- (IBAction)destBrowserClicked:(NSBrowser *)sender
{
  NSString * name = [[sender selectedCell] title];
  EOEntity * srcEntity = nil;
  EOJoin   * join = nil;
  NSInteger  row = NSNotFound;
  
  srcEntity = [_currentRelation entity];
  
  join = [_currentRelation joinToAttributeNamed:name];
  
  if (join) {
    row = [[srcEntity attributeNames] indexOfObject:[[join sourceAttribute] name]];
  }
  
  if ((row != NSNotFound)) {
    
    [sourceBrowser selectRow:row 
                    inColumn:0];
    
    
    [sourceBrowser scrollRowToVisible:row 
                             inColumn:0];
    
    [connectButton setState: NSOnState];
    [connectButton setEnabled:YES];
    
  } else {
    NSString * otherName = [[sourceBrowser selectedCell] title];
    EOJoin * otherJoin = [_currentRelation joinFromAttributeNamed:otherName];
    
    if (otherJoin) {
      [connectButton setEnabled:NO];
    } else {
      [connectButton setEnabled:YES];
    }
    
    
    [connectButton setState: NSOffState];
  }  
  
}

- (IBAction)destinationEntityBrowserClicked:(NSBrowser *)sender
{
  [destBrowser loadColumnZero];
  [destBrowser selectRow:0 
                inColumn:0];
  
}

#pragma mark -

@end

