/**
    Foundation+Categories.m

    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006

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

#include "Foundation+Categories.h" 

/* since we don't really have blocks and i don't feel like including them.. */
@implementation NSArray (GDL2PaletteAdditions)

- (NSArray *) arrayWithObjectsRespondingYesToSelector:(SEL)selector;
{
  int i,c = [self count];
  BOOL (*sel_imp)(id, SEL, ...);
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity: c];
  BOOL flag;
  
  for (i = 0; i < c; i++)
    {
      id obj = [self objectAtIndex:i];

      flag = [obj respondsToSelector:selector];

      if (flag)
	{
	  sel_imp = (BOOL (*)(id, SEL, ...))[obj methodForSelector:selector];
	  flag = (*sel_imp)(obj, selector);
	
	  if (flag)
	    [arr addObject:obj];
	}
    }
  return arr;
}

- (NSArray *) arrayWithObjectsRespondingYesToSelector:(SEL)selector
					   withObject:(id)argument;
{
  int i,c = [self count];
  BOOL (*sel_imp)(id, SEL, ...);
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity: c];
  BOOL flag;
  
  for (i = 0; i < c; i++)
    {
      id obj = [self objectAtIndex:i];

      flag = [obj respondsToSelector:selector];

      if (flag)
	{
	  sel_imp = (BOOL (*)(id, SEL, ...))[obj methodForSelector:selector];
	  flag = (*sel_imp)(obj, selector, argument);
	
	  if (flag)
	    [arr addObject:obj];
	}
    }
  return arr;
}

@end

@implementation NSObject(GDL2PaletteAdditions)
- (BOOL) isKindOfClasses:(NSArray *)classes
{
  int i,c;

  for (i = 0, c = [classes count]; i < c; i++)
    {
      if ([self isKindOfClass: [classes objectAtIndex:i]])
	return YES;
    }
  return NO;
}

@end

