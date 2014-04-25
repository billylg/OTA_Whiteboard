//
//  DrawContext.h
//  Draw2
//
//  Created by Billy Liang on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DrawContext : NSObject {
    NSMutableArray *dataPointArray;
    NSString *colorString;
}

@property (nonatomic, retain) NSMutableArray *dataPointArray;
@property (nonatomic, retain) NSString *colorString;

@end
