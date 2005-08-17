/* 
   EOEntity+GSDoc.m <title></title>

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

#include "NSArray+GSDoc.h"
#include "NSDictionary+GSDoc.h"
#include "EOModel+GSDoc.h"
#include "EOEntity+GSDoc.h"

/*
    NSString*		externalQuery;
    NSArray*		attributesNamesUsedForInsert;
    EOQualifier*	qualifier;
    GCArray*		attributesUsedForInsert;  // cache from classProperties
    GCArray*		attributesUsedForFetch;   // cache from classProperties
    GCArray*		relationsUsedForFetch;    // cache from classProperties
*/

@implementation EOEntity (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSString *content = [NSString string];

  NSLog(@"Start: %@: %@", [self class], [self name]);

  content = [content stringByAppendingFormat: @"<EOEntity%@%@%@%@%@%@>\n",
		     (xmlIdPtr ? [NSString stringWithFormat:
					     @" debugId=\"%d\"",
					   (*xmlIdPtr)++] : @""),
		     ([self name]
		      ? [NSString stringWithFormat: @" name=\"%@\"",
				  [self name]] : @""),
		     ([self externalName]
		      ? [NSString stringWithFormat: @" externalName=\"%@\"",
				  [self externalName]] : @""),
		     ([self className]
		      ? [NSString stringWithFormat: @" className=\"%@\"",
				  [self className]] : @""),
		     ([[self model] name]
		      ? [NSString stringWithFormat: @" modelName=\"%@\"",
				  [[self model] name]] : @""),
		     ([self isReadOnly] ? @"isReadOnly=\"YES\"" : @"")];

  if ([self attributes])
    content = [content stringByAppendingString: [[self attributes] 
						  gsdocContentWithTagName: nil
						  idPtr: xmlIdPtr]];

  if ([self attributesUsedForLocking])
    content = [content stringByAppendingString:
			 [[self attributesUsedForLocking] 
			   gsdocContentWithTagName:
			     @"EOAttributesUsedForLocking"
			   elementsTagName: @"EOAttributeRef"
			   idPtr: xmlIdPtr]];

  if ([self classProperties])
    content = [content stringByAppendingString:
			 [[self classProperties] 
			   gsdocContentWithTagName: @"EOClassProperties"
			   elementsTagName: @"EOAttributeRef"
			   idPtr: xmlIdPtr]];

  if ([self primaryKeyAttributes])
    content = [content stringByAppendingString:
			 [[self primaryKeyAttributes] 
			   gsdocContentWithTagName:
			     @"EOPrimaryKeyAttributes"	    
			   elementsTagName: @"EOAttributeRef"
			   idPtr: xmlIdPtr]];

  if ([self relationships])
    content = [content stringByAppendingString: [[self relationships] 
						  gsdocContentWithTagName: nil
						  idPtr: xmlIdPtr]];

  if ([[self userInfo] count])
    content = [content stringByAppendingString:
			 [[self userInfo] 
			   gsdocContentWithTagName: @"EOUserDictionary"
			   idPtr: xmlIdPtr]];

  if ([self docComment])
    content = [content stringByAppendingFormat: @"<desc>%@</desc>\n",
		       [self docComment]];

  content = [content stringByAppendingString: @"</EOEntity>\n"];

  NSLog(@"Stop: %@: %@", [self class], [self name]);

  RETAIN(content);
  DESTROY(arp);

  return AUTORELEASE(content);
}

@end
