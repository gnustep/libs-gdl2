#include <Foundation/Foundation.h>
#include <EOAccess/EOAccess.h>
#include <EOControl/EOControl.h>

int
main(int arcg, char *argv[], char **envp)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  EOModelGroup *group = [EOModelGroup defaultGroup];
  EOModel *model;
  EOAdaptor *adaptor;
  EOAdaptorContext *context;
  EOAdaptorChannel *channel; 
  EOEditingContext *ec;
  EODatabaseDataSource *authorsDS;
  EODataSource *booksDS;
  id author;
  id book;

  model = [group modelNamed:@"library"];
  
  /* Tools do not have resources so we add the model manually.  */ 
  if (!model)
    {
      NSString *path = @"./library.eomodel";
      model = [[EOModel alloc] initWithContentsOfFile: path];
      [group addModel:model];
      [model release];
    }

  adaptor = [EOAdaptor adaptorWithModel:model];
  context = [adaptor createAdaptorContext];
  channel = [context createAdaptorChannel];
  ec = [[EOEditingContext alloc] init];
  authorsDS 
    = [[EODatabaseDataSource alloc] initWithEditingContext: ec
				    entityName:@"authors"];

  [channel openChannel];

  author = [authorsDS createObject];
  [author takeValue:@"Richard Brautigan" forKey:@"name"];
  [authorsDS insertObject:author];
  
  booksDS = [authorsDS dataSourceQualifiedByKey:@"toBooks"];
  [booksDS qualifyWithRelationshipKey:@"toBooks" ofObject:author];

  book = [booksDS createObject];
  [book takeValue:@"The Hawkline Monster" forKey:@"title"];
  [booksDS insertObject:book];
  
  book = [booksDS createObject];
  [book takeValue:@"Trout Fishing in America" forKey:@"title"];
  [booksDS insertObject:book];

  [ec saveChanges];

  /* log the to many relationship from author to books */
  NSLog(@"%@ %@", 
	[author valueForKey:@"name"],
	[author valueForKeyPath:@"toBooks.title"]);
  
  /* log the to one relationship from book to author */
  NSLog(@"%@", [book valueForKeyPath:@"toAuthor.name"]);
  
  /* traverse to one through the to many through key paths
     logging the author once for each book. */
  NSLog(@"%@", [author valueForKeyPath:@"toBooks.toAuthor.name"]);

  [channel closeChannel];
  [pool release];
  return 0;
}

