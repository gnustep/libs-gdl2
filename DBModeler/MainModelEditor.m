/**
    MainModelEditor.m
 
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

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSNotification.h>
#endif

#include "MainModelEditor.h"
#include "ModelerEntityEditor.h"

#include <EOModeler/EOModelerApp.h>

#include <EOModeler/EOModelerDocument.h>
#include <EOModeler/EOModelerEditor.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>

#include <EOControl/EOObserver.h>
#include <EOControl/EOEditingContext.h>

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSPanel.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSOutlineView.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindowController.h>
#endif

#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSVersionMacros.h>

#define DEBUG_STUFF 0 

@interface ModelerOutlineView : NSOutlineView
@end
@implementation ModelerOutlineView

- (NSImage *) dragImageForRows:(NSArray *)dragRows
                event: (NSEvent *)dragEvent
                dragImageOffset: (NSPoint *)dragImageOffset
{
  id foo = [self itemAtRow:[[dragRows objectAtIndex:0] intValue]];
  NSImage *img = nil;

  if ([foo isKindOfClass: [EOEntity class]]
      || [foo isKindOfClass:[EORelationship class]])
    {
      img = [NSImage imageNamed:@"ModelDrag"];
      [img setScalesWhenResized:NO];
    }
  return img;
}


- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)flag
{
  return NSDragOperationAll;
}

@end
@implementation MainModelEditor 
- (id) initWithDocument:(EOModelerDocument *)document
{
  if ((self = [super initWithDocument:document]))
    {
      NSTableColumn *_col;
      NSScrollView *sv = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,400)];
      
      _vSplit = [[NSSplitView alloc] initWithFrame:NSMakeRect(0,0,600,400)];

      [_vSplit setVertical:YES];

      _iconPath = [[ModelerOutlineView alloc] initWithFrame:NSMakeRect(0,0,100,400)];
      [_iconPath setIndentationPerLevel:8.0];
      [_iconPath setIndentationMarkerFollowsCell:YES];
      
      [_iconPath setDelegate:self];
      [_iconPath setDataSource:self];
      _col = [(NSTableColumn *)[NSTableColumn alloc] initWithIdentifier:@"name"];
      [_iconPath addTableColumn:_col];
      [_iconPath setOutlineTableColumn:AUTORELEASE(_col)];

#if OS_API_VERSION(GS_API_NONE, MAC_OS_X_VERSION_10_4)
      [_iconPath setAutoresizesAllColumnsToFit:YES];
#else
      [_iconPath setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
#endif

      [_iconPath sizeToFit];
      
      _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(20,80,600,400)
                                            styleMask: NSTitledWindowMask | NSMiniaturizableWindowMask | NSClosableWindowMask | NSResizableWindowMask
                                              backing:NSBackingStoreBuffered
                                                defer:YES];
      [_window setTitle:[[document model] name]];
      [_window setReleasedWhenClosed:NO];
      
      [sv setHasHorizontalScroller:YES];
      [sv setHasVerticalScroller:YES];
      [sv setAutoresizingMask: NSViewWidthSizable];
      [_iconPath setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [sv setDocumentView:_iconPath];
      RELEASE(_iconPath);
      [_vSplit addSubview:sv];
      RELEASE(sv);
      
      _editorView = [[NSBox alloc] initWithFrame:NSMakeRect(0,0,500,400)];
      
      [_vSplit addSubview: _editorView];
      RELEASE(_editorView); 
      
      [_vSplit setAutoresizesSubviews:YES];
      [_vSplit setAutoresizingMask: NSViewWidthSizable
                                         | NSViewHeightSizable];
      [_vSplit adjustSubviews];
      [[_window contentView] addSubview:_vSplit];
      RELEASE(_vSplit);
      
      /* so addEntity: addAttribute: ... menu items work, 
       * and it gets close notifications */
      [_window setDelegate: document];

      [[NSNotificationCenter defaultCenter] addObserver: self
                         selector:@selector(ecStuff:)
                             name: EOObjectsChangedInEditingContextNotification
                           object: [[self document] editingContext]];
      
      [self setViewedObjectPath:[NSArray arrayWithObject:[document model]]]; 
    }
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(_window);
  [super dealloc];
}

- (void) ecStuff:(NSNotification *)notif
{
  if ([[notif object] isKindOfClass:[EOEditingContext class]])
    {
      [_iconPath reloadData];
    }
}

- (void)activateEmbeddedEditor:(EOModelerEmbedibleEditor *)editor
{
  NSView *mainView = [editor mainView];
  [mainView setFrame: [_editorView frame]];
  [_vSplit replaceSubview:_editorView with:mainView];
  _editorView = mainView;
  [_editorView setNeedsDisplay:YES];
  [super activateEmbeddedEditor:editor];
}

- (void)activateEditorWithClass:(Class)embedibleEditorClass
{
  [super activateEditorWithClass:embedibleEditorClass];
  [self activateEmbeddedEditor:
          [self embedibleEditorOfClass:embedibleEditorClass]];
  [_iconPath reloadData];
}

- (void) activate
{
  if (![_window isVisible] || ![_window isKeyWindow])
    {
      [_window makeKeyAndOrderFront:self];
      [self activateEmbeddedEditor:
                [self embedibleEditorOfClass:
                                NSClassFromString(@"ModelerEntityEditor")]];

    }
  [_iconPath reloadData];
  [super activate];
}

- (void) viewSelectedObject
{
  [self _activateSelection];
  [super viewSelectedObject];
}

- (void) _activateSelection 
{
  id selection;
  if ([[self selectionWithinViewedObject] count] == 0)
    return;
          
  selection = [[self selectionWithinViewedObject] objectAtIndex:0];
#if DEBUG_STUFF == 1 
  GSPrintf(stderr, @"viewing %@(%@)\n", NSStringFromClass([selection class]), [(EOModel *)selection name]);
#endif
  if ([[self activeEditor] canSupportCurrentSelection])
    [self activateEmbeddedEditor: [self activeEditor]];
  else
    {
      NSArray *friends = [[self activeEditor] friendEditorClasses];
      int editorsCount;
      int i,j,c;
      
      /* first look for instances of our friend classes that can support the
         current selection */
      for (i = 0, c = [friends count]; i < c; i++)
        {
          for (j = 0,editorsCount = [_editors count]; j < editorsCount; j++)
            {
              id friendEditor = [_editors objectAtIndex:j];
              id friendClass = [friends objectAtIndex:i];
                
              if ([friendEditor isKindOfClass: friendClass])
                {
                  if ([friendEditor canSupportCurrentSelection])
                    {
                      [self activateEmbeddedEditor:friendEditor];
                      return;
                    }
                }
            }
        }
      /* instantiate friends to see if we can support the current selection */ 
      for (i = 0,c = [friends count]; i < c; i++)
         {
           id friendClass = [friends objectAtIndex:i];
           id friend = [[friendClass alloc] initWithParentEditor:self];
           if ([friend canSupportCurrentSelection])
             {
               [self activateEmbeddedEditor:friend];
               RELEASE(friend);
               return;
             }
           RELEASE(friend);
         }
      /* look for any old editor this isn't very nice...
       * because it only works with registered editors, and we can only
       * register instances of editors, so a) can't load on demand non-friend 
       * editors, or b) we should register instances of all editors */
      for (i = 0, c = [_editors count]; i < c; i++)
        {
          id anEditor = [_editors objectAtIndex:i];
          
          if ([anEditor canSupportCurrentSelection])
            {
              [self activateEmbeddedEditor:anEditor];
              return;
            }
        }
      
    } 
}

/* NSOutlineView datasource stuff */
- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (id)item
{
  BOOL ret = NO;

  if (item == nil)
    ret = ([[[_document model] entities] count] > 0);
  else if ([item isKindOfClass:[EOModel class]])
    ret = ([[item entities] count] > 0); 
  else if ([item isKindOfClass:[EOEntity class]])
    ret = ([[item relationships] count] > 0); 
  else if ([item isKindOfClass:[EORelationship class]])
    ret = 0;
#if DEBUG_STUFF == 1  
  NSLog(@"%@\n\t %@ %i", NSStringFromSelector(_cmd), [item class], ret); 
#endif
  return ret;
}

- (int)        outlineView: (NSOutlineView *)outlineView
    numberOfChildrenOfItem: (id)item
{
  int ret = 0;

  if (item == nil)
    ret = 1;
  else if ([item isKindOfClass: [EOModel class]])
    ret = [[item entities] count];
  else if ([item isKindOfClass: [EOEntity class]])
    ret = [[item relationships] count];
  else if ([item isKindOfClass: [EORelationship class]])
    ret = 0;
  
#if DEBUG_STUFF == 1  
  NSLog(@"%@\n\t %i %@", NSStringFromSelector(_cmd), ret, [item class]);
#endif
  
  return ret;
}

- (id)outlineView: (NSOutlineView *)outlineView
            child: (int)index
           ofItem: (id)item
{
  id ret = @"blah.";

  if (item == nil)
    ret = [_document model];
  else if ([item isKindOfClass: [EOModel class]])
    ret = [[item entities] objectAtIndex:index];
  else if ([item isKindOfClass: [EOEntity class]])
    ret = [[item relationships] objectAtIndex:index];
  else if ([item isKindOfClass: [EORelationship class]])
    ret = nil;
#if DEBUG_STUFF == 1  
  NSLog(@"%@\n\tchild %@ atIndex: %i ofItem %@", NSStringFromSelector(_cmd), [ret class], index, [item class]);
#endif
  return ret;
}

- (id)         outlineView: (NSOutlineView *)outlineView
 objectValueForTableColumn: (NSTableColumn *)tableColumn
                    byItem: (id)item
{
  id ret;
  if (item == nil)
    ret = [[_document model] name];
  else 
    ret = [item valueForKey:@"name"]; 
#if DEBUG_STUFF == 1  
  NSLog(@"objectValue: %@", ret);
#endif
  return ret;
}

- (void) outlineViewSelectionDidChange:(NSNotification *)notif
{
  NSMutableArray *foo = [[NSMutableArray alloc] init];
  EOModel *bar = [_document model];
  id item = nil;
  int selectedRow = [_iconPath selectedRow];
  
  if (selectedRow == -1)
    return;
  while (bar != item)
    {
      if (item == nil)
        {
          
          item = [_iconPath itemAtRow:selectedRow];
          [foo insertObject:[NSArray arrayWithObject:item] atIndex:0];
        }
      else if ([item isKindOfClass:[EOEntity class]])
        {
          item = [item model];
          [foo insertObject:item atIndex:0];
        }
      else if ([item isKindOfClass:[EORelationship class]])
        {
          item = [item entity];
          [foo insertObject:item atIndex:0];
        }
    }
#if DEBUG_STUFF == 1 
  {
    int i,c;
    NSArray *selpath = [self selectionPath];
    NSLog(@"current selection path"); 
    for (i = 0, c = [selpath count]; i < c; i++)
      {
        id obj = [selpath objectAtIndex:i];
                
        if ([obj isKindOfClass:[NSArray class]])
          {
            int j,d;
            for (j = 0, d = [obj count]; j < d; j++)
              {
                GSPrintf(stderr, @"* %@(%@)\n", [[obj objectAtIndex:j] class], [(EOModel *)[obj objectAtIndex:j] name]);
              }
          }
        else
          GSPrintf(stderr, @"%@(%@)\n", [obj class], [(EOModel *)obj name]);  
      }
    NSLog(@"changing to");
    selpath = foo;
    for (i = 0, c = [selpath count]; i < c; i++)
      {
        id obj = [selpath objectAtIndex:i];

        if ([obj isKindOfClass:[NSArray class]])
          {
            int j,d;
            for (j = 0, d = [obj count]; j < d; j++)
              {
                GSPrintf(stderr, @"* %@(%@)\n", [[obj objectAtIndex:j] class], [(EOModel *)[obj objectAtIndex:j] name]);
              }
          }
        else
          GSPrintf(stderr, @"%@(%@)\n", [obj class], [(EOModel *)obj name]);
      }
  }
#endif
  [self setSelectionPath:AUTORELEASE(foo)];
  [self _activateSelection];
}

- (BOOL) outlineView:(NSOutlineView *)view
writeItems:(NSArray *)rows
toPasteboard:(NSPasteboard *)pboard
{
  NSMutableArray *foo = [[NSMutableArray alloc] init];
  EOModel *bar = [_document model];
  int selectedRow = [_iconPath selectedRow];
  id item = [_iconPath itemAtRow:selectedRow];
   
  if (selectedRow == -1)
    return NO;
  while (item != nil)
    {
      if (item == bar)
        {
          NSString *modelPath = [item valueForKey:@"path"];
          if (modelPath == nil)
            {
              NSRunAlertPanel(@"Error", @"Must save before dragging", @"OK",@"Cancel",nil);
              return NO;
            }
          [foo insertObject:modelPath atIndex:0];
          item = nil;
        }
      else if ([item isKindOfClass:[EOEntity class]])
        {
          [foo insertObject:[item valueForKey:@"name"] atIndex:0];
          item = [item model];
        }
      else if ([item isKindOfClass:[EORelationship class]])
        {
          [foo insertObject:[item valueForKey:@"name"] atIndex:0];
          item = [item entity];
        }
    }  
  [pboard declareTypes: [NSArray arrayWithObject: EOMPropertyPboardType] owner:nil];
  [pboard setPropertyList:foo forType:EOMPropertyPboardType]; 
  return YES;
}

#if 0
- (void) outlineView: (NSOutlineView *)outlineView
willDisplayCell:(NSCell *)cell
forTableColumn:(NSTableColumn *)tc
item:(id)item
{
  //if (![[tc identifier] isEqual:@"name"])
//          return; 
  if ([item isKindOfClass:[EOModel class]])
    [cell setImage: [NSImage imageNamed:@"Model_small.tiff"]];
  if ([item isKindOfClass:[EOEntity class]])
    [cell setImage: [NSImage imageNamed:@"Entity_small.tiff"]];
  if ([item isKindOfClass:[EORelationship class]])
    [cell setImage: [NSImage imageNamed:@"Relationship_small.tiff"]];
}
#endif 
@end
