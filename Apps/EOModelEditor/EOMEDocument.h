/**
 EOMEDocument.h <title>EOMEDocument Class</title>
 
 Copyright (C) Free Software Foundation, Inc.
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of DBModeler.
 
 <license>
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
 </license>
 **/

#ifndef __EOMEDocument_h
#define __EOMEDocument_h

#include <AppKit/AppKit.h>
#include <Renaissance/Renaissance.h>
#include <EOAccess/EOModel.h>
#include <EOModeler/EODefines.h>


GDL2MODELER_EXPORT NSString *EOMCheckConsistencyBeginNotification;
GDL2MODELER_EXPORT NSString *EOMCheckConsistencyEndNotification;
GDL2MODELER_EXPORT NSString *EOMCheckConsistencyForModelNotification;
GDL2MODELER_EXPORT NSString *EOMConsistencyModelObjectKey;

@class TableViewController;

@interface EOMEDocument : GSMarkupDocument
{
  IBOutlet NSOutlineView           * _outlineView;
  IBOutlet NSTableView             * _topTableView;
  IBOutlet NSTableView             * _bottomTableView;
  IBOutlet NSTableView             * _storedProcedureTableView;
  IBOutlet NSPopUpButton           * _topVisibleColumnsPopUp;
  IBOutlet NSPopUpButton           * _bottomVisibleColumnsPopUp;
  IBOutlet NSPopUpButton           * _storedProcVisibleColumnsPopUp;
  IBOutlet NSPopUpButton           * _storedProcDirectionUp;
  IBOutlet NSTabView               * _tabView;
  EOModel                          * _eomodel;
  id                                 _outlineSelection;
  TableViewController              * _topTableViewController;
  TableViewController              * _bottomTableViewController;
  TableViewController              * _procTableViewController;
  NSArray                          * _entityNames;
  NSArray                          * _selectedObjects;
}

- (NSArray *) selectedObjects;
- (id) outlineSelection;
- (EOModel*) eomodel;
- (void) setEomodel:(EOModel*) model;

- (void) setAdaptor:(id)sender;

- (void) startObserving;
- (void) stopObserving;

@end


#endif
