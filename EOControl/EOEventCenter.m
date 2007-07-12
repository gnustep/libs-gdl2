/* -*-objc-*-
   EOEventCenter.m

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>
   Date: December 2005

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#else
#include <Foundation/Foundation.h>
#endif

#include "EOEventCenter.h"
#include "EOEvent.h"

id
EONewEventOfClass(Class eventClass, NSString *type)
{
  return nil;
}
void
EOMarkAtomicEvent(EOEvent *event, id info)
{
}
void
EOMarkStartOfEvent(EOEvent *event, id info)
{
}
void
EOMarkEndOfEvent(EOEvent *event)
{
}
void
EOCancelEvent(EOEvent *event)
{
}

NSString *EOEventLoggingOverflowDisplay = @"EOEventLoggingOverflowDisplay";
NSString *EOEventLoggingEnabled = @"EOEventLoggingEnabled";
NSString *EOEventLoggingLimit = @"EOEventLoggingLimit";

/**
 * WARNING!!! This class is currently completely unimplemented.
 */
@implementation EOEventCenter
+ (EOEventCenter *)currentCenter
{
  return nil;
}
+ (NSArray *)allCenters
{
  return nil;
}
+ (void)suspendLogging
{
  return;
}
+ (void)resumeLogging
{
  return;
}
+ (void)resetLogging
{
  return;
}
- (void)resetLogging
{
  return;
}
+ (void)registerEventClass: (Class)eventClass
	      classPointer: (Class *)classPtr
{
  return;
}
+ (void)registerEventClass: (Class)eventClass
		   handler: (id <EOEventRecordingHandler>)handler
{
  return;
}
+ (NSArray *)registeredEventClasses
{
  return nil;
}
+ (BOOL)recordsEventsForClass: (Class)eventClass
{
  return NO;
}
+ (void)setRecordsEvents: (BOOL)flag
		forClass: (Class)eventClass
{
  return;
}
+ (id)newEventOfClass: (Class)eventClass
		 type: (NSString *)type
{
  return nil;
}
+ (void)markStartOfEvent: (EOEvent *)event
		    info: (id)info
{
  return;
}
+ (void)markAtomicEvent: (EOEvent *)event
		   info: (id)info
{
  return;
}
+ (void)markEndOfEvent:(EOEvent *)event
{
  return;
}
+ (void)cancelEvent:(EOEvent *)event
{
  return;
}
- (NSArray *)eventsOfClass: (Class)eventClass
		      type: (NSString *)type
{
  return nil;
}
+ (NSArray *)eventsOfClass: (Class)eventClass
		      type:(NSString *)type
{
  return nil;
}
+ (NSArray *)rootEvents
{
  return nil;
}
- (NSArray *)rootEvents
{
  return nil;
}
+ (NSArray *)rootEventsByDuration
{
  return nil;
}
- (NSArray *)allEvents
{
  return nil;
}
+ (NSArray *)allEvents
{
  return nil;
}
@end
