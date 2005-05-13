#include "ResourceManager.h"

#include <EOInterface/EODisplayGroup.h>

#include <EOModeler/EOModelerApp.h>

#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EODatabaseDataSource.h>

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

  for (i = 0, c = [modelPaths count]; i < c; i++)
    {
      if (![[EOModelGroup defaultGroup] modelWithPath:[modelPaths objectAtIndex:i]])
        [[EOModelGroup globalModelGroup] 
	      addModelWithFile:[modelPaths objectAtIndex:i]];
    }
} 

- (EOEditingContext *) defaultEditingContext
{
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
  EODisplayGroup *dg = [[EODisplayGroup alloc] init];
  EOEditingContext *ec = [self defaultEditingContext];
  EODatabaseDataSource *ds;
  NSString *modelPath = [pList objectAtIndex:0];

  int i,c;

  if (![[self document] containsObject:ec])
    {
      [[self document] attachObject:ec toParent:nil];
    }

  if (![[EOModelGroup defaultGroup] modelWithPath:modelPath])
    {	  
      [[EOModelGroup defaultGroup] addModelWithFile:modelPath];
    }
  ds = [[EODatabaseDataSource alloc]
	  	initWithEditingContext:ec
	  		    entityName:[pList objectAtIndex:1]];
  [dg setDataSource:ds];
  [[self document] attachObject:dg toParent:nil];
}

@end

