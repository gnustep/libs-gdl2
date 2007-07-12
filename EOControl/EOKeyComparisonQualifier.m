/** 
   EOKeyComparisonQualifier.m <title>EOKeyComparisonQualifier</title>

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#endif

#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EODebug.h>

/*
  This declaration is needed by the compiler to state that
  eventhough we know not all objects respond to -compare:,
  we want the compiler to generate code for the given
  prototype when calling -compare: in the following methods.
  We do not put this declaration in a header file to avoid
  the compiler seeing conflicting prototypes in user code.
*/
@interface NSObject (Comparison)
- (NSComparisonResult)compare: (id)other;
@end

@implementation EOKeyComparisonQualifier

/**
 * Returns an autoreleased EOKeyComparisonQualifier using leftKey, selector
 * and right key.  The selector should take a single id as an argument and
 * return a BOOL value.  This method calls
 * [EOKeyComparisonQualifier-initWithLeftKey:operatorSelectot:rightKey:].
 */
+ (EOQualifier *) qualifierWithLeftKey: (NSString *)leftKey
		      operatorSelector: (SEL)selector
			      rightKey: (id)rightKey
{
  return AUTORELEASE([[self alloc] initWithLeftKey: leftKey
				   operatorSelector: selector
				   rightKey: rightKey]);
}

/** <init />
 * Initializes the receiver with a copy of leftKey, selector and a copy of
 * rightKey.  The selector should take a single id as an argument and return a
 * BOOL value.
 */
- (id) initWithLeftKey: (NSString *)leftKey
      operatorSelector: (SEL)selector
	      rightKey: (id)rightKey
{
  if ((self = [super init]))
    {
     /*Ayers (09-02-2002): Maybe we should assert the correct signature
       but we currently don't have the object which should implement it.
       Assertion during evaluation (i.e. when we have an object) could be
       too expensive.*/

      _selector = selector;
      ASSIGNCOPY(_leftKey, leftKey);
      ASSIGNCOPY(_rightKey, rightKey);
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_leftKey);
  DESTROY(_rightKey);

  [super dealloc];
}

/**
 * Returns the selector used by the receiver during in-memory evaluation.
 * The selector should take a single id as an argument and return a BOOL value.
 * (More docs to follow for EOQualifierSQLGeneration.)
 */
- (SEL) selector
{
  return _selector;
}

/**
 * Returns the key with which the receiver obtains the left value during
 * in-memory evaluation. (More docs to follow for EOQualifierSQLGeneration.)
 */
- (NSString *) leftKey
{
  return _leftKey;
}

/**
 * Returns the key with which the receiver obtains the right value during
 * in-memory evaluation. (More docs to follow for EOQualifierSQLGeneration.)
 */
- (NSString *) rightKey
{
  return _rightKey;
}

/**
 * EOQualifierEvaluation protocol<br/>
 * Evaluates the object according to the receivers definition.  First the left
 * value is obtained by invoking valueForKey: on the provided object with the
 * receivers leftKey and the right value by invoking valueForKey: with the
 * recievers rightKey.  If the left value implements the receivers selector,
 * this method returns the return value of the invocation of this method with
 * the right value as the parameter.<br/> 
 * If the left object doesn't implement the receivers selector, but the
 * selector of the reciever is one of:<br/>
 * <list>
 *  <item>EOQualifierOperatorEqual</item>
 *  <item>EOQualifierOperatorNotEqual</item>
 *  <item>EOQualifierOperatorLessThan</item>
 *  <item>EOQualifierOperatorGreaterThan</item>
 *  <item>EOQualifierOperatorLessThanOrEqual</item>
 *  <item>EOQualifierOperatorGreaterThanOrEqual</item>
 *  <item>EOQualifierOperatorContains</item>
 *  <item>EOQualifierOperatorLike</item>
 *  <item>EOQualifierOperatorCaseInsensitiveLike</item>
 * </list>
 * then GDL2 tries to evaluate the qualifier by invoking
 * isEqual:, compare:, rangeOfString: respectively and interpreting the
 * results accoring to the selector.  In the case of 
 * EOQualifierOperatorCaseInsensitiveLike, the values are converted using
 * uppercaseString for evaluation.<br/>
 * Both 'Like' fallback implementations are currently implemented by using
 * isEqual: and do not yet take the ? and * wildcards into account.<br/>
 * If the receivers selector is neither implemented by the left value nor
 * corresponds to one of the EOQualifierOperators, this method simply
 * returns NO.
 */
- (BOOL) evaluateWithObject: (id)object
{
  NSObject *leftVal;
  NSObject *rightVal;
  BOOL (*imp)(id, SEL, id);

  leftVal  = [object valueForKey: _leftKey];
  rightVal = [object valueForKey: _rightKey];

  imp = (BOOL (*)(id, SEL, id))[leftVal methodForSelector: _selector];
  if (imp != NULL)
    {
      return (*imp) (leftVal, _selector, rightVal);
    }
  if (sel_eq(_selector, EOQualifierOperatorEqual) == YES)
    {
      return [leftVal isEqual: rightVal];
    }
  else if (sel_eq(_selector, EOQualifierOperatorNotEqual) == YES)
    {
      return ([leftVal isEqual: rightVal]?NO:YES);
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThan) == YES)
    {
      return [leftVal compare: rightVal] == NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThan) == YES)
    {
      return [leftVal compare: rightVal] == NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThanOrEqualTo) == YES)
    {
      return [leftVal compare: rightVal] != NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThanOrEqualTo) == YES)
    {
      return [leftVal compare: rightVal] != NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorContains) == YES)
    {
      return [(id)leftVal rangeOfString: (id)rightVal].location != NSNotFound;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [leftVal isEqual: rightVal]
	== NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorCaseInsensitiveLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [[(id)leftVal uppercaseString] isEqual: [(id)rightVal uppercaseString]]
	== NSOrderedSame;
    }
  /*Ayers (09-02-2002): Maybe we should raise instead of returning NO.*/
  return NO;
}

/**
 * Returns a human readable representation of the receiver.
 */
- (NSString *) description
{
  NSString *selectorString;
  selectorString = [isa stringForOperatorSelector: _selector];
  if (selectorString == nil)
    {
      selectorString = NSStringFromSelector(_selector);
    }
  return [NSString stringWithFormat:@"(%@ %@ %@)",
		   _leftKey,
		   selectorString,
		   _rightKey];
}
/**
 * Deprecated debug description.  Expect it to be removed.
 */
- (NSString *) debugDescription
{
  NSString *selectorString;
  selectorString = [isa stringForOperatorSelector: _selector];
  if (selectorString == nil)
    {
      selectorString = NSStringFromSelector(_selector);
    }
  return [NSString stringWithFormat:@"<%s %p - %@ %@ %@>",
		   object_get_class_name(self),
		   (void*)self,
		   _leftKey,
		   selectorString,
		   _rightKey];
}

- (void)addQualifierKeysToSet: (NSMutableSet *)keys
{
  [keys addObject: _leftKey];
}

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver*)unarchiver
{
  EOFLOGObjectFnStartOrCond(@"EOQualifier");
  
  if ((self = [self init]))
  {
    NSString *selectorName = [unarchiver decodeObjectForKey: @"selectorName"];
    
    if (selectorName) 
      _selector = NSSelectorFromString(selectorName);
    
    ASSIGN(_leftKey, [unarchiver decodeObjectForKey: @"leftKey"]);
    ASSIGN(_rightKey, [unarchiver decodeObjectForKey: @"rightKey"]);
  }
  
  EOFLOGObjectFnStopOrCond(@"EOQualifier");
  
  return self;
}

@end

