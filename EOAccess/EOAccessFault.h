/* -*-objc-*-
   EOAccessFault.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

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

#ifndef	__EOAccessFault_h__
#define	__EOAccessFault_h__


#include <EOControl/EOFault.h>

#include <EOAccess/EODefines.h>


@class EODatabaseContext;
@class EOEditingContext;
@class EOKeyGlobalID;
@class NSString;


@interface EOAccessGenericFaultHandler : EOFaultHandler
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


@interface EOAccessFaultHandler : EOAccessGenericFaultHandler
{
  EOKeyGlobalID *gid;
  EODatabaseContext *databaseContext;
  EOEditingContext *editingContext;
}

+ (EOAccessFaultHandler *)accessFaultHandlerWithGlobalID: (EOKeyGlobalID *)globalID
					 databaseContext: (EODatabaseContext *)dbcontext
					  editingContext: (EOEditingContext *)ec;

- (id)initWithGlobalID: (EOKeyGlobalID *)globalID
       databaseContext: (EODatabaseContext *)dbcontext
	editingContext: (EOEditingContext *)ec;

- (EOKeyGlobalID *)globalID;
- (EODatabaseContext *)databaseContext;
- (EOEditingContext *)editingContext;

@end


@interface EOAccessArrayFaultHandler : EOAccessGenericFaultHandler
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

- (id)initWithSourceGlobalID: (EOKeyGlobalID *)sourceGID
	    relationshipName: (NSString *)relationshipName
	     databaseContext: (EODatabaseContext *)dbcontext
	      editingContext: (EOEditingContext *)ec;

- (EOKeyGlobalID *)sourceGlobalID;
- (NSString *)relationshipName;
- (EODatabaseContext *)databaseContext;
- (EOEditingContext *)editingContext;

@end


@interface NSObject (EOAccessFaultUnableToFaultToOne)

- (void)unableToFaultObject: (id)object
	    databaseContext: (EODatabaseContext *)context;

@end


@interface EOFault (EOAccess)

- (EODatabaseContext *)databaseContext;

@end


GDL2ACCESS_EXPORT NSString *EOAccessFaultObjectNotAvailableException;


#endif
