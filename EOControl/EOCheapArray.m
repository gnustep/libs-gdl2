/**
   EOCheapArray.m <title>EOCheapCopyArray Classes</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Sep 2000

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

#include "config.h"

RCS_ID("$Id$")

#import <Foundation/Foundation.h>

#import <EOControl/EOCheapArray.h>
#import <EOControl/EODebug.h>


@implementation EOCheapCopyArray : NSArray

- (id) initWithArray: (id)array
{
  if ((self = [super initWithArray: array]))
    {
    }

  return self;
}

- (id) initWithObjects: (id*)objects
                 count: (unsigned int)count
{
  if (count > 0)
    {
      unsigned  i;

      _contents_array = NSZoneMalloc([self zone], sizeof(id) * count);

      if (_contents_array == 0)
        {
          RELEASE(self);
          return nil;
       }

      for (i = 0; i < count; i++)
        {
          if ((_contents_array[i] = RETAIN(objects[i])) == nil)
            {
              _count = i;
              RELEASE(self);
              [NSException raise: NSInvalidArgumentException
                          format: @"Tried to add nil"];
            }
        }

      _count = count;
    }

  return self;
}

- (void) dealloc
{
  NSDebugMLLog(@"gsdb", @"Deallocate EOCheapCopyArray %p", self);

  if (_contents_array)
    {
#if     !GS_WITH_GC
      unsigned i;

      for (i = 0; i < _count; i++)
        {
          [_contents_array[i] release];
        }
#endif
      NSZoneFree([self zone], _contents_array);
    }

  NSDeallocateObject(self);
}

- (void) release
{
  NSDebugMLLog(@"gsdb", @"Release EOCheapCopyArray %p", self);
  //TODO-NOW
}

- (unsigned int) retainCount
{
  NSDebugMLLog(@"gsdb", @"retainCount EOCheapCopyArray %p", self);
  //TODO-NOW
  return 1;
}

- (id) retain
{
  //TODO-NOW
  NSDebugMLLog(@"gsdb", @"retain EOCheapCopyArray %p", self);
  return self;
}

- (id) objectAtIndex: (unsigned int)index
{
  if (index >= _count)
    {
      [NSException raise: NSRangeException
                  format: @"Index out of bounds"];
    }

  return _contents_array[index];
}

//- (id) copyWithZone: (NSZone*)zone;
- (unsigned int) count
{
  return _count;
}

//- (BOOL) containsObject: (id)obejct;
@end

@implementation EOCheapCopyMutableArray

- (id) initWithCapacity: (unsigned int)capacity
{
  if (capacity == 0)
    {
      capacity = 1;
    }

  _contents_array = NSZoneMalloc([self zone], sizeof(id) * capacity);
  _capacity = capacity;
  _grow_factor = capacity > 1 ? capacity/2 : 1;

  return self;
}

- (id) initWithObjects: (id*)objects
                 count: (unsigned int)count
{
  self = [self initWithCapacity: count];

  if (self != nil && count > 0)
    {
      unsigned  i;

      for (i = 0; i < count; i++)
        {
          if ((_contents_array[i] = RETAIN(objects[i])) == nil)
            {
              _count = i;
              RELEASE(self);
              [NSException raise: NSInvalidArgumentException
                          format: @"Tried to add nil"];
            }
        }
      _count = count;
    }

  return self;
}

- (id) initWithArray:(NSArray*)array
{
  _grow_factor = 5;

  if ((self = [super initWithArray: array]))
    {
    }

  return self;
}

- (void) dealloc
{
  NSDebugMLLog(@"gsdb", @"Deallocate EOCheapCopyArray %p", self);

  if (_contents_array)
    {
#if     !GS_WITH_GC
      unsigned  i;
      for (i = 0; i < _count; i++)
        {
          [_contents_array[i] release];
        }
#endif
      NSZoneFree([self zone], _contents_array);
    }

  DESTROY(_immutableCopy);
  NSDeallocateObject(self);
}

- (id) shallowCopy
{
  //OK
  if (!_immutableCopy)
    {
      _immutableCopy= [[EOCheapCopyArray alloc]
			initWithObjects: _contents_array
			count: _count];
    }

  return _immutableCopy;
}

- (void) _setCopy: (id)param0
{
  //TODO
}

- (void) _mutate
{
  DESTROY(_immutableCopy);
}

- (unsigned int) count
{
  return _count;
}

- (id) objectAtIndex: (unsigned int)index
{
  if (index >= _count)
    {
      [NSException raise: NSRangeException
                  format: @"Index out of bounds"];
    }

  return _contents_array[index];
}

- (void)addObject: (id)object
{
//7d0
//im=530
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"self %p=%@", self, self);
  NSDebugMLLog(@"gsdb", @"object %p of class %@=%@",
               object,
               [object class],
               object);

  if (!object)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Tried to add nil"];
    }

  NSDebugMLLog(@"gsdb", @"self %p=%@", self, self);

  [self _mutate];

  NSDebugMLLog(@"gsdb",@"self %p=%@", self, self);

  if (_count >= _capacity)
    {
      unsigned int grow = (_grow_factor>5 ? _grow_factor : 5);
      size_t size = (_capacity + grow) * sizeof(id);
      id *ptr;

      ptr = NSZoneRealloc([self zone], _contents_array, size);

      if (ptr == 0)
        {
          [NSException raise: NSMallocException
                      format: @"Unable to grow"];
        }

      _contents_array = ptr;
      _capacity += _grow_factor;
      _grow_factor = _capacity / 2;
    }

  _contents_array[_count] = RETAIN(object);
  _count++;     // Do this AFTER we have retained the object.

  NSDebugMLLog(@"gsdb", @"self %p=%@", self, self);

  EOFLOGObjectFnStop();
}

- (void) insertObject: (id)object
              atIndex: (unsigned int)index
{
  unsigned i;

  if (!object)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Tried to insert nil"];
    }

  if (index > _count)
    {
      [NSException raise: NSRangeException
		   format:
		     @"in insertObject:atIndex:, index %d is out of range",
		   index];
    }

  [self _mutate];

  if (_count == _capacity)
    {
      id        *ptr;
      size_t    size = (_capacity + _grow_factor) * sizeof(id);

      ptr = NSZoneRealloc([self zone], _contents_array, size);

      if (ptr == 0)
        {
          [NSException raise: NSMallocException
                      format: @"Unable to grow"];
        }

      _contents_array = ptr;
      _capacity += _grow_factor;
      _grow_factor = _capacity / 2;
    }

  for (i = _count; i > index; i--)
    {
      _contents_array[i] = _contents_array[i - 1];
    }

  /*
   *    Make sure the array is 'sane' so that it can be deallocated
   *    safely by an autorelease pool if the '[anObject retain]' causes
   *    an exception.
   */
  _contents_array[index] = nil;
  _count++;
  _contents_array[index] = RETAIN(object);
}

- (void) removeLastObject
{
  if (_count == 0)
    {
      [NSException raise: NSRangeException
                  format: @"Trying to remove from an empty array."];
    }

  [self _mutate];
  _count--;

  RELEASE(_contents_array[_count]);
}

- (void) removeObjectAtIndex: (unsigned int)index
{
  id    obj;

  if (index >= _count)
    {
      [NSException raise: NSRangeException
                  format: @"in removeObjectAtIndex:, index %d is out of range",
                        index];
    }
  obj = _contents_array[index];
  [self _mutate];
  _count--;

  while (index < _count)
    {
      _contents_array[index] = _contents_array[index+1];
      index++;
    }

  RELEASE(obj); /* Adjust array BEFORE releasing object.        */
}

- (void) replaceObjectAtIndex: (unsigned int)index
                   withObject: (id)object;
{
  id    obj;

  if (index >= _count)
    {
      [NSException raise: NSRangeException format:
            @"in replaceObjectAtIndex:withObject:, index %d is out of range",
            index];
    }

  /*
   *    Swap objects in order so that there is always a valid object in the
   *    array in case a retain or release causes an exception.
   */
  obj = _contents_array[index];
  [self _mutate];

  IF_NO_GC(RETAIN(object));
  _contents_array[index] = object;

  RELEASE(obj);
}

//TODO implement it for speed ?? - (BOOL) containsObject:(id)object
//TODO implement it for speed ?? - (unsigned int) indexOfObjectIdenticalTo:(id)object
//TODO implement it for speed ?? - (void) removeAllObjects;
- (void) exchangeObjectAtIndex: (unsigned int)index1
             withObjectAtIndex: (unsigned int)index2
{
  id obj = nil;

  if (index1 >= _count || index2>=_count)
    {      
      [NSException raise: NSRangeException format:
            @"in exchangeObjectAtIndex:withObjectAtIndex:, index %d is out of range",
            (index1 >= _count ? index1 : index2)];
    }

  obj = _contents_array[index1];

  [self _mutate];

  _contents_array[index1] = _contents_array[index2];
  _contents_array[index2] = obj;
}

@end
