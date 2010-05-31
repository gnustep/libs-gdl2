
/*
 RelationshipInspector.h
 
 Author: Matt Rice <ratmice@gmail.com>
 Date: Apr 2005
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010

 This file is part of EOModelEditor.
 
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
 */

#include <EOModeler/EOMInspector.h>

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/AppKit.h>
#endif

@class EOModel;
@class EOEntity;
@class EORelationship;

@interface RelationshipInspector : EOMInspector
{
  IBOutlet NSTextField          *name_textField;
  IBOutlet NSPopUpButton        *model_popup;
  IBOutlet NSMatrix             *joinCardinality_matrix;
  IBOutlet NSPopUpButton        *joinSemantic_popup;
  IBOutlet NSBrowser            *destinationEntityBrowser;
  IBOutlet NSBrowser            *sourceBrowser;
  IBOutlet NSBrowser            *destBrowser;
  IBOutlet NSButton             *connectButton;
  NSArray                       *_attributes;
  NSImage                       *_dimpleImg;
  NSImage                       *_noDimpleImg;
  EORelationship                *_currentRelation;
}

- (IBAction) connectButtonClicked:(id)sender;
- (IBAction) nameChanged:(id)sender;
@end

