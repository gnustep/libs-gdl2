/* 
   SQLite3Channel.h

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@gmail.com>
   Date: 2006

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __SQLITE3_CHANNEL_H

#include "SQLite3Expression.h"
#include <EOAccess/EOAdaptorChannel.h>
#include <sqlite3.h>
  

@interface SQLite3Channel : EOAdaptorChannel
{
  sqlite3 *_sqlite3Conn; 
  BOOL _isFetchInProgress;
  sqlite3_stmt *_currentStmt;
  int _status;
  NSArray *_attributesToFetch;
}
@end

#define __SQLITE3_CHANNEL_H
#endif
