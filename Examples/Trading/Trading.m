#include "Trading.h"

/* Convience class for working with models supporting multiple adaptors */

@implementation Trading : NSObject

+ (EOModel *) defaultModel 
{
  EOModelGroup *globalGrp = [EOModelGroup globalModelGroup];
  EOModel *model = [[EOModelGroup globalModelGroup] modelNamed:@"Trading"];

  /*
   * globalModelGroup doesn't currently work with non-framework native-libs
   */
  if (!model)
    {
      NSBundle *bundle = [NSBundle bundleForClass:[self class]];
      NSString *modelPath = [bundle pathForResource:@"Trading"
					 ofType:@"eomodeld"];
      [globalGrp addModelWithFile:modelPath];
      model = [globalGrp modelNamed:@"Trading"];
    }

  return model;
}

/* calls initWithModel: with the default model */
- (id) init
{
  return [self initWithModel:[[self class] defaultModel]];
}

- (BOOL) hasAdaptorNamed:(NSString *)adaptorName;
{
  NSArray *adaptorNames;

  if (adaptorName == nil)
    return NO;

  adaptorNames = [EOAdaptor availableAdaptorNames];
 
  return [adaptorNames containsObject:adaptorName]; 
}
/* calls initWithModel:adaptorName:
 * looking for an adaptor name in the following order: 
 * first it looks at the TEST_ADAPTOR environment variable
 * then it looks for the GDL2TestAdaptor key
 * then it looks for the models -adaptorName.
 * finally if all else fails, it uses the first adaptor in the
 * +availableAdaptorNames array. 
 */
- (id) initWithModel:(EOModel *)model
{
  NSArray *adaptorNames;
  NSString *adaptorName;
  BOOL flag;
 
  adaptorNames = [EOAdaptor availableAdaptorNames];

  adaptorName = [[[NSProcessInfo processInfo] environment]
				 objectForKey:@"TEST_ADAPTOR"];
  
  if (flag == NO && ((flag = [self hasAdaptorNamed:adaptorName]) == NO))
    adaptorName = [[NSUserDefaults standardUserDefaults]
				 stringForKey:@"GDL2TestAdaptorName"];

  if (flag == NO && ((flag = [self hasAdaptorNamed:adaptorName]) == NO))
    {
      adaptorName = [model adaptorName];
    }
  if (flag == NO && ((flag = [self hasAdaptorNamed:adaptorName]) == NO))
    {
      adaptorName = [adaptorNames count] ? [adaptorNames objectAtIndex:0]
		    : nil;
    }

  return [self initWithModel:model adaptorName:adaptorName];
}

/*
 * uses the default model and an 'adaptorName'ConnectionDictionary
 * in the models userInfo.
 */
- (id) initWithModel:(EOModel *)model adaptorName:(NSString *)adaptorName
{
  NSAssert(adaptorName, @"nil adaptor name");
  {
    NSString *dictName = [adaptorName stringByAppendingString:
		@"ConnectionDictionary"];
    NSDictionary *connDict = [[model userInfo] objectForKey: dictName];

    return [self initWithModel:model
		 adaptorName:adaptorName
		connectionDictionary:connDict];
  } 
}

/* designated initializer assigns the models adaptor name, and connection
 * dictionary */
- (id) initWithModel:(EOModel *)model
	adaptorName:(NSString*)adaptorName
	connectionDictionary:(NSDictionary *)connDict
{
  self = [super init];

  if (self)
    {
      _model = [model retain];
      [model setConnectionDictionary:connDict];
      [model setAdaptorName:adaptorName];
      
      _adaptor = [[EOAdaptor adaptorWithModel:_model] retain];
      _exprClass = [_adaptor expressionClass];
      _context = [[_adaptor createAdaptorContext] retain];
      _channel = [[_context createAdaptorChannel] retain];
    }

  return self;
}

- (void) dealloc
{
  [self close];
  [_model release];
  [_adaptor release];
  [_context release];
  [_channel release];
  [super dealloc];
}

/*
 * drops the tables (ignoring any exceptions)
 * as the tables may not exist to be dropped.
 * then returns the value of [self createTables]; 
 */

- (void) recreateTables 
{
   NS_DURING
   [self dropTables];
   NS_HANDLER
   NS_ENDHANDLER

   return [self createTables];
}

- (void) dropTables
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSArray *entities = [_model entities];


  NSDictionary *dropOptDict 
    = [NSDictionary dictionaryWithObjectsAndKeys:
		      @"NO", @"EOPrimaryKeyConstraintsKey",
		    @"NO", @"EOCreatePrimaryKeySupportKey",
		    @"NO", @"EOCreateTablesKey",
		    nil];
  NSArray *exprs;
  EOSQLExpression *expr;
  unsigned i,c;

  exprs = [_exprClass schemaCreationStatementsForEntities: entities
		     options: dropOptDict];

  [self open];

  for (i=0, c=[exprs count]; i<c; i++)
    {
      expr = [exprs objectAtIndex: i];
      [_channel evaluateExpression: expr];
    }

  [self close];
  
  [pool release];
}

- (void) createTables
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  NSArray *entities = [_model entities];
  NSDictionary *createOptDict 
    = [NSDictionary dictionaryWithObjectsAndKeys:
		      @"NO", @"EODropTablesKey",
		    @"NO", @"EODropPrimaryKeySupportKey", nil];
  NSArray *exprs;
  EOSQLExpression *expr;
  unsigned i,c;

  [self open];

  exprs = [_exprClass schemaCreationStatementsForEntities: entities
		     options: createOptDict];
  for (i=0, c=[exprs count]; i<c; i++)
    {
      expr = [exprs objectAtIndex: i];
      [_channel evaluateExpression: expr];
    }

  [self close];

  [pool release];
}

- (void) open 
{
  if (![self isOpen])
    [_channel openChannel];
}

- (void) close 
{
  if ([_channel isOpen])
    [_channel closeChannel];
}

- (BOOL) isOpen 
{
  return [_channel isOpen];
}

- (Class) exprClass
{
  return _exprClass;
}

- (EOAdaptorChannel *)channel
{
  return _channel;
}

- (EOAdaptorContext *)context
{
  return _context;
}

- (EOModel *)model
{
  return _model;
}

- (EOAdaptor *)adaptor
{
  return _adaptor;
}
@end
