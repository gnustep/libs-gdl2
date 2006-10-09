/**
    Modeler.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Apr 2005

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

#include "AdaptorsPanel.h"
#include "ConsistencyChecker.h"
#include "ConsistencyResults.h"
#include "MainModelEditor.h"
#include "Modeler.h"
#include "ModelerEntityEditor.h"
#include "SQLGenerator.h"
#include "Preferences.h"

#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerEditor.h>
#include <EOModeler/EOModelerDocument.h>
#include <EOModeler/EOMInspectorController.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOAdaptor.h>

#include <EOControl/EOObserver.h>

#include <AppKit/NSOpenPanel.h>

#include <Foundation/NSObject.h>
#include <Foundation/NSFileManager.h>
@interface DebugObserver : NSObject <EOObserving> 
{

}
@end
@implementation DebugObserver
- (void) objectWillChange:(id)subj
{
  NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), [subj class], subj);
}
@end
@interface NSMenu (im_lazy)
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s;
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s  action: (SEL)sel;
@end

@interface EOModel (foo)
-(void)setCreatesMutableObjects:(BOOL)flag;
@end

@implementation NSMenu (im_lazy)
-(id <NSMenuItem>) addItemWithTitle: (NSString *)s
{
        return [self addItemWithTitle: s  action: NULL  keyEquivalent: nil];
}

-(id <NSMenuItem>) addItemWithTitle: (NSString *)s  action: (SEL)sel
{
        return [self addItemWithTitle: s  action: sel  keyEquivalent: nil];
}
@end


@implementation Modeler

-(void)bundleDidLoad:(NSNotification *)not
{
  /* a place to put breakpoints? */ 
}

- (void) applicationWillFinishLaunching:(NSNotification *)not
{
  int i,c;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSArray *bundlesToLoad = RETAIN([defaults arrayForKey: @"BundlesToLoad"]);
  NSMenu *mainMenu,*subMenu;
  NSFileManager *fm = [NSFileManager defaultManager];
 
//  [EOObserverCenter addOmniscientObserver:[DebugObserver new]];
  [[NSNotificationCenter defaultCenter] addObserver:self
  	selector:@selector(bundleDidLoad:)
	name:NSBundleDidLoadNotification
	object:nil];
  for (i=0, c = [bundlesToLoad count]; i < c; i++)
    {
      BOOL isDir;
      NSString *path = [[bundlesToLoad objectAtIndex:i] stringByExpandingTildeInPath];
      
      [fm fileExistsAtPath:path isDirectory:&isDir];
      if (isDir)
        { 
          NSLog(@"loading bundle: %@",path);

          [[[NSBundle bundleWithPath: path] principalClass] class]; //call class so +initialize gets called
        }
    }
  RELEASE(bundlesToLoad);
  
  /* useful method for setting breakpoints after an adaptor is loaded */
   
  mainMenu = [[NSMenu alloc] init];
  [mainMenu setAutoenablesItems:YES];
  subMenu = [[NSMenu alloc] init];
  [subMenu setAutoenablesItems:YES];

  [subMenu addItemWithTitle: _(@"Info...")
                     action: @selector(orderFrontStandardInfoPanel:)];

  [subMenu addItemWithTitle: _(@"Preferences...")
                     action: @selector(openPrefs:)];

  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle: _(@"Info")]];
  [subMenu release];

  subMenu = [[NSMenu alloc] init];
   
 
  [subMenu addItemWithTitle: _(@"New...")
                     action: @selector(new:)
              keyEquivalent: @"n"];
  [subMenu addItemWithTitle: _(@"New from databse...")
                     action: @selector(newFromDatabase:)
              keyEquivalent: @""]; 

  [subMenu addItemWithTitle: _(@"Open")
                     action: @selector(open:)
              keyEquivalent: @"o"];
	      
  [subMenu addItemWithTitle: _(@"Save")
                     action: @selector(save:)
              keyEquivalent: @""];
	      
  [subMenu addItemWithTitle: _(@"Save As")
                     action: @selector(saveAs:)
              keyEquivalent: @""];
	      
  [subMenu addItemWithTitle: _(@"Revert")
                     action: @selector(revert:) 
              keyEquivalent: @""];
	      
  [subMenu addItemWithTitle: _(@"Set Adaptor Info")
                     action: @selector(setAdaptor:)
              keyEquivalent: @""];
	      
  [subMenu addItemWithTitle: _(@"Switch Adaptor")
                     action: @selector(switchAdaptor:)
              keyEquivalent: @""];
	      
  [ConsistencyChecker class];
  [[subMenu addItemWithTitle: _(@"Check consistency")
                     action: @selector(checkConsistency:)
              keyEquivalent: @""] setRepresentedObject:[ConsistencyResults sharedConsistencyPanel]];
  
  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle:_(@"Model")]];
  [subMenu release];

  subMenu = [[NSMenu alloc] init];
  
  subMenu = [[NSMenu alloc] init];
  [subMenu setAutoenablesItems:YES];

  [subMenu addItemWithTitle: _(@"Copy")
                     action: @selector(copy:)
	      keyEquivalent:@"c"];
  [subMenu addItemWithTitle: _(@"Cut")
                     action: @selector(cut:)
	      keyEquivalent:@"x"];
  [subMenu addItemWithTitle: _(@"Paste")
                     action: @selector(paste:)
	      keyEquivalent:@"v"];
  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle: _(@"Edit")]];
  [subMenu release];

  
  subMenu = [[NSMenu alloc] init];
  [subMenu addItemWithTitle:_(@"Inspector")
	  	action: @selector(showInspector:)
		keyEquivalent: @"i"];
  
  [subMenu addItemWithTitle: _(@"Generate SQL")
                     action: @selector(generateSQL:)
              keyEquivalent: @""]; 

  [subMenu addItemWithTitle: _(@"Table Editor")
	  	     action: @selector(showEditor:)
		     keyEquivalent:@""];

  [subMenu addItemWithTitle: _(@"Diagram Editor")
	  	     action: @selector(showEditor:)
		     keyEquivalent:@""];
  [mainMenu setSubmenu:subMenu forItem:[mainMenu addItemWithTitle:_(@"Tools")]];
  [subMenu release];

  subMenu = [[NSMenu alloc] init];
  [subMenu setAutoenablesItems:YES];
  [subMenu addItemWithTitle: _(@"Add entity")
                     action: @selector(addEntity:)
              keyEquivalent: @"e"];
  
  [subMenu addItemWithTitle: _(@"Add attribute")
                     action: @selector(addAttribute:)
              keyEquivalent: @"a"];
  
  [subMenu addItemWithTitle: _(@"Add relationship")
                     action: @selector(addRelationship:)
              keyEquivalent: @"r"];
  [subMenu addItemWithTitle: _(@"delete")
                     action: @selector(delete:)
              keyEquivalent: @""];

  [mainMenu setSubmenu:subMenu forItem:[mainMenu addItemWithTitle:_(@"Property")]];
  [subMenu release];

  [mainMenu addItemWithTitle: _(@"Hide")
                      action: @selector(hide:)
               keyEquivalent: @"h"];

  [mainMenu addItemWithTitle: _(@"Quit...")
                      action: @selector(terminate:)
	       keyEquivalent: @"q"];
	       
  [NSApp setMainMenu: mainMenu];
  /* make this a default? */
  [EOModelerDocument setDefaultEditorClass: NSClassFromString(@"MainModelEditor")];
}
- (void) showEditor:(id)sender
{
  EOModelerCompoundEditor *ed = [EOMApp currentEditor];
  
  if ([[sender title] isEqual:_(@"Diagram Editor")])
    {
      [ed activateEmbeddedEditor: [ed embedibleEditorOfClass:NSClassFromString(@"DiagramEditor")]];
    }
  else if ([[sender title] isEqual:_(@"Table Editor")])
    {
      [ed activateEmbeddedEditor: [ed embedibleEditorOfClass:NSClassFromString(@"ModelerEntityEditor")]];
    }
}

- (void) _newDocumentWithModel:(EOModel *)newModel
{
  EOModelerDocument *newModelerDoc;
  EOModelerCompoundEditor *editor;
  newModelerDoc = [[EOModelerDocument alloc] initWithModel: newModel];
  editor = (EOModelerCompoundEditor*)[newModelerDoc addDefaultEditor];
  [EOMApp setCurrentEditor: editor];
  [EOMApp addDocument: newModelerDoc];
  RELEASE(newModelerDoc);
  [newModelerDoc activate];
}

- (void)new:(id)sender
{
  EOModel           *newModel = [[EOModel alloc] init];
  NSString		*modelName;
  NSArray *docs = [EOMApp documents];
  unsigned docNumber, c, i;

  docNumber = [[EOMApp documents] count];
  
  c = [docs count];
  docNumber = c;

  /* look for the largest NNNN in models named "Model_NNNN" 
   * or the total number of models whichever is greater.
   */
  for (i = 0; i < c; i++)
     {
       NSString *name = [(EOModel*)[[docs objectAtIndex:i] model] name];

       if ([name hasPrefix:@"Model_"])
         { 
           NSRange range;
           unsigned tmp;
  
           name = [name substringFromIndex:6];
           range = [name rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
           if (!(range.location == NSNotFound) && !(range.length == 0))
             continue;
           range = [name rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
           if (!(range.location == NSNotFound) && !(range.length == 0))
             {
                tmp = [name intValue];
                docNumber = (docNumber < ++tmp) ? tmp : docNumber;
             }
         }
     }
  
  modelName = [NSString stringWithFormat:@"Model_%u",docNumber];
  [newModel setName:modelName];
  [self _newDocumentWithModel:newModel];
  RELEASE(newModel);
}

- (void) newFromDatabase:(id)sender
{
  NSString *adaptorName;
  AdaptorsPanel *adaptorsPanel = [[AdaptorsPanel alloc] init];

  adaptorName = [adaptorsPanel runAdaptorsPanel];
  RELEASE(adaptorsPanel);
  
  if (adaptorName)
    {
      EOAdaptor *adaptor;
      EOAdaptorChannel *channel;
      EOAdaptorContext *ctxt;
      EOModel *newModel;
      NSDictionary *connDict;
      
      adaptor = [EOAdaptor adaptorWithName:adaptorName];
      connDict = [adaptor runLoginPanel];

      if (connDict)
	{
	  [adaptor setConnectionDictionary:[adaptor runLoginPanel]];
	  ctxt = [adaptor createAdaptorContext];
	  channel = [ctxt createAdaptorChannel];
	  [channel openChannel];
	  newModel = [channel describeModelWithTableNames:[channel describeTableNames]];
	  [newModel setConnectionDictionary:[adaptor connectionDictionary]];
	  [newModel setName: [[adaptor connectionDictionary] objectForKey:@"databaseName"]];
	  [channel closeChannel];
	  [self _newDocumentWithModel:newModel];
	  RELEASE(newModel);
	}
    }
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
  if ([[menuItem title] isEqualToString:@"Set Adaptor Info"])
    {
      return ([EOMApp activeDocument] != nil);
    }
  return YES;
}

- (void) setAdaptor:(id)sender
{
  NSString *adaptorName;
  EOAdaptor *adaptor;
  AdaptorsPanel *adaptorsPanel = [[AdaptorsPanel alloc] init];
  
  adaptorName = [adaptorsPanel runAdaptorsPanel];
  RELEASE(adaptorsPanel);
  
  if (!adaptorName)
    return;

  [[[EOMApp activeDocument] model] setAdaptorName: adaptorName]; 
  adaptor = [EOAdaptor adaptorWithName: adaptorName];
  [[[EOMApp activeDocument] model] setConnectionDictionary:[adaptor runLoginPanel]];

}

- (void) showInspector:(id)sender
{
  [EOMInspectorController showInspector];
}

- (BOOL) application:(NSApplication *)theApp openFile:(NSString *)filename
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *pathExt = [[filename pathExtension] lowercaseString];
  BOOL flag;
#if 0
  NSLog(@"%@ %@ %i %i %i %i %i", NSStringFromSelector(_cmd), filename,
	[fm isReadableFileAtPath:filename] == YES,
	[pathExt isEqual:@"eomodel"],
	[pathExt isEqual:@"eomodeld"],
	[fm fileExistsAtPath:filename isDirectory:&flag],
	flag);
#endif
  if (([fm isReadableFileAtPath:filename] == YES
       && [pathExt isEqual:@"eomodel"])
      || ([pathExt isEqual:@"eomodeld"]
	  && [fm fileExistsAtPath:filename isDirectory:&flag] && flag))
    {
      EOModel *model;

      NS_DURING
	model = [[EOModel alloc] initWithContentsOfFile:filename];
      NS_HANDLER
	return NO;
      NS_ENDHANDLER

      [self _newDocumentWithModel:model];
      RELEASE(model);
      return YES;
    }
  return NO;
}

- (void) open:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  NSFileManager *fm = [NSFileManager defaultManager];

  if ([panel runModalForTypes:[NSArray arrayWithObjects:@"eomodeld",@"eomodel",nil]] == NSOKButton)
    {
      NSArray *modelPaths = [panel filenames];
      int i,c;
      
      for (i = 0, c = [modelPaths count]; i < c; i++)
        {
	  NSString *modelPath = [modelPaths objectAtIndex:i];
          NSString *pathExt = [[modelPath pathExtension] lowercaseString];

	  if ([fm isReadableFileAtPath:modelPath] == YES
	      && ([pathExt isEqual:@"eomodeld"]
		  || [pathExt isEqual:@"eomodel"]))
	    {
	      EOModel *model;
	      
	      NS_DURING
		model = [[EOModel alloc] initWithContentsOfFile:modelPath];
	      NS_HANDLER
		return;
	      NS_ENDHANDLER

	      [self _newDocumentWithModel:model];
	      RELEASE(model);
	    }
	}
    }
}

- (void) generateSQL:(id)sender
{
  [[SQLGenerator sharedGenerator] openSQLGenerator:self];
}

- (void) openPrefs:(id)sender
{
  [[DBModelerPrefs sharedPreferences] showPreferences:self]; 
}

@end

