/**
    ResourceManager.m

    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006

    This file is part of GDL2Palette.

    <license>
    GDL2Palette is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    GDL2Palette is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with GDL2Palette; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/

#include "ResourceManager.h"

#include <EOInterface/EOAspectConnector.h>
#include <EOInterface/EODisplayGroup.h>
#include <EOInterface/EOMasterDetailAssociation.h>

#include <EOModeler/EOModelerApp.h>
#include <GormCore/GormDocument.h>

#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EODatabaseDataSource.h>

#include <EOControl/EODetailDataSource.h>

#include <AppKit/NSPasteboard.h>

#include <Foundation/NSBundle.h>
#include <Foundation/NSNotification.h>

@implementation GDL2ResourceManager
- (id) initWithDocument:(id<IBDocuments>)doc
{
  self = [super initWithDocument:doc];
  [[NSNotificationCenter defaultCenter] addObserver:self
	      		selector:@selector(didOpenDocument:)
			name:IBDidOpenDocumentNotification
			object:[self document]];
  
  
  return self;
}

- (void) didOpenDocument:(NSNotification *)notif
{
  /* this should probably use a different model group for each gorm document */
  NSArray  *tmp;
  NSMutableArray *modelPaths = [NSMutableArray new];
  NSString *docPath;
  int i,c;
  docPath = [[[self document] documentPath] stringByDeletingLastPathComponent];
  tmp = [[NSBundle bundleWithPath: docPath] 
  		pathsForResourcesOfType:@"eomodeld"
			    inDirectory:nil];
  [modelPaths addObjectsFromArray:tmp];
  tmp = [[NSBundle bundleWithPath: docPath] 
	  	pathsForResourcesOfType:@"eomodel"
			    inDirectory:nil];
  [modelPaths addObjectsFromArray:tmp];

  for (i = 0, c = [modelPaths count]; i < c; i++)
    {
      if (![[EOModelGroup defaultGroup] modelWithPath:[modelPaths objectAtIndex:i]])
        [[EOModelGroup globalModelGroup] 
	      addModelWithFile:[modelPaths objectAtIndex:i]];
    }
} 

- (EOEditingContext *) defaultEditingContext
{
  NSArray *tmp;
  unsigned i, c;
  
  tmp = [[self document] objects];
  for (i = 0, c = [tmp count]; i < c; i++)
    {
      id obj = [tmp objectAtIndex:i];
      
      if ([obj isKindOfClass:[EOEditingContext class]])
        {
	  _defaultEditingContext = obj;
        }
    }

  if (!_defaultEditingContext)
    _defaultEditingContext = [[EOEditingContext alloc] init];
  
  return _defaultEditingContext;
}

- (BOOL) acceptsResourcesFromPasteboard:(NSPasteboard *)pb
{
  return [[pb types] containsObject:EOMPropertyPboardType];
}

- (NSArray *)resourcePasteboardTypes
{
  return [NSArray arrayWithObject: EOMPropertyPboardType];
}

- (void) addResourcesFromPasteboard:(NSPasteboard *)pb
{
  NSArray *pList = [pb propertyListForType:EOMPropertyPboardType];
  EOEditingContext *ec = [self defaultEditingContext];
  NSString *modelPath = [pList objectAtIndex:0];
  int c = [pList count];

  if (![[self document] containsObject:ec])
    {
      [[self document] attachObject:ec toParent:nil];
    }

  if (![[EOModelGroup defaultGroup] modelWithPath:modelPath])
    {	  
      [[EOModelGroup defaultGroup] addModelWithFile:modelPath];
    }
  
  if (c == 2)
    {
      EODisplayGroup *dg = [[EODisplayGroup alloc] init];
      EODataSource *ds;
      NSNibOutletConnector *dsConn;
      NSString *eName = [pList objectAtIndex:1];
      ds = [[EODatabaseDataSource alloc]
	  	initWithEditingContext:ec
	  		    entityName:eName];
      [dg setDataSource:ds];
      RELEASE(ds);
      [[self document] attachObject:dg toParent:nil];
      [[self document] setName:eName forObject:dg];
      dsConn = [[NSNibOutletConnector alloc] init];
      [dsConn setSource:ds];
      [dsConn setDestination:dg];
      [dsConn setLabel: [NSString stringWithFormat:@"dataSource - %@", [ds class]]];
      RELEASE(dg);
      [[(id<IB>)NSApp activeDocument] addConnector: AUTORELEASE(dsConn)];
    }
  else if (c == 3) /* relationship name */
    {
      /* FIXME only valid for to many relationships */
      EODisplayGroup *masterDG;
      EODisplayGroup *detailDG;
      NSNibOutletConnector *dsConn;
      EOAspectConnector *conn;
      EOAssociation *assoc;
      EODataSource *ds;
      NSString *entName = [pList objectAtIndex:1];
      NSString *relName = [pList objectAtIndex:2];
      masterDG = [[EODisplayGroup alloc] init];
      detailDG = [[EODisplayGroup alloc] init];
      ds = [[EODatabaseDataSource alloc] initWithEditingContext:ec
					 entityName:entName];
      [masterDG setDataSource:ds];
      RELEASE(ds);
      
      dsConn = AUTORELEASE([[NSNibOutletConnector alloc] init]);
      [dsConn setSource:ds];
      [dsConn setDestination:masterDG];
      [dsConn setLabel: [NSString stringWithFormat:@"dataSource - %@", [ds class]]];
      
      [[self document] attachObject:masterDG toParent:nil];
      [[self document] setName:entName forObject:masterDG];
      [[(id<IB>)NSApp activeDocument] addConnector: dsConn];
      ds = [ds dataSourceQualifiedByKey:relName];
      [detailDG setDataSource:ds];
      
      assoc = [[EOMasterDetailAssociation alloc] initWithObject:detailDG];
      [assoc bindAspect:@"parent"
	    displayGroup:masterDG
	    key:relName];
      conn = [[EOAspectConnector alloc] initWithAssociation:assoc
	    				aspectName:@"parent"];

      [conn setSource:masterDG];
      [conn setDestination:detailDG];
      [conn setLabel:[NSString stringWithFormat:@"parent - %@",[pList objectAtIndex:2]]];
      
      dsConn = [[NSNibOutletConnector alloc] init];
      [dsConn setSource:ds];
      [dsConn setDestination:detailDG];
      [dsConn setLabel: [NSString stringWithFormat:@"dataSource - %@", [ds class]]];
      [[self document] attachObject:detailDG toParent:nil];
      [[self document] setName:relName forObject:detailDG];
      [[(id<IB>)NSApp activeDocument] addConnector: conn];
      [[(id<IB>)NSApp activeDocument] addConnector: AUTORELEASE(dsConn)];
      RELEASE(masterDG);
      RELEASE(detailDG);
    }
}

@end

