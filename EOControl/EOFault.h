/* 
   EOFault.h

   Copyright (C) 1996-2000 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: 1996

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: June 2000

   This file is part of the GNUstep Database Library.

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
*/

#ifndef	__EOFault_h__
#define	__EOFault_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSZone.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <GNUstepBase/GCObject.h>


@class NSInvocation;
@class NSMethodSignature;
@class NSDictionary;
@class NSString;

@class EOFaultHandler;

/*
 * EOFault class
 */


@interface EOFault
{
  Class isa;
  EOFaultHandler *_handler;
}


+ (void)initialize;
+ (Class)superclass;
+ (Class)class;
+ (id)self;

+ (id)retain;
+ (void)release;
+ (id)autorelease;
+ (unsigned)retainCount;

+ (BOOL)isKindOfClass: (Class)aClass;
+ (void)doesNotRecognizeSelector: (SEL)sel;
+ (BOOL)respondsToSelector: (SEL)sel;


+ (void)makeObjectIntoFault: (id)object withHandler: (EOFaultHandler *)handler;

+ (BOOL)isFault: (id)object;

+ (void)clearFault: (id)fault;

+ (EOFaultHandler *)handlerForFault: (id)fault;

+ (Class)targetClassForFault: (id)fault;


- (Class)superclass;
- (Class)class;

- (BOOL)isKindOfClass: (Class)aclass;
- (BOOL)isMemberOfClass: (Class)aclass;
- (BOOL)conformsToProtocol: (Protocol *)protocol;
- (BOOL)respondsToSelector: (SEL)sel;
- (NSMethodSignature *)methodSignatureForSelector: (SEL)aSelector;

- (id)retain;
- (void)release;
- (id)autorelease;
- (unsigned)retainCount;

- (NSString *)description;
- (NSString *)descriptionWithIndent: (unsigned)level;
- (NSString *)descriptionWithLocale: (NSDictionary *)locale;
- (NSString *)descriptionWithLocale: (NSDictionary *)locale
			     indent: (unsigned)level;
- (NSString *)eoDescription;
- (NSString *)eoShallowDescription;

- (void)dealloc;

- (NSZone *)zone;
- (BOOL)isProxy; // Always NO.

- (id)self;


- (void)doesNotRecognizeSelector: (SEL)sel;
- (void)forwardInvocation: (NSInvocation *)invocation;

- gcSetNextObject: (id)anObject;
- gcSetPreviousObject: (id)anObject;
- (id)gcNextObject;
- (id)gcPreviousObject;
- (BOOL)gcAlreadyVisited;
- (void)gcSetVisited: (BOOL)flag;
- (void)gcDecrementRefCountOfContainedObjects;
- (BOOL)gcIncrementRefCountOfContainedObjects;
- (BOOL)isGarbageCollectable;
- (void)gcIncrementRefCount;
- (void)gcDecrementRefCount;

@end /* EOFault */


@interface EOFaultHandler : NSObject
{
  gcInfo	gc;

  Class _targetClass;  // the first 8 bytes of
  void *_extraData;    // the faulted object

  unsigned _extraRefCount;

  BOOL gcEnabled;
@public
  int gcCountainedObjectRefCount;
}

- (void)setTargetClass: (Class)target extraData: (void *)data;
- (Class)targetClass;
- (void *)extraData;

- (void)incrementExtraRefCount;
- (BOOL)decrementExtraRefCountWasZero;
- (unsigned)extraRefCount;

- (NSString *)descriptionForObject: object;

- (Class)classForFault: (id)fault;

- (BOOL)isKindOfClass: (Class)aclass forFault: (id)fault;
- (BOOL)isMemberOfClass: (Class)aclass forFault: (id)fault;
- (BOOL)conformsToProtocol: (Protocol *)protocol forFault: (id)fault;
- (BOOL)respondsToSelector: (SEL)sel forFault: (id)fault;
- (NSMethodSignature *)methodSignatureForSelector: (SEL)selector
					 forFault: (id)fault;

- (void)completeInitializationOfObject: (id)object;

- (BOOL)shouldPerformInvocation: (NSInvocation *)invocation;

- (void)faultWillFire: (id)object;

// Garbage Collector

- gcSetNextObject: (id)anObject;
- gcSetPreviousObject: (id)anObject;
- (id)gcNextObject;
- (id)gcPreviousObject;
- (BOOL)gcAlreadyVisited;
- (void)gcSetVisited: (BOOL)flag;
- (void)gcDecrementRefCountOfContainedObjects;
- (BOOL)gcIncrementRefCountOfContainedObjects;
- (BOOL)isGarbageCollectable;
- (void)gcIncrementRefCount;
- (void)gcDecrementRefCount;

@end

#endif	/* __EOFault_h__ */
