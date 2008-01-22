/** 
   EOAndQualifier.m <title>EOAndQualifier Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: January 2002

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
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSSet.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOQualifier.h>
#include <EOControl/EODebug.h>


@implementation EOAndQualifier

/**
 * Returns an autoreleased EOAndQualifier consisting of the provided array of
 * qualifiers.  This method calls [EOAndQualifier-initWithQualifierArray:].  
 */ 
+ (EOQualifier *) qualifierWithQualifierArray: (NSArray *)array
{
  return AUTORELEASE([[self alloc] initWithQualifierArray: array]);
}

/**
 * Returns an autoreleased EOAndQualifier consisting of the provided
 * nil terminated list of qualifiers.  This method calls
 * [EOAndQualifier-initWithQualifierArray:].  
 */ 
+ (EOQualifier *) qualifierWithQualifiers: (EOQualifier *)qualifiers, ...
{
  NSArray *qualArray;

  GS_USEIDLIST(qualifiers, qualArray
	       = AUTORELEASE([[NSArray alloc] initWithObjects: __objects
					      count: __count]));

  return AUTORELEASE([[self alloc] initWithQualifierArray: qualArray]);
}

/**
 * Initializes the receiver with the provided
 * nil terminated list of qualifiers.  This method calls
 * [EOAndQualifier-initWithQualifierArray:].  
 */ 
- (id) initWithQualifiers: (EOQualifier *)qualifiers, ...
{
  NSArray *qualArray;

  GS_USEIDLIST(qualifiers, qualArray
	       = AUTORELEASE([[NSArray alloc] initWithObjects: __objects
					      count: __count]));

  return [self initWithQualifierArray: qualArray];
}

/** <init />
 * Initializes the receiver with the provided array of qualifiers.  
 */ 
- (id) initWithQualifierArray: (NSArray *)array
{
  if ((self = [self init]))
    {
      ASSIGNCOPY(_qualifiers, array);
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_qualifiers);

  [super dealloc];
}

/**
 * Returns the recievers array of qualifiers.
 */
- (NSArray *)qualifiers
{
  return _qualifiers;
}

/**
 * EOQualifierEvaluation protocol
 * Returns YES if all of the receivers qualifiers return YES to
 * [EOQualifierEvaluation-evaluateWithObjects:] with object.  This method
 * returns NO as soon as the first qualifier retuns NO.
 */
- (BOOL)evaluateWithObject: (id)object
{
  NSEnumerator *qualifiersEnum;
  EOQualifier *qualifier;
  
  qualifiersEnum = [_qualifiers objectEnumerator];

  while ((qualifier = [qualifiersEnum nextObject]))
    {
      if ([qualifier evaluateWithObject: object] == NO)
	return NO;
    }

  return YES;
}

- (id) qualifierMigratedFromEntity: (id)param0
                  relationshipPath: (id)param1
{
  return [self notImplemented: _cmd]; //TODO
}

- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary
{
  int i=0;
  int count=[_qualifiers count];
  for(i=0;i<count;i++)
      [[_qualifiers objectAtIndex:i]_addBindingsToDictionary:dictionary];
}

- (EOQualifier *) qualifierWithBindings: (NSDictionary *)bindings
                   requiresAllVariables: (BOOL)requiresAllVariables
{
  //Ayers: Review
  EOQualifier* resultQualifier = nil;
  int i = 0;
  int count = [_qualifiers count];
  NSMutableArray* newQualifiers = nil;
  EOFLOGObjectLevelArgs(@"EOQualifier", @"bindings=%@", bindings);

  for(i=0; i<count; i++)
    {
      EOQualifier* qualifier = [_qualifiers objectAtIndex:i];
      EOQualifier* newQualifier
	= [qualifier qualifierWithBindings: bindings
		     requiresAllVariables: requiresAllVariables];
      if (newQualifier)
        {
          if (!newQualifiers)
	    {
	      newQualifiers=(NSMutableArray*)[NSMutableArray array];
	    }
          [newQualifiers addObject: newQualifier];
        }
    }
  if ([newQualifiers count] > 0)
    {
      if ([newQualifiers count] == 1)
	{
	  resultQualifier=[newQualifiers lastObject];
	}
      else
	{ 
	  resultQualifier
	    =[[self class] qualifierWithQualifierArray:newQualifiers];
	}
    }
  return resultQualifier;
}

- (id) initWithKeyValueUnarchiver: (id) archiver
{
  if ((self = [super init])) {
    id qualifierArray = [archiver decodeObjectForKey:@"qualifiers"];
    ASSIGN (_qualifiers, qualifierArray);
  }
  return self;
}

- (void) encodeWithKeyValueArchiver: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (NSException *) validateKeysWithRootClassDescription:(EOClassDescription*)classDescription
{
  //Ayers: Review
  int i = 0;
  int count = [_qualifiers count];
  for(i=0; i<count; i++)
    {
      [[_qualifiers objectAtIndex:i] 
	validateKeysWithRootClassDescription:classDescription];
    }
  return nil;//TODO
}

- (NSString *) description
{
  NSString *dscr;
  
  dscr = [NSString stringWithFormat: @"(%@)",
		   [_qualifiers componentsJoinedByString: @" AND "]];

  return dscr;
}
/**
 * Deprecated debug description.  Expect it to be removed.
 */
- (NSString *) debugDescription
{
  NSString *dscr;

  dscr = [NSString stringWithFormat: @"<%s %p - qualifiers: %@>",
		   object_get_class_name(self),
		   (void*)self,
                   _qualifiers];

  return dscr;
}

- (void)addQualifierKeysToSet: (NSMutableSet *)keys
{
  EOQualifier *qual;
  unsigned int i,n;
  for (i=0, n=[_qualifiers count]; i < n; i++)
    {
      qual = [_qualifiers objectAtIndex:i];
      [qual addQualifierKeysToSet: keys];
    }
}
@end
