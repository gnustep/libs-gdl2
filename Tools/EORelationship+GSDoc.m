/** 
   EORelationship+GSDoc.m <title></title>

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

#include <EOAccess/EOAccess.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOEntity.h>
#include <Foundation/NSAutoreleasePool.h>
#include "NSArray+GSDoc.h"
#include "NSDictionary+GSDoc.h"
#include "EORelationship+GSDoc.h"

/*
    NSString*	definition;
    struct {
	BOOL	isFlattened:1;
	BOOL	isToMany:1;
	BOOL	createsMutableObjects:1;
    } flags;
*/


@implementation EORelationship (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr
{
  return [self gsdocContentWithTagName: @"EORelationship"
               idPtr: xmlIdPtr];
}

- (NSString *)gsdocContentWithTagName: (NSString *)tagName
				idPtr: (int *)xmlIdPtr
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSString *content = [NSString string];

  NSLog(@"Start: %@: %@", [self class], [self name]);

  if ([tagName isEqual: @"EOAttributeRef"])
    {
      content = [content stringByAppendingFormat:
			   @"<EOAttributeRef%@ name=\"%@\"/>\n",
			 (xmlIdPtr
			  ? [NSString stringWithFormat: @" debugId=\"%d\"",
				      (*xmlIdPtr)++] : @""),
			 [self name]];
    }
  else
    {
      content = [content stringByAppendingFormat:
			   @"<%@%@ name=\"%@\" entityName=\"%@\" destinationEntityName=\"%@\">\n",
			 tagName,
			 (xmlIdPtr
			  ? [NSString stringWithFormat: @" id=\"%d\"",
				      (*xmlIdPtr)++] : @""),
			 [self name],
			 [[self entity] name],
			 [[self destinationEntity] name]];

      if ([self isFlattened])
        {
          int i, count = [[self componentRelationships] count];

          for (i = 0; i < count; i++)
            {
	      EORelationship *component;
              component = [[self componentRelationships] objectAtIndex: i];

              content = [content stringByAppendingFormat:
				 @"<EORelationshipComponent%@ definition=\"%@\">\n",
				 (xmlIdPtr
				  ? [NSString stringWithFormat: @" id=\"%d\"",
					      (*xmlIdPtr)++] : @""),
				 [component name]];
            }

          for (i = 0; i < count; i++)
            content = [content stringByAppendingString:
				 @"</EORelationshipComponent>\n"];
        }
      else if ([self joins])
        content = [content stringByAppendingString:
			     [[self joins] 
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

      content = [content stringByAppendingFormat: @"</%@>\n",
			 tagName];
    }

  NSLog(@"Stop: %@: %@", [self class], [self name]);

  RETAIN(content);
  DESTROY(arp);

  return AUTORELEASE(content);
}

@end
