/** -*-ObjC-*-
   Postgres95LoginPanel.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: Matt Rice  <ratmice@yahoo.com>
   Date: February 2004

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
#include "Postgres95Channel.h"
#include "Postgres95SQLExpression.h"

@interface Postgres95LoginPanel : EOLoginPanel
{
  /* gui stuff */ 
  NSWindow *_win;
  NSScrollView *tableScrollView; 
  NSTableView *databases;
  NSButton *okButton; 
  NSButton *cancelButton;
  NSButton *showDatabasesButton;
  NSButton *newDatabaseButton;
  NSTextField *userNameLabel;
  NSTextField *databaseLabel;
  NSTextField *passwdLabel;
  NSTextField *databaseField;
  NSTextField *userNameField;
  NSSecureTextField *passwdField;
  
  NSArray *_databases;
}
-(void)showDatabases:(id)sender;
-(void)newDatabase:(id)sender;
-(void)ok:(id)sender;
-(void)cancel:(id)sender;
-(NSDictionary *)_runPanelForAdaptor:(EOAdaptor *)adaptor
                             validate:(BOOL)flag
                       allowsCreation:(BOOL)allowsCreation
               requiresAdministration:(BOOL)adminFlag;

@end

