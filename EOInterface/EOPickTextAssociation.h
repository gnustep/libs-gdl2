/** -*-ObjC-*-
   EOPickTextAssociation.h

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: David Ayers <d.ayers@inode.at>

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 2, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
*/

#ifndef __EOInterface_EOPickTextAssociation_h__
#define __EOInterface_EOPickTextAssociation_h__

#include <EOInterface/EOAssociation.h>

@class NSString;
@class NSArray;

@class EODisplayGroup;

@interface EOPickTextAssociation : EOAssociation
{
  BOOL _applyImmediately;
}

/* Defining capabilities of concete class.  */
+ (NSArray *)aspects;
+ (NSArray *)aspectSignatures;

+ (NSArray *)objectKeysTaken;
+ (BOOL)isUsableWithObject: (id)object;

+ (NSString *)primaryAspect;

/* Creation and configuration.  */
- (void)establishConnection;
- (void)breakConnection;

/* Display object value manipulation.  */
- (void)subjectChanged;

- (void)action: (id)sender;

@end

#endif
