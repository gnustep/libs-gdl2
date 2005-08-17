/* -*-objc-*-
   EOUtilities.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Sep 2000

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

#ifndef	__EOUtilities_h__
#define	__EOUtilities_h__


#include <EOControl/EOEditingContext.h>
#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOObjectStoreCoordinator.h>

#include <EOAccess/EODefines.h>


@class NSArray;
@class NSDictionary;
@class NSString;

@class EODatabaseContext;
@class EOModelGroup;
@class EOEntity;


GDL2ACCESS_EXPORT NSString *EOMoreThanOneException;


@interface EOEditingContext (EOUtilities)

- (NSArray *)objectsForEntityNamed: (NSString *)name;
- (NSArray *)objectsOfClass: (Class)classObject;
- (NSArray *)objectsWithFetchSpecificationNamed: (NSString *)fetchSpecName
				    entityNamed: (NSString *)entityName
				       bindings: (NSDictionary *)bindings;
- (NSArray *)objectsForEntityNamed: (NSString *)name
		   qualifierFormat: (NSString *)format, ...;
- (NSArray *)objectsMatchingValue: (id)value
			   forKey: (NSString *)key
		      entityNamed: (NSString *)name;
- (NSArray *)objectsMatchingValues: (NSDictionary *)values
		       entityNamed: (NSString *)name;

- (id)objectWithFetchSpecificationNamed: (NSString *)fetchSpecName
			    entityNamed: (NSString *)entityName
			       bindings: (NSDictionary *)bindings;
- (id)objectForEntityNamed: (NSString *)name
	   qualifierFormat: (NSString *)format, ...;
- (id)objectMatchingValue: (id)value
		   forKey: (NSString *)key
	      entityNamed: (NSString *)name;
- (id)objectMatchingValues: (NSDictionary *)values
	       entityNamed: (NSString *)name;
- (id)objectWithPrimaryKeyValue: (id)value
		    entityNamed: (NSString *)name;
- (id)objectWithPrimaryKey: (NSDictionary *)pkDict
	       entityNamed: (NSString *)name;

- (NSArray *)rawRowsForEntityNamed: (NSString *)name
		   qualifierFormat: (NSString *)format, ...;
- (NSArray *)rawRowsMatchingValue: (id)value
			   forKey: (NSString *)key
		      entityNamed: (NSString *)name;
- (NSArray *)rawRowsMatchingValues: (NSDictionary *)values
		       entityNamed: (NSString *)name;
- (NSArray *)rawRowsWithSQL: (NSString *)sqlString
		 modelNamed: (NSString *)name;
- (NSArray *)rawRowsWithStoredProcedureNamed: (NSString *)name
				   arguments: (NSDictionary *)args;
- (NSDictionary *)executeStoredProcedureNamed: (NSString *)name
				    arguments: (NSDictionary *)args;
- (id)objectFromRawRow: (NSDictionary *)row
	   entityNamed: (NSString *)name;

- (EODatabaseContext *)databaseContextForModelNamed: (NSString *)name;
- (void)connectWithModelNamed: (NSString *)name
connectionDictionaryOverrides: (NSDictionary *)overrides;

- (id)createAndInsertInstanceOfEntityNamed: (NSString *)entityName;

- (NSDictionary *)primaryKeyForObject: (id)object;
- (NSDictionary *)destinationKeyForSourceObject: (id)object
			      relationshipNamed: (NSString *)name;

- (id)localInstanceOfObject: (id)object;
- (NSArray *)localInstancesOfObjects: (NSArray *)objects;

- (EOModelGroup *)modelGroup;
- (EOEntity *)entityNamed: (NSString *)name;
- (EOEntity *)entityForClass: (Class)classObject;
- (EOEntity *)entityForObject: (id)obj;

@end


@interface EOFetchSpecification (EOAccess)

+ (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)name
                                      entityNamed: (NSString *)entityName;

@end


@interface EOObjectStoreCoordinator (EOModelGroup)

- (id)modelGroup;
- (void)setModelGroup: (EOModelGroup *)modelGroup;

@end


#endif
