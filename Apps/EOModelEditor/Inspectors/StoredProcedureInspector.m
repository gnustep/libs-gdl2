
/*
 StoredProcedureInspector.m
 
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

#include "StoredProcedureInspector.h"

#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>

#include <EOModeler/EOModelerApp.h>
#include "../EOMEDocument.h"
#include "../EOMEEOAccessAdditions.h"

#include <Foundation/Foundation.h>

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

@implementation StoredProcedureInspector

- (NSString *) displayName
{
  return @"Stored Procedure";
}

- (void) dealloc
{
  DESTROY(_currentProcedure);

  [super dealloc];
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
  return [anObject isKindOfClass:[EOStoredProcedure class]];
}

- (void) refresh
{
  EOModel *activeModel = [[NSApp activeDocument] eomodel];
  NSString *tmpStr;
  
  ASSIGN(_currentProcedure, (EOStoredProcedure *) [self selectedObject]);
  
  [nameField setStringValue:[_currentProcedure name]];

  tmpStr = [_currentProcedure externalName];
  
  [externalNameField setStringValue:(tmpStr != nil) ? tmpStr : @""];
}


- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id obj = [notif object];
  
  if (obj == nameField) {    
    [_currentProcedure setName:[nameField stringValue]];
    return;
  }
  if (obj == externalNameField) {    
    [_currentProcedure setExternalName:[externalNameField stringValue]];
    return;
  }
}

@end

