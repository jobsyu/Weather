//
//  WTTableViewController.m
//  Weather
//
//  Created by Scott on 26/01/2013.
//  Updated by Joshua Greene 16/12/2013.
//
//  Copyright (c) 2013 Scott Sherwood. All rights reserved.
//

#import "WTTableViewController.h"
#import "WeatherAnimationViewController.h"
#import "NSDictionary+weather.h"
#import "NSDictionary+weather_package.h"
#import "UIImageView+AFNetworking.h"

static NSString* const BaseURLString = @"http://www.raywenderlich.com/demos/weather_sample/";

@interface WTTableViewController ()
@property(strong) NSDictionary *weather;
@property(nonatomic,strong) NSMutableDictionary *currentDictionary; // current section being  parsed
@property(nonatomic,strong) NSMutableDictionary *xmlWeather; // completed parsed xml response
@property(nonatomic,strong) NSString  *elementName;
@property(nonatomic,strong) NSMutableString *outString;

@end

@implementation WTTableViewController

//when it first starts parsing
-(void)parserDidStartDocument:(NSXMLParser *)parser{
    self.xmlWeather = [NSMutableDictionary dictionary];
}
//when it finds a new element start tag
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    self.elementName = qName;
    if([qName isEqualToString:@"current_condition"] ||
       [qName isEqualToString:@"weather"] ||
       [qName isEqualToString:@"request"]){
        self.currentDictionary = [NSMutableDictionary dictionary];
    }
    
    self.outString = [NSMutableString string];

}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    if(!self.elementName){
        return;
    }
    
    [self.outString appendFormat:@"%@",string];
}

//when an  end  element tag is encoutered
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
   //1
    if([qName isEqualToString:@"current_condition"]||
       [qName isEqualToString:@"request"]){
        self.xmlWeather[qName] = @[self.currentDictionary];
        self.currentDictionary =nil;
    }
    //2
    else if ([qName isEqualToString:@"weather"]){
        //Initialize the list of weather items if it doesn't exist
        NSMutableArray *array = self.xmlWeather[@"weather"] ?: [NSMutableArray array];
        
        //Add the current weather object
        [array addObject:self.currentDictionary];
        
        //Set the new array to the "weather" key on xmlWeather dictionary
        self.xmlWeather[@"weather"] = array;
        
        self.currentDictionary = nil;
    
    }
    //3
    else if([qName isEqualToString:@"value"]){
       //Ignore value tags ,they only appear in the two conditions below
    }
    //4
    else if([qName isEqualToString:@"weatherDesc"]||
            [qName isEqualToString:@"weatherIconUrl"]){
        NSDictionary *dictionary = @{@"value":self.outString};
        NSArray *array = @[dictionary];
        self.currentDictionary[qName] = array;
    }
    //5
    else if (qName){
        self.currentDictionary[qName] = self.outString;
    }
    
    self.elementName =nil;
}
//when it end parsing document
-(void)parserDidEndDocument:(NSXMLParser *)parser{
    self.weather = @{@"data":self.xmlWeather};
    self.title = @"XML Retrieved";
    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    
    self.locationManager =[[CLLocationManager alloc] init];
    self.locationManager.delegate =self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"WeatherDetailSegue"]){
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        WeatherAnimationViewController *wac = (WeatherAnimationViewController *)segue.destinationViewController;
        
        NSDictionary *w;
        switch (indexPath.section) {
            case 0: {
                w = self.weather.currentCondition;
                break;
            }
            case 1: {
                w = [self.weather upcomingWeather][indexPath.row];
                break;
            }
            default: {
                break;
            }
        }
        wac.weatherDictionary = w;
    }
}

#pragma mark - Actions

- (IBAction)clear:(id)sender
{
    self.title = @"";
    self.weather = nil;
    [self.tableView reloadData];
}

- (IBAction)jsonTapped:(id)sender
{
    //1
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=json",BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //2
    AFHTTPRequestOperation * operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //3
        self.weather = (NSDictionary *)responseObject;
        self.title = @"JSON Retrieved";
        [self.tableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //4
        UIAlertView *alertView = [[UIAlertView alloc]
                    initWithTitle:@"Error Retrieved weather"
                        message:[error localizedDescription]
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        
        [alertView show];
    }];
    
    //5
    [operation start];
    
}

- (IBAction)plistTapped:(id)sender
{
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=plist",BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFPropertyListResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.weather = (NSDictionary*)responseObject;
        self.title = @"PLIST Retrieved";
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView =[[UIAlertView alloc]
                                 initWithTitle:@"Error Retrieved weather"
                                 message:[error localizedDescription]
                                 delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alertView show];
    }];
    
    [operation start];
}

- (IBAction)xmlTapped:(id)sender
{
    NSString *string = [NSString stringWithFormat:@"%@weather.php?format=xml",BaseURLString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSXMLParser *xmlparser= (NSXMLParser*)responseObject;
        xmlparser.shouldProcessNamespaces = YES;
        
        //These lines below were previously commented
        xmlparser.delegate = self;
        [xmlparser parse];
        //self.weather = (NSDictionary*)responseObject;
        //self.title = @"XML Retrieved";
       /// [self.tableView reloadData];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieved weather"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];
    
    [operation start];
}

- (IBAction)clientTapped:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                initWithTitle:@"AFHTTPSessionManager"
                delegate:self
                cancelButtonTitle:@"Cancel"
                destructiveButtonTitle:nil
                otherButtonTitles:@"HTTP GET",@"HTTP POST", nil];
    
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == [actionSheet cancelButtonIndex]){
        //User pressed cancel --abort
        return;
    }
    
    //1
    NSURL *baseURL = [NSURL URLWithString:BaseURLString];
    NSDictionary *parameters = @{@"format":@"json"};
    
    //2
    AFHTTPSessionManager *manager =[[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    //3
    if(buttonIndex ==0){
       [manager GET:@"weather.php" parameters:parameters
            success:^(NSURLSessionDataTask *task, id responseObject) {
                self.weather = responseObject;
                self.title = @"HTTP GET";
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:@"Error Retrieved weather" message:[error localizedDescription]
                    delegate:nil
                    cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                
                [alertView show];
            }];
        
    }
    else if (buttonIndex ==1)
    {
       [manager POST:@"weather.php" parameters:parameters
             success:^(NSURLSessionDataTask *task, id responseObject) {
                 self.weather = responseObject;
                 self.title = @"HTTP POST";
                 [self.tableView reloadData];
             } failure:^(NSURLSessionDataTask *task, NSError *error) {
                 UIAlertView *alertView =[[UIAlertView alloc] initWithTitle:@"Error Retrieved weather" message:[error localizedDescription] delegate:nil
                     cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                          
                [alertView show];
             }];
    }
  
}

- (IBAction)apiTapped:(id)sender
{
    [self.locationManager startUpdatingLocation];
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //Last object contains the recents locations
    CLLocation *newLocation = [locations lastObject];
    
    //if the location is more than 5 minutes old,ignore it
    if([newLocation.timestamp timeIntervalSinceNow] >300){
        return;
    }
    
    [self.locationManager stopUpdatingLocation];
    
    WeatherHTTPClient *client = [WeatherHTTPClient sharedWeatherHTTPClient];
    client.delegate = self;
    [client updateWeatherAtLocation:newLocation forNumberOfDays:5];
}

-(void)weatherHTTPClient:(WeatherHTTPClient *)client didUpdateWithWeather:(id)weather{
    self.weather = weather;
    self.title= @"API Updated";
    [self.tableView reloadData];
}

-(void)weatherHTTPClient:(WeatherHTTPClient *)client didFailWithError:(NSError *)error{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieved Weather"
                                message:[NSString stringWithFormat:@"%@",error] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!self.weather){
        return 0;
    }
    
    switch (section) {
        case 0:{
            return 1;
        }
        case 1:{
            NSArray *upcomingWeather = [self.weather upcomingWeather];
            return [upcomingWeather count];
        }
        default:{
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WeatherCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell.
    NSDictionary *dayweathers=nil;
    
    switch (indexPath.section) {
        case 0:{
            dayweathers = [self.weather currentCondition];
            break;
        }
        case 1:{
            NSArray* upcomingWeather = [self.weather upcomingWeather];
            dayweathers =  upcomingWeather[indexPath.row];
            break;
        }
        default:
            break;
    }
    
    cell.textLabel.text = [dayweathers weatherDescription];
    
    //you will add code  here later to customize cell ,but it's good for now
    NSURL * url = [NSURL URLWithString:dayweathers.weatherIconURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage =[UIImage imageNamed:@"placeholder"];
    
    __weak UITableViewCell *weakCell= cell;
    
    [cell.imageView setImageWithURLRequest:request
                placeholderImage:placeholderImage
                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        weakCell.imageView.image = image;
                        [weakCell setNeedsLayout];
                    } failure:nil];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
}

@end