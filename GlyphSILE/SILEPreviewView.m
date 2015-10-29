//
//  SILEPreviewView.m
//  GlyphSILE
//
//  Created by Simon Cozens on 11/10/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import "SILEPreviewView.h"
#import "NSLua.h"
#import "LuaBridgedFunctions.h"

@import AppKit;

@implementation SILEPreviewView

CTFontRef lastFont;

- (void)drawRect:(NSRect)pNSRect {
	[[NSColor whiteColor] set];
	NSRectFill(pNSRect);
    [[NSColor blackColor] set];
    if ([self inLiveResize]) return; /* Don't try to be too clever */
    lua_State *L = [[NSLua sharedLua] getLuaState];
    lua_getglobal(L, "doSILEDisplay");
    to_lua(L, self, 1);
    if (lua_pcall(L, 1, 0, 0) != 0)
        NSLog(@"Preview error running function `f': %s", lua_tostring(L, -1));
}

- (void)viewDidEndLiveResize {
    [self setNeedsDisplay:TRUE];
}

- (void)drawGSLayer:(GSLayer *)l atX:(float)x atY:(float)y withSize:(float)s {
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:x yBy:y];
    [transform scaleBy: s];
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

- (void)loadFontFromPath:(char*)path withHeight:(CGFloat)height
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(path);
    if (!dataProvider) { return; }
    // Create the font with the data provider, then release the data provider.
    CGFontRef fontRef = CGFontCreateWithDataProvider(dataProvider);
    if (!fontRef) {
        CGDataProviderRelease(dataProvider);
        return;
    }
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0f, 1.0f));
    CGContextSetFont(context, fontRef);
    CGContextSetFontSize(context, height);
    lastFont = CTFontCreateWithGraphicsFont(fontRef, height, NULL, NULL);
    CGDataProviderRelease(dataProvider);
    CGFontRelease(fontRef);
}

/* Not optimized */
- (void)drawGlyph:(unsigned int)gid atX:(float)x atY:(float)y
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0f, 1.0f));
    CGPoint pos[] = { CGPointMake(x,y) };
    CGGlyph glyphs[] = { (CGGlyph)gid };
    CGContextShowGlyphsAtPositions(context, glyphs, pos, 1);
}
@end