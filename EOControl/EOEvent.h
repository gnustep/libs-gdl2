/* -*-objc-*-
   EOEvent.h

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

#ifndef	__EOControl_EOEvent_h__
#define	__EOControl_EOEvent_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>

GDL2CONTROL_EXPORT
NSString *EOEventGroupName;

typedef enum {
  EOBasicEventSignature
} EOEventSignatureType;

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSCalendarDate;

/*
 * WARNING!!! This class is currently completely unimplemented.
 */
@interface EOEvent : NSObject
{
  id        _info;
  NSString *_type;
  double    _encountered;
  double    _duration;
  EOEvent  *_parent;
  EOEvent  *_child;
  EOEvent  *_next;
}
+ (NSDictionary *)eventTypeDescriptions;
- (NSString *)title;

- (void)markStartWithInfo: (id)info;
- (void)markAtomicWithInfo: (id)info;
- (void)markEnd;
- (void)setInfo: (id)info;
- (id)info;
- (void)setType: (NSString *)type;
- (NSString *)type;
- (NSArray *)subevents;
- (EOEvent *)parentEvent;
- (id)signatureOfType: (EOEventSignatureType)tag;
- (NSString *)comment;
- (NSCalendarDate *)startDate;
- (NSString *)displayComponentName;
- (int)duration;
- (int)durationWithoutSubevents;
+ (NSArray *)groupEvents: (NSArray *)events
       bySignatureOfType: (EOEventSignatureType)tag;
+ (NSArray *)aggregateEvents: (NSArray *)events
	   bySignatureOfType: (EOEventSignatureType)tag;
@end

#endif
