/* -*-objc-*-
   EODatabaseContextPriv.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: July 2000

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

#ifndef __EODatabaseContextPriv_h__
#define __EODatabaseContextPriv_h__


@class EOAccessFaultHandler;
@class EOAccessArrayFaultHandler;
@class EOKeyGlobalID;
@class EOFault;


@interface EODatabaseContext (EODatabaseContextPrivate)

- (void)_fireArrayFault: (id)object;
- (void)_fireFault: (id)object;
- (void)_addBatchForGlobalID: (EOKeyGlobalID *)globalID
		       fault: (EOFault *)fault;
- (void)_removeBatchForGlobalID: (EOKeyGlobalID *)globalID
			  fault: (EOFault *)fault;
- (void)_addToManyBatchForSourceGlobalID: (EOKeyGlobalID *)globalID
			relationshipName: (NSString *)relationshipName
				   fault: (EOFault *)fault;

/*
- (void)_batchToOne: (id)fault
	withHandler: (EOAccessFaultHandler *)handler;
- (void)_batchToMany: (id)fault
	 withHandler: (EOAccessArrayFaultHandler *)handler;
*/

@end


@interface EODatabaseContext (EODatabaseContextPrivate2)

- (void)_verifyNoChangesToReadonlyEntity: (EODatabaseOperation *)dbOpe;
- (EOGlobalID *)_globalIDForObject: (id)object;
- (NSDictionary *)_primaryKeyForObject: (id)object;
- (NSDictionary *)_primaryKeyForObject: (id)object
			raiseException: (BOOL)raiseException;
- (NSDictionary *)_currentCommittedSnapshotForObject: (id)object;
- (id)_addDatabaseContextStateToException: (id)param0;
- (id)_databaseContextState;
- (void)_cleanUpAfterSave;
- (void)_assertValidStateWithSelector: (SEL)sel;
- (BOOL)_shouldGeneratePrimaryKeyForEntityName: (NSString *)entityName;
- (void)_buildPrimaryKeyGeneratorListForEditingContext: (EOEditingContext *)context;

@end

#endif /* __EODatabaseContextPriv_h__ */
