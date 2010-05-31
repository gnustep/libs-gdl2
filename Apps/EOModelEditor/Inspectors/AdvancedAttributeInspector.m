
/*
 AdvancedAttributeInspector.m
 
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

#include "AdvancedAttributeInspector.h"

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

@implementation AdvancedAttributeInspector

- (NSString *) displayName
{
  return @"Advanced Attribute";
}

- (void) dealloc
{
  DESTROY(_currentAttribute);

  [super dealloc];
}


- (void) awakeFromGSMarkup
{
  
}

- (float) displayOrder
{
  return 2;
}

- (BOOL) canInspectObject:(id)anObject
{
  BOOL weCan = [anObject isKindOfClass:[EOAttribute class]];
  
  
  // avoid the AdvancedAttributeInspector on Stored Procedures.
  if (weCan) {
    id outlineSel = [[NSApp activeDocument] outlineSelection];
    if ((outlineSel) && ([outlineSel class] == [EOEntity class])) {
      return YES;
    }
    return NO;
  }
  
  return weCan;
}

- (void) refresh
{  
  NSString * tmpStr;
  ASSIGN(_currentAttribute, (EOAttribute *) [self selectedObject]);
 
  [readOnlySwitch setIntValue:[_currentAttribute isReadOnly]];
  [allowNullSwitch setIntValue:[_currentAttribute allowsNull]];
  
  tmpStr = [_currentAttribute readFormat];
  if (!tmpStr) {
    [readField setStringValue:@""];
  } else {
    [readField setStringValue:tmpStr];
  }

  tmpStr = [_currentAttribute writeFormat];
  if (!tmpStr) {
    [writeField setStringValue:@""];
  } else {
    [writeField setStringValue:tmpStr];
  }
  
}


- (void) controlTextDidEndEditing:(NSNotification *)notif
{
  id obj = [notif object];
  
  if (obj == readField) {    
    [_currentAttribute setReadFormat:[readField stringValue]];
    return;
  }
  if (obj == writeField) {    
    [_currentAttribute setWriteFormat:[writeField stringValue]];
    return;
  }
}

- (IBAction) readOnlyClicked:(id) sender
{
  [_currentAttribute setReadOnly:[sender intValue]];
}

- (IBAction) allowNullClicked:(id) sender
{
  [_currentAttribute setAllowsNull:[sender intValue]];
}

@end

