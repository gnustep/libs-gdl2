/**
    Foundation+Categories.h 

    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005

    This file is part of GDL2Palette.

    <license>
    GDL2Palette is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    GDL2Palette is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with GDL2Palette; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/
#include <Foundation/NSArray.h>
/* since we don't really have blocks and i don't feel like including them.. */
@interface NSArray (SelectorStuff)
- (NSArray *) arrayWithObjectsRespondingYesToSelector:(SEL)selector;
- (NSArray *) arrayWithObjectsRespondingYesToSelector:(SEL)selector
withObject:(id)argument;
@end

@interface NSObject(GDL2PaletteAdditions)
- (BOOL) isKindOfClasses:(NSArray *)classes;
@end
