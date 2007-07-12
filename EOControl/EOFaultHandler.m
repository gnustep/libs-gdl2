/** 
   EOFaultHandler.m <title>EOFaultHandler Class</title>

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: June 2000

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
#include <Foundation/NSObject.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <Foundation/NSInvocation.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOFault.h>
#include <EOControl/EODebug.h>

#ifndef GNU_RUNTIME
#include <objc/objc-class.h>
#endif

#include <objc/Protocol.h>

@implementation EOFaultHandler

- (id)init
{
  if ((self = [super init]))
    {
    }

  return self;
}

- (void)setTargetClass: (Class)target
             extraData: (void *)data
{
  _targetClass = target;
  _extraData = data;
}

- (Class)targetClass
{
  return _targetClass;
}

- (void *)extraData
{
  return _extraData;
}

- (void)incrementExtraRefCount
{
  _extraRefCount++;
}

- (BOOL)decrementExtraRefCountIsZero
{
  if (!(--_extraRefCount))
    return YES;

  return NO;
}

- (unsigned)extraRefCount
{
  return _extraRefCount;
}

- (NSString *)descriptionForObject: object
{
  return [NSString stringWithFormat: @"%@ (EOFault 0x%08x)",
		   NSStringFromClass(_targetClass), object];
}

- (Class)classForFault: (id)fault
{
  return [self targetClass];
}

- (BOOL)isKindOfClass: (Class)aclass 
             forFault: (id)fault
{
  Class class;

  for (class = _targetClass; class != Nil; class = class_get_super_class(class))
    {
      if (class == aclass)
	return YES;
    }

  return NO;
}

- (BOOL)isMemberOfClass: (Class)aclass 
               forFault: (id)fault
{
  return _targetClass == aclass;
}

- (BOOL)conformsToProtocol: (Protocol *)protocol 
                  forFault: (id)fault
{
  int i;
  struct objc_protocol_list *proto_list;
  Class class;

  for(class = _targetClass; class != Nil; class = class_get_super_class(class))
    {
      for (proto_list =
	     ((struct objc_class *)_targetClass)->class_pointer->protocols;
	   proto_list; proto_list = proto_list->next)
	{
	  for (i = 0; i < proto_list->count; i++)
	    {
	      if ([proto_list->list[i] conformsTo: protocol])
		return YES;
	    }
	}
    }

  return NO;
}

- (BOOL)respondsToSelector: (SEL)sel
                  forFault: (id)fault
{
  [self notImplemented: _cmd];
  return NO;
  //  return __objc_responds_to((id)&self, sel);
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)selector
					 forFault: (id)fault
{ // TODO
  NSMethodSignature *sig;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"_targetClass=%p", _targetClass);
  NSDebugMLLog(@"gsdb", @"_targetClass=%@", _targetClass);
  NSDebugMLLog(@"gsdb", @"selector=%@", NSStringFromSelector(selector));
  //TODO VERIFY
  NSAssert(_targetClass, @"No target class");

  sig = [_targetClass instanceMethodSignatureForSelector: selector];

  NSDebugMLLog(@"gsdb",@"sig=%p", (void*)sig);
  EOFLOGObjectFnStop();

  return sig;
}

- (void)completeInitializationOfObject: (id)object
{
  [self subclassResponsibility: _cmd];
}

- (BOOL)shouldPerformInvocation: (NSInvocation *)invocation
{
  NSDebugFLLog(@"gsdb",@"invocation selector=%@ target: %p",
               NSStringFromSelector([invocation selector]),
               [invocation target]);
  return YES;
}

- (void)faultWillFire: (id)object
{
  return;
}

@end
