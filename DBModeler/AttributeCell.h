/**
    AttributeCell.h

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

#ifndef __ATTRIBUTE_CELL_H

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSCell.h>
#include <AppKit/NSTextFieldCell.h>
#endif

@class NSImageCell;

@interface TitleCell : NSTextFieldCell
@end

@interface AttributeCell : NSCell
{
  NSTextFieldCell *name;
  NSSize sz;
  BOOL isKey, isLock, isProp;
  NSImageCell *key;
  NSImageCell *lock;
  NSImageCell *prop;

}

- (void) setLock:(BOOL)flag;
- (void) setKey:(BOOL)flag;
- (void) setProp:(BOOL)flag;
@end


#define __ATTRIBUTE_CELL_H
#endif
