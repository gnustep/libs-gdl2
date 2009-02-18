#include <Foundation/Foundation.h>
#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>

int
main(int arcg, char *argv[], char **envp)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  EOModelGroup *modelGroup = [EOModelGroup defaultGroup];
  EOModel *model = [modelGroup modelNamed:@"library"];
  EOAdaptor *adaptor;
  EOAdaptorContext *context;
  EOAdaptorChannel *channel;

  /* Tools don't have resources so we have to add the model manually. */ 
  if (!model)
    {
      NSString *path = @"./library.eomodel";
      model = [[EOModel alloc] initWithContentsOfFile: path];
      [modelGroup addModel:model];
      [model release];
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

