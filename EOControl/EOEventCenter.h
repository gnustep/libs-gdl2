/* -*-objc-*-
   EOEventCenter.h

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

#ifndef	__EOControl_EOEventCenter_h__
#define	__EOControl_EOEventCenter_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSHashTable.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>

@class NSString;
@class EOEvent;

/*
 * WARNING!!! These functions are currently completely unimplemented.
 */
GDL2CONTROL_EXPORT 
id EONewEventOfClass(Class eventClass, NSString *type);
GDL2CONTROL_EXPORT
void EOMarkAtomicEvent(EOEvent *event, id info);
GDL2CONTROL_EXPORT
void EOMarkStartOfEvent(EOEvent *event, id info);
GDL2CONTROL_EXPORT
void EOMarkEndOfEvent(EOEvent *event);
GDL2CONTROL_EXPORT
void EOCancelEvent(EOEvent *event);

GDL2CONTROL_EXPORT NSString *EOEventLoggingOverflowDisplay;
GDL2CONTROL_EXPORT NSString *EOEventLoggingEnabled;
GDL2CONTROL_EXPORT NSString *EOEventLoggingLimit;

@protocol EOEventRecordingHandler
- (void)setLoggingEnabled: (BOOL)flag
	    forEventClass: (Class)eventClass;
@end

@interface NSObject (EOEventRecordingHandler) <EOEventRecordingHandler>
- (void)setLoggingEnabled: (BOOL)flag
	    forEventClass: (Class)eventClass;
@end

/*
 * WARNING!!! This class is currently completely unimplemented.
 */
@interface EOEventCenter : NSObject
{
  EOEvent     *_rootEvent;
  EOEvent     *_lastEvent;
  NSHashTable *_events;
  int          _eventCounter;
}
+ (EOEventCenter *)currentCenter;
+ (NSArray *)allCenters;
+ (void)suspendLogging;
+ (void)resumeLogging;
+ (void)resetLogging;
- (void)resetLogging;
+ (void)registerEventClass: (Class)eventClass
	      classPointer: (Class *)classPtr;
+ (void)registerEventClass: (Class)eventClass
		   handler: (id <EOEventRecordingHandler>)handler;
+ (NSArray *)registeredEventClasses;
+ (BOOL)recordsEventsForClass: (Class)eventClass;
+ (void)setRecordsEvents: (BOOL)flag
		forClass: (Class)eventClass;
+ (id)newEventOfClass: (Class)eventClass
		 type: (NSString *)type;
+ (void)markStartOfEvent: (EOEvent *)event
		    info: (id)info;
+ (void)markAtomicEvent: (EOEvent *)event
		   info: (id)info;
+ (void)markEndOfEvent:(EOEvent *)event;
+ (void)cancelEvent:(EOEvent *)event;
- (NSArray *)eventsOfClass: (Class)eventClass
		      type: (NSString *)type;
+ (NSArray *)eventsOfClass: (Class)eventClass
		      type:(NSString *)type;
+ (NSArray *)rootEvents;
- (NSArray *)rootEvents;
+ (NSArray *)rootEventsByDuration;
- (NSArray *)allEvents;
+ (NSArray *)allEvents;
@end

#endif
