/** 
   EOJoin+GSDoc.m <title>EOJoin+GSDoc</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSAutoreleasePool.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOAccess/EOAccess.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EORelationship.h>

#include "NSArray+GSDoc.h"
#include "NSDictionary+GSDoc.h"
#include "EOAttribute+GSDoc.h"
#include "EOJoin+GSDoc.h"


@implementation EOJoin (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSString *content = [NSString string];

  NSLog(@"Start: %@", [self class]);

  content = [content stringByAppendingFormat:
		       @"<EOJoin%@ relationshipName=\"%@\" joinOperator=\"%@\" joinSemantic=\"%@\" sourceAttribute=\"%@\" destinationAttribute=\"%@\">\n",
		     (xmlIdPtr
		      ? [NSString stringWithFormat: @" debugId=\"%d\"",
				  (*xmlIdPtr)++] : @""),
		     @"",//[[self relationship] name],
		     @"",//[self joinOperatorDescription],
		     @"",//[self joinSemanticDescription],
		     [[self sourceAttribute] name],
		     [[self destinationAttribute] name]];

  /*  if ([self docComment])
      content=[content stringByAppendingFormat:@"<desc>%@</desc>\n",[self docComment]];*/

  content = [content stringByAppendingString: @"</EOJoin>\n"];

  NSLog(@"Stop: %@", [self class]);

  RETAIN(content);
  DESTROY(arp);

  return AUTORELEASE(content);
}

@end
