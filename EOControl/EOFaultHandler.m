/** 
   EOFaultHandler.m <title>EOFaultHandler Class</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#import <Foundation/NSObject.h>
#import <Foundation/NSUtilities.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSDebug.h>
#import <Foundation/NSException.h>

#import <gnustep/base/GCObject.h>

#import <EOControl/EOFault.h>
#import <EOControl/EODebug.h>

#ifndef GNU_RUNTIME
#include <objc/objc-class.h>
#endif

#include <objc/Protocol.h>


BOOL __isGCEnabled(Class class_)
{
  Class gcObjectClass = [GCObject class];

  if ([class_ instancesRespondToSelector: @selector(gcIncrementRefCount)])
    return YES;
  else
    {
      Class class;

      for (class = class_; 
	   class != Nil;
	   class = class_get_super_class (class))
	{
	  if (class == gcObjectClass)
	    return YES;
	  else if ([class instancesRespondToSelector: @selector(gcIncrementRefCount)])
	      return YES;
	  else if ([class instancesRespondToSelector: @selector(gcNextObject)])
	      return YES;
	}
    }

  return NO;
}


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

  gcEnabled = __isGCEnabled(_targetClass);

  if (gcEnabled)
    _extraRefCount++;
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

- (BOOL)decrementExtraRefCountWasZero
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
  return YES;
}

- (void)faultWillFire: (id)object
{
  return;
}

// GC

+ allocWithZone: (NSZone *)zone_
{
  id newObject = [super allocWithZone: zone_];

  ((EOFaultHandler *)newObject)->gc.flags.refCount = 0;

  return newObject;
}

/*
- retain
{
  if (gcEnabled)
	{
	  gc.flags.refCount++;
	  return self;
	}
  else
	{
	  return [super retain];
	};
}

- (unsigned int)retainCount
{
  if (gcEnabled)
	{
	  return gc.flags.refCount;
	}
  else
	{
	  return [super retainCount];
	};
}
*/
- gcSetNextObject: (id)anObject
{
  if (gcEnabled)
    gc.next = anObject;

  return self;
}

- gcSetPreviousObject: (id)anObject
{
  if (gcEnabled)
    gc.previous = anObject;

  return self;
}

- (id)gcNextObject
{
  if (gcEnabled)
    return gc.next;

  return nil;
}

- (id)gcPreviousObject
{
  if (gcEnabled)
    return gc.previous;

  return nil;
}

- (BOOL)gcAlreadyVisited
{
  if (gcEnabled)
    return gc.flags.visited;

  return YES;
}

- (void)gcSetVisited: (BOOL)flag
{
  if (gcEnabled)
    gc.flags.visited = flag;
}

- (void)gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  if (gcEnabled)
    gcCountainedObjectRefCount--;

  EOFLOGObjectFnStop();
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  if (gcEnabled)
    {
      if (gc.flags.visited)
	return NO;

      gcCountainedObjectRefCount++;
      gc.flags.visited = YES;

      return YES;
    }

  return NO;
}

- (BOOL)isGarbageCollectable
{
  return gcEnabled;
}

- (void)gcIncrementRefCount
{
  if (gcEnabled);
  //gc.flags.refCount++;
  //    faultReferences++;
}

- (void)gcDecrementRefCount
{
  if(gcEnabled);
  //gc.flags.refCount--;
  //    faultReferences--;
}

/*
- (BOOL)afterFault
{
  if (gcEnabled)
    {
      [fault gcIncrementRefCount];
      fault->gc.next = gc.next;
      fault->gc.previous = gc.previous;
      while (gcCountainedObjectRefCount-- > 0)
	{
	  [fault gcIncrementRefCountOfContainedObjects];
	}
    };
  return NO;
}
*/

@end
