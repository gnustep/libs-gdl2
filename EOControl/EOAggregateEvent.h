/* -*-objc-*-
   EOAggregateEvent.h

   Copyright (C) 2007 Free Software Foundation, Inc.

   Date: July 2007

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

#ifndef	__EOControl_EOAggregateEvent_h__
#define	__EOControl_EOAggregateEvent_h__

#include <EOControl/EOEvent.h>

@class NSArray;
@class NSMutableSet;

@interface EOAggregateEvent : EOEvent
{
  NSMutableSet *_references;
  NSArray *_children;
  int _aggregateSignatureTag;
}

- (void)addEvent:(EOEvent *)event;
- (NSArray *)events;

@end

#endif
