/* 
   EOObjectStore.h

   Copyright (C) 2000, 2003 Free Software Foundation, Inc.

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

#ifndef	__EOObjectStore_h__
#define	__EOObjectStore_h__

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>

@class NSArray;
@class NSDictionary;
@class NSString;

@class EOEditingContext;
@class EOGlobalID;
@class EOFetchSpecification;


@interface EOObjectStore : NSObject

- (id)faultForGlobalID: (EOGlobalID *)globalID
	editingContext: (EOEditingContext *)context;

- (id)faultForRawRow: (NSDictionary *)row
	 entityNamed: (NSString *)entityName
      editingContext: (EOEditingContext *)context;

- (NSArray *)arrayFaultWithSourceGlobalID: (EOGlobalID *)globalID
			 relationshipName: (NSString *)name
			   editingContext: (EOEditingContext *)context;

- (void)initializeObject: (id)object
	    withGlobalID: (EOGlobalID *)globalID
          editingContext: (EOEditingContext *)context;

- (NSArray *)objectsForSourceGlobalID: (EOGlobalID *)globalID
		     relationshipName: (NSString *)name
		       editingContext: (EOEditingContext *)context;

- (void)refaultObject: object
	 withGlobalID: (EOGlobalID *)globalID
       editingContext: (EOEditingContext *)context;

- (void)saveChangesInEditingContext: (EOEditingContext *)context;

- (NSArray *)objectsWithFetchSpecification: (EOFetchSpecification *)fetchSpecification
			    editingContext: (EOEditingContext *)context;

- (BOOL)isObjectLockedWithGlobalID: (EOGlobalID *)gid
		    editingContext: (EOEditingContext *)context;

- (void)lockObjectWithGlobalID: (EOGlobalID *)gid
		editingContext: (EOEditingContext *)context;

- (void)invalidateAllObjects;
- (void)invalidateObjectsWithGlobalIDs: (NSArray *)globalIDs;

- (id) propertiesForObjectWithGlobalID: (EOGlobalID *)gid
			editingContext: (EOEditingContext *)context;
@end


GDL2CONTROL_EXPORT NSString *EOObjectsChangedInStoreNotification;

GDL2CONTROL_EXPORT NSString *EOInvalidatedAllObjectsInStoreNotification;

GDL2CONTROL_EXPORT NSString *EODeletedKey;
GDL2CONTROL_EXPORT NSString *EOInsertedKey;
GDL2CONTROL_EXPORT NSString *EOInvalidatedKey;
GDL2CONTROL_EXPORT NSString *EOUpdatedKey;

#endif
