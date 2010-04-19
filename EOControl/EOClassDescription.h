/* -*-objc-*-
   EOClassDescription.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOClassDescription_h__
#define __EOClassDescription_h__

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSZone.h>
#else
#include <Foundation/Foundation.h>
#endif

#import <Foundation/NSClassDescription.h>

#include <EOControl/EODefines.h>

@class NSDictionary;
@class EOEditingContext;
@class NSFormatter;
@class EOGlobalID;
@class NSMutableDictionary;
@class EORelationship;

typedef enum
{
  EODeleteRuleNullify = 0,
  EODeleteRuleCascade,
  EODeleteRuleDeny,
  EODeleteRuleNoAction
} EODeleteRule;


@interface EOClassDescription : NSClassDescription

+ (void)registerClassDescription: (EOClassDescription *)description
                        forClass: (Class)aClass;

+ (void)invalidateClassDescriptionCache;

+ (EOClassDescription *)classDescriptionForClass: (Class)aClass;

+ (EOClassDescription *)classDescriptionForEntityName: (NSString *)entityName;

+ (void)setClassDelegate: (id)delegate;
+ (id)classDelegate;

/*
 * Subclass responsibility.
 */
- (NSString *)entityName;

- (id)createInstanceWithEditingContext: (EOEditingContext *)editingContext
			      globalID: (EOGlobalID *)globalID
				  zone: (NSZone *)zone;

- (void)awakeObject: (id)object
fromInsertionInEditingContext: (EOEditingContext *)editingContext;

- (void)awakeObject: (id)object
fromFetchInEditingContext: (EOEditingContext *)editingContext;

- (void)propagateDeleteForObject: (id)object
		  editingContext: (EOEditingContext *)editingContext;

- (NSArray *)attributeKeys;
- (NSArray *)toOneRelationshipKeys;
- (NSArray *)toManyRelationshipKeys;

/** returns a new autoreleased mutable dictionary to store properties **/
- (NSMutableDictionary *)dictionaryForInstanceProperties;

- (EORelationship *)relationshipNamed: (NSString *)relationshipName;
- (EORelationship *)anyRelationshipNamed: (NSString *)relationshipName;

- (NSString *)inverseForRelationshipKey: (NSString *)relationshipKey;

- (EODeleteRule)deleteRuleForRelationshipKey: (NSString *)relationshipKey;

- (BOOL)ownsDestinationObjectsForRelationshipKey: (NSString *)relationshipKey;

- (EOClassDescription *)classDescriptionForDestinationKey: (NSString *)detailKey;

- (NSFormatter *)defaultFormatterForKey: (NSString *)key;

- (NSString *)displayNameForKey: (NSString *)key;

- (NSString *)userPresentableDescriptionForObject: (id)object;

- (NSException *)validateValue: (id *)valueP forKey: (NSString *)key;

- (NSException *)validateObjectForSave: (id)object;

- (NSException *)validateObjectForDelete: (id)object;

@end


GDL2CONTROL_EXPORT NSString *EOClassDescriptionNeededNotification;
GDL2CONTROL_EXPORT NSString *EOClassDescriptionNeededForClassNotification;
GDL2CONTROL_EXPORT NSString *EOClassDescriptionNeededForEntityNameNotification;


@interface NSArray (EOShallowCopy)

- (NSArray *)shallowCopy;

@end

/*
 * Validation exceptions (with name EOValidationException)
 */
GDL2CONTROL_EXPORT NSString *EOValidationException;
GDL2CONTROL_EXPORT NSString *EOAdditionalExceptionsKey;
GDL2CONTROL_EXPORT NSString *EOValidatedObjectUserInfoKey;
GDL2CONTROL_EXPORT NSString *EOValidatedPropertyUserInfoKey;

@interface NSException (EOValidationError)

+ (NSException *)validationExceptionWithFormat: (NSString *)format, ...;
+ (NSException *)aggregateExceptionWithExceptions: (NSArray *)subexceptions;
- (NSException *)exceptionAddingEntriesToUserInfo: (NSDictionary *)additions;

@end

@interface NSObject (EOClassDescriptionClassDelegate)

- (BOOL)shouldPropagateDeleteForObject: (id)object
		      inEditingContext: (EOEditingContext *)editingContext
		    forRelationshipKey: (NSString *)key;

@end

#endif
