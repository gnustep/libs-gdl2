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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOObjectStore.h>
#include <EOControl/EOObjectStoreCoordinator.h>
#include <EOControl/EOEditingContext.h>
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

@interface EOQualifier (Privat)
- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary;
- (NSException *)_validateKey: (NSString*)key
     withRootClassDescription: (EOClassDescription *)classDescription;
@end

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
  NSObject *val;
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
      return [(id)val rangeOfString: _value].location != NSNotFound;
    }
  else if (sel_eq(_selector, EOQualifierOperatorLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [val isEqual: _value] == NSOrderedSame;
    }
  else if (sel_eq(_selector, EOQualifierOperatorCaseInsensitiveLike) == YES)
    {
      NSEmitTODO();  //TODO
      return [[(id)val uppercaseString] isEqual: [_value uppercaseString]]
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


- (NSException *)validateKeysWithRootClassDescription:(EOClassDescription*)classDescription
{
  return [self _validateKey:_key
                withRootClassDescription:classDescription];
}

- (EOQualifier *) qualifierWithBindings: (NSDictionary*)bindings
		   requiresAllVariables: (BOOL)requiresAllVariables
{
  EOQualifier* qualifier=nil;

  EOFLOGObjectLevelArgs(@"EOQualifier", @"bindings=%@", bindings);

  if ([_value isKindOfClass:[EOQualifierVariable class]])
    {
      id value=[bindings valueForKeyPath:[(EOQualifierVariable*)_value key]];
      if (value)
        qualifier=[EOKeyValueQualifier qualifierWithKey:_key
                                       operatorSelector:_selector
                                       value:value];
      else if (requiresAllVariables)
        {
          [NSException raise: EOQualifierVariableSubstitutionException
                       format: @"%@ -- %@ 0x%x: Value for '%@' not found in binding resolution",
                       NSStringFromSelector(_cmd),
                       NSStringFromClass([self class]),
                       self,
                       _key];
        };
    } 
  else
    qualifier=self;
  return qualifier;
}

- (EOQualifier *) qualifierMigratedFromEntity: (id)param0
                  relationshipPath: (id)param1
{
  return [self notImplemented: _cmd]; //TODO
}

@end

@implementation EOKeyValueQualifier (Privat)
- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary
{
  if ([_value isKindOfClass:[EOQualifierVariable class]])
      [dictionary setObject:[(EOQualifierVariable*)_value key]
                  forKey:_key];
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

- (void) encodeWithKeyValueArchiver: (EOKeyValueArchiver*)archiver
{
  NSString* selectorName=NSStringFromSelector(_selector);
  [archiver encodeObject:_key
            forKey:@"key"];
  [archiver encodeObject:selectorName
            forKey:@"selectorName"];
  [archiver encodeObject:_value
            forKey:@"value"];
}

@end
