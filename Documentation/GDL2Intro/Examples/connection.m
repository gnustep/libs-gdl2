#include <Foundation/Foundation.h>
#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>

int main()
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  EOModelGroup *modelGroup = [EOModelGroup defaultGroup];
  EOModel *model = [modelGroup modelNamed:@"library"];
  EOAdaptor *adaptor;
  EOAdaptorContext *context;
  EOAdaptorChannel *channel;

  /* Tools don't have resources so we have to add the model manually */ 
  if (!model)
    {
      model = [[EOModel alloc] initWithContentsOfFile:@"./library.eomodel"];
      [modelGroup addModel:model];
    }
 
  adaptor = [EOAdaptor adaptorWithName:[model adaptorName]];
  context = [adaptor createAdaptorContext];
  channel = [context createAdaptorChannel];

  [channel openChannel];

  /* insert code here */

  [channel closeChannel];
  [pool release];
  return 0;
}

