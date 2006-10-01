#ifndef __EOMInspector_H__
#define __EOMInspector_H__

/* -*-objc-*-
   EOMInspector.h

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

#include <AppKit/NSNibDeclarations.h>
#include <Foundation/NSObject.h>

@class NSArray;
@class NSWindow;
@class NSView;
@class NSImage;

@interface EOMInspector : NSObject
{
  IBOutlet NSImage	*image;
  IBOutlet NSView	*view;
  IBOutlet NSWindow	*window;
}
+ (NSArray *)allRegisteredInspectors;
+ (NSArray *)allInspectorsThatCanInspectObject:(id)anObject; 
+ (EOMInspector *) sharedInspector;

- (NSView *)view;
- (BOOL) canInspectObject:(id)anObject;
- (void) prepareForDisplay;
- (void) refresh;
- (id) selectedObject;

- (NSString *)displayName;
- (float) displayOrder;
- (NSImage *)image;
- (NSImage *)hilightedImage;
@end

#endif // __EOMInspector_H__
