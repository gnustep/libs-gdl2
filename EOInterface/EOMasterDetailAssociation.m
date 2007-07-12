/**
   EOMasterDetailAssociation.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 3, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODetailDataSource.h>

#include "EODisplayGroup.h"
#include "EOMasterDetailAssociation.h"
#include "SubclassFlags.h"

@implementation EOMasterDetailAssociation

+ (NSArray *)aspects
{
  static NSArray *_aspects = nil;
  if (_aspects == nil)
    {
      _aspects
        = RETAIN ([[super aspects] arrayByAddingObject: @"parent"]);
    }
  return _aspects;
}

+ (NSArray *)aspectSignatures
{
  static NSArray *_signatures = nil;
  if (_signatures == nil)
    {
      _signatures
        = RETAIN ([[super aspectSignatures] arrayByAddingObject: @"1M"]);
    }
  return _signatures;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return [object isKindOfClass: [EODisplayGroup class]]
    && [[object dataSource] isKindOfClass: [EODetailDataSource class]];
}

+ (NSString *)displayName
{
  return @"EOMasterDetailAssoc";
}

+ (NSString *)primaryAspect
{
  return @"parent";
}

- (void)establishConnection
{
  EODisplayGroup *parent = [self displayGroupForAspect:@"parent"];

  [super establishConnection];
  if (parent)
    {
      EODetailDataSource *ds = (id)[_object dataSource];
      subclassFlags |= ParentAspectMask;
      [ds setMasterClassDescription:[[parent dataSource]
	      				classDescriptionForObjects]];
      [ds setDetailKey:[self displayGroupKeyForAspect:@"parent"]];
    }
}

- (void)breakConnection
{
  [super breakConnection];
  subclassFlags = 0;
}

- (void)subjectChanged
{
  if (subclassFlags & ParentAspectMask)
    {
      id selectedObject = [[self displayGroupForAspect:@"parent"]
	      				selectedObject];
      id key = [self displayGroupKeyForAspect:@"parent"];
      [[_object dataSource]
	    qualifyWithRelationshipKey:key
		    	      ofObject:selectedObject];
      if ([_object fetch])
	[_object redisplay];
    }
}

- (EOObserverPriority)priority
{
  return EOObserverPrioritySecond;
}

@end
