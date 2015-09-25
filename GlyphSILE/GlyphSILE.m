//
//  GlyphSILE.m
//  GlyphSILE
//
//  Created by Simon Cozens on 25/09/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "GlyphSILE.h"

@implementation GlyphSILE

- (id) init {
	self = [super init];
	if (self) {
		// do stuff
	}
	return self;
}

- (NSUInteger) interfaceVersion {
	// Distinguishes the API verison the plugin was built for. Return 1.
	return 1;
}

@end
