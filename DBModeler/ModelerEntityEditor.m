/**
    ModelerEntityEditor.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: 2005, 2006

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
  return flag;
}

- (NSArray *) friendEditorClasses
{
  return [NSArray arrayWithObjects: [ModelerAttributeEditor class], nil];
}

- (void) dealloc
{
  [EOObserverCenter removeObserver:self forObject:[[self document] model]];
  RELEASE(_splitView);
  RELEASE(dg);
  [super dealloc];
}

- (id) initWithParentEditor: (EOModelerCompoundEditor *)parentEditor
{
  if ((self = [super initWithParentEditor:parentEditor]))
    {
      EOClassDescription *classDescription = nil;
      KVDataSource   *wds;
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
      [_topTable setAutoresizesAllColumnsToFit:NO];
      [scrollView setDocumentView:_topTable];
      RELEASE(_topTable);
      [_splitView addSubview:scrollView];
      RELEASE(scrollView);

      scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,10,10)];
      [scrollView setHasHorizontalScroller:YES];
      [scrollView setHasVerticalScroller:YES];
      [scrollView setBorderType: NSBezelBorder];
      [_bottomTable setAutoresizesAllColumnsToFit:NO];
      [scrollView setDocumentView:_bottomTable];
      RELEASE(_bottomTable);
      [_splitView addSubview:scrollView];
      RELEASE(scrollView);

      
      [DefaultColumnProvider class]; // calls +initialize
      
      cornerView = [[NSPopUpButton alloc] initWithFrame:[[_topTable cornerView] bounds] pullsDown:YES];
      [cornerView setPreferredEdge:NSMinYEdge];
      [cornerView setTitle:@"+"];
      [cornerView setBezelStyle:NSShadowlessSquareBezelStyle];
      [[cornerView cell] setBezelStyle:NSShadowlessSquareBezelStyle];
      [[cornerView cell] setArrowPosition:NSPopUpNoArrow];
      //[mi setImage:[NSImage imageNamed:@"plus"]];
     // [mi setOnStateImage:[NSImage imageNamed:@"plus"]];
     // [mi setOffStateImage:[NSImage imageNamed:@"plus"]];
      //[mi setState:NSOnState];
      [[cornerView cell] setUsesItemFromMenu:NO];
      [[cornerView cell] setShowsFirstResponder:NO];
      [[cornerView cell] setShowsStateBy:NSContentsCellMask];
      [[cornerView cell] setMenuItem:mi];
      RELEASE(mi);
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
      RELEASE(wds);
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

  [dg selectObjectsIdenticalTo:[self selectionWithinViewedObject]
	  selectFirstOnNoMatch:NO];
}

- (NSView *)mainView
{
  return _splitView;
}

- (void) objectWillChange:(id)anObject
{
  [[NSRunLoop currentRunLoop]
	  performSelector:@selector(needToFetch:)
	  	   target:self
		 argument:nil
		    order:999 /* this number is probably arbitrary */
		    modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
}

- (void) needToFetch:(id)sth
{
  [dg fetch];
}

@end

@implementation ModelerEntityEditor (DisplayGroupDelegate)
- (void) displayGroupDidChangeSelection:(EODisplayGroup *)displayGroup
{
  [[self parentEditor] setSelectionWithinViewedObject: [displayGroup selectedObjects]];
}

@end

