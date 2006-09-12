/**
    KeyWrapper.m

    Author: Matt Rice <ratmice@yahoo.com>
    Date: Mar 2006

    This file is part of GDL2Palette.

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
    along with GDL2Palette; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/

#include "KeyWrapper.h"
#include <Foundation/NSString.h>
@implementation KeyWrapper 
+ (id) wrapperWithKey:(NSString *)key type:(KeyType)type;
{
  return AUTORELEASE([[self allocWithZone:NSDefaultMallocZone()]
		  initWithKey:key
		  	 type:type]);
}

- (id) initWithKey:(NSString *)key type:(KeyType)type;
{
  if (!(self = [super init]))
    return self;

  ASSIGN(_key, key);
  _type = type;
  return self;
}

- (void) setKeyType:(KeyType)type
{
  _type = type;
}

- (KeyType) keyType 
{
  return _type;
}

- (NSString *) key;
{
  return _key;
}

- (BOOL) isEqual:(id)obj
{
  return [_key isEqual:[obj key]]; 
}

- (void) setKey:(NSString *)key;
{
  ASSIGN(_key, key);
}

- (id) copyWithZone:(NSZone *)zone
{
  return [[[self class] allocWithZone:zone] initWithKey:_key type:_type];
}

@end
