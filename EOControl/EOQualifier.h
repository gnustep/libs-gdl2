/* 
   EOQualifier.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOQualifier_h__
#define __EOQualifier_h__

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EOKeyValueArchiver.h>


@class NSArray;
@class NSDictionary;
@class NSString;
@class NSException;

@class EOClassDescription;
@class EOSQLExpression;
@class EOQualifier;
@class EOEntity;


@interface EOQualifier : NSObject <NSCopying>
{
}

+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)qualifierFormat, ...;

+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)format
                                    arguments: (NSArray *)args;

+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)format
                                   varargList: (va_list)args;

+ (EOQualifier *)qualifierToMatchAllValues: (NSDictionary *)values;
+ (EOQualifier *)qualifierToMatchAnyValue: (NSDictionary *)values;

- (NSException *)validateKeysWithRootClassDescription: (EOClassDescription *)classDesc;

+ (NSArray *)allQualifierOperators;

+ (NSArray *)relationalQualifierOperators;

+ (NSString *)stringForOperatorSelector: (SEL)selector;
+ (SEL)operatorSelectorForString: (NSString *)string;

- (EOQualifier *)qualifierByApplyingBindings: (id)bindings;

- (EOQualifier *)qualifierByApplyingBindingsAllVariablesRequired: (id)bindings;

- (EOQualifier *)qualifierWithBindings: (NSDictionary *)bindings
		  requiresAllVariables: (BOOL)requiresAll;

- (NSArray *)bindingKeys;
- (NSString *)keyPathForBindingKey: (NSString *)key;

- (BOOL)evaluateWithObject: (id)object;

@end


@interface EOQualifier (EOModelExtensions)

- (EOQualifier *)qualifierMigratedFromEntity: (EOEntity *)entity 
                            relationshipPath: (NSString *)relationshipPath;

@end


@protocol EOQualifierEvaluation

- (BOOL)evaluateWithObject: object;

@end


@interface NSObject (EORelationalSelectors)

- (BOOL)isEqualTo: (id)object;
- (BOOL)isLessThanOrEqualTo: (id)object;
- (BOOL)isLessThan: (id)object;
- (BOOL)isGreaterThanOrEqualTo: (id)object;
- (BOOL)isGreaterThan: (id)object;
- (BOOL)isNotEqualTo: (id)object;
- (BOOL)doesContain: (id)object;
- (BOOL)isLike: (NSString *)object;
- (BOOL)isCaseInsensitiveLike: (NSString *)object;

@end


#define EOQualifierOperatorEqual @selector(isEqualTo:)
#define EOQualifierOperatorNotEqual @selector(isNotEqualTo:)
#define EOQualifierOperatorLessThan @selector(isLessThan:)
#define EOQualifierOperatorGreaterThan @selector(isGreaterThan:)
#define EOQualifierOperatorLessThanOrEqualTo @selector(isLessThanOrEqualTo:)
#define EOQualifierOperatorGreaterThanOrEqualTo @selector(isGreaterThanOrEqualTo:)
#define EOQualifierOperatorContains @selector(doesContain:)
#define EOQualifierOperatorLike @selector(isLike:)
#define EOQualifierOperatorCaseInsensitiveLike @selector(isCaseInsensitiveLike:)


@interface EOKeyValueQualifier:EOQualifier <EOQualifierEvaluation>
{
  SEL _selector;
  NSString *_key;
  id _value;
}

+ (EOKeyValueQualifier*)qualifierWithKey: (NSString *)key
			operatorSelector: (SEL)selector
				   value: (id)value;

- (id)  initWithKey: (NSString *)key
   operatorSelector: (SEL)selector
              value: (id)value;
- (SEL)selector;
- (NSString *)key;
- (id)value;

@end

@interface EOKeyComparisonQualifier:EOQualifier <EOQualifierEvaluation>
{
  SEL _selector;
  NSString *_leftKey;
  NSString *_rightKey;
}

+ (EOQualifier*)qualifierWithLeftKey: (NSString *)leftKey
		    operatorSelector: (SEL)selector
			    rightKey: (id)rightKey;

- initWithLeftKey: (NSString *)leftKey
 operatorSelector: (SEL)selector
	 rightKey: (id)rightKey;
- (SEL)selector;
- (NSString *)leftKey;
- (NSString *)rightKey;

@end


@interface EOAndQualifier : EOQualifier <EOQualifierEvaluation>
{
  NSArray *_qualifiers;
}

+ (EOQualifier *)qualifierWithQualifierArray: (NSArray *)array;
+ (EOQualifier *)qualifierWithQualifiers: (EOQualifier *)qualifiers, ...;

- initWithQualifiers: (EOQualifier *)qualifiers, ...;
- initWithQualifierArray: (NSArray *)array;

- (NSArray *)qualifiers;

@end


@interface EOOrQualifier:EOQualifier <EOQualifierEvaluation>
{
  NSArray *_qualifiers;
}

+ (EOQualifier *)qualifierWithQualifierArray: (NSArray *)array;
+ (EOQualifier *)qualifierWithQualifiers: (EOQualifier *)qualifiers, ...;

- initWithQualifiers: (EOQualifier *)qualifiers, ...;
- initWithQualifierArray: (NSArray *)array;

- (NSArray *)qualifiers;

@end


@interface EONotQualifier:EOQualifier <EOQualifierEvaluation>
{
  EOQualifier *_qualifier;
}

+ (EOQualifier *)qualifierWithQualifier: (EOQualifier *)qualifier;

- initWithQualifier: (EOQualifier *)qualifier;

- (EOQualifier *)qualifier;

@end

extern NSString *EOQualifierVariableSubstitutionException;


@interface EOQualifierVariable:NSObject <NSCoding, EOKeyValueArchiving>
{
  NSString *_key;
}

+ (EOQualifierVariable *)variableWithKey: (NSString *)key;
- (EOQualifierVariable *)initWithKey: (NSString *)key;
- (NSString *)key;

- (id)valueByApplyingBindings: (id)bindings;

- (id)requiredValueByApplyingBindings: (id)bindings;

@end


@interface NSArray (EOQualifierExtras)
- (NSArray *)filteredArrayUsingQualifier: (EOQualifier *)qualifier;
@end


#endif
