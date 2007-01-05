/**
    DisplayGroupInspector.h

    Author: Matt Rice <ratmice@gmail.com>
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
#include <InterfaceBuilder/IBInspector.h>
#include <AppKit/NSNibDeclarations.h>

@class NSButton;
@class NSTableView;
@class NSMutableArray;

@interface GDL2DisplayGroupInspector : IBInspector
{
  IBOutlet NSButton	*_fetchesOnLoad;
  IBOutlet NSButton	*_refresh;
  IBOutlet NSButton	*_validate;
 
  IBOutlet NSTableView	*_localKeysTable;
  IBOutlet NSButton	*_addKey;
  IBOutlet NSButton	*_removeKey;
  
  NSMutableArray *_localKeys;
}
-(IBAction) setValidatesImmediately:(id)sender;
-(IBAction) setRefreshesAll:(id)sender;
-(IBAction) setFetchesOnLoad:(id)sender;
@end

