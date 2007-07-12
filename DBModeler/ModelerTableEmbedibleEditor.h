#ifndef __ModelerTableEmbedibleEditor_H__
#define __ModelerTableEmbedibleEditor_H__

/*
    ModelerTableEmbedibleEditor.h
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: Apr 2005

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

#include <EOModeler/EOModelerEditor.h>
#include <AppKit/NSMenuItem.h>
@class EODisplayGroup;
@class NSPopUpButton;
@class NSTableView;
/* base class for the default embedible editors 
 * mostly takes care of corner views right now..
 */
@interface ModelerTableEmbedibleEditor : EOModelerEmbedibleEditor
- (void) setupCornerView:(NSPopUpButton *)cornerView
		tableView:(NSTableView *)tableView
		displayGroup:(EODisplayGroup *)dg
		forClass:(Class)aClass;

- (void) _cornerAction:(id)sender;
- (NSArray *)defaultColumnNamesForClass:(Class)aClass;
- (void) addDefaultTableColumnsForTableView:(NSTableView *)tv
		displayGroup:(EODisplayGroup *)dg;
- (void) addTableColumnForItem:(NSMenuItem <NSMenuItem>*)item
	  tableView:(NSTableView *)tv;
- (void) removeTableColumnForItem:(NSMenuItem <NSMenuItem>*)menuItem
	  tableView:(NSTableView *)tv;

@end

#endif // __ModelerTableEmbedibleEditor_H__
