/** 
   EOStoredProcedure.m <title>EOStoredProcedure Class</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

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
#include <Foundation/NSException.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <gnustep/base/GCObject.h>

#include <EOControl/EODebug.h>

#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOModel.h>


@implementation EOStoredProcedure

- (EOStoredProcedure *)initWithName:(NSString *)name
{
  self = [super init];

  [self setName:name];
  _userInfo = [NSDictionary new];
  _internalInfo = [NSDictionary new];

  return self;
}

- (void)gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevel(@"gsdb", @"model gcDecrementRefCount");

  [(id)_model gcDecrementRefCount];
  [(id)_arguments gcDecrementRefCount];

  EOFLOGObjectFnStop();
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  if (![super gcIncrementRefCountOfContainedObjects])
    return NO;

  [(id)_model gcIncrementRefCount];
  [(id)_arguments gcIncrementRefCount];

  [(id)_model gcIncrementRefCountOfContainedObjects];
  [(id)_arguments gcIncrementRefCountOfContainedObjects];

  return YES;
}

+ (EOStoredProcedure *)storedProcedureWithPropertyList: (NSDictionary *)propertyList 
                                                 owner: (id)owner
{
  return [[[self alloc] initWithPropertyList: propertyList 
			owner: owner] autorelease];
}

- initWithPropertyList: (NSDictionary *)propertyList owner: (id)owner
{
  NSArray *array;
  NSEnumerator *enumerator;
  id attributePList;

  _model = RETAIN(owner);

  [self setName: [propertyList objectForKey: @"name"]];
  [self setExternalName: [propertyList objectForKey: @"externalName"]];
  [self setUserInfo: [propertyList objectForKey: @"userInfo"]];

  if (!_userInfo)
    [self setUserInfo:[propertyList objectForKey:@"userInfo"]];

  array = [propertyList objectForKey:@"attributes"];
  if ([array count])
    {
      _arguments = [[GCMutableArray alloc] initWithCapacity: [array count]];

      enumerator = [array objectEnumerator];
      while ((attributePList = [enumerator nextObject]))
        {
	  EOAttribute *attribute = [EOAttribute
				     attributeWithPropertyList: attributePList
				     owner: self];

	  [(GCMutableArray *)_arguments addObject: attribute];
        }
    }

  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList
{
  NSEnumerator *argsEnum;
  EOAttribute *attribute;

  argsEnum = [_arguments objectEnumerator];
  while ((attribute = [argsEnum nextObject]))
    [attribute awakeWithPropertyList: propertyList];
}

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList
{
  return;
}

- (NSString *)name
{
  return _name;
}

- (NSString *)externalName
{
  return _externalName;
}

- (EOModel *)model
{
  return _model;
}

- (NSArray *)arguments
{
  return _arguments;
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (void)setName: (NSString *)name
{
  ASSIGN(_name, name);
}

- (void)setExternalName: (NSString *)name
{
  ASSIGN(_externalName, name);
}

- (void)setArguments: (NSArray *)arguments
{
  if ([arguments isKindOfClass: [GCArray class]]
      || [arguments isKindOfClass: [GCMutableArray class]])
    ASSIGN(_arguments, arguments);
  else
    _arguments = [[GCArray alloc] initWithArray: arguments];
}

- (void)setUserInfo: (NSDictionary *)dictionary
{
  ASSIGN(_userInfo, dictionary);
}

@end


@implementation EOStoredProcedure (EOModelBeautifier)

- (void)beautifyName
{
  NSArray	*listItems;
  NSString	*newString = [NSMutableString string];
  int		 anz, i;
  
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOStoredProcedure");
  
  if ((_name) && ([_name length] > 0))
    {
      listItems = [_name componentsSeparatedByString: @"_"];
      newString = [newString stringByAppendingString: [[listItems objectAtIndex: 0]
							lowercaseString]];
      anz = [listItems count];

      for (i = 1; i < anz; i++)
	{
	  newString = [newString stringByAppendingString:
				   [[listItems objectAtIndex: i] capitalizedString]];
	}
 
    NS_DURING
      [self setName: newString];
    NS_HANDLER
      NSLog(@"%@ in Class: EOStoredProcedure , Method: beautifyName >> error : %@",
            [localException name], [localException reason]);
    NS_ENDHANDLER;
  }
  
  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EOStoredProcedure");
}

@end
