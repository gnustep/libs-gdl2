/** -*-ObjC-*-
   SQLite3LoginPanel.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: Matt Rice <ratmice@gmail.com>
   Date: January 2006

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/


#include <EOAccess/EOAccess.h>

@class NSPanel;
@class NSTextField;
@class NSButton;

@interface SQLite3LoginPanel : EOLoginPanel
{
  NSPanel *_win;
  NSTextField *_path;
  NSButton *_browse;
  NSButton *_ok;
  NSButton *_cancel;
}
@end
