#include <Foundation/Foundation.h>
#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>

int main()
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  EOModel *model = [[EOModelGroup defaultGroup] modelNamed:@"library"];
  EOAdaptor *adaptor = [EOAdaptor adaptorWithName:[model adaptorName]];
  EOAdaptorContext *context = [adaptor createAdaptorContext];
  EOAdaptorChannel *channel = [context createAdaptorChannel];

  [channel openChannel];

  /* insert code here */

  [channel closeChannel];
  [pool release];
  return 0;
}

