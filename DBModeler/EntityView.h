/**
    EntityView.h

    Author: Matt Rice <ratmice@gmail.com>
    Date: Oct 2006

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

#ifndef _ENTITY_VIEW_H

#include <AppKit/NSView.h>
#include <EOAccess/EOEntity.h>
#include "AttributeCell.h"

@class NSTextFieldCell;
@class NSMatrix;
@class NSBox;

@interface EntityView : NSView
{
  NSTextFieldCell *_title;
  NSRect _titleRect;

  NSMatrix *_attributesView;

  NSBox *_box;
  NSRect _attribRect;
}

- (void) sizeToFit;
- (void) setNumberOfAttributes:(int)num;
- (void) setTitle:(NSString *)name;
- (AttributeCell *)cellAtRow:(int)row;
- (NSRect) attributeRectAtRow:(int)row;
- (void) orderViewFront:(NSView *)view;
@end

#define _ENTITY_VIEW_H
#endif
