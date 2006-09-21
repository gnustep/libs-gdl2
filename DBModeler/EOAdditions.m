/**
    EOAdditions.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: 2005, 2006

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

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>

#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>

/* this is all stuff for key value coding.. */
static inline NSNumber * isClassProperty(id self)
{
  return [NSNumber numberWithBool:
	  	[[[self entity] classProperties] containsObject:self]];
}

static inline void setIsClassProperty(id self, NSNumber *flag)
{
  BOOL isProp = [flag boolValue];
  NSArray *props = [[self entity] classProperties];

  if (isProp)
    {
      if (!props)
        {
	  if (![[self entity] setClassProperties: [NSArray arrayWithObject:self]])
	    NSLog(@"invalid class property");
	}
      else if (![props containsObject:self])
        {
	  [[self entity] setClassProperties: [props arrayByAddingObject:self]];
	}
    }
  else
    {
      if ([props containsObject:self])
	{
	  NSMutableArray *newProps = [NSMutableArray arrayWithArray:props];
	  [newProps removeObject: self];
	  [[self entity] setClassProperties: newProps];
	}
    }
}

@implementation EOAttribute (ModelerAdditions)

- (NSNumber *) isPrimaryKey
{
  BOOL flag = [[[self entity] primaryKeyAttributes] containsObject:self];
  return [NSNumber numberWithBool: flag];
}

- (void) setIsPrimaryKey:(NSNumber *)flag
{
  BOOL isKey = [flag boolValue];
  NSArray *pka = [[self entity] primaryKeyAttributes];

  if (isKey)
    {
	if (!pka)
	  {
	    [[self entity]
		setPrimaryKeyAttributes: [NSArray arrayWithObject:self]];
	  }
	else if (![pka containsObject:self])
          {
	    [[self entity]
		setPrimaryKeyAttributes: [pka arrayByAddingObject:self]];
	  }
    }
  else
    {
      if ([pka containsObject:self])
	{
	  NSMutableArray *newPks = [NSMutableArray arrayWithArray:pka];
	  [newPks removeObject: self];
	  [[self entity] setPrimaryKeyAttributes: newPks];
	  
	}
    }
}

- (NSNumber *) isClassProperty
{
  id flag = isClassProperty(self);
  
  return flag;
}

- (void) setIsClassProperty:(NSNumber *)flag
{
  setIsClassProperty(self, flag);
}

- (NSNumber *) isUsedForLocking
{
  BOOL flag;
  
  flag = [[[self entity] attributesUsedForLocking] containsObject:self];
  
  return [NSNumber numberWithBool:flag];
}

- (void) setIsUsedForLocking:(NSNumber *)flag
{
  BOOL yn = [flag boolValue];
  NSArray *la = RETAIN([[self entity] attributesUsedForLocking]);

  if (yn)
    {

      if (la == nil)
	{
	  [[self entity]
		setAttributesUsedForLocking:[NSArray arrayWithObject:self]];
	}
      else if (![la containsObject:self])
        {
	  [[self entity]
		setAttributesUsedForLocking:[la arrayByAddingObject:self]];
	}
    }
  else
    {
      if ([la containsObject:self])
	{
	   NSMutableArray *newLA = [NSMutableArray arrayWithArray:la];
	   [newLA removeObject:self];
	   [[self entity] setAttributesUsedForLocking:newLA];
	}
    }
}

- (NSNumber *)allowNull
{
  BOOL flag = [self allowsNull]; 
  return [NSNumber numberWithBool:flag];
}

- (void) setAllowNull:(NSNumber *)flag
{
  [self setAllowsNull:[flag boolValue]];
}

@end


@implementation EORelationship (ModelerAdditions)
- (NSNumber *) isClassProperty
{
  id flag = isClassProperty(self);
  return flag;
}

- (void) setIsClassProperty:(NSNumber *)flag
{
  setIsClassProperty(self, flag);
}

@end

