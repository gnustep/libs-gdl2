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

static char rcsId[] = "$Id$";

#import <Foundation/NSDictionary.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSUtilities.h>

#import <EOControl/EOQualifier.h>


@implementation EONotQualifier

+ (EOQualifier *)qualifierWithQualifier: (EOQualifier *)qualifier
{
  return [[[self alloc] initWithQualifier: qualifier] autorelease];
}

- initWithQualifier: (EOQualifier *)qualifier
{
  self = [super init];

  ASSIGN(_qualifier, qualifier);

  return self;
}

- (EOQualifier *)qualifier
{
  return _qualifier;
}

- (id)copyWithZone: (NSZone *)zone
{
  EONotQualifier *qual = [[EONotQualifier alloc] init];

  qual->_qualifier = [_qualifier copyWithZone: zone];

  return qual;
}

- (BOOL)evaluateWithObject: (id)object
{
  //TODO
  [self notImplemented: _cmd];
  return NO;
}

@end
