//
//  SILEPreviewController.m
//  GlyphSILE
//
//  Created by Simon Cozens on 11/10/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "SILEPreviewController.h"
#import "NSLua.h"

@import AppKit;

@implementation SILEPreviewController

- (void)drawRect:(NSRect)pNSRect {
    lua_State *L = [[NSLua sharedLua] getLuaState];
    lua_getglobal(L, "doSILEDisplay");
    if (lua_pcall(L, 0, 0, 0) != 0)
        NSLog(@"error running function `f': %s", lua_tostring(L, -1));
}

- (void)drawGSLayer:(GSLayer *)l atX:(float)x atY:(float)y withSize:(float)s {
    NSLog(@"I have a layer %@, at %f %f", l, x,y);
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:x yBy:y];
    [transform scaleBy: s/1000.0];
    NSBezierPath *GlyphBezierPath = [[l bezierPath] copy];
    if (!GlyphBezierPath) {
        GlyphBezierPath = [[NSBezierPath alloc] init];
    }
    NSBezierPath *OpenGlyphsPath = [[l openBezierPath] copy];
    if (!OpenGlyphsPath) {
        OpenGlyphsPath = [NSBezierPath bezierPath];
    }
    for (GSComponent *currComponent in l.components) {
        [GlyphBezierPath appendBezierPath:[currComponent bezierPath]];
        [OpenGlyphsPath appendBezierPath:[currComponent openBezierPath]];
    }
    [GlyphBezierPath transformUsingAffineTransform:transform];
    [OpenGlyphsPath transformUsingAffineTransform:transform];
    [GlyphBezierPath fill];
    [OpenGlyphsPath setLineWidth:0.75];
    [OpenGlyphsPath stroke];
}

@end