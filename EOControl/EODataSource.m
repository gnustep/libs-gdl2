/** 
   EODataSource.m <title>EODataSource Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: July 2000

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


#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EODataSource.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EODebug.h>

#include <string.h>


@implementation EODataSource

- (id)createObject
{
  id object;
  EOClassDescription *cd;
  EOEditingContext *receiverEdCtxt;

  EOFLOGObjectFnStart();

  cd = [self classDescriptionForObjects];
  EOFLOGObjectLevelArgs(@"EODataSource", @"cd=%@", cd);

  object = [cd createInstanceWithEditingContext: nil
               globalID: nil
               zone: NULL];

  EOFLOGObjectLevelArgs(@"EODataSource", @"object=%@", object);

  if (object && (receiverEdCtxt = [self editingContext])) 
    [receiverEdCtxt insertObject: object];

  EOFLOGObjectFnStop();

  return object;
}

- (void)insertObject: object
{
  [self subclassResponsibility: _cmd];
}

- (void)deleteObject: object
{
  [self subclassResponsibility: _cmd];
}

- (NSArray *)fetchObjects
{
  return nil;
}

- (EOEditingContext *)editingContext
{
  return nil;
}

- (void)qualifyWithRelationshipKey: (NSString *)key ofObject: sourceObject
{
  [self subclassResponsibility: _cmd];
}

- (EODataSource *)dataSourceQualifiedByKey: (NSString *)key
{
  [self subclassResponsibility: _cmd];

  return nil;
}

- (EOClassDescription *)classDescriptionForObjects
{
  return nil;
}

- (NSArray *)qualifierBindingKeys
{
  return nil;
}

- (void)setQualifierBindings: (NSDictionary *)bindings
{
}

- (NSDictionary *)qualifierBindings
{
  return nil;
}

@end
