/**
    ConsistencyResults.h
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: Jul 2005

    This file is part of DBModeler.
    
    <license>
    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/

#include <Foundation/NSObject.h>

#include <AppKit/NSNibDeclarations.h>

@class NSPanel;
@class NSButton;
@class NSTextView;

@interface ConsistencyResults : NSObject
{
  IBOutlet NSPanel *_panel;
  IBOutlet NSButton *okButton;
  IBOutlet NSButton *cancelButton;
  IBOutlet NSTextView *results;
  BOOL successful;
}
+ (id) sharedConsistencyPanel;
- (int) showConsistencyCheckResults:(id)sender cancelButton:(BOOL)useCancel
showOnSuccess:(BOOL)flag;
@end
