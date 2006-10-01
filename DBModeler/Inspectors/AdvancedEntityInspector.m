/*
    AdvancedEntityInspector.m

    Author: Matt Rice <ratmice@yahoo.com>
    Date: 2005, 2006

    This file is part of DBModeler.

    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
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
#include <AppKit/NSButton.h>
#include <Foundation/NSValue.h>

@implementation AdvancedEntityInspector

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

- (void) refresh
{
  [abstract setState:[(EOEntity *)[self selectedObject] isAbstractEntity] ? NSOnState : NSOffState];
  [readOnly setState:[(EOEntity *)[self selectedObject] isReadOnly] ? NSOnState : NSOffState];
  [cachesObjects setState:[(EOEntity *)[self selectedObject] cachesObjects] ? NSOnState : NSOffState];
}

- (BOOL) canInspectObject:(id)anObject
{
  return [anObject isKindOfClass:[EOEntity class]];
}
@end
