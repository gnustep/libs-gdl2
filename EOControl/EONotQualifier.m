/** 
   EOOrQualifier.m <title>EONotQualifier</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

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
   version 2 of the License, or (at your option) any later version.

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
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EOQualifier.h>

@interface EOQualifier (Privat)
- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary;
@end

@implementation EONotQualifier

/**
 * Returns an autoreleased EONotQualifier referencing qualifiers.  This method
 * calls [EONotQualifier-initWithQualifier:].
 */
+ (EOQualifier *)qualifierWithQualifier: (EOQualifier *)qualifier
{
  return [[[self alloc] initWithQualifier: qualifier] autorelease];
}

/** <init />
 * Initializes the receiver with the provided qualifier.
 */
- initWithQualifier: (EOQualifier *)qualifier
{
  self = [super init];

  ASSIGN(_qualifier, qualifier);

  return self;
}

/**
 * Returns the qualifier the reciever negates.
 */
- (EOQualifier *)qualifier
{
  return _qualifier;
}

/**
 * EOQualifierEvaluation protocol
 * Returns YES if qualifier the receivers refernces returns NO on
 * [EOQualifierEvaluation-evaluateWithObjects:] with object.  Returns NO
 * otherwise.  
 */
- (BOOL)evaluateWithObject: (id)object
{
  return ([_qualifier evaluateWithObject: object] ? NO : YES);
}

- (NSException *) validateKeysWithRootClassDescription:(EOClassDescription*)classDescription
{
  return [_qualifier validateKeysWithRootClassDescription:classDescription];
}

- (EOQualifier *) qualifierWithBindings: (NSDictionary *)bindings
                   requiresAllVariables: (BOOL)requiresAllVariables
{
  EOQualifier* resultQualifier
    = [_qualifier qualifierWithBindings: bindings
		  requiresAllVariables: requiresAllVariables];
  if (resultQualifier==_qualifier)
    resultQualifier=self;
  else if (resultQualifier)
    resultQualifier=[[self class]qualifierWithQualifier:resultQualifier];
  return resultQualifier;
}

- (void) _addBindingsToDictionary: (NSMutableDictionary*)dictionary
{
  [_qualifier _addBindingsToDictionary:dictionary];
}

- (void)addQualifierKeysToSet: (NSMutableSet *)keys
{
  [_qualifier addQualifierKeysToSet: keys];
}

@end
