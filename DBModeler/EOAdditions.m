/**
    EOAdditions.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Apr 2005

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
  return [NSNumber numberWithBool: [[[self entity] classProperties] containsObject:self]];
}

static inline void setIsClassProperty(id self, NSNumber *flag)
{
  BOOL isProp = [flag boolValue];
  NSArray *props = RETAIN([[self entity] classProperties]);

  if (isProp)
    {
      if (![props containsObject:self])
        [[self entity] setClassProperties: [props arrayByAddingObject:self]];
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
  RELEASE(props);
}

@implementation EOAttribute (ModelerAdditions)

- (NSNumber *) isPrimaryKey
{
  return [NSNumber numberWithBool: [[[self entity] primaryKeyAttributes] containsObject:self]];
}

- (void) setIsPrimaryKey:(NSNumber *)flag
{
  BOOL isKey = [flag boolValue];
  NSArray *pka = RETAIN([[self entity] primaryKeyAttributes]);

  if (isKey)
    {
      if (![pka containsObject:self])
        [[self entity] setPrimaryKeyAttributes: [pka arrayByAddingObject:self]];
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
  RELEASE(pka);
}

- (NSNumber *) isClassProperty
{
  return isClassProperty(self);
}

- (void) setIsClassProperty:(NSNumber *)flag
{
  return setIsClassProperty(self, flag);
}

- (NSNumber *) isUsedForLocking
{
  return [NSNumber numberWithBool:NO];
  /* FIXME */
}

- (void) setIsUsedForLocking:(NSNumber *)flag
{
  /* FIXME */
}
@end


@implementation EORelationship (ModelerAdditions)
- (NSNumber *) isClassProperty
{
  return isClassProperty(self);
}

- (void) setIsClassProperty:(NSNumber *)flag
{
  return setIsClassProperty(self, flag);
}
@end
