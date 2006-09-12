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

#include <Foundation/NSObject.h>
@class NSString;
typedef enum KeyType
{
  AttributeType		 	= 1,
  ToOneRelationshipType		= 2,
  ToManyRelationshipType 	= 4,
  OtherType			= 8
}KeyType;

@interface KeyWrapper: NSObject
{
  NSString *_key;
  KeyType _type;
}
+ (id) wrapperWithKey:(NSString *)key type:(KeyType)type;
- (id) initWithKey:(NSString *)key type:(KeyType)type;
- (void) setKey:(NSString *)key;
- (NSString *) key;
- (void) setKeyType:(KeyType)type;
- (KeyType) keyType;
@end

