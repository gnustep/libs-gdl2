#ifndef __EOModelerApp_H__
#define __EOModelerApp_H__

/* -*-objc-*-
   EOModelerApp.h

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@yahoo.com>
   Date: Apr 2005

   This file is part of the GNUstep Database Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include <AppKit/NSApplication.h>
#include <EOModeler/EODefines.h>

@class EOModelerApp;
@class EOModelerEditor;
@class EOModelerDocument;
@class NSMutableArray;
@class NSMutableDictionary;
@class EODisplayGroup;
@class NSTableColumn;
GDL2MODELER_EXPORT NSString *EOMSelectionChangedNotification;
GDL2MODELER_EXPORT EOModelerApp *EOMApp;
GDL2MODELER_EXPORT NSString *EOMPropertyPboardType;
@protocol EOMColumnProvider
- (void) initColumn:(NSTableColumn *)tableColumn
  class:(Class)objectClass
  name:(NSString *)columnName
  displayGroup:(EODisplayGroup *)dg
  document:(EOModelerDocument *)document;
@end

@interface EOModelerApp : NSApplication
{
  NSMutableArray *_documents;
  NSMutableDictionary *_columnsByClass;
  EOModelerEditor *_currentEditor;
}
- (EOModelerDocument *)activeDocument;
- (EOModelerEditor *)currentEditor;
- (void)setCurrentEditor:(EOModelerEditor *)editor;
- (NSArray *)documents;
- (void) addDocument:(EOModelerDocument *)document;
- (NSArray *)columnNamesForClass:(Class)aClass;
- (id <EOMColumnProvider>) providerForName:(NSString *)name class:(Class)objectClass;
- (void) registerColumnName:(NSString *)columnNames forClass:(Class)objectClass
provider:(id <EOMColumnProvider>)provider;
- (void) registerColumnNames:(NSArray *)columnNames forClass:(Class)objectClass
provider:(id <EOMColumnProvider>)provider;

@end

#endif // __EOModelerApp_H__
