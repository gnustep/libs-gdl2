/**
    ModelerEntityEditor.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Apr 2005

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


#include "DefaultColumnProvider.h"
#include "ModelerAttributeEditor.h"
#include "ModelerEntityEditor.h"
#include "KVDataSource.h"

#include <EOInterface/EODisplayGroup.h>
#include <EOAccess/EOEntity.h>
#include <EOControl/EOObserver.h>
#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerDocument.h>

#include <AppKit/NSImage.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>

@interface EOModelerDocument (asdf)
-(void)_setDisplayGroup:(id)displayGroup;
@end

@interface ModelerEntityEditor (Private)
- (void) _loadColumnsForClass:(Class) aClass;
@end

@implementation ModelerEntityEditor

- (BOOL) canSupportCurrentSelection
{
  id selection = [self selectionWithinViewedObject];
  BOOL flag;

  if ([selection count] == 0)
    {
      flag = NO;
      return flag;
    }
  selection = [selection objectAtIndex:0]; 
  flag = [selection isKindOfClass:[EOModel class]];
  //NSLog(@"%@ %@ %i", [self class], NSStringFromSelector(_cmd), flag);
  return flag;
}

- (NSArray *) friendEditorClasses
{
  return [NSArray arrayWithObjects: [ModelerAttributeEditor class], nil];
}

- (id) initWithParentEditor: (EOModelerCompoundEditor *)parentEditor
{
  if (self = [super initWithParentEditor:parentEditor])
    {
      id columnProvider;
      NSTableColumn *tc;
      EOClassDescription *classDescription = nil;
      KVDataSource   *wds;
      NSArray *columnNames;
      int i;
      Class editorClass = [EOEntity class];
      NSScrollView *scrollView;
      NSPopUpButton *cornerView;
      NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:@"+" action:(SEL)nil keyEquivalent:@""];

      _splitView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0,0,10,10)];
      scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,10,10)];
      [scrollView setHasHorizontalScroller:YES];
      [scrollView setHasVerticalScroller:YES];
      [scrollView setBorderType: NSBezelBorder];

      _topTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0,0,10,10)];
      _bottomTable = [[NSTableView alloc] initWithFrame:NSMakeRect(0,0,10,10)];
      [_topTable setAutoresizesAllColumnsToFit:YES];
      [scrollView setDocumentView:_topTable];
      [_splitView addSubview:scrollView];

      scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,10,10)];
      [scrollView setHasHorizontalScroller:YES];
      [scrollView setHasVerticalScroller:YES];
      [scrollView setBorderType: NSBezelBorder];
      [_bottomTable setAutoresizesAllColumnsToFit:YES];
      [scrollView setDocumentView:_bottomTable];
      [_splitView addSubview:scrollView];
      
      [DefaultColumnProvider class]; // calls +initialize
      
      cornerView = [[NSPopUpButton alloc] initWithFrame:[[_topTable cornerView] bounds] pullsDown:YES];
      [cornerView setPreferredEdge:NSMinYEdge];
      [cornerView setTitle:@"+"];
      [[cornerView cell] setArrowPosition:NSPopUpNoArrow];
      //[mi setImage:[NSImage imageNamed:@"plus"]];
     // [mi setOnStateImage:[NSImage imageNamed:@"plus"]];
     // [mi setOffStateImage:[NSImage imageNamed:@"plus"]];
      //[mi setState:NSOnState];
      [[cornerView cell] setUsesItemFromMenu:NO];
      [[cornerView cell] setShowsFirstResponder:NO];
      [[cornerView cell] setShowsStateBy:NSContentsCellMask];
      [[cornerView cell] setMenuItem:mi];
      [[cornerView cell] setImagePosition:NSNoImage];
      
      [_topTable setCornerView:cornerView];
      RELEASE(cornerView);
      [_topTable setAllowsMultipleSelection:YES];  
      
      classDescription = nil; 
      wds = [[KVDataSource alloc]
	      initWithClassDescription:classDescription 
  			editingContext:[[self document] editingContext]];
  
      [wds setDataObject: [[self document] model]];
      [wds setKey:@"entities"];
      dg = [[EODisplayGroup alloc] init];
      [EOObserverCenter addObserver:self forObject:[[self document] model]];
      [dg setDataSource: wds];
      [dg setFetchesOnLoad:YES];
      [dg setDelegate: self]; 
  
      [self setupCornerView:cornerView
	  tableView:_topTable
	  displayGroup:dg
	  forClass:[EOEntity class]];
  
      [self addDefaultTableColumnsForTableView:_topTable
	  		displayGroup:dg];

      
    }
  return self;
}
- (NSArray *)defaultColumnNamesForClass:(Class)aClass
{
  NSArray *colNames = [super defaultColumnNamesForClass:aClass];
  if (colNames == nil || [colNames count] == 0)
    {
      if (aClass == [EOEntity class])
        return DefaultEntityColumns;
      else return nil;
    }

  return colNames;
}

- (void) activate
{
  [dg fetch];
}

- (NSView *)mainView
{
  return _splitView;
}

- (void) objectWillChange:(id)anObject
{
  [[NSRunLoop currentRunLoop] performSelector:@selector(needToFetch:) target:self argument:nil order:999 modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void) needToFetch:(id)sth
{
  [dg fetch];
  [_topTable reloadData];
}
@end

@implementation ModelerEntityEditor (DisplayGroupDelegate)
- (void) displayGroupDidChangeSelection:(EODisplayGroup *)displayGroup
{
  //NSLog(@"didChangeSelection %@ %@",dg,[dg selectedObjects]);
  [self setSelectionWithinViewedObject: [displayGroup selectedObjects]];
}

@end

