/**
    Preferences.m

    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006

    This file is part of DBModeler.

    <license>
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
    </license>
**/


#include "Preferences.h"

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSInvocation.h>
#include <Foundation/NSUserDefaults.h>
#endif

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSMatrix.h>
#endif

#define DisableAttributeDetailsCheck      @"DisableAttributeDetailsCheck"
#define DisableEntityStoredProcedureCheck @"DisableEntityStoredProcedureCheck"
#define DisableExternalNameCheck          @"DisableExternalNameCheck"
#define DisableInheritanceCheck           @"DisableInheritanceCheck"
#define DisablePrimaryKeyCheck            @"DisablePrimaryKeyCheck"
#define DisableRelationshipCheck          @"DisableRelationshipCheck"
#define DisableStoredProcedureCheck       @"DisableStoredProcedureCheck"
static NSString *BundlesToLoad = @"BundlesToLoad";
static NSString *DisableConsistencyCheckOnSave=@"DisableConsistencyCheckOnSave";


static NSUserDefaults *ud;
static DBModelerPrefs *_sharedPrefs;

/* do it this way so i can add the switch title later instead of being
 * hard coded into the .gorm */
static NSString *_switches[][2] = 
{
  {DisableAttributeDetailsCheck, @"Attribute details"},
  {DisableExternalNameCheck, @"External name"},
  {DisablePrimaryKeyCheck, @"Primary key"},
  {DisableRelationshipCheck, @"Relationship"},
  {DisableEntityStoredProcedureCheck, @"Entity stored procedure"},
  {DisableStoredProcedureCheck, @"Stored procedure"},
  {DisableInheritanceCheck, @"Inheritance"}
};

#define FROBKEY(key) [ud boolForKey:key] ? NO : YES
#define COUNT(key) sizeof(key) / sizeof(key[0])

@implementation DBModelerPrefs : NSObject
+ (DBModelerPrefs *) sharedPreferences
{
  if (_sharedPrefs == nil)
    {
      _sharedPrefs = [self new];
    }
  return _sharedPrefs;
}

- (id) init
{
  self = [super init];
  /* setup ud before -awakeFromNib is called... */
  ud = [NSUserDefaults standardUserDefaults];
  _bundles = [[NSMutableArray alloc] init];
  [_bundles addObjectsFromArray:[self bundlesToLoad]];
  [NSBundle loadNibNamed:@"Preferences" owner:self];
  return self;
}

- (void) awakeFromNib
{
  int i, c  = COUNT(_switches);
  
  [check_matrix renewRows:c columns:1];
  
  for (i = 0; i < c; i++)
    {
      NSButtonCell *cell = [check_matrix cellAtRow:i column:0];
      BOOL flag;
      
      flag = [ud boolForKey:_switches[i][0]]; 
      [cell setState: (flag == NO) ? NSOnState : NSOffState];
      [cell setTitle: _switches[i][1]];
    }
  [check_matrix sizeToCells];
  [consistencyCheckOnSave 
	setState:[ud boolForKey:DisableConsistencyCheckOnSave]
		 ? NSOffState
		 : NSOnState];
  [bundlesToLoad reloadData];
}

- (void) showPreferences:(id)sender
{
  [prefsWindow makeKeyAndOrderFront:self]; 
}

- (void) switchButtonChanged:(id)sender
{
  int selRow;

  if ((selRow = [sender selectedRow]) != -1)
    [ud setBool:([[sender selectedCell] state] == NSOffState)
         forKey:_switches[selRow][0]];
}

- (void) checkOnSaveChanged:(id)sender
{
  [ud setBool:([sender state] == NSOffState)
       forKey:DisableConsistencyCheckOnSave];
}

- (NSArray *)bundlesToLoad
{
  return [ud arrayForKey:BundlesToLoad];
}

- (BOOL) consistencyCheckOnSave
{
  return FROBKEY(DisableConsistencyCheckOnSave);
}

- (BOOL) attributeDetailsCheck
{
  return FROBKEY(DisableAttributeDetailsCheck);
}

- (BOOL) entityStoredProcedureCheck
{
  return FROBKEY(DisableEntityStoredProcedureCheck);
}

- (BOOL) externalNameCheck
{
  return FROBKEY(DisableExternalNameCheck);
}

- (BOOL) inheritanceCheck
{
  return FROBKEY(DisableInheritanceCheck);
}

- (BOOL) primaryKeyCheck
{
  return FROBKEY(DisablePrimaryKeyCheck);
}

- (BOOL) relationshipCheck
{
  return FROBKEY(DisableRelationshipCheck);	 
}

- (BOOL) storedProcedureCheck
{
  return FROBKEY(DisableStoredProcedureCheck);
}


- (int) numberOfRowsInTableView:(NSTableView *)tv
{
  int num = [_bundles count];
  return num;
}

- (id) tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)rowIndex
{
  id ov = [_bundles objectAtIndex:rowIndex];
  return ov;
}

- (void) tableView:(NSTableView *)tv
setObjectValue:(id)newVal
forTableColumn:(NSTableColumn *)tc
	   row:(int)rowIndex
{
  [_bundles replaceObjectAtIndex:rowIndex withObject:newVal];
  [ud setObject:_bundles forKey:BundlesToLoad];
}

- (void) addBundle:(id)sender
{
  [_bundles addObject:@""];
  [bundlesToLoad reloadData];
  [bundlesToLoad selectRow:[_bundles count] - 1 byExtendingSelection:NO];
  [bundlesToLoad editColumn:0 row:[_bundles count] - 1 withEvent:nil select:YES];
}
- (void) removeBundle:(id)sender
{
  [_bundles removeObjectAtIndex:[bundlesToLoad selectedRow]];
  [bundlesToLoad reloadData];
  [ud setObject:_bundles forKey:BundlesToLoad];
}

@end
