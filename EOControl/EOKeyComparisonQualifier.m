/** 
   EOKeyComparisonQualifier.m <title>EOKeyComparisonQualifier</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSDebug.h>

#import <EOControl/EOQualifier.h>
#import <EOControl/EOKeyValueCoding.h>
#import <EOControl/EODebug.h>


@implementation EOKeyComparisonQualifier

+ (EOQualifier *)qualifierWithLeftKey: (NSString *)leftKey
		     operatorSelector: (SEL)selector
			     rightKey: (id)rightKey
{
  return [[[self alloc] initWithLeftKey: leftKey
			operatorSelector: selector
			rightKey: rightKey] autorelease];
}

- initWithLeftKey: (NSString *)leftKey
 operatorSelector: (SEL)selector
	 rightKey: (id)rightKey
{
  if ((self = [super init]))
    {
      _selector = selector;
      ASSIGN(_leftKey, leftKey);
      ASSIGN(_rightKey, rightKey);
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_leftKey);
  DESTROY(_rightKey);

  [super dealloc];
}

- (SEL)selector
{
  return _selector;
}

- (NSString *)leftKey
{
  return _leftKey;
}

- (NSString *)rightKey
{
  return _rightKey;
}

- (id)copyWithZone: (NSZone *)zone
{
  EOKeyComparisonQualifier *qual = [[EOKeyComparisonQualifier
				      allocWithZone: zone] init];

  qual->_selector = _selector;
  qual->_leftKey = [_leftKey copyWithZone: zone];
  qual->_rightKey = [_rightKey copyWithZone: zone];

  return qual;
}

- (BOOL)evaluateWithObject: (id)object
{
  id leftKey, rightKey;

  leftKey  = [object valueForKey: _leftKey];
  rightKey = [object valueForKey: _rightKey];

  if (sel_eq(_selector, EOQualifierOperatorEqual) == YES)
    {
      return [leftKey isEqual: rightKey] == NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorNotEqual) == YES)
    {
      return [leftKey isEqual: rightKey] != NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThan) == YES)
    {
      return [leftKey compare: rightKey] == NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThan) == YES)
    {
      return [leftKey compare: rightKey] == NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThanOrEqualTo) == YES)
    {
      return [leftKey compare: rightKey] != NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThanOrEqualTo) == YES)
    {
      return [leftKey compare: rightKey] != NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorContains) == YES)
    {
      [self notImplemented: _cmd];

      return NO;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [leftKey isEqual: rightKey]
	== NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorCaseInsensitiveLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [[leftKey uppercaseString] isEqual: [rightKey uppercaseString]]
	== NSOrderedSame;
    }

  return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%s %p - %@ %@ %@>",
		     object_get_class_name(self),
		     (void*)self,
		     _leftKey,
		     [isa stringForOperatorSelector:_selector],
		     _rightKey];
}

@end

