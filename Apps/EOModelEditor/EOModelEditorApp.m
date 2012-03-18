/*
 EOModelEditorApp.m
 
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
 along with DBModeler; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#import "EOModelEditorApp.h"
#import "EOMEEOAccessAdditions.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "AdaptorsPanel.h"
#import "EOMEDocument.h"

@implementation EOModelEditorApp

/*
 on Interface Builder the DocumentController is created by loading the NIB after it has been added to.
 We don't have a NIB file so we have to do this manually -- dw
 */

- (void)finishLaunching
{
  //NSDocumentController * dc = [NSDocumentController sharedDocumentController];

 // [dc retain];
  [EOMEEOAccessAdditions class];
  [super finishLaunching];
}

- (void)orderFrontStandardAboutPanel:(id)sender
{
  NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:@"Credits", @"Credits.rtf",
                         @"Version", @"0.1 (2010)", nil];
  
  [self orderFrontStandardAboutPanelWithOptions: dict];

}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) ==
      NSWindows95InterfaceStyle)
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (id)sender
{
  if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", nil) ==
      NSWindows95InterfaceStyle)
    {
      NSDocumentController *docController;
      docController = [NSDocumentController sharedDocumentController];
      
      if ([[docController documents] count] > 0)
        {
          return NO;
        }
      else
        {
          return YES;
        }
    }
  else
    {
      return NO;
    }
}

- (void) newDocumentWithModel:(EOModel *)newModel
{
  EOMEDocument *newModelerDoc;
  NSError      *outError = nil;
  NSDocumentController * sharedDocController = [NSDocumentController sharedDocumentController];

  
  newModelerDoc = [sharedDocController openUntitledDocumentAndDisplay:YES
                                                                error:&outError];
  
  if (newModelerDoc) {
    [newModelerDoc setEomodel:newModel];
  }
  
}

- (void) newFromDatabase:(id)sender
{
  NSString *adaptorName;
  AdaptorsPanel *adaptorsPanel = [[AdaptorsPanel alloc] init];
  
  adaptorName = [adaptorsPanel runAdaptorsPanel];
  RELEASE(adaptorsPanel);
  
  if (adaptorName)
  {
    NS_DURING {
    EOAdaptor *adaptor;
    EOAdaptorChannel *channel;
    EOAdaptorContext *ctxt;
    EOModel *newModel;
    NSDictionary *connDict;
    
    adaptor = [EOAdaptor adaptorWithName:adaptorName];
    connDict = [adaptor runLoginPanel];
    
    if (connDict)
    {
      [adaptor setConnectionDictionary:connDict];
      ctxt = [adaptor createAdaptorContext];
      channel = [ctxt createAdaptorChannel];
      [channel openChannel];
      newModel = [channel describeModelWithTableNames:[channel describeTableNames]];
      [newModel setConnectionDictionary:[adaptor connectionDictionary]];
      [newModel setName: [[adaptor connectionDictionary] objectForKey:@"databaseName"]];
      [channel closeChannel];
      [self newDocumentWithModel:newModel];
    }
    } NS_HANDLER {
      NSRunCriticalAlertPanel (@"Problem creating model from Database",
                               @"%@",
                               @"Ok",
                               nil,
                               nil,
                               localException);
    } NS_ENDHANDLER;
  }
}

- (void) new:(id)sender
{
  EOModel           *newModel = [[EOModel alloc] init];
  
//  [newModel setName: @"test"];
  [self newDocumentWithModel:newModel];
  RELEASE(newModel);
  
}

- (EOMEDocument *) activeDocument
{
  return (EOMEDocument *) [[NSDocumentController sharedDocumentController] currentDocument];
}

@end
