/* 
   EOMultipleKnownKeyDictionary.h

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#ifndef	__EOMultipleKnownKeyDictionary_h__
#define	__EOMultipleKnownKeyDictionary_h__

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSObject.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSZone.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <gnustep/base/GCObject.h>


@class NSArray;
@class NSDictionary;
@class NSMutableDictionary;

@class EOMutableKnownKeyDictionary;


@interface EOMKKDInitializer : GCObject
{
  unsigned int _count;
  NSMapTable *_keyToIndex; //key to index
  NSString **_keys;
}

+ (EOMKKDInitializer*)initializerFromKeyArray:(NSArray*)keys;
+ (id)newWithKeyArray: (NSArray*)keys;
+ (id)newWithKeyArray: (NSArray*)keys
		 zone: (NSZone*)zone;

- (id)initWithKeys: (NSArray*)keys;
- (void) dealloc;
- (NSString*)description;
- (unsigned int) count;
- (void) setObject: (id)object
          forIndex: (unsigned int)index
        dictionary: (NSMutableDictionary*)dictionary;
- (id) objectForIndex: (unsigned int)index
           dictionary: (NSDictionary*)dictionary;
- (unsigned int) indexForKey: (id)key;
- (id) arrayMappingForKeys: (id)keys;
- (id) subsetMappingForSourceDictionaryInitializer: (EOMKKDInitializer*)initialize
                                        sourceKeys: (NSArray*)sourceKeys
                                   destinationKeys: (NSArray*)destinationKeys;
- (id) subsetMappingForSourceDictionaryInitializer: (id)param0;
- (id*) keys;
- (BOOL)hasKey: (id)key;

@end

@interface EOMKKDKeyEnumerator : NSEnumerator
{
  EOMutableKnownKeyDictionary *_target;
  int _position;
  int _end;
  //  id* tvalues;
  id _extraEnumerator;
  NSString **_keys;
}

- (id) initWithTarget: (EOMutableKnownKeyDictionary*)target;
- (void) dealloc;
- (NSString*)description;
- (id) nextObject;

@end

@interface EOMKKDSubsetMapping : NSObject
{
@public
  EOMKKDInitializer *_sourceDescription;
  EOMKKDInitializer *_destinationDescription;
  int _sourceOffsetForDestinationOffset[1];
}

+(id)newInstanceWithKeyCount: (unsigned int)keyCount
           sourceDescription: (EOMKKDInitializer*)source
      destinationDescription: (EOMKKDInitializer*)destination
                        zone: (NSZone*)zone;
- (void) dealloc;
- (NSString*)description;

@end

@interface EOMKKDArrayMapping : NSObject
{
@public
  EOMKKDInitializer *_destinationDescription;
  int _destinationOffsetForArrayIndex[1];
}
+ (id)newInstanceWithKeyCount: (unsigned int)keyCount
       destinationDescription: (EOMKKDInitializer*)destination
			 zone: (NSZone*)zone;
- (void) dealloc;
- (NSString*)description;

@end


@interface EOMutableKnownKeyDictionary : NSMutableDictionary
{
  EOMKKDInitializer *_MKKDInitializer;
  NSMutableDictionary *_extraData;
  id *_values;
}

+ (id)dictionaryFromDictionary: (NSDictionary *)dict
                 subsetMapping: (EOMKKDSubsetMapping *)subsetMapping;
+ (id)newDictionaryFromDictionary: (NSDictionary*)dict
		    subsetMapping: (EOMKKDSubsetMapping*)subsetMapping
			     zone: (NSZone*)zone;
+ (id)newDictionaryWithObjects: (id*)objects
		  arrayMapping: (id)mapping
			  zone: (NSZone*)zone;
+ (id)newWithInitializer: (EOMKKDInitializer*)initializer
		 objects: (id*)objects
		    zone: (NSZone*)zone;
+ (id)dictionaryWithObjects: (NSArray*)objects
		    forKeys: (NSArray*)keys;

+ (EOMKKDInitializer*)initializerFromKeyArray: (NSArray*)keys;
+ (id) dictionaryWithInitializer: (EOMKKDInitializer*)initializer;
+ (id)newWithInitializer: (EOMKKDInitializer*)initializer;
+ (id)newWithInitializer: (EOMKKDInitializer*)initializer
		    zone: (NSZone*)zone;
+ (id) dictionaryWithInitializer: (EOMKKDInitializer*)initializer;

- (id)initWithInitializer: (EOMKKDInitializer*)initializer;
- (id) initWithInitializer: (EOMKKDInitializer*)initializer
                   objects: (id*)objects;
- (id) initWithObjects: (id*)objects
               forKeys: (id*)keys
                 count: (unsigned int)count;
- (void) dealloc;
- (unsigned int) count;
- (id) objectForKey: (id)key;
- (void) setObject: (id)object
            forKey: (NSString*)key;
- (void) removeObjectForKey: (NSString*)key;
- (BOOL) containsObjectsNotIdenticalTo: (id)object;
- (void) addEntriesFromDictionary: (NSDictionary*)dictionary;
- (NSEnumerator*) keyEnumerator;
- (EOMKKDInitializer*) eoMKKDInitializer;
- (NSMutableDictionary*)extraData;
- (BOOL)hasKey:(id)key;
- (NSString *)debugDescription;

@end

#endif
