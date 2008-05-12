/**
    Modeler.m
 
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

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSOpenPanel.h>
#endif

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSObject.h>
#include <Foundation/NSFileManager.h>
#endif

#include <GNUstepBase/GNUstep.h>

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
- (NSMenuItem *)addItemWithTitle: (NSString *)s;
- (NSMenuItem *)addItemWithTitle: (NSString *)s  action: (SEL)sel;
@end

@implementation NSMenu (im_lazy)
- (NSMenuItem *)addItemWithTitle: (NSString *)s
{
        return [self addItemWithTitle: s  action: NULL keyEquivalent: @""];
}

- (NSMenuItem *)addItemWithTitle: (NSString *)s  action: (SEL)sel
{
        return [self addItemWithTitle: s  action: sel  keyEquivalent: @""];
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
  NSMenu *mainMenu,*subMenu,*servicesMenu;
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

  subMenu = [[NSMenu alloc] initWithTitle: _(@"Info")];
  [subMenu setAutoenablesItems:YES];

  [subMenu addItemWithTitle: _(@"About DBModeler")
                     action: NULL];

  [subMenu addItem: [NSMenuItem separatorItem]];

  [subMenu addItemWithTitle: _(@"Preferences...")
                     action: @selector(openPrefs:)
              keyEquivalent: @","];

#ifdef NeXT_GUI_LIBRARY
  [subMenu addItem: [NSMenuItem separatorItem]];

  servicesMenu = [[NSMenu alloc] initWithTitle: _(@"Services")];
  [subMenu setSubmenu: servicesMenu forItem: [subMenu addItemWithTitle: _(@"Services")]];
  [NSApp setServicesMenu: servicesMenu];
  [servicesMenu release];

  [subMenu addItem: [NSMenuItem separatorItem]];

  [subMenu addItemWithTitle: _(@"Hide DBModeler")
                     action: @selector(hide:)
              keyEquivalent: @"h"];

  [subMenu addItemWithTitle: _(@"Hide Others")
                     action: @selector(hideOtherApplications:)
              keyEquivalent: @""];

  [subMenu addItemWithTitle: _(@"Show All")
                     action: @selector(unhideAllApplications:)
              keyEquivalent: @""];

  [subMenu addItem: [NSMenuItem separatorItem]];

  [subMenu addItemWithTitle: _(@"Quit DBModeler")
                     action: @selector(terminate:)
              keyEquivalent: @"q"];
#endif /* NeXT_GUI_LIBRARY */
       
  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle: @"Info"]];
  [subMenu release];

  subMenu = [[NSMenu alloc] initWithTitle: _(@"Model")];
   
  [subMenu addItemWithTitle: _(@"New...")
                     action: @selector(new:)
              keyEquivalent: @"n"];
  [subMenu addItemWithTitle: _(@"New From Database...")
                     action: @selector(newFromDatabase:)
              keyEquivalent: @""]; 

  [subMenu addItemWithTitle: _(@"Open")
                     action: @selector(open:)
              keyEquivalent: @"o"];
      
  [subMenu addItem:[NSMenuItem separatorItem]];

  [subMenu addItemWithTitle: _(@"Save")
                     action: @selector(save:)
              keyEquivalent: @"s"];
      
  [subMenu addItemWithTitle: _(@"Save As...")
                     action: @selector(saveAs:)
              keyEquivalent: @"S"];
      
  [subMenu addItemWithTitle: _(@"Revert to Saved")
                     action: @selector(revert:) 
              keyEquivalent: @"u"];
      
  [subMenu addItem:[NSMenuItem separatorItem]];

  [subMenu addItemWithTitle: _(@"Set Adaptor Info...")
                     action: @selector(setAdaptor:)
              keyEquivalent: @"I"];
      
  [subMenu addItemWithTitle: _(@"Switch Adaptor...")
                     action: @selector(switchAdaptor:)
              keyEquivalent: @""];
      
  [ConsistencyChecker class];
  [[subMenu addItemWithTitle: _(@"Check Consistency...")
                     action: @selector(checkConsistency:)
              keyEquivalent: @""] setRepresentedObject:[ConsistencyResults sharedConsistencyPanel]];
  
  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle:_(@"Model")]];
  [subMenu release];

  subMenu = [[NSMenu alloc] initWithTitle: _(@"Edit")];
  [subMenu setAutoenablesItems:YES];

  [subMenu addItemWithTitle: _(@"Copy")
                     action: @selector(copy:)
              keyEquivalent: @"c"];
  [subMenu addItemWithTitle: _(@"Cut")
                     action: @selector(cut:)
              keyEquivalent: @"x"];
  [subMenu addItemWithTitle: _(@"Paste")
                     action: @selector(paste:)
              keyEquivalent: @"v"];
  [mainMenu setSubmenu: subMenu forItem: [mainMenu addItemWithTitle: _(@"Edit")]];
  [subMenu release];

  
  subMenu = [[NSMenu alloc] initWithTitle: _(@"Tools")];
  [subMenu addItemWithTitle: _(@"Inspector")
                     action: @selector(showInspector:)
              keyEquivalent: @"i"];
  
  [subMenu addItemWithTitle: _(@"Generate SQL")
                     action: @selector(generateSQL:)
              keyEquivalent: @""];

  [subMenu addItemWithTitle: _(@"Table Editor")
                     action: @selector(showEditor:)
              keyEquivalent: @""];

  [subMenu addItemWithTitle: _(@"Diagram Editor")
                     action: @selector(showEditor:)
              keyEquivalent: @""];
  [mainMenu setSubmenu:subMenu forItem:[mainMenu addItemWithTitle:_(@"Tools")]];
  [subMenu release];

  subMenu = [[NSMenu alloc] initWithTitle: _(@"Property")];
  [subMenu setAutoenablesItems:YES];
  [subMenu addItemWithTitle: _(@"Add Entity")
                     action: @selector(addEntity:)
              keyEquivalent: @"E"];
  
  [subMenu addItemWithTitle: _(@"Add Attribute")
                     action: @selector(addAttribute:)
              keyEquivalent: @"A"];
  
  [subMenu addItemWithTitle: _(@"Add Relationship")
                     action: @selector(addRelationship:)
              keyEquivalent: @"R"];

  [subMenu addItemWithTitle: _(@"Delete")
                     action: @selector(delete:)
              keyEquivalent: @""];

  [mainMenu setSubmenu:subMenu forItem:[mainMenu addItemWithTitle:_(@"Property")]];
  [subMenu release];

#ifdef GNU_GUI_LIBRARY
  servicesMenu = [[NSMenu alloc] initWithTitle: _(@"Services")];
  [mainMenu setSubmenu: servicesMenu forItem: [mainMenu addItemWithTitle: _(@"Services")]];
  [NSApp setServicesMenu: servicesMenu];
  [servicesMenu release];

  [mainMenu addItemWithTitle: _(@"Hide")
                      action: @selector(hide:)
               keyEquivalent: @"h"];

  [mainMenu addItemWithTitle: _(@"Quit...")
                      action: @selector(terminate:)
               keyEquivalent: @"q"];
#endif /* GNU_GUI_LIBRARY */

  [NSApp setMainMenu: mainMenu];
  /* make this a default? */
  [EOModelerDocument setDefaultEditorClass: NSClassFromString(@"MainModelEditor")];
}
- (void) showEditor:(id)sender
{
  EOModelerCompoundEditor *ed = (id)[EOMApp currentEditor];
  
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
  NSString *modelName;
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

