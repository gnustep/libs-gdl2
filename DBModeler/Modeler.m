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

#include "Modeler.h"
#include "AdaptorsPanel.h"
#include "MainModelEditor.h"
#include "ModelerEntityEditor.h"

#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerEditor.h>
#include <EOModeler/EOModelerDocument.h>
#include <EOModeler/EOMInspectorController.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>

#include <AppKit/NSOpenPanel.h>

#include <Foundation/NSObject.h>

/* TODO validate menu items.. */
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
  subMenu = [[NSMenu alloc] init];

  [subMenu addItemWithTitle: _(@"Info..")
                     action: @selector(:orderFrontStandardInfoPanel:)];

  [subMenu addItemWithTitle: _(@"Preferences...")
                     action: @selector(openPrefs:)];

  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle: _(@"Info")]];
  [subMenu release];
  subMenu = [[NSMenu alloc] init];

  [subMenu addItemWithTitle: _(@"New...")
                     action: @selector(new:)
              keyEquivalent: @"n"];

  [subMenu addItemWithTitle: _(@"Open")
                     action: @selector(open:)
              keyEquivalent: @""];
	      
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
	      
  [subMenu addItemWithTitle: _(@"Check consistency")
                     action: @selector(checkConsistency:)
              keyEquivalent: @""]; 

  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle:_(@"Model")]];
  [subMenu release];

  
  subMenu = [[NSMenu alloc] init];
  [subMenu addItemWithTitle:_(@"Inspector")
	  	action: @selector(showInspector:)
		keyEquivalent: @"i"];
  [mainMenu setSubmenu:subMenu forItem:[mainMenu addItemWithTitle:_(@"Tools")]];
  [subMenu release];

  subMenu = [[NSMenu alloc] init];
  [subMenu addItemWithTitle: _(@"Add entity")
                     action: @selector(addEntity:)
              keyEquivalent: @"e"];
  
  [subMenu addItemWithTitle: _(@"Add attribute")
                     action: @selector(addAttribute:)
              keyEquivalent: @"a"];
  
  [subMenu addItemWithTitle: _(@"Add relationship")
                     action: @selector(addRelationship:)
              keyEquivalent: @"r"];

  [mainMenu setSubmenu:subMenu forItem:[mainMenu addItemWithTitle:_(@"Property")]];
  [subMenu release];

  [mainMenu addItemWithTitle: _(@"Hide")
                      action: @selector(hide:)
               keyEquivalent: @"h"];

  [mainMenu addItemWithTitle: _(@"Quit...")
                      action: @selector(terminate:)
	       keyEquivalent: @"q"];
	       
  [NSApp setMainMenu: mainMenu];
  /* make this a bundle? */
  [EOModelerDocument setDefaultEditorClass: NSClassFromString(@"MainModelEditor")];
  [[mainMenu window] makeKeyAndOrderFront:self];
}

- (void)new:(id)sender
{
  /* this entire function -really- seems to belong somewhere else */
  EOModelerCompoundEditor *editor;
  EOModelerDocument *newModelerDoc;
  EOModel           *newModel = [[EOModel alloc] init];
  EOAdaptor         *newAdaptor;
  NSString		*modelName;
  unsigned int nDocs;

  //[newModel setCreateMutableObjects:YES];
  nDocs = [[EOMApp documents] count];
      
  modelName=[NSString stringWithFormat:@"Model_%u",++nDocs];
  [newModel setName:modelName];
  [[EOModelGroup defaultGroup] addModel:newModel];
  
  newModelerDoc = [[EOModelerDocument alloc] initWithModel: newModel];
  editor = (EOModelerCompoundEditor*)[newModelerDoc addDefaultEditor];
  [EOMApp setCurrentEditor: editor];
  [EOMApp addDocument: newModelerDoc];
  [newModelerDoc activate];
}

- (void) setAdaptor:(id)sender
{
  NSString *adaptorName;
  EOAdaptor *adaptor;
  AdaptorsPanel *adaptorsPanel = [[AdaptorsPanel alloc] init];
  
  adaptorName = [adaptorsPanel runAdaptorsPanel];
  RELEASE(adaptorsPanel);
  [[[EOMApp activeDocument] model] setAdaptorName: adaptorName]; 
  adaptor = [EOAdaptor adaptorWithName: adaptorName];
  [[[EOMApp activeDocument] model] setConnectionDictionary:[adaptor runLoginPanel]];

}

- (void) showInspector:(id)sender
{
  [EOMInspectorController showInspector];
}

- (void) open:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  if ([panel runModalForTypes:[NSArray arrayWithObject:@"eomodeld"]] == NSOKButton)
    {
      NSArray *modelPaths = [panel filenames];
      int i,c;
      
      for (i = 0, c = [modelPaths count]; i < c; i++)
        {
	  NSString *modelPath = [modelPaths objectAtIndex:i];
          EOModel *model = [[EOModel alloc] initWithContentsOfFile:modelPath];
	  EOModelerDocument *newDoc = [[EOModelerDocument alloc] initWithModel:model];
          EOModelerEditor *editor = (EOModelerCompoundEditor*)[newDoc addDefaultEditor];
          [EOMApp setCurrentEditor: editor];
          [EOMApp addDocument: newDoc];
	  [newDoc activate];
	}
    }
}
@end

