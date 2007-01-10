/**
    EntityView.m

    Author: Matt Rice <ratmice@gmail.com>
    Date: Oct 2006

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

#include "EntityView.h"
#include "DiagramView.h"
#include "AttributeCell.h"
#include "NSView+Additions.h"
#include <AppKit/NSApplication.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSScrollView.h>



@interface AttributeMatrix : NSMatrix
@end

@implementation AttributeMatrix : NSMatrix
- (void) mouseDown:(NSEvent *)ev
{
  [self orderViewFront:self];
  [super mouseDown:ev];
}
@end

@interface AttributeBox : NSBox

@end

@implementation AttributeBox : NSBox
- (void) drawRect:(NSRect)aRect
{
  [[NSColor blackColor] set];
  NSFrameRect(aRect);
}
@end

@implementation EntityView
- (NSString *) description
{
  return [NSString stringWithFormat:@"<%@ %p %@>", [self class], self, [_title stringValue]];
}
- (BOOL) isFlipped
{
  return YES;
}

- (void) setTitle:(NSString *)title
{
  [_title setStringValue:title];
}

- (AttributeCell *)cellAtRow:(int)row
{
  return [_attributesView cellAtRow:row column:0];
}

- (void) setNumberOfAttributes:(int)num
{
  [_attributesView renewRows:num columns:1];

}

- (void) sizeToFit
{
  NSSize s;
  NSRect r; 
  [_attributesView sizeToCells];
  [_attributesView sizeToFit];
  [_box sizeToFit];
  
  _titleRect.size = [_title cellSize];
  r = [_box bounds];
  s.height = _titleRect.size.height + r.size.height + 4;
  s.width = ((_titleRect.size.width > r.size.width) ? _titleRect.size.width : r.size.width) + 4;
  
  [_box setFrameOrigin:NSMakePoint(2, _titleRect.size.height + 2)];
  [self setFrameSize:s];
  [self setNeedsDisplay:YES];
}

- (void) dealloc
{
  RELEASE(_title); 
  [super dealloc];
}

- (id) initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  
  _title = [[TitleCell alloc] init];
  [_title setFont: [NSFont boldSystemFontOfSize:0]]; 
  [_title setEditable:NO];
  [_title setSelectable:NO];
  [_title setAlignment:NSLeftTextAlignment]; 
  _titleRect = NSMakeRect(2,2, 0, 0);
  
  _box = [[AttributeBox alloc] initWithFrame:NSMakeRect(2,2,0,0)];
  [_box setContentViewMargins:NSMakeSize(0,0)];
  [_box setBorderType:NSBezelBorder];
  [_box setTitlePosition:NSNoTitle];
  
  _attributesView = [[AttributeMatrix alloc] initWithFrame:NSMakeRect(1,1,1,1)];
  [_attributesView setBackgroundColor:[NSColor whiteColor]];
  [_attributesView setPrototype:[[AttributeCell alloc] init]];
  [_attributesView setAutosizesCells:YES];
  
  [[_box contentView] addSubview:_attributesView];
  RELEASE(_attributesView);
  [_box sizeToFit];
  
  [self addSubview:_box];  
  RELEASE(_box); 
  return self;
}

- (void) drawRect:(NSRect)dRect
{
  [[NSColor lightGrayColor] set];
  NSRectFill([self bounds]);

  [_title drawWithFrame:_titleRect inView:self];
  [[NSColor controlShadowColor] set];
  NSFrameRect(_bounds);

  [_attributesView setNeedsDisplay:YES];
}

- (void) orderViewFront:(NSView *)v
{
  [(DiagramView *)[self superview] orderViewFront:self];
}

- (void) mouseDown:(NSEvent *)ev
{
  NSPoint pt = [self convertPoint:[ev locationInWindow] fromView:nil];
  // allow clicking on title to move it..
  if (NSMouseInRect(pt, NSMakeRect(0, 0, _frame.size.width, _titleRect.size.height), YES))
    {
      DiagramView *dv = [self superview];      
      float in, up;
      pt = [dv convertPoint:pt fromView:self];
      up = pt.y - _frame.origin.y ;
      in = pt.x - _frame.origin.x;

      [dv orderViewFront:self];

      while ((ev = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:nil inMode:NSEventTrackingRunLoopMode dequeue:YES]))
	{
	  float tox, toy;
	  if ([ev type] == NSLeftMouseUp) break;
          NSPoint pt2 = [dv convertPoint:[ev locationInWindow] fromView:nil];
	  tox = pt2.x - in;
	  toy = pt2.y - up;
	  /* contrain to a positive x,y. */ 
	  // at 1.0 we can get some libart artifacts for some reason.. 
  	  pt2.x = tox > 1.0 ? tox : 1.1;
	  pt2.y = toy > 1.0 ? toy : 1.1; 
	  [self setFrameOrigin:pt2];
	  [self autoscroll:ev];
	  [dv setNeedsDisplay:YES];
	  [self setNeedsDisplay:YES];
	}
    }
}

- (NSRect) attributeRectAtRow:(int)row
{
  NSRect cellFrame = [_attributesView cellFrameAtRow:row column:0];
  cellFrame.origin.y += _titleRect.origin.y + _titleRect.size.height;
  return cellFrame;
}
@end

