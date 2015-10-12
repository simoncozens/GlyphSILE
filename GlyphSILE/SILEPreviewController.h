//
//  SILEPreviewController.h
//  GlyphSILE
//
//  Created by Simon Cozens on 11/10/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GlyphsCore/GlyphsPluginProtocol.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSComponent.h>

@interface SILEPreviewController : NSView

-(void)drawGSLayer:(GSLayer*)l atX:(float)x atY:(float)y withSize:(float)s;

@end
