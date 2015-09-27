//
//  GlyphSILE.h
//  GlyphSILE
//
//  Created by Simon Cozens on 25/09/2015.
//  Copyright © 2015 Simon Cozens. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsPluginProtocol.h>

@interface GlyphSILE : NSObject <GlyphsPlugin> {}
@property (nonatomic, weak) IBOutlet NSTextField *incomingCode;
@property (nonatomic, weak) IBOutlet NSTextField *luaResult;
@property (nonatomic, weak) IBOutlet NSButton *compileButton;
@property (nonatomic, weak) IBOutlet NSWindow *consoleWindow;

@end
