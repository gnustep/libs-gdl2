/**
   EEOMutableKnownKeyDictionary.m <title>EEOMutableKnownKeyDictionary</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

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
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
   </license>
**/

static char rcsId[] = "$Id$";

#import <Foundation/Foundation.h>

#import <EOControl/EOControl.h>
#import <EOControl/EOMutableKnownKeyDictionary.h>
#import <EOControl/EODebug.h>


@implementation EOMKKDInitializer

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
	     count: (int)count
{
  if ((self = [self init]))
    {
      int i;

      NSAssert(keys, @"No array of keys");
      NSAssert(count > 0, @"No keys in array");

      _keyToIndex = NSCreateMapTableWithZone(NSObjectMapKeyCallBacks, 
					     NSIntMapValueCallBacks,
					     count,
					     [self zone]);
      _keys = NSZoneMalloc([self zone], count * sizeof(NSString*));

      EOFLOGObjectLevelArgs(@"EOMKKD", @"keys=%p _keys=%p", keys, _keys);

      for (i = 0; i < count; i++)
        {
          id key = keys[i];
          void *oldValue;

          _count = i + 1;

          EOFLOGObjectLevelArgs(@"EOMKKD", @"key=%p", key);
          EOFLOGObjectLevelArgs(@"EOMKKD", @"key=%@ RETAINCOUNT=%d",
				key, [key retainCount]);

          oldValue = NSMapInsertIfAbsent(_keyToIndex,key, (const void*)(i + 1)); //+1 because 0 = no object
          _keys[i] = key; //Don't retain: already retained by Map

          EOFLOGObjectLevelArgs(@"EOMKKD", @"key=%@ RETAINCOUNT=%d",
				key, [key retainCount]);
          NSAssert1(!oldValue, @"%@ already present", key);
        }

      EOFLOGObjectLevelArgs(@"EOMKKD", @"self=%p", self);
    }

  return self;
}

- (id)initWithKeys: (NSArray*)keys
{
  int count = [keys count];

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

  EOFLOGObjectLevelArgs(@"EOMKKD", @"self=%p", self);

  return self;
}

- (void)dealloc
{
  EOFLOGObjectLevelArgs(@"EOMKKD", @"Deallocate EOMKKDInitliazer %p", self);

  if (_keyToIndex)
    NSFreeMapTable(_keyToIndex);
  if (_keys)    
    NSZoneFree([self zone],_keys);

  [super dealloc];

  //EOFLogC("GSWElementIDString end of dealloc");
}

- (void)gcDecrementRefCountOfContainedObjects
{
//    [X gcDecrementRefCount];
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  if (![super gcIncrementRefCountOfContainedObjects])
    return NO;
  
  //[XX gcIncrementRefCount];
  //[XX gcIncrementRefCountOfContainedObjects];
  return YES;
}

- (NSString*)description
{
  NSString *dscr;
  int i;

  dscr = [NSString stringWithFormat: @"<%s %p - keys=",
		   object_get_class_name(self),
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
          forIndex: (unsigned int)index
        dictionary: (NSMutableDictionary*)dictionary
{
  //OK?
  id key;

  NSAssert2(index < _count, @"bad index %d (count=%u)", index, _count);

  key = _keys[index];

  [dictionary setObject: object
              forKey: key];
}

- (id) objectForIndex: (unsigned int)index
           dictionary: (NSDictionary*)dictionary
{
  id key;

  NSAssert2(index < _count, @"bad index %d (count=%u)", index, _count);

  key = _keys[index];

  return [dictionary objectForKey: key];
}

- (unsigned int) indexForKey: (NSString*)key
{
  void *index = NSMapGet(_keyToIndex, (const void *)key);

  if (!index)
    return NSNotFound;
  else
    return (unsigned int)(index - 1);
}

- (BOOL)hasKey: (id)key
{
  return ([self indexForKey: key] != NSNotFound);
}

- (EOMKKDArrayMapping*) arrayMappingForKeys: (NSArray*)keys
{
  int selfKeyCount = [keys count];
  int keyCount = [keys count];
  EOMKKDArrayMapping *arrayMapping;
  int i;

  NSAssert(keyCount <= selfKeyCount, @"key count greater than our key count");

  arrayMapping = [[EOMKKDArrayMapping newInstanceWithKeyCount: selfKeyCount
				      destinationDescription: self
				      zone: [self zone]] autorelease];  

  for (i = 0; i < keyCount; i++)
    {
      NSString *key = [keys objectAtIndex: i];
      int destinationIndex = [self indexForKey:key];

      arrayMapping->_destinationOffsetForArrayIndex[i] = destinationIndex + 1;
    }

  return arrayMapping;
}

- (EOMKKDSubsetMapping*) subsetMappingForSourceDictionaryInitializer: (EOMKKDInitializer*)sourceInitializer
                                                          sourceKeys: (NSArray*)sourceKeys
                                                     destinationKeys: (NSArray*)destinationKeys
{
  unsigned int selfKeyCount = [self count];
  unsigned int keyCount = [destinationKeys count];
  EOMKKDSubsetMapping *subsetMapping;
  int i;

  NSAssert([sourceKeys count] == keyCount, @"Source and destination keys count are different");
  NSAssert(keyCount <= selfKeyCount, @"key count greater than our key count");

  subsetMapping = [[EOMKKDSubsetMapping newInstanceWithKeyCount: selfKeyCount
					sourceDescription: sourceInitializer
					destinationDescription: self
					zone: [self zone]] autorelease];  

  EOFLOGObjectLevelArgs(@"EOMKKD", @"sourceDescription=%@", sourceInitializer);
  EOFLOGObjectLevelArgs(@"EOMKKD", @"destinationDescription=%@", self);
  EOFLOGObjectLevelArgs(@"EOMKKD", @"sourceKeys=%@", sourceKeys);
  EOFLOGObjectLevelArgs(@"EOMKKD", @"destinationKeys=%@", destinationKeys);

  for (i = 0; i < keyCount; i++)
    {
      NSString *sourceKey;
      NSString *destinationKey;
      int destinationIndex;
      int sourceIndex;

      sourceKey = [sourceKeys objectAtIndex: i];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"sourceKey=%@", sourceKey);

      destinationKey = [destinationKeys objectAtIndex: i];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"destinationKey=%@", destinationKey);

      destinationIndex = [self indexForKey: destinationKey];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"destinationIndex=%d",
			    destinationIndex);

      sourceIndex = [sourceInitializer indexForKey: sourceKey];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"sourceIndex=%d", sourceIndex);

      NSAssert2(destinationIndex != NSNotFound,
                @"Key %@ not found in %@",
                destinationKey,
                self);
      NSAssert2(sourceIndex != NSNotFound,
                @"Key %@ not found in %@",
                sourceKey,
                sourceInitializer);

      subsetMapping->_sourceOffsetForDestinationOffset[destinationIndex]
	= sourceIndex + 1;
    }

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
  int i;

  for (i = 0; i < keyCount; i++)
    {
      NSString *key;
      int index;

      key = _keys[i];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"key=%@", key);

      index = [sourceInitializer indexForKey: key];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"index=%d", index);

      subsetMapping->_sourceOffsetForDestinationOffset[i]
	= (index == NSNotFound ? 0 : index + 1);
    }

  return subsetMapping;
}

- (id*) keys
{
  return _keys;
}

- (unsigned int) count
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
    }

  return self;
}

- (void) dealloc
{
//  EOFLOGObjectLevelArgs(@"EOMKKD",@"Deallocate EOMKKDEnumerator %p (target=%p)",self,_target);
  DESTROY(_target);
  DESTROY(_extraEnumerator);

  [super dealloc];
}

- (NSString*)description
{
  NSString *dscr;

  dscr = [NSString stringWithFormat: @"<%s %p - target=%p>",
		   object_get_class_name(self),
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

+ (id)newInstanceWithKeyCount: (unsigned int)keyCount
	    sourceDescription: (EOMKKDInitializer*)source
       destinationDescription: (EOMKKDInitializer*)destination
			 zone: (NSZone*)zone
{
  unsigned extraBytes = (keyCount > 0 ? (keyCount - 1) : 0) * sizeof(int);
  EOMKKDSubsetMapping *subsetMapping;

  subsetMapping = (EOMKKDSubsetMapping*)NSAllocateObject([EOMKKDSubsetMapping class],
							 extraBytes,
							 zone);
  [subsetMapping init];

  ASSIGN(subsetMapping-> _sourceDescription,source);
  ASSIGN(subsetMapping-> _destinationDescription,destination);

  memset(subsetMapping-> _sourceOffsetForDestinationOffset, 0, 
	 extraBytes + sizeof(int));

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
  int i;
  int count = [_destinationDescription count];

  dscr = [NSString stringWithFormat: @"<%s %p - ",
		   object_get_class_name(self),
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

+ (id)dictionaryFromDictionary: (NSDictionary *)dict
		 subsetMapping: (EOMKKDSubsetMapping *)subsetMapping
{
  return [[self newDictionaryFromDictionary: dict
                subsetMapping: subsetMapping
                zone: NULL] autorelease];
}

+ (id)newInstanceWithKeyCount: (unsigned int)keyCount
       destinationDescription: (EOMKKDInitializer*)destination
			 zone: (NSZone*)zone
{
  unsigned extraBytes = (keyCount > 0 ? (keyCount - 1) : 0) * sizeof(int);
  EOMKKDArrayMapping *arrayMapping;

  arrayMapping = (EOMKKDArrayMapping*)NSAllocateObject([EOMKKDArrayMapping class],
                                                       extraBytes,
                                                       zone);
  [arrayMapping init];

  ASSIGN(arrayMapping->_destinationDescription, destination);
  memset(arrayMapping->_destinationOffsetForArrayIndex, 0,
	 extraBytes + sizeof(int));

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
		   object_get_class_name(self),
		   (void*)self];
  return dscr;
}

@end


@implementation EOMutableKnownKeyDictionary

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
  int objectsCount;

  NSAssert(dict, @"No dictionary");
  NSAssert(subsetMapping, @"No subsetMapping");

  EOFLOGObjectLevelArgs(@"EOMKKD", @"dict=%@", dict);
  EOFLOGObjectLevelArgs(@"EOMKKD", @"subsetMapping->_sourceDescription=%@",
			subsetMapping->_sourceDescription);
  EOFLOGObjectLevelArgs(@"EOMKKD", @"subsetMapping->_destinationDescription=%@",
			subsetMapping->_destinationDescription);

  objectsCount = [subsetMapping->_destinationDescription count];
  EOFLOGObjectLevelArgs(@"EOMKKD", @"objectsCount=%d", objectsCount);

  if (objectsCount > 0)
    {
      id objects[objectsCount];
      int i;

      for (i = 0; i < objectsCount; i++)
	{
	  objects[i] = nil;

	  if (subsetMapping->_sourceOffsetForDestinationOffset[i] > 0)
	    {
	      int index = subsetMapping->_sourceOffsetForDestinationOffset[i] - 1;

	      EOFLOGObjectLevelArgs(@"EOMKKD", @"index=%d", index);

	      objects[i] = [subsetMapping->_sourceDescription
					 objectForIndex: index
					 dictionary: dict];

	      EOFLOGObjectLevelArgs(@"EOMKKD", @"objects[i]=%@", objects[i]);
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

  EOFLOGObjectLevel(@"EOMKKD", @"END");

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
  int objectsCount = [objects count];
  int keysCount = [keys count];

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
  EOFLOGObjectFnStart();

  if ((self = [self init]))
    {
      int count;

      NSAssert(initializer, @"No Initializer");
      EOFLOGObjectLevel(@"EOMKKD", @"suite");

      ASSIGN(_MKKDInitializer, initializer);

      count = [_MKKDInitializer count];
      EOFLOGObjectLevelArgs(@"EOMKKD", @"count=%d", count);

      _values = NSZoneMalloc([self zone], count * sizeof(id));
      memset(_values, 0, count * sizeof(id));
    }

  EOFLOGObjectFnStop();

  return self;
}

- (id) initWithInitializer: (EOMKKDInitializer*)initializer
                   objects: (id*)objects
{
  EOFLOGObjectFnStart();

  if ((self = [self initWithInitializer: initializer]))
    {
      EOFLOGObjectLevelArgs(@"EOMKKD", @"suite objects=%p initializer=%p",
			    objects, _MKKDInitializer);

      if (objects)
        {
          int i;
          int count = [_MKKDInitializer count];

          EOFLOGObjectLevelArgs(@"EOMKKD", @"count=%d", count);

          for (i = 0; i < count; i++)
            {
              EOFLOGObjectLevelArgs(@"EOMKKD", @"%d=%p (old=%p)",
				   i, objects[i], _values[i]);
              ASSIGN(_values[i], objects[i]);
            }
        }
    }

  EOFLOGObjectLevel(@"EOMKKD", @"END");

  return self;
}

// This is the designated initializer
- (id) initWithObjects: (id*)objects
               forKeys: (id*)keys
                 count: (unsigned int)count
{
  //OK
  EOMKKDInitializer *initializer = nil;

  EOFLOGObjectFnStart();

  if (count > 0)
    {
      NSAssert(keys, @"No keys array");
      NSAssert(count > 0, @"No keys");

      initializer = [[[EOMKKDInitializer alloc] initWithKeys: keys
						count: count] autorelease];

      NSAssert(initializer, @"No Initializer");
      EOFLOGObjectLevel(@"EOMKKD", @"suite");

      ASSIGN(_MKKDInitializer, initializer);

      _values = NSZoneMalloc([self zone], count * sizeof(id));

      if (objects)
        {
          int i;

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
  EOFLOGObjectLevelArgs(@"EOMKKD", @"Deallocate EOMKKDDictionary %p", self);

  if (_values)    
    {
      int i;
      unsigned int count = [_MKKDInitializer count];

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

- (unsigned int) count
{
  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");
  return [_MKKDInitializer count];
}

- (id) objectForKey: (NSString*)key
{
  id object = nil;
  unsigned int index;

//  EOFLOGObjectFnStart();
  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");

  index = [_MKKDInitializer indexForKey: key];

//  EOFLOGObjectLevelArgs(@"EOMKKD", @"index=%d", index);

  if (index == NSNotFound)
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

//  EOFLOGObjectLevelArgs(@"EOMKKD",@"object=%p",object);
//  EOFLOGObjectFnStop();

  return object;
}

- (void) setObject: (id)object
            forKey: (NSString*)key
{
  unsigned int index;

  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");

  index = [_MKKDInitializer indexForKey: key];

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

- (void) removeObjectForKey: (NSString*)key
{
  unsigned int index;

  NSAssert(_MKKDInitializer, @"No _MKKDInitializer");

  index = [_MKKDInitializer indexForKey: key];

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
  int i;
  unsigned int count = [_MKKDInitializer count];

  for (i = 0; !result && i < count; i++)
    {
      if (_values[i] != object)
        {
          if (isNilOrEONull(_values[i]))
            result =! isNilOrEONull(object);
          else if (isNilOrEONull(object))
            result = YES;
          else
            result = ![_values[i] isEqual: object];
        }
    }

  EOFLOGObjectLevelArgs(@"EOMKKD", @"result = %s", (result ? "YES" : "NO"));

  return result;
}

- (void)addEntriesFromDictionary: (NSDictionary*)dictionary
{
  NSEnumerator *e = [dictionary keyEnumerator];
  id key;

  while ((key = [e nextObject]))
    {
      if (![self objectForKey: key]) //Don't overwrite already present values ?
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
  int i;
  int count;
  id *keys;

  dscr = [NSString stringWithFormat: @"<%s %p - KV=",
		   object_get_class_name(self),
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
