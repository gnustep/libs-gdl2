/**
 main.m
 
 Author: Matt Rice <ratmice@gmail.com>
 Date: Apr 2005
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
 <license>
 EOModelEditor is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 EOModelEditor is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with EOModelEditor; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 </license>
 **/


#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSAutoreleasePool.h>
#endif

#include "EOModelEditorApp.h"

#include <Renaissance/Renaissance.h>

#include <GNUstepBase/GNUstep.h>


// required for windows.
int (*linkRenaissanceIn)(int, const char **) = GSMarkupApplicationMain; 

int main (int argc, const char **argv)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [EOModelEditorApp sharedApplication];

  [NSApp setDelegate: NSApp];

  
#ifdef NeXT_GUI_LIBRARY
  [NSBundle loadGSMarkupNamed: @"Menu-Cocoa" owner: NSApp];
#else
  [NSBundle loadGSMarkupNamed: @"Menu-GNUstep" owner: NSApp];
#endif
  
  [NSApp run];
  RELEASE(pool);
  return 0;
}
