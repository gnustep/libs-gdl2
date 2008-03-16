/* -*-objc-*-
   EOEditingContext.m

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

#include <Foundation/Foundation.h>

#include <GNUstepBase/GNUstep.h>

#include "EOAggregateEvent.h"

@implementation EOAggregateEvent

- (id)init
{
  if ((self = [super init]))
    {
      NSZone *zone = [self zone];
      _children = [[NSArray allocWithZone: zone] init];
      _references = [[NSMutableSet allocWithZone: zone] init];
      _aggregateSignatureTag = 0;
    }
  return self;
}

- (void)addEvent:(EOEvent *)event
{
  _children = RETAIN([_children arrayByAddingObject: event]);
}

- (NSArray *)events
{
  return _children;
}

@end
