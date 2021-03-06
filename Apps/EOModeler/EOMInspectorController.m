/**
 EOMInspectorController.m <title>EOMInspectorController Class</title>
 
 Copyright (C) 2005 Free Software Foundation, Inc.
 
 Author: Matt Rice <ratmice@gmail.com>
 Date: April 2005
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
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

#include <EOModeler/EOMInspector.h>
#include <EOModeler/EOMInspectorController.h>

#include <AppKit/AppKit.h>

#include <Foundation/Foundation.h>

static EOMInspectorController *_sharedInspectorController;

static NSMatrix *_iconBar;

@interface EOMInspectorController(Private)
- (void) selectionChanged:(NSNotification *)notif;
@end

NSString *EOMSelectionChangedNotification = @"EOModelerSelectionChanged";

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
  
  [scrollView setHasHorizontalScroller:YES];
  [scrollView setHasVerticalScroller:NO]; 
  _iconBar = [[NSMatrix alloc] initWithFrame:NSMakeRect(0, 0, 272, 64)];
  [_iconBar setMode:NSRadioModeMatrix];
  [_iconBar setAllowsEmptySelection:NO];
  [_iconBar setAutosizesCells:NO];
  [_iconBar setCellSize:NSMakeSize(64,64)];
  [_iconBar setTarget:self];
  [_iconBar setAction:@selector(selectInspector:)];
  iconCell = [[NSButtonCell alloc] initTextCell:@""];
//  [iconCell setButtonType:NSMomentaryPushInButton]; 
  [iconCell setButtonType:NSOnOffButton]; 
  [iconCell setImagePosition:NSImageOnly];
  [_iconBar setPrototype:iconCell];
  [scrollView setDocumentView: _iconBar];
  
  [[window contentView] addSubview: scrollView];
  
  _sharedInspectorController = self;
  
  [[NSNotificationCenter defaultCenter]
   addObserver:_sharedInspectorController
   selector:@selector(selectionChanged:)
   name:EOMSelectionChangedNotification
   object:nil];
  
  return self;
}

- (void) _showInspector
{
  [window makeKeyAndOrderFront:self];
  [self selectionChanged:nil];
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

- (void) _selectInspector:(EOMInspector*)inspector
{  
  [inspector prepareForDisplay];
  
  if ([lastInspector view] && lastInspector != inspector)
    [[lastInspector view] removeFromSuperviewWithoutNeedingDisplay];
  
  if ([inspector view] && lastInspector != inspector) {
    //    NSRect bounds = [[inspector view] bounds];
    
    [[window contentView] addSubview:[inspector view]
                          positioned:NSWindowBelow
                          relativeTo:scrollView];
    [[inspector view] setFrameOrigin:NSMakePoint(0,0)];
    [[inspector view] setNeedsDisplay:YES];
    [[window contentView] setNeedsDisplay:YES];
    
    [window setTitle:[inspector displayName]];
    
    //    NSLog(@"%@ view size: %f x %f origin:  %f x %f", NSStringFromClass([inspector class]),
    //          bounds.size.width, bounds.size.height,
    //          bounds.origin.x, bounds.origin.y);
  }
  
  [[inspector view] setNeedsDisplay:YES];
  [inspector refresh];
  
  lastInspector = inspector;
}


- (void) selectionChanged:(NSNotification *)notif
{
  
  id currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
  
  NSArray *swvop = [currentDocument selectedObjects];
  id inspector;
  
  
  if ([swvop count])
  {
    /* inspectors is ordered in the lowest -displayOrder first. */
    id selection = [swvop objectAtIndex:0];
    NSArray *inspectors;
    NSUInteger i, c;
    
    inspectors = [EOMInspector allInspectorsThatCanInspectObject: selection];
    c = [inspectors count];
    [_iconBar renewRows:1 columns:c];
    [_iconBar sizeToCells];
    [_iconBar setNeedsDisplay:YES];

    if (c)
    {
      for (i = 0; i < c; i++)
	    {
	      NSCell *aCell = [_iconBar cellAtRow:0 column:i];
	      inspector = [inspectors objectAtIndex:i];
	      
	      [aCell setImage:[inspector image]];
	      [aCell setRepresentedObject:inspector];
//        [aCell setState:NSOffState];
	    }
      
      [_iconBar setNeedsDisplay:YES];
      
      /* if the current inspector can support the object,
	     select it instead.  Otherwise select the first inspector.
       */
      if ([inspectors containsObject:lastInspector])
	    {
	      inspector = lastInspector;
	    }
      else
	    {
        inspector = [inspectors objectAtIndex:0];
	    }
      
      [self _selectInspector:inspector];
    }
    else
    {
      [[lastInspector view] removeFromSuperview];
      lastInspector = nil;
      NSLog(@"no inspector for selection.");
    }
  }
  else
  {
    [[lastInspector view] removeFromSuperview];
    lastInspector = nil;
    NSLog(@"no selection");
  }
}

- (void) selectInspector:(id)sender
{
  EOMInspector *inspector = [[sender selectedCell] representedObject];
  
  [self _selectInspector:inspector];
  
}

@end
