/* 
   EOAccessFault.h

   Copyright (C) 2000 Free Software Foundation, Inc.

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

#ifndef	__EOAccessFault_h__
#define	__EOAccessFault_h__


#import <Foundation/NSObject.h>

#import <EOControl/EOFault.h>


@class EODatabaseContext;
@class EOEditingContext;
@class EOKeyGlobalID;
@class NSString;


@interface EOAccessGenericFaultHandler:EOFaultHandler
{
  unsigned int _generation;
  EOAccessGenericFaultHandler *_next;
  EOAccessGenericFaultHandler *_prev;
}

- (void)linkAfter: (EOAccessGenericFaultHandler *)faultHandler
  usingGeneration: (unsigned int)gen;
- (EOAccessGenericFaultHandler *)next;
- (EOAccessGenericFaultHandler *)previous;
- (unsigned int)generation;

@end


@interface EOAccessFaultHandler:EOAccessGenericFaultHandler
{
  EOKeyGlobalID *gid;
  EODatabaseContext *databaseContext;
  EOEditingContext *editingContext;
}

+ (EOAccessFaultHandler *)accessFaultHandlerWithGlobalID: (EOKeyGlobalID *)globalID
					 databaseContext: (EODatabaseContext *)dbcontext
					  editingContext: (EOEditingContext *)ec;

- initWithGlobalID: (EOKeyGlobalID *)globalID
   databaseContext: (EODatabaseContext *)dbcontext
    editingContext: (EOEditingContext *)ec;

- (EOKeyGlobalID *)globalID;
- (EODatabaseContext *)databaseContext;
- (EOEditingContext *)editingContext;

@end


@interface EOAccessArrayFaultHandler:EOAccessGenericFaultHandler
{
  EOKeyGlobalID *sgid;
  NSString *relationshipName;
  EODatabaseContext *databaseContext;
  EOEditingContext *editingContext;
  id copy;
}

+ (EOAccessArrayFaultHandler *)accessArrayFaultHandlerWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
							relationshipName: (NSString *)relationshipName
							 databaseContext: (EODatabaseContext *)dbcontext
							  editingContext: (EOEditingContext *)ec;

- initWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
	relationshipName: (NSString *)relationshipName
	 databaseContext: (EODatabaseContext *)dbcontext
	  editingContext: (EOEditingContext *)ec;

- (EOKeyGlobalID *)sourceGlobalID;
- (NSString *)relationshipName;
- (EODatabaseContext *)databaseContext;
- (EOEditingContext *)editingContext;

@end


@interface NSObject (EOAccessFaultUnableToFaultToOne)

- (void)unableToFaultObject:(id)object
	    databaseContext:(EODatabaseContext *)context;

@end


@interface EOFault (EOAccess)

- (EODatabaseContext *)databaseContext;

@end


extern NSString *EOAccessFaultObjectNotAvailableException;


#endif
