/** 
   EOFault.m <title>EOFault Class</title>

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: 1996

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
#include <Foundation/NSObject.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <objc/Protocol.h>

#include <EOControl/EOFault.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EODebug.h>

/*
 * EOFault class
 */

@implementation EOFault

static Class EOFaultClass = NULL;

+ (void)initialize
{
  // Must be here as initialize is called for each root class
  // without asking if it responds to it !
  if (EOFaultClass == NULL)
    {
      EOFaultClass = [EOFault class];
    }
}

+ (Class)superclass
{
  return GSObjCSuper(self);
}

+ (Class)class
{
  return self;
}

+ self
{
  return self;
}

+ (id)retain
{
  return self;
}

+ (void)release
{
  return;
}

+ (id)autorelease
{
  return self;
}

+ (unsigned)retainCount
{
  return UINT_MAX;
}

+ (BOOL)isKindOfClass: (Class)aClass
{
  if (aClass == EOFaultClass)
    return YES;

  return NO;
}

+ (void)doesNotRecognizeSelector: (SEL)sel
{
  [NSException raise: NSInvalidArgumentException
	       format: @"%@ -- %@ 0x%x: selector \"%@\" not recognized",
	       NSStringFromSelector(_cmd),
	       NSStringFromClass([self class]),
	       self,
	       NSStringFromSelector(sel)];
}

+ (BOOL)respondsToSelector: (SEL)sel
{
  return (GSGetInstanceMethod(self, sel) != (GSMethod)0);
}


// Fault class methods

+ (void)makeObjectIntoFault: (id)object
                withHandler: (EOFaultHandler *)handler
{
  if (object)
    {
      EOFault *fault = object;
      unsigned int refs;

      NSAssert(handler, @"No Handler");

      refs = [object retainCount];
      
      [handler setTargetClass: [object class]
               extraData: fault->_handler];
      fault->isa = self;
      fault->_handler = [handler retain];
      
      while (refs-- > 0)
        [fault retain];
    }
}

+ (BOOL)isFault: (id)object
{
//  NSDebugFLLog(@"gsdb",@"object=%p",object);

  if (object == nil)
    return NO;
  else
    return ((EOFault *)object)->isa == self;
}

+ (void)clearFault: (id)fault
{
  EOFaultHandler *handler;
  EOFault *aFault = (EOFault *)fault;
  BOOL gcEnabled = NO;
  unsigned gcCountainedObjectRefCount = 0;
  int refs = 0;

  NSDebugFLLog(@"gsdb", @"START fault=%p", fault);

  if ([EOFaultClass isFault:fault] == NO)
    {
//REVOIR!!!
/*
      [NSException raise:NSInvalidArgumentException
                   format:@"%@ -- %@ 0x%x: object %@ of class %@ is not a fault object", 
                   NSStringFromSelector(_cmd), 
                   NSStringFromClass([self class]),
                   self,
                   fault,
                   [fault class]];
*/
    }
  else
    {
      handler = aFault->_handler;
      
      [handler faultWillFire: fault];
      
      refs = [handler extraRefCount];
      gcEnabled = [handler isGarbageCollectable];
      gcCountainedObjectRefCount = aFault->_handler->gcCountainedObjectRefCount;

      aFault->isa = [handler targetClass];
      aFault->_handler = [handler extraData];

      [handler autorelease];

      refs -= [fault retainCount];

      if (refs > 0)
        while (refs-- > 0)
          [aFault retain];
      else
        while (refs++ < 0)
          [aFault release];

      if(gcEnabled)
        {
          [aFault gcIncrementRefCount];
          [aFault gcSetNextObject: [self gcNextObject]];
          [aFault gcSetPreviousObject: [self gcPreviousObject]];
          
          while (gcCountainedObjectRefCount-- > 0)
            [aFault gcIncrementRefCountOfContainedObjects];
        }
    }

  NSDebugFLLog(@"gsdb", @"STOP fault=%p", fault);
}

+ (EOFaultHandler *)handlerForFault:(id)fault
{
  BOOL isFault = [EOFaultClass isFault: fault];

  NSDebugFLLog(@"gsdb", @"object %p is%s a fault", fault,
	       (isFault ? "" : " not"));

  if (isFault)
    return ((EOFault *)fault)->_handler;
  else
    return nil;
}

+ (Class)targetClassForFault: (id)fault
{
  if ([EOFaultClass isFault:fault])
    return [((EOFault *)fault)->_handler targetClass];
  else
    return nil;
}


// Fault Instance methods

- superclass
{
  return [[_handler targetClass] superclass];
}

- (Class)class
{
  return [_handler targetClass];
}

- (BOOL)isKindOfClass: (Class)aclass;
{
  Class class;
  BOOL koc=NO;

  class = [_handler targetClass];

  for (; !koc && class != Nil; class = GSObjCSuper(class))
    if (class == aclass)
      koc = YES;

  return koc;
}

- (BOOL)isMemberOfClass: (Class)aclass
{
  return [_handler targetClass] == aclass;
}

- (BOOL)conformsToProtocol: (Protocol *)protocol
{
  int i;
  struct objc_protocol_list* protos;
  Class class, sClass;

  class = [_handler targetClass];

  for (protos = class->protocols; protos; protos = protos->next)
    {
      for (i = 0; i < protos->count; i++)
	if ([protos->list[i] conformsTo: protocol])
	  return YES;
    }

  sClass = [class superclass];

  if (sClass)
    return [sClass conformsToProtocol: protocol];
  else
    return NO;
}

- (BOOL)respondsToSelector: (SEL)aSelector
{
  Class class;
  BOOL respondsToSelector;

  NSDebugFLLog(@"gsdb", @"START self=%p", self);

  class = [_handler targetClass];
  NSDebugFLLog(@"gsdb", @"class=%@ aSelector=%@", class,
	       NSStringFromSelector(aSelector));

  respondsToSelector = (GSGetInstanceMethod(class, aSelector) != (GSMethod)0);
  NSDebugFLLog(@"gsdb", @"STOP self=%p", self);

  return respondsToSelector;
}

- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSelector
{
  NSMethodSignature *sig;

  NSDebugFLLog(@"gsdb", @"START self=%p", self);
  NSDebugFLLog(@"gsdb", @"_handler=%p", _handler);

  sig = [_handler methodSignatureForSelector: aSelector
		  forFault: self];

  NSDebugFLLog(@"gsdb", @"STOP self=%p", self);

  return sig;
}

- retain
{
  [_handler incrementExtraRefCount];

  return self;
}

- (void)release
{
  if ([_handler extraRefCount] <= 0)
    [self dealloc];
  else
    [_handler decrementExtraRefCountWasZero];
}

- autorelease
{
  [NSAutoreleasePool addObject: self];

  return self;
}

- (unsigned)retainCount
{
  return [_handler extraRefCount];
}

- (NSString *)description
{
  return [_handler descriptionForObject: self];
}

- (NSString *)descriptionWithIndent: (unsigned)level
{
  return [self description];
}

- (NSString *)descriptionWithLocale: (NSDictionary *)locale
{
  //OK
  return [self description];
}

- (NSString *)descriptionWithLocale: (NSDictionary *)locale
			     indent: (unsigned)level
{
  return [self description];
}

- (NSString *)eoDescription
{
  return [self description];
}

- (NSString *)eoShallowDescription
{
  return [self description];
}

- (EOKeyGlobalID *)globalID
{
  if ([_handler respondsToSelector: @selector(globalID)])
    return [(id)_handler globalID];
  else
    {
      [_handler completeInitializationOfObject: self];
      return [self globalID];
    }
}

- (EOEditingContext *)editingContext
{
  return [_handler editingContext];
}

/*
- (EOKeyGlobalID *)sourceGlobalID;
- (NSString *)relationshipName;
*/

- (void)dealloc
{
#ifdef DEBUG
  NSDebugFLog(@"Dealloc EOFault %p. %@",
              (void*)self,GSCurrentThread());
#endif
  [EOFaultClass clearFault: self];
  NSDebugMLog(@"EOFault dealloc self=%p",self);
  if (![EOFaultClass isFault:self]) // otherwise, this loop. 
    [self dealloc];
#ifdef DEBUG
  NSDebugFLog(@"Stop Dealloc EOFault %p. %@",
              (void*)self,GSCurrentThread());
#endif
}

- (NSZone *)zone
{
  return NSZoneFromPointer(self);
}

- (BOOL)isProxy
{
  return NO;
}

- (id)self
{
  [_handler completeInitializationOfObject: self];

  return self;
}

- (void)doesNotRecognizeSelector: (SEL)sel
{
  [NSException raise: NSInvalidArgumentException
               format: @"%@ -- %@ 0x%x: selector \"%@\" not recognized",
               NSStringFromSelector(_cmd),
               NSStringFromClass([self class]),
               self,
               NSStringFromSelector(sel)];
}

- (retval_t)forward: (SEL)sel 
                   : (arglist_t)args
{
  retval_t ret;
  NSInvocation *inv;

  inv = [[[NSInvocation alloc] initWithArgframe: args
			       selector: sel]
	  autorelease];
  [self forwardInvocation: inv];

  ret = [inv returnFrame: args];

  return ret;
}

- (void)forwardInvocation: (NSInvocation *)invocation
{
  if ([_handler shouldPerformInvocation: invocation])
    [_handler completeInitializationOfObject: self];

  [invocation invoke];
}

- (unsigned int)hash
{
  unsigned int hash;
  EOFaultHandler *handler;
  Class fault;

  fault = isa;
  handler = _handler;

  isa = [handler targetClass];
  _handler = [handler extraData];

  hash = [self hash];

  isa = fault;
  _handler = handler;

  return hash;
}

// GC

- gcSetNextObject: (id)anObject
{
  return [_handler gcSetNextObject: anObject];
}

- gcSetPreviousObject: (id)anObject
{
  return [_handler gcSetPreviousObject: anObject];
}

- (id)gcNextObject
{
  return [_handler gcNextObject];
}

- (id)gcPreviousObject
{
  return [_handler gcPreviousObject];
}

- (BOOL)gcAlreadyVisited
{
  return [_handler gcAlreadyVisited];
}

- (void)gcSetVisited: (BOOL)flag
{
  [_handler gcSetVisited: flag];
}

- (void)gcDecrementRefCountOfContainedObjects
{
  [_handler gcDecrementRefCountOfContainedObjects];
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  return [_handler gcIncrementRefCountOfContainedObjects];
}

- (BOOL)isGarbageCollectable
{
  return [_handler isGarbageCollectable];
}

- (void)gcIncrementRefCount
{
  [_handler gcIncrementRefCount];
}

- (void)gcDecrementRefCount
{
  EOFLOGObjectLevelArgs(@"gsdb", @"START self=%p", self);

  EOFLOGObjectLevel(@"gsdb", @"handler gcDecrementRefCount");

  [_handler gcDecrementRefCount];

  EOFLOGObjectLevelArgs(@"gsdb", @"STOP self=%p", self);
}

@end
