/* 
   EONull.h

   Copyright (C) 1996-2002 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Date: 1996

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

#ifndef __EONull_h__
#define __EONull_h__

#import <Foundation/NSObject.h>


@interface EONull : NSObject <NSCopying>
+ null;
@end /* EONull */

@interface NSObject (EONull)

- (BOOL)isEONull;
- (BOOL)isNotEONull;

@end

extern BOOL isNilOrEONull(id v);

#endif /* __EONull_h__ */
