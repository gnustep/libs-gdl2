/* -*-objc-*-
   EOFault.h

   Copyright (C) 1996-2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: 1996

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef	__EOFault_h__
#define	__EOFault_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSZone.h>
#else
#include <Foundation/Foundation.h>
#endif

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
@public
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
+ (void)doesNotRecognizeSelector: (SEL)selector;
+ (BOOL)respondsToSelector: (SEL)selector;


+ (void)makeObjectIntoFault: (id)object withHandler: (EOFaultHandler *)handler;

+ (BOOL)isFault: (id)object;

+ (void)clearFault: (id)fault;

+ (EOFaultHandler *)handlerForFault: (id)fault;

+ (Class)targetClassForFault: (id)fault;


- (Class)superclass;
- (Class)class;

- (BOOL)isKindOfClass: (Class)aClass;
- (BOOL)isMemberOfClass: (Class)aClass;
- (BOOL)conformsToProtocol: (Protocol *)protocol;
- (BOOL)respondsToSelector: (SEL)selector;
- (NSMethodSignature *)methodSignatureForSelector: (SEL)selector;

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
- (BOOL)isProxy;

- (id)self;


- (void)doesNotRecognizeSelector: (SEL)selector;
- (void)forwardInvocation: (NSInvocation *)invocation;

@end /* EOFault */


@interface EOFaultHandler : NSObject
{

  Class _targetClass; /* Cached class of original object.  */
  void *_extraData;   /* Cached memory contents of original object
			 overwritten by fault handler reference.  */

  unsigned _extraRefCount;
}

- (void)setTargetClass: (Class)target extraData: (void *)data;
- (Class)targetClass;
- (void *)extraData;

- (void)incrementExtraRefCount;
- (BOOL)decrementExtraRefCountIsZero;
- (unsigned)extraRefCount;

- (NSString *)descriptionForObject: (id)object;

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

@end

#endif	/* __EOFault_h__ */
