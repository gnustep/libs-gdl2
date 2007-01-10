/**
    DiagramView.h

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

#ifndef __DIAGRAM_VIEW_H
#include <AppKit/NSView.h>
@class NSColor;
@class NSMutableDictionary;
@class EOModel;
@class NSArray;
@class NSString;

@interface DiagramView : NSView
{
  EOModel *_model;
  NSMutableDictionary *_shownEntities;
  NSMutableArray *_relationships;
  NSColor *_bgColor;
  NSMutableArray *_subview_order;
}
- (void) setModel:(EOModel *)model;
- (void) showEntity:(NSString *)name;
- (void) setupRelationships;
- (void) orderViewFront:(NSView *)view;
@end

#define __DIAGRAM_VIEW_H
#endif
