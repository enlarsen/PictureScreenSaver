//
//  DonnaArtShowView.m
//  DonnaArtShow
//
//  Created by Erik Larsen on 2/25/15.
//  Copyright (c) 2015 Erik Larsen. All rights reserved.
//


#import "DonnaArtShowView.h"

@interface DonnaArtShowView()

@property (nonatomic) NSTimeInterval changeTimeInterval;
@property (nonatomic) NSTimeInterval currentTimeInterval;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSArray *files;
@property (nonatomic) int currentIndex;
@property (strong, nonatomic) NSImage *currentImage;

@end

@implementation DonnaArtShowView

#pragma mark - Properties

- (NSString *)path
{
    if(!_path)
    {
        _path = @"/Users/erikla/Desktop/screensaver";
    }
    return _path;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self)
    {
        [self setAnimationTimeInterval:5.0];
        self.changeTimeInterval = 1.0; //20.0 * 60.0;
        self.currentTimeInterval = self.changeTimeInterval;
        self.currentIndex = 0;
    }
    return self;
}

- (void)startAnimation
{
    NSError *error;

    [super startAnimation];

    self.files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
}

- (void)stopAnimation
{
    [super stopAnimation];
        // TODO save index so we can start with the same file next time
}

- (void)drawRect:(NSRect)rect
{

    [super drawRect:rect];
    if(self.currentImage)
    {
        if(self.currentImage.size.height > rect.size.height ||
           self.currentImage.size.width > rect.size.width)
        {
            // TODO: handle case where picture is too big for the screen
        }
        CGFloat centerX = (rect.size.width / 2.0) - (self.currentImage.size.width / 2.0);
        CGFloat centerY = (rect.size.height / 2.0) - (self.currentImage.size.height / 2.0);

        [self.currentImage drawInRect:CGRectMake(centerX, centerY, self.currentImage.size.width,
                                                 self.currentImage.size.height)];
    }
}

- (void)animateOneFrame
{
    self.currentTimeInterval += self.animationTimeInterval;
    if(self.currentTimeInterval > self.changeTimeInterval)
    {
        do
        {
            self.currentIndex++;
            if(self.currentIndex >= self.files.count)
            {
                self.currentIndex = 0;
            }

            self.currentImage = [[NSImage alloc]
                                 initByReferencingFile:[self.path stringByAppendingPathComponent:self.files[self.currentIndex]]];
            [self setNeedsDisplay:YES];

        } while(!self.currentImage);


        self.currentTimeInterval = 0.0;
    }
    
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
