/** 
   EOKeyGlobalID.m <title>EOKeyGlobalID Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EODebug.h>
#include <EOControl/EONull.h>


@implementation EOKeyGlobalID

+ (id)globalIDWithEntityName: (NSString *)entityName
			keys: (id *)keys
		    keyCount: (unsigned)count
			zone: (NSZone *)zone
{
  EOKeyGlobalID *gid = AUTORELEASE([[EOKeyGlobalID allocWithZone: zone] init]);
  int i;

  ASSIGN(gid->_entityName, entityName);
  gid->_keyCount = count;

  gid->_keyValues = NSZoneMalloc(zone, count * sizeof(id));

  for (i = 0; i < count; i++)
    {
      gid->_keyValues[i] = nil;
      ASSIGN(gid->_keyValues[i], keys[i]);
    }

  if ([gid areKeysAllNulls])
    NSWarnLog(@"All key of globalID %p (%@) are nulls",
              gid,
              gid);

  return gid;
}

- (void)dealloc
{
  int i;

  for (i = 0; i < _keyCount; i++)
    DESTROY(_keyValues[i]);

  NSZoneFree(NULL, _keyValues);

  DESTROY(_entityName);

  [super dealloc];
}

- (NSString *)entityName
{
  return _entityName;
}

- (id *)keyValues
{
  return _keyValues;
}

- (unsigned)keyCount
{
  return _keyCount;
}

- (NSArray *)keyValuesArray
{
  return [NSArray arrayWithObjects: _keyValues count: _keyCount];
}

- (BOOL)isEqual: other
{
  unsigned short oCount;
  int i;
  id *oValues;

  if (self == other)
    return YES;

  if ([self hash] != [other hash])
    return NO;

  if ([_entityName isEqualToString: [other entityName]] == NO)
    return NO;

  oCount = [other keyCount];
  oValues = [other keyValues];

  for (i = 0; i < oCount; i++)
    if ([_keyValues[i] isEqual: oValues[i]] == NO)
      return NO;

  return YES;
}


- (unsigned int)hash // TODO
{
  int i;
  unsigned int hash = 0;

  for (i = 0; i < _keyCount; i++)
    hash += [_keyValues[i] hash];

  hash += [_entityName hash];

  return hash;
}

- (void)encodeWithCoder: (NSCoder *)coder
{
  [coder encodeValueOfObjCType: @encode(unsigned short) at: &_keyCount];
  [coder encodeObject: _entityName];
  [coder encodeArrayOfObjCType: @encode(id) count: _keyCount at: _keyValues];
}

- (id)initWithCoder: (NSCoder *)coder
{
  self = [super init];

  [coder decodeValueOfObjCType: @encode(unsigned short) at: &_keyCount];
  _entityName = RETAIN([coder decodeObject]);

  _keyValues = NSZoneMalloc([coder objectZone], _keyCount);
  [coder decodeArrayOfObjCType: @encode(id) count: _keyCount at: _keyValues];

  return self;
}

- (id)copyWithZone: (NSZone *)zone
{
  EOKeyGlobalID *gid = [super copyWithZone: zone];
  int i;

  ASSIGN(gid->_entityName, _entityName);
  gid->_keyCount = _keyCount;

  gid->_keyValues = NSZoneMalloc(zone, _keyCount * sizeof(id));

  for (i = 0; i < _keyCount; i++)
    {
      gid->_keyValues[i] = nil;
      ASSIGN(gid->_keyValues[i], _keyValues[i]);
    }

  return gid;
}

- (BOOL) isFinal
{
//  [self notImplemented:_cmd]; //TODO
  return YES;
}

- (NSString*)description
{
  NSString *dscr;
  int i;

  dscr = [NSString stringWithFormat: @"<%s %p - Entity %@ - keysValues:",
		   object_get_class_name(self),
		   (void*)self,
                   _entityName];

  for(i = 0; i < _keyCount; i++)
    {
      dscr = [dscr stringByAppendingFormat: @"\"%@\" (%@) ",
                   _keyValues[i],
                   [_keyValues[i] class]];
    }
  dscr = [dscr stringByAppendingString: @">"];

  return dscr;
}

-(BOOL)areKeysAllNulls
{
  int i;
  BOOL areNulls = YES;

  for (i = 0; areNulls && i < _keyCount; i++)
    areNulls = isNilOrEONull(_keyValues[i]);

  return areNulls;
}

@end
