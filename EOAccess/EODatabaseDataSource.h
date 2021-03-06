/* -*-objc-*-
   EODatabaseDataSource.m

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: July 2000

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EODatabaseDataSource_h__
#define __EODatabaseDataSource_h__


#include <EOControl/EODataSource.h>


@class NSDictionary;
@class NSString;

@class EOEntity;
@class EODatabaseContext;
@class EOEditingContext;
@class EOFetchSpecification;
@class EOQualifier;


@interface EODatabaseDataSource : EODataSource <NSCoding>
{
  EOEditingContext *_editingContext;
  EOFetchSpecification *_fetchSpecification;
  EOQualifier *_auxiliaryQualifier;
  NSDictionary *_bindings;

  struct {
    unsigned int fetchEnabled:1;
    unsigned int _reserved:31;
  } _flags;
}

- (id)initWithEditingContext: (EOEditingContext *)editingContext
		  entityName: (NSString *)entityName;
- (id)initWithEditingContext: (EOEditingContext *)editingContext
		  entityName: (NSString *)entityName
      fetchSpecificationName: (NSString *)fetchName;

- (EOEntity *)entity;

- (EODatabaseContext *)databaseContext;

- (void)setFetchSpecification: (EOFetchSpecification *)fetchSpecification;
- (EOFetchSpecification *)fetchSpecification;

- (void)setAuxiliaryQualifier: (EOQualifier *)qualifier;
- (EOQualifier *)auxiliaryQualifier;

- (EOFetchSpecification *)fetchSpecificationForFetch;

- (void)setFetchEnabled: (BOOL)flag;
- (BOOL)isFetchEnabled;

@end


#endif /* __EODatabaseDataSource_h__ */
