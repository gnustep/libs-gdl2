/** 
   EOJoin.m <title>EOJoin Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOJoin.h>


@implementation EOJoin

+ (EOJoin *) joinWithSourceAttribute: (EOAttribute *)source
                destinationAttribute: (EOAttribute *)destination
{
  return [[[self alloc] initWithSourceAttribute: source
			destinationAttribute: destination] autorelease];
}

- (id) initWithSourceAttribute: (EOAttribute *)source
          destinationAttribute: (EOAttribute *)destination
{
  if ((self = [super init]))
    {
      if (!source || !destination)
        [NSException raise: NSInvalidArgumentException
		     format: @"%@ -- %@ 0x%x: source and destination attributes can't be nil", 
                     NSStringFromSelector(_cmd), 
                     NSStringFromClass([self class]), 
                     self];

      ASSIGN(_sourceAttribute, source);
      ASSIGN(_destinationAttribute, destination);
    }

  return self;
}

- (void)gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevel(@"gsdb", @"sourceAttribute gcDecrementRefCount");

  [_sourceAttribute gcDecrementRefCount];
  EOFLOGObjectLevel(@"gsdb", @"destinationAttribute gcDecrementRefCount");

  [_destinationAttribute gcDecrementRefCount];

  EOFLOGObjectFnStop();
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  if (![super gcIncrementRefCountOfContainedObjects])
    return NO;

  [_sourceAttribute gcIncrementRefCount];
  [_destinationAttribute gcIncrementRefCount];
  
  [_sourceAttribute gcIncrementRefCountOfContainedObjects];
  [_destinationAttribute gcIncrementRefCountOfContainedObjects];
  
  return YES;
}

- (unsigned)hash
{
  return [_sourceAttribute hash];
}

- (NSString *)description
{
  NSString *dscr = nil;
/*NSString *joinOperatorDescr = nil;
  NSString *joinSemanticDescr = nil;

  switch(joinOperator)
  {
      case EOJoinEqualTo:
          joinOperatorDescr=@"EOJoinEqualTo";
          break;
      case EOJoinNotEqualTo:
          joinOperatorDescr=@"EOJoinNotEqualTo";
          break;
      case EOJoinGreaterThan:
          joinOperatorDescr=@"EOJoinGreaterThan";
          break;
      case EOJoinGreaterThanOrEqualTo:
          joinOperatorDescr=@"EOJoinGreaterThanOrEqualTo";
          break;
      case EOJoinLessThan:
          joinOperatorDescr=@"EOJoinLessThan";
          break;
      case EOJoinLessThanOrEqualTo:
          joinOperatorDescr=@"EOJoinLessThanOrEqualTo";
          break;
  };
  switch(joinSemantic)
  {
      case EOInnerJoin:
          joinSemanticDescr=@"EOInnerJoin";
          break;
      case EOFullOuterJoin:
          joinSemanticDescr=@"EOFullOuterJoin";
          break;
      case EOLeftOuterJoin:
          joinSemanticDescr=@"EOLeftOuterJoin";
          break;
      case EORightOuterJoin:
          joinSemanticDescr=@"EORightOuterJoin";
          break;
  };
*/  

  dscr = [NSString stringWithFormat: @"<%s %p -",
		   object_get_class_name(self),
		   (void*)self];
  dscr = [dscr stringByAppendingFormat: @" sourceAttribute=%@",
	       [_sourceAttribute name]];
  dscr = [dscr stringByAppendingFormat: @" destinationAttribute=%@",
	       [_destinationAttribute name]];

/*  dscr=[dscr stringByAppendingFormat:@" relationship name=%@",
			 [relationship name]];
  dscr=[dscr stringByAppendingFormat:@" joinOperator=%@ joinSemantic=%@>",
			 joinOperatorDescr,
			 joinSemanticDescr];*/

  return dscr;
}

- (EOAttribute *)destinationAttribute
{
  return _destinationAttribute;
}

- (EOAttribute *)sourceAttribute
{
  return _sourceAttribute;
}

- (BOOL)isReciprocalToJoin: (EOJoin *)otherJoin
{
  //OK
  NSDebugMLLog(@"gsdb", @"_sourceAttribute name=%@",
	       [_sourceAttribute name]);
  NSDebugMLLog(@"gsdb", @"[[otherJoin destinationAttribute] name]=%@",
	       [[otherJoin destinationAttribute] name]);
  NSDebugMLLog(@"gsdb", @"_destinationAttribute name=%@",
	       [_destinationAttribute name]);
  NSDebugMLLog(@"gsdb", @"[[otherJoin sourceAttribute] name]=%@",
	       [[otherJoin sourceAttribute] name]);

  if ([[_sourceAttribute name]
	isEqual: [[otherJoin destinationAttribute] name]]
      && [[_destinationAttribute name]
	   isEqual: [[otherJoin sourceAttribute] name]])
    return YES;
  else
    return NO;
}

@end
