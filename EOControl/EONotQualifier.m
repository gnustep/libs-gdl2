/** 
   EOOrQualifier.m <title>EOOrQualifier</title>

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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSUtilities.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EOQualifier.h>


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

@end
