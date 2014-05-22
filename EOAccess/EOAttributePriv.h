/* -*-objc-*-
   EOAttributePriv.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: July 2000

   This file is part of the GNUstep Database Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef __EOAttributePriv_h__
#define __EOAttributePriv_h__

typedef enum _EOAttributeProtoOverrideBits
{
  EOAttributeProtoOverrideBits_externalType	= 0,
  EOAttributeProtoOverrideBits_columnName 		= 1,
  EOAttributeProtoOverrideBits_readOnly 		= 2,
  EOAttributeProtoOverrideBits_valueClassName 	= 3,
  EOAttributeProtoOverrideBits_valueType		= 4,
  EOAttributeProtoOverrideBits_width		= 5,
  EOAttributeProtoOverrideBits_precision		= 6,
  EOAttributeProtoOverrideBits_scale		= 7,
  EOAttributeProtoOverrideBits_writeFormat		= 8,
  EOAttributeProtoOverrideBits_readFormat		= 9,
  EOAttributeProtoOverrideBits_userInfo		= 10,
  EOAttributeProtoOverrideBits_serverTimeZone	= 11,
  EOAttributeProtoOverrideBits_valueFactoryMethodName		= 12,
  EOAttributeProtoOverrideBits_adaptorValueConversionMethodName	= 13,
  EOAttributeProtoOverrideBits_factoryMethodArgumentType		= 14,
  EOAttributeProtoOverrideBits_allowsNull		= 15,
  EOAttributeProtoOverrideBits_parameterDirection	= 16,
  EOAttributeProtoOverrideBits_internalInfo	= 17,
  EOAttributeProtoOverrideBits__count
} EOAttributeProtoOverrideBits;

@interface EOAttribute (EOAttributePrivate)
-(EOExpressionArray*)_objectForPList:(NSDictionary*)pList;
- (EOExpressionArray *)_definitionArray;

- (EOAttribute *)realAttribute;

- (Class)_valueClass;
- (unichar)_valueTypeCharacter;
- (void)_setDefinitionWithoutFlushingCaches: (NSString *)definition;
- (EOModel*)_parentModel;
- (void)_removeFromEntityArray:(NSArray*)entityArray
		      selector:(SEL)setSelector;
- (void)_setValuesFromTargetAttribute;
-(void)_setSourceToDestinationKeyMap:(NSDictionary*)map;
-(NSDictionary*) _sourceToDestinationKeyMap;

-(BOOL)_isNonUpdateable;
-(BOOL)_isPrimaryKeyClassProperty;
@end

@interface EOAttribute (EOAttributePrivate2)
- (BOOL)_hasAnyOverrides;
- (void)_resetPrototype;
- (void)_updateFromPrototype;
- (void)_setOverrideForKeyEnum: (EOAttributeProtoOverrideBits)keyEnum;
- (BOOL)_isKeyEnumOverriden: (EOAttributeProtoOverrideBits)keyEnum;
- (BOOL)_isKeyEnumDefinedByPrototype: (EOAttributeProtoOverrideBits)keyEnum;
@end

#endif  /* __EOAttributePriv_h__ */
