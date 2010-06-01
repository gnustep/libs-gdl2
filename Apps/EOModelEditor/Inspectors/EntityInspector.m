
/*
    EntityInspector.m
 
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

#include "EntityInspector.h"

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

@implementation EntityInspector

- (NSString *) displayName
{
  return @"Entity";
}

- (void) dealloc
{
  DESTROY(_currentEntity);

  [super dealloc];
}

- (EOEntity *)selectedEntity
{
  NSInteger row;
  return nil;
//  NSInteger row = [destinationEntityBrowser selectedRow];
  
  if ((row == -1))
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
  return [anObject isKindOfClass:[EOEntity class]];
}

- (void) refresh
{
  NSString * stringValue = nil;
  EOModel  * activeModel = [[NSApp activeDocument] eomodel];
  
  ASSIGN(_currentEntity, (EOEntity *) [self selectedObject]);
  
  stringValue = [_currentEntity name];
  [nameField setStringValue:(stringValue) ? stringValue : @""];
  stringValue = [_currentEntity externalName];
  [tableNameField setStringValue:(stringValue) ? stringValue : @""];
  stringValue = [_currentEntity className];
  [classNameField setStringValue:(stringValue) ? stringValue : @""];
}


- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id obj = [notif object];
  
  if (obj == nameField) {    
    [_currentEntity setName:[nameField stringValue]];
    return;
  }
  if (obj == tableNameField) {    
    [_currentEntity setExternalName:[tableNameField stringValue]];
    return;
  }
  if (obj == classNameField) {    
    [_currentEntity setClassName:[classNameField stringValue]];
    return;
  }
}

@end

