/** 
   EOAccessFault.m <title>EOAccessFault Class</title>

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
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSException.h>
#include <Foundation/NSThread.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

#include <EOControl/EOCheapArray.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOAccessFault.h>
#include <EOAccess/EODatabaseContext.h>

#include "EOAccessFaultPriv.h"
#include "EODatabaseContextPriv.h"


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
      NSDebugFLog(@"INIT EOAccessFaultHandler %p. ThreadID=%@",
		  (void*)self, [NSThread currentThread]);
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


      ASSIGNCOPY(gid, globalID);
      ASSIGN(databaseContext, dbcontext);
      ASSIGN(editingContext, ec);


    }

  return self;
}

- (void)dealloc
{
#ifdef DEBUG
  NSDebugFLog(@"Dealloc EOAccessFaultHandler %p. ThreadID=%@",
              (void*)self, [NSThread currentThread]);
#endif

  DESTROY(gid);
  DESTROY(databaseContext);
  DESTROY(editingContext);

  [super dealloc];

}

- (EOKeyGlobalID *)globalID
{
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


  // We want to be sure that we will not be autoreleased 
  // in an autorelease pool of another thread!
  AUTORELEASE(RETAIN(self)); 

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

}

- (BOOL)shouldPerformInvocation: (NSInvocation *)invocation
{
  NSDebugFLLog(@"gsdb",@"invocation selector=%@ target: %p",
               NSStringFromSelector([invocation selector]),
               [invocation target]);
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


  // we should avoid putting self here as this will fire a fault again...
  
  [NSException raise: EOAccessFaultObjectNotAvailableException
               format: @"%@ -- %@ 0x%x: cannot fault to-one for object of class %@ databaseContext %@ handler %@ (globalID=%@)",
               NSStringFromSelector(_cmd),
               NSStringFromClass([self class]),
               object,
               [EOFault targetClassForFault: object],
               context,
               handler,
               globalID];
}

@end


@implementation EOAccessArrayFaultHandler

+ (EOAccessArrayFaultHandler *)accessArrayFaultHandlerWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
							relationshipName: (NSString *)relName
							 databaseContext: (EODatabaseContext *)dbcontext
							  editingContext: (EOEditingContext *)ec
{
  return [[[self alloc] initWithSourceGlobalID: sourceGID
			relationshipName: relName
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

- (id)initWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
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
  NSDebugFLog(@"Dealloc EOAccessArrayFaultHandler %p. ThreadID=%@",
              (void*)self, [NSThread currentThread]);
#endif

  DESTROY(sgid);
  DESTROY(relationshipName);
  DESTROY(databaseContext);
  DESTROY(editingContext);

  [super dealloc];
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


  // We want to be sure that we will not be autoreleased 
  // in an autorelease pool of another thread!
  AUTORELEASE(RETAIN(self)); 

  [databaseContext _fireArrayFault: anObject];
  [(EOCheapCopyMutableArray *)anObject _setCopy: NO];




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
  NSDebugFLLog(@"gsdb",@"invocation selector=%@ target: %p",
               NSStringFromSelector([invocation selector]),
               [invocation target]);
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
