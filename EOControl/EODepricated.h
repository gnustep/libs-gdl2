/**
   EODeprecated.h

   Copyright (C) 2003 Free Software Foundation, Inc.

   Author: Stephane Corthesy <stephane@sente.ch>
   Date: March 2003

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

#ifndef __EOControl_EODeprecated_h__
#define __EOControl_EODeprecated_h__

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSUndoManager.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODefines.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EOFetchSpecification.h>

@interface NSObject (EODeprecated)
/** Depricated. GDL2 doesn't cache key bindungs.*/
+ (void) flushClassKeyBindings;
@end

@interface EOClassDescription (EODeprecated)
/** Depricated. Use +setClassDelegate. */
+ (void) setDelegate:(id)delegate;
/** Depricated. Use +classDelegate. */
+ (id) delegate;
@end

/** Depricated. Use NSUndoManager. */
@interface EOUndoManager : NSUndoManager

/** Depricated. Use -removeAllActionsWithTarget:. */
- (void) forgetAllWithTarget: (id)param0;

/** Depricated. Use -removeAllActionsWithTarget:. */
- (void) forgetAll;

/** Depricated. Use -registerUndoWithTarget:selector:object:. */
- (void) registerUndoWithTarget: (id)param0
                       selector: (SEL)param1
                            arg: (id)param2;

/** Depricated. Use -enableUndoRegistration. */
- (void) reenableUndoRegistration; 

@end


#endif 
