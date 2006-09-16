/* -*-objc-*-
   EOAttributePriv.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: July 2000

   This file is part of the GNUstep Database Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

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

@interface EOAttribute (EOAttributePrivate)
- (GCMutableArray *)_definitionArray;

- (void)setParent: (id)parent;
- (EOAttribute *)realAttribute;

- (Class)_valueClass;
- (unichar)_valueTypeCharacter;
@end

@interface EOAttribute (EOAttributePrivate2)
- (BOOL)_hasAnyOverrides;
- (void)_resetPrototype;
- (void)_updateFromPrototype;
- (void)_setOverrideForKeyEnum: (int)keyEnum;
- (BOOL)_isKeyEnumOverriden: (int)param0;
- (BOOL)_isKeyEnumDefinedByPrototype: (int)param0;
@end

#endif  /* __EOAttributePriv_h__ */
