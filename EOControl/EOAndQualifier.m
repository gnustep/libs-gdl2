/** 
   EOAndQualifier.m <title>EOAndQualifier Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
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
  NSMutableArray *qualArray = [NSMutableArray array];
  EOQualifier *tmpId;
  va_list ap;

  va_start(ap, qualifiers);

  for (tmpId = qualifiers; tmpId != nil; tmpId = va_arg(ap, id))
    {
      [qualArray addObject: tmpId];
    }

  va_end(ap);

  return AUTORELEASE([[self alloc] initWithQualifierArray: qualArray]);
}

/**
 * Initializes the receiver with the provided
 * nil terminated list of qualifiers.  This method calls
 * [EOAndQualifier-initWithQualifierArray:].  
 */ 
- (id) initWithQualifiers: (EOQualifier *)qualifiers, ...
{
  NSMutableArray *qualArray = [NSMutableArray array];
  EOQualifier *tmpId;
  va_list ap;

  va_start(ap, qualifiers);

  for (tmpId = qualifiers; tmpId != nil; tmpId = va_arg(ap, id))
    {
      [qualArray addObject: tmpId];
    }

  va_end(ap);

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

- (void) _addBindingsToDictionary: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (EOQualifier *) qualifierWithBindings: (NSDictionary *)bindings
                   requiresAllVariables: (BOOL)requiresAllVariables
{
  EOFLOGObjectLevelArgs(@"EOQualifier", @"bindings=%@", bindings);

  if ([bindings count] > 0)
    {
      NSEmitTODO();  
      return [self notImplemented: _cmd]; //TODO
    }
  else 
    return self;
}

- (id) initWithKeyValueUnarchiver: (id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (void) encodeWithKeyValueArchiver: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (id) validateKeysWithRootClassDescription: (id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (id) description
{
  NSString *dscr;

  dscr = [NSString stringWithFormat: @"<%s %p - qualifiers: %@>",
		   object_get_class_name(self),
		   (void*)self,
                   _qualifiers];

  return dscr;
}

@end
