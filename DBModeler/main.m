/**
    main.m
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: Apr 2005

    This file is part of DBModeler.
    
    <license>
    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
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


#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSAutoreleasePool.h>
#endif

#include <EOModeler/EOModelerApp.h>
#include "Modeler.h"

#include <Renaissance/Renaissance.h>

#include <GNUstepBase/GNUstep.h>

int main (int argc, const char **argv)
{
  Modeler *m;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
 
  [EOModelerApp sharedApplication];
  m = [[Modeler alloc] init];
  [NSApp setDelegate: m];

#ifdef NeXT_GUI_LIBRARY
  [NSBundle loadGSMarkupNamed: @"Menu-Cocoa" owner: m];
#else
  [NSBundle loadGSMarkupNamed: @"Menu-GNUstep" owner: m];
#endif

  [NSApp run];
  RELEASE(pool);
  return 0;
}
