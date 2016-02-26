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

#import "EventSource.h"


#define kErrorCodeBadResponseStatusCode 1
#define kErrorCodeBadResponseContentType 2


@interface EventSource () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableString *currentMessage;

@end

@implementation EventSource

- (id)initWithURL:(NSURL*)url delegate:(NSObject<EventSourceDelegate>*)delegate
{
    self = [super init];
    if (self)
    {
        _url = url;
        _delegate = delegate;
        
        // start connection
        _currentMessage = [NSMutableString string];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
        _connection = [NSURLConnection connectionWithRequest:request delegate:self];
    }
    return self;
}

- (void)cancel
{
    [_connection cancel];
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(eventSource:didFailWithError:)]) {
        [_delegate eventSource:self didFailWithError:error];
    }
}

#pragma mark - NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    // ensure we've got a successful response
    if ([[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)] containsIndex:[httpResponse statusCode]])
    {
        // ensure HTTP content-type is text/event-stream
        if ([httpResponse.allHeaderFields[@"content-type"] isEqualToString:@"text/event-stream"])
        {
            if ([_delegate respondsToSelector:@selector(eventSourceDidOpenConnection:)]) {
                [_delegate eventSourceDidOpenConnection:self];
            }
        }
        else
        {
            if ([_delegate respondsToSelector:@selector(eventSource:didFailWithError:)])
            {
                NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                     code:kErrorCodeBadResponseContentType
                                                 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Server must respond with a content-type of 'text/event-stream'.", nil) }];
                
                [_delegate eventSource:self didFailWithError:error];
            }
            
            [_connection cancel];
        }
    }
    else
    {
        if ([_delegate respondsToSelector:@selector(eventSource:didFailWithError:)])
        {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                 code:kErrorCodeBadResponseStatusCode
                                             userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Server must respond with a status code in the 200-299 range.", nil) }];
            
            [_delegate eventSource:self didFailWithError:error];
        }
        
        [_connection cancel];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *receivedString = [[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding];
    [_currentMessage appendString:receivedString];
    
    NSArray *messages = [_currentMessage componentsSeparatedByString:@"\n\n"];
    
    for (int i = 0; i < messages.count - 1; i++)
    {
        [self processMessage:messages[i]];
    }
    
    _currentMessage = [NSMutableString stringWithString:[messages lastObject]];
}


#pragma mark - Privates

- (void)processMessage:(NSString*)message
{
    NSMutableString *eventMessage = [NSMutableString string];
    NSString *eventType = nil;
    NSString *eventID = nil;
    
    NSArray *lines = [message componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines)
    {
        if ([line hasPrefix:@":"])
        {
            // comment; do nothing
        }
        else if ([line hasPrefix:@"id:"])
        {
            // id
            NSString *value = [line substringFromIndex:3];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            eventID = value;
            _lastEventID = value;
        }
        else if ([line hasPrefix:@"event:"])
        {
            // event
            NSString *value = [line substringFromIndex:6];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            eventType = value;
        }
        else if ([line hasPrefix:@"data:"])
        {
            // data
            NSString *value = [line substringFromIndex:5];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [eventMessage appendFormat:@"%@\n", value];
        }
    }
    
    [_delegate eventSource:self didReceiveMessage:eventMessage eventID:eventID type:eventType];
}

@end
