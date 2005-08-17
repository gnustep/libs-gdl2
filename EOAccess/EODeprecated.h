/* -*-objc-*-
 EODeprecated.h

 Copyright (C) 2002,2003,2004,2005 Free Software Foundation, Inc.

 Author: Stephane Corthesy <stephane@sente.ch>
 Date: Feb 2003

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

#ifndef __EOAccess_EODeprecated_h__
#define __EOAccess_EODeprecated_h__

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOModelGroup.h>

@interface EOLoginPanel (Deprecated)
/**
 * Use runPanelForAdaptor:validate:allowsCreation: instead.
 */
- (NSDictionary *)runPanelForAdaptor: (EOAdaptor *)adaptor validate: (BOOL)yn;

@end

#endif 
