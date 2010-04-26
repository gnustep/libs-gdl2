/* -*-objc-*-
   EOGenericRecord.m <title>EOGenericRecord Category</title>

   Copyright (C) 2009 Free Software Foundation, Inc.

   Author: David Ayers
   Date: February 2009

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

#include "config.h"

RCS_ID("$Id: EOEntity.m 27910 2009-02-18 05:52:42Z ayers $")

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#endif

#include <EOAccess/EOEntity.h>

#include <EOControl/EOGenericRecord.h>

@implementation EOGenericRecord (EOAccessAdditions)
/**
 * Determins and returns the receivers entity.
 */
- (EOEntity *)entity
{
  if ([classDescription respondsToSelector:@selector(entity)])
    return [(EOEntityClassDescription *)classDescription entity];
  return nil;
}
@end
