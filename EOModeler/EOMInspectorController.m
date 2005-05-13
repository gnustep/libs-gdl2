/**
  EOMInspectorController.m <title>EOMInspectorController Class</title>
  
  Copyright (C) 2005 Free Software Foundation, Inc.
 
  Author: Matt Rice <ratmice@yahoo.com>
  Date: April 2005
  
  This file is part of the GNUstep Database Library.
  
  <license>
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
  </license>
**/

#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOMInspector.h>
#include <EOModeler/EOMInspectorController.h>
#include <EOModeler/EOModelerEditor.h>

#include <AppKit/NSWindow.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSButtonCell.h>

#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSArray.h>

static EOMInspectorController *_sharedInspectorController;

static NSBox *_placeHolderView;
@interface EOMInspectorController(Private)
- (void) _selectionChanged:(NSNotification *)notif;
@end
@implementation EOMInspectorController

- (id) init
{
  if (_sharedInspectorController)
    [[NSException exceptionWithName: NSInternalInconsistencyException
	    reason: @"EOMInspectorController is a singleton"
	    userInfo:nil] raise];
  self = [super init];
  window = [[NSWindow alloc] initWithContentRect:NSMakeRect(220, 536, 272, 388)
			     styleMask:NSTitledWindowMask | NSClosableWindowMask
			     backing:NSBackingStoreBuffered
			     defer:YES];
  scrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 0, 250, 68)];
  _placeHolderView = [[NSBox alloc] initWithFrame:NSMakeRect(0,68,250,333)];

  [_placeHolderView setBorderType:NSNoBorder];
  _sharedInspectorController = self;
  
  [[NSNotificationCenter defaultCenter]
     addObserver:_sharedInspectorController
     selector:@selector(_selectionChanged:)
     name:EOMSelectionChangedNotification
     object:nil];
    
  [[window contentView] addSubview: scrollView];
  return self;
}

- (void) _showInspector
{
  [window makeKeyAndOrderFront:self];
  [self _selectionChanged:nil];
}

+ (void) showInspector
{
  [[self sharedInstance] _showInspector];
}

+ (EOMInspectorController *)sharedInstance
{
  if (!_sharedInspectorController)
    return [[self alloc] init];
 
  return _sharedInspectorController;
}

- (void) _selectionChanged:(NSNotification *)notif
{
  /* load the highest ordered inspector for the new selection
   * if the current inspector can support the object, select it instead. */
  NSArray *selection = [[EOMApp currentEditor] selectionWithinViewedObject];
  id inspector;

  if ([selection count])
    {
      NSArray *inspectors =  [EOMInspector allInspectorsThatCanInspectObject: [selection objectAtIndex:0]];
      
      if ([inspectors count])
	{
          inspector = [inspectors objectAtIndex:0];
	  [inspector prepareForDisplay];
	  [[window contentView] replaceSubview:[lastInspector view] with:[inspector view]];
	  [inspector refresh];
	  lastInspector = inspector;
	}
      else
	{
	  NSLog(@"no inspector");
	}
    }
  else
    {
      NSLog(@"no selection");
    }
}

- (void) selectInspector:(id)sender
{
  
}

@end
