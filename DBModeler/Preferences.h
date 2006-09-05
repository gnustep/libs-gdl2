/**
    Preferences.h 

    Author: Matt Rice <ratmice@yahoo.com>
    Date: Mar 2006

    This file is part of DBModeler.

    <license>
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
    </license>
**/

#include <Foundation/NSObject.h>
#include <AppKit/NSNibDeclarations.h>

@class NSWindow;
@class NSButton;
@class NSTableView;
@class NSMatrix;
@class NSMutableArray;

@interface DBModelerPrefs : NSObject
{
  IBOutlet NSWindow *prefsWindow;
  IBOutlet NSButton *consistencyCheckOnSave;
  IBOutlet NSTableView *bundlesToLoad;
  /* consistency checks */
  IBOutlet NSMatrix *check_matrix;
  NSMutableArray *_bundles;
}

+ (DBModelerPrefs *) sharedPreferences;

- (void) showPreferences:(id)sender;

- (BOOL) consistencyCheckOnSave;
- (BOOL) attributeDetailsCheck;
- (BOOL) storedProcedureCheck;
- (BOOL) relationshipCheck;
- (BOOL) primaryKeyCheck;
- (BOOL) inheritanceCheck;
- (BOOL) externalNameCheck;
- (BOOL) entityStoredProcedureCheck;
- (NSArray *)bundlesToLoad;

- (IBAction) switchButtonChanged:(id)sender;
- (IBAction) checkOnSaveChanged:(id)sender;
- (IBAction) addBundle:(id)sender;
- (IBAction) removeBundle:(id)sender;
@end
