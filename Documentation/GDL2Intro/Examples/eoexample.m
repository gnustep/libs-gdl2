#include <Foundation/Foundation.h>
#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>

int main()
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  EOModelGroup *group = [EOModelGroup defaultGroup];
  EOModel *model;
  EOAdaptor *adaptor;
  EOAdaptorContext *context;
  EOAdaptorChannel *channel; 
  EOEditingContext *ec;
  EODatabaseDataSource *authorsDS;
  NSArray *authors;
  id author;
  
  model = [group modelNamed:@"library"];
  
  /* Tools don't have resources so we have to add the model manually */ 
  if (!model)
    {
      model = [[EOModel alloc] initWithContentsOfFile:@"./library.eomodel"];
      [group addModel:model];
    }

  adaptor = [EOAdaptor adaptorWithModel:model];
  context = [adaptor createAdaptorContext];
  channel = [context createAdaptorChannel];
  ec = [[EOEditingContext alloc] init];
  authorsDS = [[EODatabaseDataSource alloc] initWithEditingContext: ec
						entityName:@"authors"];

  [channel openChannel];

  /* Create a new author object */
  author = [authorsDS createObject];
  [author takeValue:@"Anonymous" forKey:@"name"];
  [authorsDS insertObject:author];
  [ec saveChanges];

  
  /* Fetch the newly inserted object from the database */
  authors = [authorsDS fetchObjects];
  NSLog(@"%@", authors);

  /* Update the authors name */
  [[authors objectAtIndex:0] 
  	takeValue:@"John Doe" forKey:@"name"];
  [ec saveChanges];
 
  NSLog(@"%@", [authorsDS fetchObjects]);

  [channel closeChannel];
  [pool release];
  return 0;
}

