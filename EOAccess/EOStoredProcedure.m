/** 
   EOStoredProcedure.m <title>EOStoredProcedure Class</title>

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

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
   version 3 of the License, or (at your option) any later version.

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
#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

#include <EOControl/EODebug.h>
#include <EOControl/EOObserver.h>

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

+ (EOStoredProcedure *)storedProcedureWithPropertyList: (NSDictionary *)propertyList 
                                                 owner: (id)owner
{
  return [[[self alloc] initWithPropertyList: propertyList 
			owner: owner] autorelease];
}

- (id)initWithPropertyList: (NSDictionary *)propertyList owner: (id)owner
{
  NSArray *array;
  NSEnumerator *enumerator;
  id attributePList;

  _model = owner;

  [self setName: [propertyList objectForKey: @"name"]];
  [self setExternalName: [propertyList objectForKey: @"externalName"]];
  [self setUserInfo: [propertyList objectForKey: @"userInfo"]];

  if (!_userInfo)
    [self setUserInfo:[propertyList objectForKey:@"userInfo"]];

  array = [propertyList objectForKey:@"arguments"];
  if (!array)
    {
      array = [propertyList objectForKey:@"attributes"];
      if (array)
        {
	  NSLog(@"warning found 'attributes' key in property list you should"
		@"fix your model files to use the 'arguments' key!!");
	}
    }
  if ([array count])
    {
      _arguments = [[NSMutableArray alloc] initWithCapacity: [array count]];

      enumerator = [array objectEnumerator];
      while ((attributePList = [enumerator nextObject]))
        {
	  EOAttribute *attribute 
	    = [EOAttribute attributeWithPropertyList: attributePList
			   owner: self];
	  [attribute awakeWithPropertyList: attributePList];
	  [(NSMutableArray *)_arguments addObject: attribute];
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
  unsigned i, count;

  if (_name)
    {
      [propertyList setObject: _name forKey: @"name"];
    }

  if (_externalName)
    {
      [propertyList setObject: _externalName forKey: @"externalName"];
    }

  if (_userInfo)
    {
      [propertyList setObject: _userInfo forKey: @"userInfo"];
    }

  if ((count = [_arguments count]))
    {
      NSMutableArray *attributesPList 
	= [NSMutableArray arrayWithCapacity: count];

      for (i = 0; i < count; i++)
	{
	  NSMutableDictionary *attributePList 
	    = [NSMutableDictionary dictionary];
	  EOAttribute *attribute
	    = [_arguments objectAtIndex: i];

	  [attribute encodeIntoPropertyList: attributePList];
	  [attributesPList addObject: attributePList];
	}

      [propertyList setObject: attributesPList forKey: @"arguments"];
    }
}

- (NSString*) description
{
  NSMutableDictionary *plist;

  plist = [NSMutableDictionary dictionaryWithCapacity: 6];
  [self encodeIntoPropertyList: plist];

  return [plist description];
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
  [self willChange];
  ASSIGNCOPY(_name, name);
}

- (void)setExternalName: (NSString *)name
{
  [self willChange];
  ASSIGNCOPY(_externalName, name);
}

- (void)setArguments: (NSArray *)arguments
{
  [self willChange];
  ASSIGNCOPY(_arguments, arguments);
}

- (void)setUserInfo: (NSDictionary *)dictionary
{
  [self willChange];
  ASSIGN(_userInfo, dictionary);
}

@end


@implementation EOStoredProcedure (EOModelBeautifier)

- (void)beautifyName
{
  NSArray  *listItems;
  NSString *newString = [NSMutableString string];
  NSString *tmpString;
  unsigned  anz, i;
  
  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EOStoredProcedure");
  
  if ((_name) && ([_name length] > 0))
    {
      listItems = [_name componentsSeparatedByString: @"_"];
      tmpString = [listItems objectAtIndex: 0];
      tmpString = [tmpString lowercaseString];
      newString = [newString stringByAppendingString: tmpString];
      anz = [listItems count];

      for (i = 1; i < anz; i++)
	{
	  tmpString = [listItems objectAtIndex: i];
	  tmpString = [tmpString capitalizedString];
	  newString = [newString stringByAppendingString: tmpString];
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

@implementation EOStoredProcedure (privat)
- (void)_setIsEdited
{
}
@end
