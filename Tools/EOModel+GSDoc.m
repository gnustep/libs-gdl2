/** 
   EOModel+GSDoc.m <title></title>

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

static char rcsId[] = "$Id$";

#include <EOAccess/EOAccess.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDebug.h>
#include "NSArray+GSDoc.h"
#include "NSDictionary+GSDoc.h"
#include "EOEntity+GSDoc.h"
#include "EOModel+GSDoc.h"


@implementation EOModel (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr
{
  return [self gsdocContentSplittedByEntities: NULL
               idPtr: xmlIdPtr];
}

- (NSString *)gsdocContentSplittedByEntities: (NSDictionary **)entitiesPtr
				   withIdPtr: (int *)xmlIdPtr
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSString *content = [NSString string];
  NSArray *entities = [self entities];
  int i, count = [entities count];

  NSLog(@"Start: %@", [self class]);

  content = [content stringByAppendingFormat:
		       @"<chapter%@>\n<heading>EOModel %@</heading>\n<EOModel %@%@%@%@%@>\n",
		     ([self name]
		      ? [NSString stringWithFormat: @" id=\"%@\"",
				  [self name]] : @""),
		     ([self name] ? [self name] : @""),
		     (xmlIdPtr
		      ? [NSString stringWithFormat: @" debugId=\"%d\"",
				  (*xmlIdPtr)++] : @""),
		     ([self name]
		      ? [NSString stringWithFormat: @" name=\"%@\"",
				  [self name]] : @""),
		     ([self version]
		      ? [NSString stringWithFormat: @" version=\"%f\"",
				  [self version]] : @""),
		     ([self adaptorName]
		      ? [NSString stringWithFormat: @" adaptorName=\"%@\"",
				  [self adaptorName]] : @""),
		     ([self adaptorClassName]
		      ? [NSString stringWithFormat: @" adaptorClassName=\"%@\"",
				  [self adaptorClassName]]
		      : @" adaptorClassName=\"\"")];

  if ([self connectionDictionary])
    content = [content stringByAppendingString:
			 [[self connectionDictionary] 
			   gsdocContentWithTagName: @"EOConnectionDictionary"
			   idPtr: xmlIdPtr]];

  if (entitiesPtr)
    {
      *entitiesPtr = [NSMutableDictionary dictionary];
      content = [content stringByAppendingString: @"[[entities]]"];
    }

  for (i = 0; i < count; i++)
    {
      EOEntity *entity = [entities objectAtIndex: i];
      NSString *entityContent = [entity gsdocContentWithIdPtr: xmlIdPtr];

      NSAssert(entityContent, @"No entity gsdoc content");

      if (entitiesPtr)
        {
          entityContent = [NSString stringWithFormat:
				      @"<chapter id=\"%@\">\n<heading>EOEntity %@</heading>\n%@\n</chapter>\n",
				    [entity name],
				    [entity name],
				    entityContent];
          [(NSMutableDictionary*)*entitiesPtr setObject: entityContent
                                 forKey: [entity name]];
        }
      else
        content = [content stringByAppendingString: entityContent];
    }

  if ([[self userInfo] count])
    content = [content stringByAppendingString:
			 [[self userInfo] 
			   gsdocContentWithTagName: @"EOUserDictionary"
			   idPtr: xmlIdPtr]];

  if ([self docComment])
    content = [content stringByAppendingFormat: @"<desc>%@</desc>\n",
		       [self docComment]];

  content = [content stringByAppendingString: @"</EOModel>\n</chapter>\n"];

  NSLog(@"Stop: %@", [self class]);

  RETAIN(content);

  if (entitiesPtr)
    RETAIN(*entitiesPtr);

  DESTROY(arp);

  if (entitiesPtr)
    AUTORELEASE(*entitiesPtr);

  return AUTORELEASE(content);
}

@end
