/**
    DisplayGroupInspector.m

    Author: Matt Rice <ratmice@yahoo.com>
    Date: Sept 2006

    This file is part of GDL2Palette.

    <license>
    GDL2Palette is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    GDL2Palette is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with GDL2Palette; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/
#include "DisplayGroupInspector.h"
#include <EOInterface/EODisplayGroup.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTableView.h>
#include <Foundation/NSArray.h>

@implementation GDL2DisplayGroupInspector 
- (id) init
{
  self = [super init];
  [NSBundle loadNibNamed:@"GDL2DisplayGroupInspector" owner:self];
  _localKeys = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  RELEASE(_localKeys);
  [super dealloc];
}

-(IBAction) setValidatesImmediately:(id)sender;
{
  [(EODisplayGroup *)[self object]
	  setValidatesChangesImmediately:[sender intValue]];
}

-(IBAction) setRefreshesAll:(id)sender;
{
  [(EODisplayGroup *)[self object]
	  setUsesOptimisticRefresh:([sender intValue] ? NO : YES)]; 
}

-(IBAction) setFetchesOnLoad:(id)sender;
{
  [(EODisplayGroup *)[self object]
	  setFetchesOnLoad:[sender intValue]];
}

- (void) revert:(id)sender
{
  if (object == nil)
    return;

  [_fetchesOnLoad setIntValue:[object fetchesOnLoad]];
  [_validate setIntValue:[object validatesChangesImmediately]];
  [_refresh setIntValue:[object usesOptimisticRefresh] ? NO : YES];
  [_localKeys removeAllObjects];
  [_localKeys addObjectsFromArray:[object localKeys]];
  [_localKeysTable reloadData];
}

- (void) addKey:(id)sender
{
  [_localKeys addObject:@""];
  [_localKeysTable reloadData];
  [_localKeysTable selectRow:([_localKeys count] - 1) byExtendingSelection:NO];
}

- (void) removeKey:(id)sender
{
  int selRow = [_localKeysTable selectedRow];
  if (selRow != NSNotFound && selRow > 0 && selRow < [_localKeys count])
    {
      [_localKeys removeObjectAtIndex:[_localKeysTable selectedRow]];
      [_localKeysTable reloadData];
    }
}

- (int) numberOfRowsInTableView:(NSTableView *)tv
{
  return [_localKeys count];
}

- (id) tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc
row:(int)row
{
  return [_localKeys objectAtIndex:row];
}

- (void) tableView:(NSTableView *)tv setObjectValue:(id)newValue forTableColumn:(NSTableColumn *)tc row:(int) row;
{
  [_localKeys replaceObjectAtIndex:row withObject:newValue];
  [object setLocalKeys:_localKeys];
}

@end


