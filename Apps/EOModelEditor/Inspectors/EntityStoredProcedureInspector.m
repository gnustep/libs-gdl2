
/*
 EntityStoredProcedureInspector.m
 
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

#include "EntityStoredProcedureInspector.h"

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

@implementation EntityStoredProcedureInspector

- (NSString *) displayName
{
  return @"Stored Procedure";
}

- (void) dealloc
{
  DESTROY(_currentEntity);

  [super dealloc];
}

- (void) awakeFromGSMarkup
{
  
}

- (float) displayOrder
{
  return 4;
}

- (BOOL) canInspectObject:(id)anObject
{
  return [anObject isKindOfClass:[EOEntity class]];
}

/*
 EOModel storedProcedureNamed:
 – (NSArray *)storedProcedureNames
 EOStoredProcedure name
 
 */
 
- (void) refresh
{
  NSString *tmpStr;
  
  ASSIGN(_currentEntity, (EOEntity *) [self selectedObject]);
  
  tmpStr = [[_currentEntity storedProcedureForOperation:EOInsertProcedureOperation] name];
  
  [_insertField setStringValue:(tmpStr != nil) ? tmpStr : @""];
  
  tmpStr = [[_currentEntity storedProcedureForOperation:EODeleteProcedureOperation] name];
  
  [_deleteField setStringValue:(tmpStr != nil) ? tmpStr : @""];

  tmpStr = [[_currentEntity storedProcedureForOperation:EOFetchAllProcedureOperation] name];
  
  [_fetchAllField setStringValue:(tmpStr != nil) ? tmpStr : @""];

  tmpStr = [[_currentEntity storedProcedureForOperation:EOFetchWithPrimaryKeyProcedureOperation] name];
  
  [_fetchWithPKField setStringValue:(tmpStr != nil) ? tmpStr : @""];

  tmpStr = [[_currentEntity storedProcedureForOperation:EONextPrimaryKeyProcedureOperation] name];
  
  [_pkGetField setStringValue:(tmpStr != nil) ? tmpStr : @""];
}


- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id obj = [notif object];
  NSString * tmpStr = [obj stringValue];
  EOModel  * model = [_currentEntity model];
  EOStoredProcedure * sProc = [model storedProcedureNamed:tmpStr];

  if (obj == _insertField) {    
    [_currentEntity setStoredProcedure:sProc
                          forOperation:EOInsertProcedureOperation];
    return;
  }
  if (obj == _deleteField) {    
    [_currentEntity setStoredProcedure:sProc
                          forOperation:EODeleteProcedureOperation];
    return;
  }
  if (obj == _fetchAllField) {    
    [_currentEntity setStoredProcedure:sProc
                          forOperation:EOFetchAllProcedureOperation];
    return;
  }
  if (obj == _fetchWithPKField) {    
    [_currentEntity setStoredProcedure:sProc
                          forOperation:EOFetchWithPrimaryKeyProcedureOperation];
    return;
  }
  if (obj == _pkGetField) {    
    [_currentEntity setStoredProcedure:sProc
                          forOperation:EONextPrimaryKeyProcedureOperation];
    return;
  }
}

@end

