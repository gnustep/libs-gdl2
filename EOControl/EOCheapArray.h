/* 
   EOCheapArray.h

   Copyright (C) 2000 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#ifndef __EOCheapArray_h__
#define __EOCheapArray_h__

#import <Foundation/NSArray.h>
#import <Foundation/NSZone.h>


@interface EOCheapCopyArray : NSArray
{
  unsigned int _count;
  id *_contents_array;
  unsigned int _refcount;
}

- (id) initWithArray: (id)array;
- (id) initWithObjects: (id*)objects
                 count: (unsigned int)count;
- (void) dealloc;
- (void) release;
- (unsigned int) retainCount;
- (id) retain;
- (id) objectAtIndex: (unsigned int)index;
//- (id) copyWithZone: (NSZone*)zone;
- (unsigned int) count;
//- (BOOL) containsObject: (id)obejct;

@end


@interface EOCheapCopyMutableArray : NSMutableArray
{
  unsigned int _count;
  id *_contents_array;
  unsigned int _capacity;
  unsigned int _grow_factor;
  id _immutableCopy;
}

- (id) initWithCapacity: (unsigned int)capacity;
- (id) initWithObjects: (id*)objects
                 count: (unsigned int)count;
- (id) initWithArray: (NSArray*)array;
- (void) dealloc;
- (id) shallowCopy;
- (void) _setCopy: (id)param0;
- (void) _mutate;
- (unsigned int) count;
- (id) objectAtIndex: (unsigned int)index;
- (void) addObject: (id)object;
- (void) insertObject: (id)object
              atIndex: (unsigned int)index;
- (void) removeLastObject;
- (void) removeObjectAtIndex: (unsigned int)index;
- (void) replaceObjectAtIndex: (unsigned int)index
                   withObject: (id)object;
//- (BOOL) containsObject: (id)object;
//- (unsigned int) indexOfObjectIdenticalTo: (id)object;
//- (void) removeAllObjects;
- (void) exchangeObjectAtIndex: (unsigned int)index1
             withObjectAtIndex: (unsigned int)index2;
@end


#endif //__EOCheapArray_h__
