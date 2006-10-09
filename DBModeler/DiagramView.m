/**
    DiagramView.m

    Author: Matt Rice <ratmice@yahoo.com>
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


#include "DiagramView.h"
#include "EntityView.h"
#include "AttributeCell.h"
#include <Foundation/NSSet.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSBezierPath.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSDragging.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOModeler/EOModelExtensions.h>

@implementation DiagramView
- (id) initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  _shownEntities = [NSMutableDictionary new];
  _relationships = [NSMutableArray new];
  _subview_order = [NSMutableArray new];
  _bgColor = RETAIN([NSColor colorWithCalibratedRed:0.881437 green:0.941223 blue:1.0 alpha:1.0]);
  [self registerForDraggedTypes:[NSArray arrayWithObject:NSColorPboardType]];
  return self;
}

- (void) dealloc
{
  RELEASE(_shownEntities);
  RELEASE(_relationships);
  RELEASE(_subview_order);
  RELEASE(_bgColor);
  [super dealloc];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{
  return YES;
}
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
  return [sender draggingSourceOperationMask];
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
  NSPasteboard *pb = [sender draggingPasteboard];
  NSColor *color = [NSColor colorFromPasteboard:pb];

  ASSIGN(_bgColor, color);
  [self setNeedsDisplay:YES];
  return YES;
}

- (BOOL) isFlipped
{
  return YES;
}

- (void) setModel:(EOModel *)model
{
  ASSIGN(_model, model);
}

- (void) showEntity:(NSString *)name
{
  EntityView *ev;

  if (!(ev = [_shownEntities objectForKey:name]))
    {
      EOEntity *entity = [_model entityNamed:name];
      NSArray *attribs = [entity attributes];
      NSRect vis = [[self enclosingScrollView] documentVisibleRect];
      NSRect evFrame;
      NSPoint toPoint;
      int i, c = [attribs count];
   
      ev = [[EntityView alloc] initWithFrame:NSMakeRect(0,0,1,1)];
      [ev setTitle:[entity name]];
      [ev setNumberOfAttributes:c];

      for (i = 0; i < c; i++)
        {
          EOAttribute *attrib = [attribs objectAtIndex:i];
          AttributeCell *cell = [ev cellAtRow:i];

          [cell setStringValue:[attrib name]];
          [cell setLock:[[entity attributesUsedForLocking] containsObject:attrib]];
          [cell setProp:[[entity classProperties] containsObject:attrib]];
          [cell setKey:[[entity primaryKeyAttributes] containsObject:attrib]];
        }
 
      [ev sizeToFit];
      evFrame = [ev frame];
  
      /* this "layout mechanism" is pure evil... */
      toPoint.x = vis.origin.x  + ((vis.size.width - evFrame.size.width) * rand()/(RAND_MAX + vis.origin.x));
      toPoint.y = vis.origin.y + ((vis.size.height - evFrame.size.height) * rand()/(RAND_MAX + vis.origin.y));
      
      [ev setFrameOrigin:toPoint];
      [_shownEntities setObject:ev forKey:[entity name]];
  
      [self addSubview:ev];
      [_subview_order addObject:ev];
      [self setupRelationships];
    }
  else
    {
      EOEntity *entity = [_model entityNamed:name];
      NSArray *attribs = [entity attributes];
      int i, c = [attribs count];

      [ev setTitle:[entity name]];
      [ev setNumberOfAttributes:c];
      
      for (i = 0; i < c; i++)
        {
          EOAttribute *attrib = [attribs objectAtIndex:i];
          AttributeCell *cell = [ev cellAtRow:i];

          [cell setStringValue:[attrib name]];
          [cell setLock:[[entity attributesUsedForLocking] containsObject:attrib]];
          [cell setProp:[[entity classProperties] containsObject:attrib]];
          [cell setKey:[[entity primaryKeyAttributes] containsObject:attrib]];
        }
      [ev sizeToFit];
      [ev setNeedsDisplay:YES];
     
    }
}

int sortSubviews(id view1, id view2, void *context)
{
  DiagramView *self = context;
  unsigned idx1, idx2;

  idx1 = [self->_subview_order indexOfObject:view1];
  idx2 = [self->_subview_order indexOfObject:view2];
  
  return (idx1 < idx2) ? NSOrderedDescending : NSOrderedAscending;
}

- (void) orderViewFront:(NSView *)v
{
  int idx = [_subview_order indexOfObject:v];
  RETAIN(v);
  [_subview_order removeObjectAtIndex:idx];
  [_subview_order insertObject:v atIndex:0];
  RELEASE(v);
  [self sortSubviewsUsingFunction:(int (*)(id, id, void *))sortSubviews context:self];
  [self setNeedsDisplay:YES];
}

- (void) setupRelationships
{
  int i,c;
  NSArray *stuff = [_shownEntities allKeys];
  [_relationships removeAllObjects];
  for (i = 0, c = [stuff count]; i < c; i++)
     {
       int j, d;
       NSString *entName = [stuff objectAtIndex:i];
       EOEntity *ent = [_model entityNamed:entName];
       NSArray *rels = [ent relationships];
       
       for (j = 0, d = [rels count]; j < d; j++)
         {
	   EORelationship *rel = [rels objectAtIndex:j];
	   EOEntity *dest = [rel destinationEntity];
	   id srcName = [ent name];
	   id destName = [dest name]; 
	   EntityView *from = [_shownEntities objectForKey:srcName];
	   EntityView *to = [_shownEntities objectForKey:destName];
	   NSArray *srcAttribs = [rel sourceAttributes]; 
	   NSArray *destAttribs = [rel destinationAttributes]; 
	   int k, e;
	   for (k = 0, e = [srcAttribs count]; k < e; k++)
	     {
	       id sAttrib = [srcAttribs objectAtIndex:k];
	       id dAttrib = [destAttribs objectAtIndex:k];
	       int sIdx = [[ent attributes] indexOfObject:sAttrib];
	       int dIdx = [[dest attributes] indexOfObject:dAttrib];
	       NSRect fromRect = [from attributeRectAtRow:sIdx];
	       NSRect toRect = [to attributeRectAtRow:dIdx];
	       NSRect fromViewFrame = [from frame];
	       NSRect toViewFrame = [to frame];
	       NSPoint midPoint;
	       NSPoint tmp; 
	       float arrowOffset; 
 	       NSBezierPath *path = [NSBezierPath bezierPath];
	       BOOL fromRight;
	       BOOL toRight;

	       [path setLineWidth:2];

	       fromRect.origin.y += fromViewFrame.origin.y; 
	       toRect.origin.y += toViewFrame.origin.y; 
	      
	       /* which side of the EntityView the arrow line will be connecting
		* to, for the source and destination entities */
	       fromRight = (fromViewFrame.origin.x - 40 < toViewFrame.origin.x + toViewFrame.size.width);
	       toRight = (toViewFrame.origin.x - 40 < fromViewFrame.origin.x + fromViewFrame.size.width);
	       
	       if (fromRight)
	         {
		   fromRect.origin.x = fromViewFrame.origin.x + fromViewFrame.size.width + 5;
	         }
	       else
	         {
	           fromRect.origin.x = fromViewFrame.origin.x - 5;
	         }
	       
	       if (toRight)
		 {
		   toRect.origin.x = toViewFrame.origin.x + toViewFrame.size.width;
	           toRect.origin.x += 5;
		   /* <- */
		   arrowOffset = -5.0;
		 }
	       else
	         {
		   toRect.origin.x = toViewFrame.origin.x;
	           toRect.origin.x -= 5;
		   /* -> */
		   arrowOffset = 5.0;
		 }

	       fromRect.origin.y = NSMidY(fromRect);
	       toRect.origin.y = NSMidY(toRect);
	       
	       /* every line segment is drawn forwards and backwards so we dont
		* end up with lightning bolts when filling the arrow */

	       /* a recursive relationship... 
		* Don't think they are particularly useful but... */
	       if (fromRect.origin.y == toRect.origin.y
		   && fromRect.origin.x == toRect.origin.x)
	         {  
		   [path moveToPoint:NSMakePoint(toRect.origin.x + 15, toRect.origin.y)];
		   [path lineToPoint:NSMakePoint(toRect.origin.x + 15, toRect.origin.y + 5)];
		   [path lineToPoint:NSMakePoint(toRect.origin.x + 15, toRect.origin.y)];

		   [path moveToPoint:NSMakePoint(toRect.origin.x + 15, toRect.origin.y + 5)];
		   [path lineToPoint:NSMakePoint(toRect.origin.x + 20, toRect.origin.y + 5)];
		   [path lineToPoint:NSMakePoint(toRect.origin.x + 15, toRect.origin.y + 5)];
		   
		   [path moveToPoint:NSMakePoint(toRect.origin.x + 20, toRect.origin.y + 5)];
		   [path lineToPoint:NSMakePoint(toRect.origin.x + 20, toRect.origin.y)];
		   [path lineToPoint:NSMakePoint(toRect.origin.x + 20, toRect.origin.y + 5)];
	         }
	       
	       if ((fromRight || toRight) && !(fromRight && toRight))
	         {
		   /* a line like...   +-----
		    *                  |   
		    *             -----+ 
		    *  (from the right side, to the left side or vice versa)
		    */           
	           [path moveToPoint:fromRect.origin];
	       
	           midPoint.x = (fromRect.origin.x + toRect.origin.x) / 2;
	           midPoint.y = fromRect.origin.y;
	           [path lineToPoint:midPoint];
	       
	           [path lineToPoint:fromRect.origin];
 	           [path moveToPoint:midPoint]; 
	           tmp = midPoint;
	           midPoint.x = (fromRect.origin.x + toRect.origin.x) / 2;
	           midPoint.y = toRect.origin.y;
	           [path lineToPoint:midPoint];
	           [path lineToPoint:tmp];

	           [path moveToPoint:midPoint];
	           [path lineToPoint:toRect.origin];
	           [path lineToPoint:midPoint];
		 }
	       else if (fromRight && toRight)
	         {
	           /*  need to       --+   or -------+ <- joint end or start.
	 	    * make a line      |             |
		    * like...   -------+           --+ <- joint start or end.
		    * from the right side to the right side.
		    */
			 
		   NSPoint jointStart;
		   NSPoint jointEnd;
		   
		   if (toRect.origin.x + toRect.size.width < fromRect.origin.x + fromRect.size.width)
		     {
		       jointStart = NSMakePoint(fromRect.origin.x + 20, fromRect.origin.y);
		       jointEnd = NSMakePoint(fromRect.origin.x + 20, toRect.origin.y);
		     }
		   else
		     {
		       jointStart = NSMakePoint(toRect.origin.x + 20, fromRect.origin.y);
		       jointEnd = NSMakePoint(toRect.origin.x + 20, toRect.origin.y);
		     } 
		   [path moveToPoint:fromRect.origin];
		   [path lineToPoint:jointStart];
		   [path lineToPoint:fromRect.origin];
		   
		   [path moveToPoint:jointStart];
		   [path lineToPoint:jointEnd];
		   [path lineToPoint:jointStart];
		   
		   [path moveToPoint:jointEnd]; 
		   [path lineToPoint:toRect.origin];
		   [path lineToPoint:jointEnd];
	         }

	       /* draw arrows.. */ 
	       if ([rel isToMany]) 
	         {
	           [path moveToPoint:toRect.origin]; 
	           [path lineToPoint:NSMakePoint(toRect.origin.x - arrowOffset, toRect.origin.y + arrowOffset)];
	           [path lineToPoint:NSMakePoint(toRect.origin.x - arrowOffset, toRect.origin.y - arrowOffset)]; 
	           [path lineToPoint:toRect.origin]; 
		   toRect.origin.x -= arrowOffset;
	           [path moveToPoint:toRect.origin]; 
	           [path lineToPoint:NSMakePoint(toRect.origin.x - arrowOffset, toRect.origin.y + arrowOffset)];
	           [path lineToPoint:NSMakePoint(toRect.origin.x - arrowOffset, toRect.origin.y - arrowOffset)]; 
	           [path lineToPoint:toRect.origin]; 
	         }
	       else
	         {
	           [path moveToPoint:toRect.origin]; 
	           [path lineToPoint:NSMakePoint(toRect.origin.x - arrowOffset, toRect.origin.y + arrowOffset)];
	           [path lineToPoint:NSMakePoint(toRect.origin.x - arrowOffset, toRect.origin.y - arrowOffset)]; 
	           [path lineToPoint:toRect.origin]; 
	         }

	       [path closePath];
	       [_relationships addObject:path];
	     }

         }
     }
}

- (void) mouseDown:(NSEvent *)ev
{
  /* create new relationshp??*/
}

- (BOOL) autoscroll:(NSEvent *)ev
{
  NSPoint pt = [self convertPoint:[ev locationInWindow] fromView:nil];
  NSRect r = _frame;
  BOOL flag;

  if (!NSPointInRect(pt, r))
    {
      if (pt.x > r.size.width)
        r.size.width = pt.x; 
      if (pt.y > r.size.height)
        r.size.height = pt.y;
      [self setFrameSize:r.size];
    }
  flag = [super autoscroll:ev];
  return flag;
}

- (void) drawRect:(NSRect)aRect
{
  int i, c;
  [_bgColor set];
  NSRectFill([self frame]);
  [self setupRelationships];
  
  for (i = 0, c = [_relationships count]; i < c; i++)
    {
      [[NSColor blackColor] set];
      NSBezierPath *path = [_relationships objectAtIndex:i];
      [path stroke];
      [path fill];
    }
}

@end
