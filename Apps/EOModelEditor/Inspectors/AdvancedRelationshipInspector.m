
/*
    AdvancedRelationshipInspector.m
 
    Author: David Wetzel <dave@turbocat.de>
    Date: 2010

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

#include "AdvancedRelationshipInspector.h"

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

@implementation AdvancedRelationshipInspector

- (NSString *) displayName
{
  return @"Advanced Relationship";
}

- (void) dealloc
{
  DESTROY(_currentRelation);

  [super dealloc];
}

- (EOEntity *)selectedEntity
{
  NSInteger row;
  return nil;
//  NSInteger row = [destinationEntityBrowser selectedRow];
  
  if (row == -1)
    return nil;
  
  return [[[[NSApp activeDocument] eomodel] entities] objectAtIndex:row];
}



- (void) awakeFromGSMarkup
{
  
}

- (float) displayOrder
{
  return 1;
}

- (BOOL) canInspectObject:(id)anObject
{
  return [anObject isKindOfClass:[EORelationship class]];
}

- (void) refresh
{
  EOModel *activeModel = [[NSApp activeDocument] eomodel];
  

  ASSIGN(_currentRelation, (EORelationship *) [self selectedObject]);
  
  [batchSizeField setIntValue:[_currentRelation numberOfToManyFaultsToBatchFetch]];
  
  [optionalityMatrix selectCellWithTag:[_currentRelation isMandatory]];
  [deleteRuleMatrix selectCellWithTag:[_currentRelation deleteRule]];
  
  [ownsDestinationSwitch setIntValue:[_currentRelation ownsDestination]];
  [propagadePrimaryKeySwitch setIntValue:[_currentRelation propagatesPrimaryKey]];
  
}

- (IBAction) optionalityClicked:(id)sender
{
  [_currentRelation setIsMandatory:[[sender selectedCell] tag]];
}


- (IBAction) deleteRuleClicked:(id)sender
{
  [_currentRelation setDeleteRule:[[sender selectedCell] tag]];
}

- (IBAction) ownsDestinationClicked:(id)sender
{
  [_currentRelation setOwnsDestination:[sender intValue]];
}

- (IBAction) propagadePrimaryKeyClicked:(id)sender
{
  [_currentRelation setPropagatesPrimaryKey:[sender intValue]];
}

- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id obj = [notif object];
  
  if (obj == batchSizeField) {
    int batchsize = [batchSizeField intValue];
    if (batchsize<1) {
      batchsize = 0;
    }
    
    [_currentRelation setNumberOfToManyFaultsToBatchFetch:batchsize];
  }
}

@end

