/** 
   EOAccessFault.m <title>EOAccessFault Class</title>

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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

#include <EOControl/EOCheapArray.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAccessFault.h>
#include <EOAccess/EOAccessFaultPriv.h>
#include <EOAccess/EODatabaseContext.h>
#include <EOAccess/EODatabaseContextPriv.h>


NSString *EOAccessFaultObjectNotAvailableException = @"EOAccessFaultObjectNotAvailableException";


@implementation EOAccessGenericFaultHandler

- (id)init
{
  if ((self = [super init]))
    {
    }

  return self;
}
- (void)linkAfter: (EOAccessGenericFaultHandler *)faultHandler
  usingGeneration: (unsigned int)gen
{
  _generation = gen;
  _prev = faultHandler;
  _next = faultHandler->_next;

  faultHandler->_next = self;

  if(_next)
    _next->_prev = self;
}

- (void)_linkNext: (EOAccessGenericFaultHandler *)next
{
  if(_next)
    _next->_prev = nil;

  _next = next;

  if(next)
    next->_prev = self;
}

- (void)_linkPrev: (EOAccessGenericFaultHandler *)prev
{
  if(_prev)
    _prev->_next = nil;

  _prev = prev;

  if(prev)
    prev->_next = self;
}

- (EOAccessGenericFaultHandler *)next
{
  return _next;
}

- (EOAccessGenericFaultHandler *)previous
{
  return _prev;
}

- (unsigned int)generation
{
  return _generation;
}

- (void)faultWillFire: (id)object
{
  //We will be deallocated so link previous and next together...
  if (_next)
      _next->_prev=_prev;
  if (_prev)
    _prev->_next=_next;

  _prev=nil;
  _next=nil;
}

@end



@implementation EOAccessFaultHandler

- (id) init
{
  if ((self = [super init]))
    {
    }

  return self;
}

+ (EOAccessFaultHandler *)accessFaultHandlerWithGlobalID: (EOKeyGlobalID *)globalID
					 databaseContext: (EODatabaseContext *)dbcontext
					  editingContext: (EOEditingContext *)ec
{
  EOAccessFaultHandler* handler= [[[self alloc] initWithGlobalID: globalID
			databaseContext: dbcontext
			editingContext: ec] autorelease];
  return handler;
}

- (id) initWithGlobalID: (EOKeyGlobalID *)globalID
        databaseContext: (EODatabaseContext *)dbcontext
         editingContext: (EOEditingContext *)ec
{
  if ((self = [self init]))
    {
      EOFLOGObjectFnStartOrCond(@"EOAccesFaultHandler");

      ASSIGNCOPY(gid, globalID);
      ASSIGN(databaseContext, dbcontext);
      ASSIGN(editingContext, ec);

      EOFLOGObjectFnStopOrCond(@"EOAccesFaultHandler");
    }

  return self;
}

- (void)dealloc
{
#ifdef DEBUG
//  NSDebugFLog(@"Dealloc EOAccessFaultHandler %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif

  DESTROY(gid);
  DESTROY(databaseContext);
  DESTROY(editingContext);

  [super dealloc];

#ifdef DEBUG
//  NSDebugFLog(@"Dealloc EOAccessFaultHandler %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif
}

- (EOKeyGlobalID *)globalID
{
#ifdef DEBUG
  EOFLOGObjectFnStartOrCond(@"EOAccesFaultHandler");
  EOFLOGObjectFnStopOrCond(@"EOAccesFaultHandler");
#endif

  return gid;
}

- (EODatabaseContext *)databaseContext
{
  return databaseContext;
}

- (EOEditingContext *)editingContext
{
  return editingContext;
}

- (void)completeInitializationOfObject:(id)anObject
{
  EOFLOGObjectFnStart();

  [databaseContext _fireFault: anObject];

//MIRKO: replaced
/*
  [databaseContext _batchToOne:anObject
		   withHandler:self];
*/

  if ([EOFault isFault: anObject] == YES)
    {
      NSDebugMLLog(@"error", @"UnableToFaultObject: %p of class %@",
                   anObject,
                   [EOFault targetClassForFault: anObject]);      
      [self unableToFaultObject: anObject
            databaseContext: databaseContext];
    }

  EOFLOGObjectFnStop();
}

- (BOOL)shouldPerformInvocation: (NSInvocation *)invocation
{
  return YES;
}

@end


@implementation NSObject (EOAccessFaultUnableToFaultToOne)

- (void)unableToFaultObject: (id)object
	    databaseContext: (EODatabaseContext *)context
{
  EOFaultHandler *handler = [EOFault handlerForFault:object];
  EOGlobalID *globalID = nil;

  if ([handler respondsToSelector: @selector(globalID)])
    globalID = [(EOAccessFaultHandler *)handler globalID];

  NSDebugMLLog(@"gsdb", @"Fault Handler=%@ (%@)", handler, [handler class]);

  [NSException raise: EOAccessFaultObjectNotAvailableException
               format: @"%@ -- %@ 0x%x: cannot fault to-one for object %@ of class %@ databaseContext %@ handler %@ (globalID=%@)",
               NSStringFromSelector(_cmd),
               NSStringFromClass([self class]),
               self,
               object,
               [EOFault targetClassForFault: object],
               context,
               handler,
               globalID];
}

@end


@implementation EOAccessArrayFaultHandler

+ (EOAccessArrayFaultHandler *)accessArrayFaultHandlerWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
							relationshipName: (NSString *)aRelationshipName
							 databaseContext: (EODatabaseContext *)dbcontext
							  editingContext: (EOEditingContext *)ec
{
  return [[[self alloc] initWithSourceGlobalID: sourceGID
			relationshipName: aRelationshipName
			databaseContext: dbcontext
			editingContext: ec] autorelease];
}

- (id)init
{
  if ((self = [super init]))
    {
    }

  return self;
}

- initWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
	relationshipName: (NSString *)relName
	 databaseContext: (EODatabaseContext *)dbcontext
	  editingContext: (EOEditingContext *)ec
{
  if ((self = [self init]))
    {
      ASSIGN(sgid, sourceGID);
      ASSIGN(relationshipName, relName);
      ASSIGN(databaseContext, dbcontext);
      ASSIGN(editingContext, ec);
    }

  return self;
}

- (void)dealloc
{
#ifdef DEBUG
//  NSDebugFLog(@"Dealloc EOAccessArrayFaultHandler %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif

  DESTROY(sgid);
  DESTROY(relationshipName);
  DESTROY(databaseContext);
  DESTROY(editingContext);

  [super dealloc];
#ifdef DEBUG
//  NSDebugFLog(@"Stop Dealloc EOAccessArrayFaultHandler %p. ThreadID=%p",
//              (void*)self,(void*)objc_thread_id());
#endif
}

- (EOKeyGlobalID *)sourceGlobalID
{
  return sgid;
}

- (NSString *)relationshipName
{
  return relationshipName;
}

- (EODatabaseContext *)databaseContext
{
  return databaseContext;
}

- (EOEditingContext *)editingContext
{
  return editingContext;
}

- (void)completeInitializationOfObject: (id)anObject
{
  EOFLOGObjectFnStart();

  [databaseContext _fireArrayFault: anObject];
  [(EOCheapCopyMutableArray *)anObject _setCopy: NO];

  NSDebugMLLog(@"gsdb", @"anObject %p=%@", anObject, anObject);
  EOFLOGObjectFnStop();

/*MIRKO replaced
  [databaseContext _batchToMany:anObject
		   withHandler:self];
*/
}

- (id) descriptionForObject: (id)object
{
  //OK
  return [NSString stringWithFormat: @"<ArrayFault(%p) source: %@ relationship: %@>",
                   object,
                   sgid,
                   relationshipName];
}

- (BOOL)shouldPerformInvocation: (NSInvocation *)invocation
{
  return YES;
}

@end


@implementation EOFault (EOAccess)

- (EODatabaseContext *)databaseContext
{
  if ([_handler respondsToSelector: @selector(databaseContext)])
    return [(id)_handler databaseContext];
  else
    {
      [_handler completeInitializationOfObject: self];
      return [self databaseContext];
    }
}

@end
