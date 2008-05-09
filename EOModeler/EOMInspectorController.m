/**
  EOMInspectorController.m <title>EOMInspectorController Class</title>
  
  Copyright (C) 2005 Free Software Foundation, Inc.
 
  Author: Matt Rice <ratmice@gmail.com>
  Date: April 2005
  
  This file is part of the GNUstep Database Library.
  
  <license>
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 3 of the License, or (at your option) any later version.
 
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

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSBox.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSView.h>
#endif

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSArray.h>
#endif

static EOMInspectorController *_sharedInspectorController;

static NSMatrix *_iconBar;

@interface EOMInspectorController(Private)
- (void) _selectionChanged:(NSNotification *)notif;
@end

@implementation EOMInspectorController

- (id) init
{
  NSButtonCell *iconCell;
  NSSize scrollSize;

  if (_sharedInspectorController)
    [[NSException exceptionWithName: NSInternalInconsistencyException
	    reason: @"EOMInspectorController is a singleton"
	    userInfo:nil] raise];
  self = [super init];
  scrollSize = [NSScrollView frameSizeForContentSize:NSMakeSize(256, 64)
	  			hasHorizontalScroller:YES
				hasVerticalScroller:NO
				borderType:NSNoBorder];
  window = [[NSPanel alloc] initWithContentRect:NSMakeRect(220, 536, 272, 388+scrollSize.height)
			     styleMask:NSTitledWindowMask | NSClosableWindowMask
			     backing:NSBackingStoreBuffered
			     defer:YES];
  [window setReleasedWhenClosed:NO];
  
  scrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(0, 388, 272, scrollSize.height)];
  scrollSize = [NSScrollView contentSizeForFrameSize:NSMakeSize(256,64)
	  			hasHorizontalScroller:YES
				hasVerticalScroller:NO
				borderType:NSNoBorder];
  
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setHasVerticalScroller:NO];
  _iconBar = [[NSMatrix alloc] initWithFrame:NSMakeRect(0, 0, 272, scrollSize.height)];
  [_iconBar setAutosizesCells:NO];
  [_iconBar setCellSize:NSMakeSize(64,64)];
  [_iconBar setTarget:self];
  [_iconBar setAction:@selector(_selectInspector:)];
  iconCell = [[NSButtonCell alloc] initTextCell:@""];
  [iconCell setButtonType:NSMomentaryPushInButton]; 
  [iconCell setImagePosition:NSImageOnly];
  [_iconBar setPrototype:iconCell];
  [scrollView setDocumentView: _iconBar];
  
  [[window contentView] addSubview: scrollView];
  
  _sharedInspectorController = self;
  
  [[NSNotificationCenter defaultCenter]
     addObserver:_sharedInspectorController
     selector:@selector(_selectionChanged:)
     name:EOMSelectionChangedNotification
     object:nil];
    
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
  NSArray *swvop = [[EOMApp currentEditor] selectionWithinViewedObject];
  id inspector;
  

  if ([swvop count])
    {
      /* inspectors is ordered in the lowest -displayOrder first. */
      id selection = [swvop objectAtIndex:0];
      NSArray *inspectors;
      int i, c;

      inspectors = [EOMInspector allInspectorsThatCanInspectObject: selection];
      c = [inspectors count];
      [_iconBar renewRows:1 columns:c];
      [_iconBar setNeedsDisplay:YES];

      if (c)
	{
	  for (i = 0; i < c; i++)
	    {
	      NSCell *aCell = [_iconBar cellAtRow:0 column:i];
	      inspector = [inspectors objectAtIndex:i];
	      
	      [aCell setImage:[inspector image]];
	      [aCell setRepresentedObject:inspector];
	    }
	  
	  [_iconBar setNeedsDisplay:YES];
          
	  /* if the current inspector can support the object,
	     select it instead.  Otherwise select the first inspector.
	   */
	  if ([inspectors containsObject:lastInspector])
	    {
	      inspector = lastInspector;
	      [inspector prepareForDisplay];
	    }
	  else
	    {
              inspector = [inspectors objectAtIndex:0];
	      [inspector prepareForDisplay];
	  
	      if ([lastInspector view] && lastInspector != inspector)
	        [[window contentView] removeSubview:[lastInspector view]];

	      if ([inspector view] && lastInspector != inspector)
	        [[window contentView] addSubview:[inspector view]];

	      [window setTitle:[inspector displayName]];
	    }
	  
	  [[inspector view] setNeedsDisplay:YES];
	  [inspector refresh];
	  lastInspector = inspector;
	}
      else
	{
	  [[lastInspector view] removeFromSuperview];
	  lastInspector = nil;
	  NSLog(@"no inspector");
	}
    }
  else
    {
      [[lastInspector view] removeFromSuperview];
      lastInspector = nil;
      NSLog(@"no selection");
    }
}

- (void) _selectInspector:(id)sender
{
  EOMInspector *inspector = [[sender selectedCell] representedObject];

  [inspector prepareForDisplay];
  
  if ([lastInspector view] && lastInspector != inspector)
    [[window contentView] removeSubview:[lastInspector view]];

  if ([inspector view] && lastInspector != inspector)
    [[window contentView] addSubview:[inspector view]];
	  
  [[inspector view] setNeedsDisplay:YES];
  [inspector refresh];
    
  lastInspector = inspector;
}

@end
