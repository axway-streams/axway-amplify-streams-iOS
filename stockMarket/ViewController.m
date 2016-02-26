// Copyright 2016 Streamdata.io
//
//     Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//     You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//     Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//     See the License for the specific language governing permissions and
// limitations under the License.
//
//
//  ViewController.m
//  stockMarket

#import "ViewController.h"
#import "JSONTools.h"
#import "TRVSEventSource.h"

static NSString * const kStreamdataioPrefix =
    @"https://streamdata.motwin.net/";
static NSString * const kStockMarketUrl =
    @"http://stockmarket.streamdata.io/prices";
static NSString * kToken =
    @"YOUR_TOKEN-HERE";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // build the URL String
    NSString * sUrl = [NSString stringWithFormat:@"%@%@?X-Sd-Token=%@", kStreamdataioPrefix, kStockMarketUrl, kToken];
    // initialize the NSURL object with url string
    URL = [NSURL URLWithString:sUrl];
    event = [[TRVSEventSource alloc] initWithURL:URL];
    event.delegate = self;
}

-(void) viewWillAppear:(BOOL)animated
{
    // start event when view is shown
    [event open];
}

-(void) viewWillDisappear:(BOOL)animated
{
    // stop event when view is hiddent
    [event close];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - TRVSEventSourceDelegate

- (void)eventSource:(TRVSEventSource *)eventSource didReceiveEvent:(TRVSServerSentEvent *)anEvent;
{
    NSLog(@"%@", anEvent.data);
    
    NSError *e;
    if([anEvent.event isEqualToString:@"data"]==TRUE)
    {
        dataObject = [NSJSONSerialization JSONObjectWithData:anEvent.data options:NSJSONReadingMutableContainers error:&e];
    }
    else if ([anEvent.event isEqualToString:@"patch"]==TRUE)
    {
        NSArray *patch =[NSJSONSerialization JSONObjectWithData:anEvent.data options:NSJSONReadingMutableContainers error:&e];
        [JSONPatch applyPatches:patch toCollection:dataObject];
    }
    
    [tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}

- (void)eventSourceDidClose:(TRVSEventSource *)eventSource
{
    NSLog(@"Event closed");
}

- (void)eventSource:(TRVSEventSource *)eventSource didFailWithError:(NSError *)error
{
    NSLog(@"ooooops !");
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return [dataObject count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"tableViewCellIdentifier";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
                                      reuseIdentifier:identifier];
    }
    
    NSArray *data = [dataObject sortedArrayUsingComparator:
                     ^NSComparisonResult(id obj1, id obj2) {
                         if ([obj1 objectForKey:@"price"] < [obj2 objectForKey:@"price"])
                         { return NSOrderedDescending; }
                         else if ([obj1 objectForKey:@"price"] > [obj2 objectForKey:@"price"])
                         { return NSOrderedAscending; }
                         else
                         { return NSOrderedSame; }
                     }];
    
    cell.textLabel.text = [[data objectAtIndex:indexPath.row] objectForKey:@"title"];
    cell.detailTextLabel.text = [[[data objectAtIndex:indexPath.row] objectForKey:@"price"] stringValue];
    
    return cell;
}

@end
