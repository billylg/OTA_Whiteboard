//
//  DrawContext.m
//  Draw2
//
//  Created by Billy Liang on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DrawContext.h"


@implementation DrawContext

@synthesize dataPointArray;
@synthesize colorString;

- (void)dealloc
{
    [dataPointArray release];
    [colorString release];
    [super dealloc];
}

@end
