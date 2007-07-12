/* -*-objc-*-
   EOAttribute+GSDoc.h <title></title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: August 2000

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

// $Id$

#ifndef __EOAttribute_GSDoc_h__
#define __EOAttribute_GSDoc_h__

#include <EOAccess/EOAttribute.h>


@interface EOAttribute (GSDoc)

- (NSString *)gsdocContentWithIdPtr: (int *)xmlIdPtr;
- (NSString *)gsdocContentWithTagName: (NSString *)tagName
                                idPtr: (int *)xmlIdPtr;

@end


#endif /* __EOAttribute_GSDoc_h__ */
