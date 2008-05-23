/**
    AttributeCell.m

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

#include "AttributeCell.h"

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSGraphics.h>
#endif

#include <GNUstepBase/GNUstep.h>

@implementation TitleCell
- (void) setShowsFirstResponder:(BOOL)flag
{
}
@end

/* this should probably be done in seperate matrices */
@implementation AttributeCell

- (id) copyWithZone:(NSZone *)zone
{
  AttributeCell *cell = [super copyWithZone:zone];

  cell->name = [name copyWithZone:zone];
  cell->prop = [prop copyWithZone:zone];
  cell->lock = [lock copyWithZone:zone];
  cell->key = [key copyWithZone:zone];
  return cell;
}

- (void) dealloc
{
  RELEASE(name);
  RELEASE(key);
  RELEASE(lock);
  RELEASE(prop);
  [super dealloc];
}

- (id) init
{
  self = [super init]; 
  
  name = [[TitleCell alloc] init];
  [name setEditable:NO];
  [name setSelectable:NO];
  [name setAlignment:NSLeftTextAlignment]; 
  key = [[NSImageCell alloc] init];
  lock = [[NSImageCell alloc] init];
  prop = [[NSImageCell alloc] init];

  [key setImage:[NSImage imageNamed:@"Key_Diagram"]];
  [lock setImage:[NSImage imageNamed:@"Locking_Diagram"]];
  [prop setImage:[NSImage imageNamed:@"ClassProperty_Diagram"]];
  return self;
}

- (void) setStringValue:(NSString *)str
{
  [name setStringValue:str];
}

- (id) stringValue:(NSString *)str
{
  return [name stringValue];
}

- (void) setKey:(BOOL)flag
{
  
  if (flag)
    {
      isKey = flag;
    }
}

- (void) setLock:(BOOL)flag
{
  if (flag)
    {
      isLock = flag;
    }
}

- (void) setProp:(BOOL)flag
{
  if (flag)
    {
      isProp = flag;
    }
}

- (NSSize) cellSize
{
  sz = [name cellSize];
  sz.width += 60;  
  return sz;
}

- (void) drawWithFrame:(NSRect)frame inView:(NSView *)view
{
  [name drawWithFrame:NSMakeRect(frame.origin.x, frame.origin.y, sz.width, sz.height) inView:view];
  
  if (isKey)
    [key drawWithFrame:NSMakeRect(frame.size.width - 18, frame.origin.y + 2, 11, 6) inView:view];
  
  if (isLock)
    [lock drawWithFrame:NSMakeRect(frame.size.width - 36, frame.origin.y + 2, 10, 11) inView:view];

  if (isProp)
    [prop drawWithFrame:NSMakeRect(frame.size.width - 54, frame.origin.y + 2, 9, 8) inView:view];
 
  if ([self showsFirstResponder])
    {
      NSFrameRect(frame);
    }
}
@end
