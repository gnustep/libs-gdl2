/* -*-objc-*-
   EOUndoManager.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#ifndef __EOUndoManager_h__
#define __EOUndoManager_h__

#ifdef GNUSTEP
#include <Foundation/NSUndoManager.h>
#else
#include <Foundation/Foundation.h>
#endif


@interface EOUndoManager : NSUndoManager

- (void)forgetAllWithTarget: (id)param0;
- (void)forgetAll;
- (void)registerUndoWithTarget: (id)param0
		      selector: (SEL)param1
			   arg: (id)param2;
- (void)reenableUndoRegistration;

@end

#endif // __EOUndoManager_h__
