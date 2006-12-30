/* -*-objc-*-
   EOEvent.m

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>
   Date: December 2005

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

#include "config.h"

RCS_ID("$Id$")

#include "EOEvent.h"

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSCalendarDate.h>
#endif

NSString *EOEventGroupName = @"EOEventGroupName";

/**
 * WARNING!!! This class is currently completely unimplemented.
 */
@implementation EOEvent
+ (NSDictionary *)eventTypeDescriptions
{
  return nil;
}
- (NSString *)title
{
  return nil;
}

- (void)markStartWithInfo: (id)info
{
  return;
}
- (void)markAtomicWithInfo: (id)info
{
  return;
}
- (void)markEnd
{
  return;
}
- (void)setInfo: (id)info
{
  return;
}
- (id)info
{
  return nil;
}
- (void)setType: (NSString *)type
{
  return;
}
- (NSString *)type
{
  return nil;
}
- (NSArray *)subevents
{
  return nil;
}
- (EOEvent *)parentEvent
{
  return nil;
}
- (id)signatureOfType: (EOEventSignatureType)tag
{
  return nil;
}
- (NSString *)comment
{
  return nil;
}
- (NSCalendarDate *)startDate
{
  return nil;
}
- (NSString *)displayComponentName
{
  return nil;
}
- (int)duration
{
  return 0;
}
- (int)durationWithoutSubevents
{
  return 0;
}
+ (NSArray *)groupEvents: (NSArray *)events
       bySignatureOfType: (EOEventSignatureType)tag
{
  return nil;
}
+ (NSArray *)aggregateEvents: (NSArray *)events
	   bySignatureOfType: (EOEventSignatureType)tag
{
  return nil;
}
@end
