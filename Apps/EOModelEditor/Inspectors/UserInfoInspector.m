
/*
 UserInfoInspector.m
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
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
 */

#include "UserInfoInspector.h"

#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>

#include <EOModeler/EOModelerApp.h>
#include "../EOMEDocument.h"
#include "../EOMEEOAccessAdditions.h"

#include <Foundation/Foundation.h>

#import "../TableViewController.h"

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

@implementation UserInfoInspector

- (NSString *) displayName
{
  return @"User Info";
}

- (void) dealloc
{

  [super dealloc];
}



- (float) displayOrder
{
  return 5;
}

- (BOOL) canInspectObject:(id)anObject
{
  BOOL weCan = YES; //[anObject isKindOfClass:[EOModel class]];
      
  return weCan;
}

- (void) commitChanges
{
  NSMutableDictionary * mDict = [NSMutableDictionary dictionary];
  
  if ((_dataArray) && ([_dataArray count])) {
    NSEnumerator * aEnumer = [_dataArray objectEnumerator];
    NSDictionary * myDict = nil;
    
    while ((myDict = [aEnumer nextObject])) {
      [mDict setObject:[myDict objectForKey:@"value"]
                forKey:[myDict objectForKey:@"key"]];
    }

  }
  [[self selectedObject] setUserInfo:mDict];
}



- (void) refresh
{  
  [self setDataFromDictionary:[[self selectedObject] userInfo]];
  DESTROY(_selectedDict);

}



@end

