#ifndef __EOModelerEditor_H__
#define __EOModelerEditor_H__

/* -*-objc-*-
   EOModelerEditor.h

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

#include <Foundation/NSObject.h>

@class EOModelerDocument;
@class EOModelerEmbedibleEditor;
@class NSView;
@class NSMutableArray;

@interface EOModelerEditor : NSObject
{
  EOModelerDocument *_document;
  NSMutableArray *_editors;
  EOModelerEmbedibleEditor *_activeEditor;
  NSArray *_viewedObjectPath;
  NSArray *_selectionWithinViewedObject;
  BOOL _storedProceduresSelected;
}
- (id) initWithDocument:(EOModelerDocument *)document;
- (EOModelerDocument *)document;
- (void) setSelectionWithinViewedObject:(NSArray *)selectionWithin;
- (id) selectionWithinViewedObject; 
- (void) setSelectionPath:(NSArray *)selectionPath;
- (NSArray *)selectionPath;
- (void) setViewedObjectPath:(NSArray *)viewedObjectPath;
- (NSArray *)viewedObjectPath;
@end

@interface EOModelerCompoundEditor : EOModelerEditor
- (void) viewSelectedObject;
- (void) registerEmbedibleEditor:(EOModelerEmbedibleEditor *)embedibleEditor;
- (void) activateEmbeddedEditor:(EOModelerEmbedibleEditor *)embedibleEditor;
- (void) activateEditorWithClass:(Class)editorClass;
- (void) activate;
- (EOModelerEmbedibleEditor *) activeEditor;
- (EOModelerEmbedibleEditor *) embedibleEditorOfClass:(Class)eeClass;
@end


@interface EOModelerEmbedibleEditor : EOModelerEditor
{
  EOModelerCompoundEditor *_parentEditor;
}
- (id)initWithParentEditor:(EOModelerCompoundEditor *)parentEditor;
- (NSView *)mainView;
- (BOOL) canSupportCurrentSelection;
- (NSArray *)friendEditorClasses;
@end

#endif // __EOModelerEditor_H__

