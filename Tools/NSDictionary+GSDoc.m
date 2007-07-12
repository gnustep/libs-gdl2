/** 
   NSDictionary+GSDoc.m <title></title>

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
   version 3 of the License, or (at your option) any later version.

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
#include <Foundation/NSString.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSAutoreleasePool.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include "NSDictionary+GSDoc.h"


@implementation NSDictionary (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr
{
  return [self gsdocContentWithTagName: @"dictionary"
	       idPtr: xmlIdPtr];
}

- (NSString *)gsdocContentWithTagName: (NSString *)tagName
				idPtr: (int *)xmlIdPtr
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSString *content = [NSString string];
  NSEnumerator *enumerator = [self keyEnumerator];
  id key = nil;

  NSLog(@"Start: %@", [self class]);

  if (tagName)
    content = [content stringByAppendingFormat: @"<%@%@>\n",
		       tagName,
		       (!xmlIdPtr
			|| [tagName isEqualToString: @"dictionary"] ? @""
			: [NSString stringWithFormat: @" debugId=\"%d\"",
				    (*xmlIdPtr)++])];  

  while ((key = [enumerator nextObject]))
    {
      id elem = [self objectForKey: key];

      NSLog(@"key: %@ elem: %@", key, elem);

      if ([elem respondsToSelector: @selector(gsdocContentWithIdPtr:)])
        content = [content stringByAppendingFormat:
			     @"<dictionaryItem key=\"%@\">\n%@</dictionaryItem>\n",
			   key,
			   [elem gsdocContentWithIdPtr: xmlIdPtr]];
      else
        content = [content stringByAppendingFormat:
			     @"<dictionaryItem key=\"%@\" value=\"%@\"/>\n",
			   key,
			   elem];
    }

  if (tagName)
    content = [content stringByAppendingFormat: @"</%@>\n",
		       tagName];

  NSLog(@"Stop: %@", [self class]);

  RETAIN(content);
  DESTROY(arp);

  return AUTORELEASE(content);
}

@end
