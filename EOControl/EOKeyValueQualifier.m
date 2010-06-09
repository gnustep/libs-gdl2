/** 
   EOKeyValueQualifier.m <title>EOKeyValueQualifier Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#endif

#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOObjectStore.h>
#include <EOControl/EOObjectStoreCoordinator.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EONull.h>
#include <EOControl/EODebug.h>

#include "EOPrivate.h"

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

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_PrivateInit();
    };
}

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
      if (value == nil)
	{
	  value = GDL2_EONull;
	}
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
  NSObject *objectValue;
  NSObject *selfValue=_value;
  BOOL (*imp)(id, SEL, id);

  objectValue = [object valueForKey: _key];

  if (objectValue == nil)
    {
      objectValue = GDL2_EONull;
    }
  if (selfValue == nil)
    {
      selfValue = GDL2_EONull;
    }

  imp = (BOOL (*)(id, SEL, id))[objectValue methodForSelector: _selector];
  if (imp != NULL)
    {
      return (*imp) (objectValue, _selector, selfValue);
    }
  if (sel_isEqual(_selector, EOQualifierOperatorEqual) == YES)
    {
      return [objectValue isEqual: selfValue];
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorNotEqual) == YES)
    {
      return ([objectValue isEqual: selfValue]?NO:YES);
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorLessThan) == YES)
    {
      if (objectValue==GDL2_EONull)
        return ((selfValue==GDL2_EONull) ? NO : YES);
      else if (selfValue==GDL2_EONull)
        return NO;
      else
        return [objectValue compare: selfValue] == NSOrderedAscending;
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorGreaterThan) == YES)
    {
      if (objectValue==GDL2_EONull)
        return NO;
      else if (selfValue==GDL2_EONull)
        return YES;
      else
        return [objectValue compare: selfValue] == NSOrderedDescending;
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorLessThanOrEqualTo) == YES)
    {
      if (objectValue==GDL2_EONull)
        return YES;
      else if (selfValue==GDL2_EONull)
        return NO;
      else
        return [objectValue compare: selfValue] != NSOrderedDescending;
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorGreaterThanOrEqualTo) == YES)
    {
      if (objectValue==GDL2_EONull)
        return ((selfValue==GDL2_EONull) ? YES : NO);
      else if (selfValue==GDL2_EONull)
        return YES;
      else
        return [objectValue compare: selfValue] != NSOrderedAscending;
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorContains) == YES)
    {
      //Philosophical question: does nil contains nil ??

      if (objectValue==GDL2_EONull) // Let's say nil does contain nothing (even not nil)
        return NO;
      else if (selfValue==GDL2_EONull) // Let's say nil is contained by nothing
        return NO;
      else
        return [(NSString*)objectValue rangeOfString: 
                             (NSString*)selfValue].location != NSNotFound;
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorLike) == YES)
    {
      NSEmitTODO();  //TODO
      //How to handle nil like ?
      return [objectValue isEqual: selfValue];
    }
  else if (sel_isEqual(_selector, EOQualifierOperatorCaseInsensitiveLike) == YES)
    {
      NSEmitTODO();  //TODO
      //How to handle nil like ?
      if (objectValue==GDL2_EONull)
        return ((selfValue==GDL2_EONull) ? YES : NO);
      else if (selfValue==GDL2_EONull)
        return NO;
      else
        return [(id)objectValue caseInsensitiveCompare: 
                      (NSString*)selfValue] == NSOrderedSame;
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
  return [NSString stringWithFormat:@"(%@ %@ '%@')",
		   _key,
		   selectorString,
		   _value];
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
  return [NSString stringWithFormat:@"<%s %p - %@ %@ (%@)'%@'>",
		   object_getClassName(self),
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

- (void)addQualifierKeysToSet: (NSMutableSet *)keys
{
  [keys addObject: _key];
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


  if ((self = [self init]))
    {
      NSString *selectorName = [unarchiver decodeObjectForKey: @"selectorName"];

      if (selectorName) 
        _selector = NSSelectorFromString(selectorName);
      
      ASSIGN(_key, [unarchiver decodeObjectForKey: @"key"]);
      ASSIGN(_value, [unarchiver decodeObjectForKey: @"value"]);
    }
  


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
