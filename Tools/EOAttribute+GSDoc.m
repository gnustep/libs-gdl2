/* 
   EOAttribute+GSDoc.m <title></title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: August 2000

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
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
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSAutoreleasePool.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOAccess/EOAccess.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>

#include "NSArray+GSDoc.h"
#include "NSDictionary+GSDoc.h"
#include "EOAttribute+GSDoc.h"

/*
    NSString*	calendarFormat;
    NSTimeZone*	clientTimeZone;
    NSTimeZone*	serverTimeZone;
    NSString*	insertFormat;
    NSString*	selectFormat;
    NSString*	updateFormat;
    NSMutableArray* definitionArray;	// These variables are meaningful only
    EOAttribute* realAttribute;		// if the attribute is flattened

*/

@implementation EOAttribute (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr
{
  return [self gsdocContentWithTagName: @"EOAttribute"
               idPtr: xmlIdPtr];
}

- (NSString *)gsdocContentWithTagName: (NSString *)tagName
				idPtr: (int *)xmlIdPtr
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSString *content = [NSString string];

  NSLog(@"Start: %@: %@ tagName=%@", [self class], [self name], tagName);

  if ([tagName isEqual: @"EOAttributeRef"])
    {
      content = [content stringByAppendingFormat:
			   @"<EOAttributeRef name=\"%@\"%@/>\n",
			 [self name],
			 (xmlIdPtr ? [NSString stringWithFormat:
						 @" debugId=\"%d\"",
					       (*xmlIdPtr)++] : @"")];
    }
  else
    {
      content = [content stringByAppendingFormat:
			   @"<%@%@%@%@%@%@%@%@%@%@%@>\n",
			 tagName,
			 ([self columnName]
			  ? [NSString stringWithFormat: @" columnName=\"%@\"",
				      [self columnName]] : @""),
			 ([self definition]
			  ? [NSString stringWithFormat: @" definition=\"%@\"",
				      [self definition]] : @""),
			 ([self externalType]
			  ? [NSString stringWithFormat: @" externalType=\"%@\"",
				      [self externalType]] : @""),
			 ([self name]
			  ? [NSString stringWithFormat: @" name=\"%@\"",
				      [self name]] : @""),
			 ([self valueClassName]
			  ? [NSString stringWithFormat:
					@" valueClassName=\"%@\"",
				      [self valueClassName]] : @""),
			 ([self valueType]
			  ? [NSString stringWithFormat: @" valueType=\"%@\"",
				      [self valueType]] : @""),
			 ([[self entity] name]
			  ? [NSString stringWithFormat: @" entityName=\"%@\"",
				      [[self  entity] name]] : @""),
			 ([self isReadOnly] ? @" isReadOnly=\"YES\"" : @""),
			 ([self isDerived] ? @" isDerived=\"YES\"" : @""),
			 ([self isFlattened] ? @" isFlattened=\"YES\"" : @"")];

      if ([[self userInfo] count])
        content = [content stringByAppendingString:
			     [[self userInfo] 
			       gsdocContentWithTagName: @"EOUserDictionary"
			       idPtr: xmlIdPtr]];
      if ([self docComment])
        content = [content stringByAppendingFormat: @"<desc>%@</desc>\n",
			   [self docComment]];

      content = [content stringByAppendingFormat: @"</%@>\n",
			 tagName];
    }

  NSLog(@"Stop: %@: %@", [self class], [self name]);

  RETAIN(content);
  DESTROY(arp);

  return AUTORELEASE(content);
}

@end
