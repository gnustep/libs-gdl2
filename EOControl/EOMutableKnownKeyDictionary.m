/**
   EEOMutableKnownKeyDictionary.m <title>EEOMutableKnownKeyDictionary</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSZone.h>
#include <Foundation/NSMapTable.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif

#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EODebug.h>
#include <EOControl/EONull.h>

#include "EOPrivate.h"

@implementation EOMKKDInitializer

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;
      GDL2_PrivateInit();
    }
}

+ (EOMKKDInitializer*)initializerFromKeyArray: (NSArray*)keys
{
  EOMKKDInitializer *initializer = [[self newWithKeyArray: keys] autorelease];

  return initializer;
}

+ (id)newWithKeyArray: (NSArray*)keys
{
  return [[self alloc]
           initWithKeys: keys];
}

+ (id)newWithKeyArray: (NSArray*)keys
		 zone: (NSZone*)zone
{
  return [[self allocWithZone: zone]
           initWithKeys: keys];
}

- (id)initWithKeys: (id*)keys
	     count: (NSUInteger)count
{
  if ((self = [self init]))
    {
      NSUInteger i;

      NSAssert(keys, @"No array of keys");
      NSAssert(count > 0, @"No keys in array");

      _keyToIndex = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks, 
					     NSIntMapValueCallBacks,
					     count,
					     [self zone]);
      _keys = NSZoneMalloc([self zone], count * sizeof(NSString*));



      for (i = 0; i < count; i++)
        {
          id key = keys[i];
          void *oldValue;

          _count = i + 1;


          EOFLOGObjectLevelArgs(@"EOMKKD", @"key=%@ RETAINCOUNT=%d",
				key, [key retainCount]);

          oldValue = NSMapInsertIfAbsent(_keyToIndex,key, (const void*)(NSUInteger)(i + 1)); //+1 because 0 = no object
          _keys[i] = key; //Don't retain: already retained by Map

          EOFLOGObjectLevelArgs(@"EOMKKD", @"key=%@ RETAINCOUNT=%d",
				key, [key retainCount]);
          NSAssert1(!oldValue, @"%@ already present", key);
        }


    }

  return self;
}

- (id)initWithKeys: (NSArray*)keys
{
  NSUInteger count = [keys count];

  NSAssert(keys, @"No array of keys");
  NSAssert([keys count] > 0, @"No keys in array");

  {
    id keysArray[count];

    memset(keysArray, 0, count * sizeof(id));
    [keys getObjects: keysArray];

    if ((self = [self initWithKeys: keysArray
		      count: count]))
      {
      }
  }



  return self;
}

- (void)dealloc
{


  if (_keyToIndex)
    NSFreeMapTable(_keyToIndex);
  if (_keys)    
    NSZoneFree([self zone],_keys);

  [super dealloc];

  //EOFLogC("GSWElementIDString end of dealloc");
}

- (NSString*)description
{
  NSString *dscr;
  NSUInteger i;

  dscr = [NSString stringWithFormat: @"<%s %p - keys=",
		   object_getClassName(self),
		   (void*)self];

  for (i = 0; i < _count; i++)
    {
      dscr = [dscr stringByAppendingFormat: @"%@ [%d] ",
                   _keys[i],
                   i];
    }

  dscr = [dscr stringByAppendingString: @">"];

  return dscr;
}

- (void) setObject: (id)object
          forIndex: (NSUInteger)index
        dictionary: (NSMutableDictionary*)dictionary
{
  //OK?
  id key;

  NSAssert2(index < _count, @"bad index %d (count=%u)", index, _count);

  key = _keys[index];

  [dictionary setObject: object
              forKey: key];
}

- (id) objectForIndex: (NSUInteger)index
           dictionary: (NSDictionary*)dictionary
{
  id key;

  NSAssert2(index < _count, @"bad index %d (count=%u)", index, _count);

  key = _keys[index];

  return [dictionary objectForKey: key];
}

- (NSUInteger) indexForKey: (id)key
{
  void *index = NSMapGet(_keyToIndex, (const void *)key);
  
  if (!index) {
    return NSNotFound;
  }
  
  return (NSUInteger)(index - 1);
}

- (BOOL)hasKey: (id)key
{
  return (EOMKKDInitializer_indexForKeyWithImpPtr(self,NULL,key) != NSNotFound);
}

- (EOMKKDArrayMapping*) arrayMappingForKeys: (NSArray*)keys
{
  NSUInteger selfKeyCount = [keys count];
  NSUInteger keyCount = [keys count];
  EOMKKDArrayMapping *arrayMapping = nil;

  NSAssert(keyCount <= selfKeyCount, @"key count greater than our key count");

  arrayMapping = [[EOMKKDArrayMapping newInstanceWithKeyCount: selfKeyCount
				      destinationDescription: self
				      zone: [self zone]] autorelease];  

  if (keyCount>0)
    {
      NSUInteger i=0;
      GDL2IMP_UINT indexForKeyIMP=NULL;
      IMP objectAtIndexIMP=[keys methodForSelector:@selector(objectAtIndex:)];

      for (i = 0; i < keyCount; i++)
        {
          NSString *key = GDL2_ObjectAtIndexWithImp(keys,objectAtIndexIMP,i);
          int destinationIndex =  EOMKKDInitializer_indexForKeyWithImpPtr(self,&indexForKeyIMP,key);
          
          
          arrayMapping->_destinationOffsetForArrayIndex[i] = destinationIndex + 1;
        }
    };

  return arrayMapping;
}

- (EOMKKDSubsetMapping*) subsetMappingForSourceDictionaryInitializer: (EOMKKDInitializer*)sourceInitializer
                                                          sourceKeys: (NSArray*)sourceKeys
                                                     destinationKeys: (NSArray*)destinationKeys
{
  NSUInteger selfKeyCount = [self count];
  NSUInteger keyCount = [destinationKeys count];
  EOMKKDSubsetMapping *subsetMapping = nil;

  NSAssert([sourceKeys count] == keyCount, @"Source and destination keys count are different");
  NSAssert(keyCount <= selfKeyCount, @"key count greater than our key count");

  subsetMapping = [[EOMKKDSubsetMapping newInstanceWithKeyCount: selfKeyCount
					sourceDescription: sourceInitializer
					destinationDescription: self
					zone: [self zone]] autorelease];  






  if (keyCount>0)
      {
        NSUInteger i;
        GDL2IMP_UINT selfIndexForKeyIMP=NULL;
        GDL2IMP_UINT sourceInitializerIndexForKeyIMP=NULL;
        IMP sourceObjectAtIndexIMP=[sourceKeys methodForSelector:@selector(objectAtIndex:)];
        IMP destinationObjectAtIndexIMP=[destinationKeys methodForSelector:@selector(objectAtIndex:)];

        for (i = 0; i < keyCount; i++)
          {
            NSString *sourceKey = nil;
            NSString *destinationKey = nil;
            NSUInteger destinationIndex = 0;
            NSUInteger sourceIndex = 0;
            
            sourceKey = 
              GDL2_ObjectAtIndexWithImp(sourceKeys,sourceObjectAtIndexIMP,i);

            
            destinationKey = 
              GDL2_ObjectAtIndexWithImp(destinationKeys,destinationObjectAtIndexIMP,i);

            
            destinationIndex =  
              EOMKKDInitializer_indexForKeyWithImpPtr(self,
                                                      &selfIndexForKeyIMP,
                                                      destinationKey);
            EOFLOGObjectLevelArgs(@"EOMKKD", @"destinationIndex=%d",
                                  destinationIndex);
            
            sourceIndex = 
              EOMKKDInitializer_indexForKeyWithImpPtr(sourceInitializer,
                                                      &sourceInitializerIndexForKeyIMP,
                                                      sourceKey);

            
            NSAssert2(destinationIndex != NSNotFound,
                      @"Destination Key %@ not found in %@",
                      destinationKey,
                      self);
            NSAssert2(sourceIndex != NSNotFound,
                      @"Source Key %@ not found in %@",
                      sourceKey,
                      sourceInitializer);
            
            subsetMapping->_sourceOffsetForDestinationOffset[destinationIndex]
              = sourceIndex + 1;
          }
      };

  return subsetMapping;
}

- (EOMKKDSubsetMapping*)subsetMappingForSourceDictionaryInitializer: (EOMKKDInitializer*)sourceInitializer
{
  unsigned keyCount = [self count];
  EOMKKDSubsetMapping *subsetMapping = [[EOMKKDSubsetMapping
					  newInstanceWithKeyCount: keyCount
					  sourceDescription: sourceInitializer
					  destinationDescription: self
					  zone: [self zone]] autorelease];

  if (keyCount>0)
    {
      NSUInteger i=0;
      GDL2IMP_UINT indexForKeyIMP=NULL;
  
      for (i = 0; i < keyCount; i++)
        {
          NSString *key;
          NSInteger index;
          
          key = _keys[i];

          
          index = EOMKKDInitializer_indexForKeyWithImpPtr(sourceInitializer,
                                                          &indexForKeyIMP,key);

          
          subsetMapping->_sourceOffsetForDestinationOffset[i]
            = (index == NSNotFound ? 0 : index + 1);
        }
    };

  return subsetMapping;
}

- (id*) keys
{
  return _keys;
}

- (NSUInteger) count
{
  return _count;
}

@end


@implementation EOMKKDKeyEnumerator : NSEnumerator

- (id) initWithTarget: (EOMutableKnownKeyDictionary*)target
{
  if ((self = [super init]))
    {
      EOMKKDInitializer *initializer;

      NSAssert(target,@"No target");

      ASSIGN(_target,target);
      ASSIGN(_extraEnumerator, [[_target extraData] keyEnumerator]);

      initializer = [_target eoMKKDInitializer];
      _end = [initializer count];
      _keys = [initializer keys];
      _position = 0;
    }

  return self;
}

- (void) dealloc
{
//
  DESTROY(_target);
  DESTROY(_extraEnumerator);

  [super dealloc];
}

- (NSString*)description
{
  NSString *dscr;

  dscr = [NSString stringWithFormat: @"<%s %p - target=%p>",
		   object_getClassName(self),
		   (void*)self,
                   _target];
  return dscr;
}

- (id) nextObject
{
  id object = nil;

  if (_position < _end)
    {
      object = _keys[_position];
      _position++;
    }
  else if (_extraEnumerator)
    {
      object = [_extraEnumerator nextObject];

      if (object)
        _position++;
    }

  return object;
}

@end

@implementation EOMKKDSubsetMapping

+ (id)newInstanceWithKeyCount: (NSUInteger)keyCount
	    sourceDescription: (EOMKKDInitializer*)source
       destinationDescription: (EOMKKDInitializer*)destination
			 zone: (NSZone*)zone
{
  unsigned extraBytes = (keyCount > 0 ? (keyCount - 1) : 0) * sizeof(NSUInteger);
  EOMKKDSubsetMapping *subsetMapping;

  subsetMapping = (EOMKKDSubsetMapping*)NSAllocateObject([EOMKKDSubsetMapping class],
							 extraBytes,
							 zone);

  [subsetMapping init];

  ASSIGN(subsetMapping-> _sourceDescription,source);
  ASSIGN(subsetMapping-> _destinationDescription,destination);

  memset(subsetMapping-> _sourceOffsetForDestinationOffset, 0, 
	 extraBytes + sizeof(NSUInteger));

  return subsetMapping;
}

- (void) dealloc
{
  DESTROY(_sourceDescription);
  DESTROY(_destinationDescription);

  [super dealloc];
}

- (NSString*)description
{
  NSString *dscr;
  NSMutableString *offsets = [NSMutableString string];
  NSUInteger i;
  int count = [_destinationDescription count];

  dscr = [NSString stringWithFormat: @"<%s %p - ",
		   object_getClassName(self),
		   (void*)self];
  dscr = [dscr stringByAppendingFormat: @"\nsourceDescription=%@",
	       [_sourceDescription description]];
  dscr = [dscr stringByAppendingFormat: @"\ndestinationDescription=%@",
	       [_destinationDescription description]];

  for (i = 0; i < count; i++)
    [offsets appendFormat: @" %d", _sourceOffsetForDestinationOffset[i]];

  dscr = [dscr stringByAppendingFormat:
		 @"\nsourceOffsetForDestinationOffset:%@>", offsets];

  return dscr;
}

@end

@implementation EOMKKDArrayMapping

+ (id)newInstanceWithKeyCount: (NSUInteger)keyCount
       destinationDescription: (EOMKKDInitializer*)destination
			 zone: (NSZone*)zone
{
  NSUInteger extraBytes = (keyCount > 0 ? (keyCount - 1) : 0) * sizeof(NSUInteger);
  EOMKKDArrayMapping *arrayMapping;

  arrayMapping = (EOMKKDArrayMapping*)NSAllocateObject([EOMKKDArrayMapping class],
                                                       extraBytes,
                                                       zone);
  [arrayMapping init];

  ASSIGN(arrayMapping->_destinationDescription, destination);
  memset(arrayMapping->_destinationOffsetForArrayIndex, 0,
	 extraBytes + sizeof(NSUInteger));

  return arrayMapping;
}

- (void) dealloc
{
  DESTROY(_destinationDescription);

  [super dealloc];
}

- (NSString*)description
{
  NSString *dscr;

  dscr = [NSString stringWithFormat: @"<%s %p >",
		   object_getClassName(self),
		   (void*)self];
  return dscr;
}

@end


@implementation EOMutableKnownKeyDictionary

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;
      GDL2_PrivateInit();
    }
}

+ (id)dictionaryFromDictionary: (NSDictionary *)dict
		 subsetMapping: (EOMKKDSubsetMapping *)subsetMapping
{
  return [[self newDictionaryFromDictionary: dict
                subsetMapping: subsetMapping
                zone: NULL] autorelease];
}

+ (id)newDictionaryFromDictionary: (NSDictionary*)dict
		    subsetMapping: (EOMKKDSubsetMapping*)subsetMapping
			     zone: (NSZone*)zone
{
  EOMutableKnownKeyDictionary *newDict = nil;  
  NSUInteger objectsCount;

  NSAssert(dict, @"No dictionary");
  NSAssert(subsetMapping, @"No subsetMapping");


  EOFLOGObjectLevelArgs(@"EOMKKD", @"subsetMapping->_sourceDescription=%@",
			subsetMapping->_sourceDescription);
  EOFLOGObjectLevelArgs(@"EOMKKD", @"subsetMapping->_destinationDescription=%@",
			subsetMapping->_destinationDescription);

  objectsCount = [subsetMapping->_destinationDescription count];


  if (objectsCount > 0)
    {
      id objects[objectsCount];
      NSUInteger i;

      for (i = 0; i < objectsCount; i++)
	{
	  objects[i] = nil;

	  if (subsetMapping->_sourceOffsetForDestinationOffset[i] > 0)
	    {
	      NSUInteger index = subsetMapping->_sourceOffsetForDestinationOffset[i] - 1;

	

	      objects[i] = [subsetMapping->_sourceDescription
					 objectForIndex: index
					 dictionary: dict];

	
	      NSAssert2(objects[i], @"No object for index %d from row %@",
			index,
			dict);
	    }
	}

      newDict = [self newWithInitializer: subsetMapping->_destinationDescription
		      objects: objects
		      zone: zone];
    }
  else
    newDict = [self newWithInitializer: subsetMapping->_destinationDescription
		    zone: zone];



  return newDict;
}

+ (id)newDictionaryWithObjects: (id*)objects
		  arrayMapping: (id)mapping
			  zone: (NSZone*)zone
{
  return [self notImplemented: _cmd];
}

+ (id)newWithInitializer: (EOMKKDInitializer*)initializer
		 objects: (id*)objects
		    zone: (NSZone*)zone
{
  return [[self allocWithZone: zone] initWithInitializer: initializer
				     objects: objects];
}
  
+ (id)dictionaryWithObjects: (NSArray*)objects
		    forKeys: (NSArray*)keys
{
  EOMutableKnownKeyDictionary *dict = nil;
  NSUInteger objectsCount = [objects count];
  NSUInteger keysCount = [keys count];

  NSAssert2(objectsCount == keysCount,
            @"Objects Count (%d) is not equal to keys Count (%d)",
            objectsCount,
            keysCount);

  if (objectsCount > 0)
  {
    id objectIds[objectsCount];
    id keyIds[keysCount];

    [objects getObjects: objectIds];
    [keys getObjects: keyIds];

    dict = [[[self alloc] initWithObjects: objectIds
			  forKeys: keyIds
			  count: objectsCount] autorelease];
  }

  return dict;
}
  
+ (EOMKKDInitializer*)initializerFromKeyArray: (NSArray*)keys
{
  return [EOMKKDInitializer initializerFromKeyArray: keys];
}

+ (id)newWithInitializer: (EOMKKDInitializer*)initializer
{
  return [self newWithInitializer: initializer
               zone: NULL];
}

+ (id)newWithInitializer: (EOMKKDInitializer*)initializer
		    zone: (NSZone*)zone
{
  return [[self allocWithZone: zone] initWithInitializer: initializer];
}

+ (id) dictionaryWithInitializer: (EOMKKDInitializer*)initializer
{
  return [[self newWithInitializer: initializer]autorelease];
}

- (id) initWithInitializer: (EOMKKDInitializer*)initializer
{


  if ((self = [self init]))
    {
      NSUInteger count;

      NSAssert(initializer, @"No Initializer");


      ASSIGN(_MKKDInitializer, initializer);

      count = [_MKKDInitializer count];


      _values = NSZoneMalloc([self zone], count * sizeof(id));
      memset(_values, 0, count * sizeof(id));
    }



  return self;
}

- (id) initWithInitializer: (EOMKKDInitializer*)initializer
                   objects: (id*)objects
{


  if ((self = [self initWithInitializer: initializer]))
    {
      EOFLOGObjectLevelArgs(@"EOMKKD", @"suite objects=%p initializer=%p",
			    objects, _MKKDInitializer);

      if (objects)
        {
          NSUInteger i;
          NSUInteger count = [_MKKDInitializer count];



          for (i = 0; i < count; i++)
            {
              EOFLOGObjectLevelArgs(@"EOMKKD", @"%d=%p (old=%p)",
				   i, objects[i], _values[i]);
              ASSIGN(_values[i], objects[i]);
            }
        }
    }



  return self;
}

// This is the designated initializer
- (id) initWithObjects: (id*)objects
               forKeys: (id*)keys
                 count: (NSUInteger)count
{
  //OK
  EOMKKDInitializer *initializer = nil;



  if (count > 0)
    {
      NSAssert(keys, @"No keys array");
      NSAssert(count > 0, @"No keys");

      initializer = [[[EOMKKDInitializer alloc] initWithKeys: keys
						count: count] autorelease];

      NSAssert(initializer, @"No Initializer");


      ASSIGN(_MKKDInitializer, initializer);

      _values = NSZoneMalloc([self zone], count * sizeof(id));

      if (objects)
        {
          NSUInteger i;

          for (i = 0; i < count; i++)
            {
              ASSIGN(_values[i], objects[i]);
            }
        }
      else
        {
          memset(_values, 0, count * sizeof(id));
        }
    }

  return self;
}

- (void) dealloc
{


  if (_values)    
    {
      NSUInteger i;
      NSUInteger count = [_MKKDInitializer count];

      for (i = 0; i < count; i++)
        {
          DESTROY(_values[i]);
        }

      NSZoneFree([self zone], _values);
    }

  DESTROY(_MKKDInitializer);
  DESTROY(_extraData);

  [super dealloc];
}

- (NSUInteger) count
{
  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");
  return [_MKKDInitializer count];
}

- (id) objectForKey: (id)key
{
  id object = nil;
  NSUInteger index;
  
  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");
  
  index = EOMKKDInitializer_indexForKeyWithImpPtr(_MKKDInitializer,NULL,key);
    
  if ((index == NSNotFound))
  {
    if (_extraData)
      object = [_extraData objectForKey: key];
  }
  else
  {
    NSAssert2(index < [_MKKDInitializer count], @"bad index %d (count=%u)",
              index, [_MKKDInitializer count]);
          object = _values[index];
  }
  
  
  return object;
}

- (void) setObject: (id)object
            forKey: (id)key
{
  NSUInteger index;

  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");

  index = EOMKKDInitializer_indexForKeyWithImpPtr(_MKKDInitializer,NULL,key);

  if (index == NSNotFound)
    {
      if (!_extraData)
        _extraData = [NSMutableDictionary new];

      [_extraData setObject: object
                  forKey: key];
    }
  else
    {
      NSAssert2(index < [_MKKDInitializer count], @"bad index %d (count=%u)",
		index, [_MKKDInitializer count]);

      ASSIGN(_values[index], object);
    }
}

- (void) removeObjectForKey: (id)key
{
  NSUInteger index;

  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");

  index = EOMKKDInitializer_indexForKeyWithImpPtr(_MKKDInitializer,NULL,key);

  if (index == NSNotFound)
    {
      if (_extraData)
        [_extraData removeObjectForKey: key];
    }
  else
    {
      NSAssert2(index < [_MKKDInitializer count], @"bad index %d (count=%u)",
		index, [_MKKDInitializer count]);

      DESTROY(_values[index]);
    }
}

- (BOOL) containsObjectsNotIdenticalTo: (id)object
{
  BOOL result = NO;
  NSUInteger i;
  NSUInteger count = [_MKKDInitializer count];

  for (i = 0; !result && i < count; i++)
    {
      if (_values[i] != object)
        {
          if (_isNilOrEONull(_values[i]))
            result =! _isNilOrEONull(object);
          else if (_isNilOrEONull(object))
            result = YES;
          else
            result = ![_values[i] isEqual: object];
        }
    }



  return result;
}

- (void)addEntriesFromDictionary: (NSDictionary*)dictionary
{
  NSEnumerator *e = [dictionary keyEnumerator];
  id key=nil;
  IMP indexForKeyIMP=NULL;

  while ((key = [e nextObject]))
    {
      if (!EOMKKD_objectForKeyWithImpPtr(self,&indexForKeyIMP,key)) //Don't overwrite already present values ?
        {
          [self setObject: [dictionary objectForKey: key]
                forKey: key];
        }
    }
}

- (NSEnumerator*) keyEnumerator
{
  EOMKKDKeyEnumerator *MKKDEnum;

  MKKDEnum = [[[EOMKKDKeyEnumerator alloc] initWithTarget: self] autorelease];

  return MKKDEnum;
}

- (EOMKKDInitializer*) eoMKKDInitializer
{
  return _MKKDInitializer;
}

- (NSMutableDictionary*)extraData
{
  return _extraData;
}

- (NSString*)debugDescription
{
  NSString *dscr;
  NSUInteger i;
  NSUInteger count;
  id *keys;

  dscr = [NSString stringWithFormat: @"<%s %p - KV=",
		   object_getClassName(self),
		   (void*)self];

  count = [_MKKDInitializer count];
  keys = [_MKKDInitializer keys];

  for (i = 0; i < count; i++)
    dscr = [dscr stringByAppendingFormat: @"%@=%@\n", keys[i], _values[i]];

  dscr = [dscr stringByAppendingFormat: @"extraDatas:%@", _extraData];
  dscr = [dscr stringByAppendingString: @">"];

  return dscr;
}

- (BOOL)hasKey: (id)key
{
  if ([_MKKDInitializer hasKey: key])
    return YES;
  else if ([_extraData objectForKey: key])
    return YES;
  else
    return NO;
}

@end
