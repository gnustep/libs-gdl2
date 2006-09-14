/* -*-objc-*-
   EOKeyValueArchiver.h

   Copyright (C) 2000,2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

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

#ifndef __EOKeyValueArchiving_h__
#define __EOKeyValueArchiving_h__


#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#include <Foundation/NSHashTable.h>
#else
#include <Foundation/Foundation.h>
#endif


@class NSArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSString;


@interface EOKeyValueArchiver : NSObject
{
  NSMutableDictionary *_propertyList;
  id _delegate;
}

- (void)encodeObject: (id)object
              forKey: (NSString *)key;

- (void)encodeReferenceToObject: (id)object
                         forKey: (NSString *)key;
	
- (void)encodeBool: (BOOL)yn
            forKey: (NSString *)key;

- (void)encodeInt: (int)intValue
           forKey: (NSString *)key;

- (NSDictionary *)dictionary;

- (void)setDelegate: (id)delegate;
- (id)delegate;

@end


@interface NSObject (EOKeyValueArchiverDelegation)

- (id)archiver: (EOKeyValueArchiver *)archiver 
referenceToEncodeForObject: (id)object;

@end
    
    
@interface EOKeyValueUnarchiver : NSObject
{
  NSDictionary   *_propertyList;
  id              _parent;
  id		  _nextParent;
  NSMutableArray *_allUnarchivedObjects;
  id              _delegate;
  NSHashTable    *_awakenedObjects;
}

- (id)initWithDictionary: (NSDictionary *)dictionary;

- (id)decodeObjectForKey: (NSString *)key;

- (id)decodeObjectReferenceForKey: (NSString *)key;

- (BOOL)decodeBoolForKey: (NSString *)key;

- (int)decodeIntForKey: (NSString *)key;

- (BOOL)isThereValueForKey: (NSString *)key;

- (void)ensureObjectAwake: (id)object;

- (void)finishInitializationOfObjects;

- (void)awakeObjects;

- (id)parent;

- (void)setDelegate: (id)delegate;
- (id)delegate;

- (id)_findTypeForPropertyListDecoding: (id)param0;
- (id)_dictionaryForPropertyList: (NSDictionary *)propList;
- (id)_objectsForPropertyList: (NSArray *)propList;
- (id)_objectForPropertyList: (NSDictionary *)propList;

@end

@interface NSObject (EOKeyValueUnarchiverDelegation)

- (id)unarchiver: (EOKeyValueUnarchiver *)archiver 
objectForReference: (id)keyPath;

@end

@protocol EOKeyValueArchiving

- (id)initWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver;

- (void)encodeWithKeyValueArchiver: (EOKeyValueArchiver *)archiver;

@end

@interface NSObject(EOKeyValueArchivingAwakeMethods)

- (void)finishInitializationWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver;

- (void)awakeFromKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver;

@end 


#endif
