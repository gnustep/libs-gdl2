/** 
   EOKeyValueQualifier.m <title>EOKeyValueQualifier Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: November 2001

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

#import <Foundation/Foundation.h>

#import <EOControl/EOQualifier.h>
#import <EOControl/EOKeyValueCoding.h>
#import <EOControl/EOObjectStore.h>
#import <EOControl/EOObjectStoreCoordinator.h>
#import <EOControl/EOEditingContext.h>
#import <EOControl/EODebug.h>


@implementation EOKeyValueQualifier

/**
 * Returns an autoreleased EOKeyValueQualifier using key, selector and value.  
 * The selector should take a single id as an argument an return a BOOL value.
 * This method calls [EOKeyValueQualifier-initWithKey:operatorSelectot:value:].
 */
+ (EOKeyValueQualifier *) qualifierWithKey: (NSString *)key
			  operatorSelector: (SEL)selector
				     value: (id)value
{
  return AUTORELEASE([[self alloc] initWithKey: key
				   operatorSelector: selector
				   value: value]);
}

/** <init />
 * Initializes the receiver with a copy of leftKey, selector and a copy of
 * rightKey.  The selector should take a single id as an argument an return a
 * BOOL value.
 */
- (id) initWithKey: (NSString *)key
  operatorSelector: (SEL)selector
	     value: (id)value
{
  if ((self = [super init]))
    {
     /*Ayers (09-02-2002): Maybe we should assert the correct signature
       but we currently don't have the object which should implement it.
       Assertion during evaluation (i.e. when we have an object) could be
       too expensive.*/

      _selector = selector;
      ASSIGNCOPY(_key, key);
      ASSIGN(_value, value);
    }

  return self;
}

- (void) dealloc
{
  DESTROY(_key);
  DESTROY(_value);

  [super dealloc];
}

/**
 * Returns the selector used by the receiver during in-memory evaluation.
 * The selector should take a single id as an argument an return a BOOL value.
 * (More docs to follow for EOQualifierSQLGeneration.)
 */
- (SEL) selector
{
  return _selector;
}

/**
 * Returns the key with which the receiver obtains the value to compare with 
 * receivers value during in-memory evaluation. (More docs to follow for 
 * EOQualifierSQLGeneration.)
 */
- (NSString *) key
{
  return _key;
}

/**
 * Returns the value with which the receiver compares the value obtained from
 * the provided object during in-memory evaluation. (More docs to follow for 
 * EOQualifierSQLGeneration.)
 */
- (id) value
{
  return _value;
}

/**
 * EOQualifierEvaluation protocol<br/>
 * Evaluates the object according to the receivers definition.  First the
 * provided objects value object is obtained by invoking valueForKey: on it
 * with the receivers key.  If the value object implements the receivers
 * selector, this method returns the return value of the invocation of this
 * method with the receivers value as the parameter.<br/> 
 * If the value object doesn't implement the receivers selector, but the
 * selector of the reciever is one of:<br/>
 + <list>
 * EOQualifierOperatorEqual
 * EOQualifierOperatorNotEqual
 * EOQualifierOperatorLessThan
 * EOQualifierOperatorGreaterThan
 * EOQualifierOperatorLessThanOrEqual
 * EOQualifierOperatorGreaterThanOrEqual
 * EOQualifierOperatorContains
 * EOQualifierOperatorLike
 * EOQualifierOperatorCaseInsensitiveLike
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
  id val;
  BOOL (*imp)(id, SEL, id);

  val = [object valueForKey: _key];

  imp = (BOOL (*)(id, SEL, id))[val methodForSelector: _selector];
  if (imp != NULL)
    {
      return (*imp) (val, _selector, _value);
    }
  if (sel_eq(_selector, EOQualifierOperatorEqual) == YES)
    {
      return [val isEqual: _value];
    }
  else if (sel_eq(_selector, EOQualifierOperatorNotEqual) == YES)
    {
      return ([val isEqual: _value]?NO:YES);
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThan) == YES)
    {
      return [val compare: _value] == NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThan) == YES)
    {
      return [val compare: _value] == NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLessThanOrEqualTo) == YES)
    {
      return [val compare: _value] != NSOrderedDescending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorGreaterThanOrEqualTo) == YES)
    {
      return [val compare: _value] != NSOrderedAscending;
    }
  else if (sel_eq(_selector, EOQualifierOperatorContains) == YES)
    {
      return [val rangeOfString: _value].location != NSNotFound;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [val isEqual: _value] == NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorCaseInsensitiveLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [[val uppercaseString] isEqual: [_value uppercaseString]]
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
  return [NSString stringWithFormat:@"<%s %p - %@ %@ (%@)'%@'>",
		   object_get_class_name(self),
		   (void*)self,
		   _key,
		   selectorString,
		   NSStringFromClass([_value class]),
		   _value];
}


- (id) validateKeysWithRootClassDescription: (id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (id) initWithKeyValueUnarchiver: (id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (void) encodeWithKeyValueArchiver: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (void) _addBindingsToDictionary: (id)param0
{
  [self notImplemented: _cmd]; //TODO
}

- (EOQualifier *) qualifierWithBindings: (NSDictionary*)bindings
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

- (EOQualifier *) qualifierMigratedFromEntity: (id)param0
                  relationshipPath: (id)param1
{
  return [self notImplemented: _cmd]; //TODO
}

@end

@implementation EOKeyValueQualifier (EOKeyValueArchiving)

- (id) initWithKeyValueUnarchiver: (EOKeyValueUnarchiver*)unarchiver
{
  EOFLOGObjectFnStartOrCond(@"EOQualifier");

  if ((self = [self init]))
    {
      NSString *selectorName = [unarchiver decodeObjectForKey: @"selectorName"];

      if (selectorName) 
        _selector = NSSelectorFromString(selectorName);
      
      ASSIGN(_key, [unarchiver decodeObjectForKey: @"key"]);
      ASSIGN(_value, [unarchiver decodeObjectForKey: @"value"]);
    }
  
  EOFLOGObjectFnStopOrCond(@"EOQualifier");

  return self;
}

- (void) encodeWithKeyValueArchiver: (EOKeyValueUnarchiver*)archiver
{
  [self notImplemented: _cmd];
}

@end
