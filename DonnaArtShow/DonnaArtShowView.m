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

    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];

    self.files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error] sortedArrayUsingDescriptors:@[sort]];
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
        NSInteger repWidth = 0;
        NSInteger repHeight = 0;
        CGFloat height, width;
        for(NSImageRep *rep in self.currentImage.representations)
        {
            NSLog(@"Image rep width: %ld height: %ld", (long)rep.pixelsWide, (long)rep.pixelsHigh);
            if([rep pixelsWide] > repWidth)
            {
                repWidth = [rep pixelsWide];
                repHeight = [rep pixelsHigh];
            }
        }
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(repWidth, repHeight)];
        [image addRepresentations:self.currentImage.representations];

        CGFloat centerX, centerY;

//        if(image.size.height > rect.size.height ||
//           image.size.width > rect.size.width)
//        {
            CGFloat horizontalScaleFactor = rect.size.width / image.size.width;
            CGFloat verticalScaleFactor = rect.size.height / image.size.height;
            CGFloat scaleFactor;

            if(verticalScaleFactor < horizontalScaleFactor)
            {
                scaleFactor = verticalScaleFactor;
            }
            else
            {
                scaleFactor = horizontalScaleFactor;
            }

            width = image.size.width * scaleFactor;
            height = image.size.height * scaleFactor;
//        }
//        else
//        {
//            width = image.size.width;
//            height = image.size.height;
//        }

        centerX = (rect.size.width / 2.0) - (width / 2.0);
        centerY = (rect.size.height / 2.0) - (height / 2.0);


        NSRect newRect = CGRectMake(centerX, centerY, width,
                                 height);
        [image drawInRect:newRect];
        NSLog(@"Drawing %@ (%@) in rect: %@", self.files[self.currentIndex],
              NSStringFromSize(self.currentImage.size), NSStringFromRect(newRect));

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
    if(!self.configureWindow)
    {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        BOOL result = [bundle loadNibNamed:@"ConfigurationSheet" owner:self topLevelObjects:nil];
        [self.pictureChangeIntervalComboBox addItemsWithObjectValues:[DonnaArtShowView comboBoxToInterval].allKeys];
    }
    return self.configureWindow;

}
- (IBAction)configureOK:(NSButton *)sender
{
    
}

- (IBAction)configureCancel:(NSButton *)sender
{

}
- (IBAction)configureChooseFolder:(NSButton *)sender
{

}

+ (NSDictionary *)comboBoxToInterval
{
    return @{@"5 seconds": @5.0,
             @"Minute": @60,
             @"15 minutes": @(60 * 15),
             @"20 minutes": @(60 * 20),
             @"Hour": @(60 * 60),
             @"4 hours": @(60 * 60 * 4),
             @"8 hours": @(60 * 60 * 8),
             @"Day": @(60 *60 * 24)};
}

@end
