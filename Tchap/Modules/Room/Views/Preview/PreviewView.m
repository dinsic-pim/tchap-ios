/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "PreviewView.h"

#import "DesignValues.h"

#import "GeneratedInterface-Swift.h"

@interface PreviewView() <Stylable>

@property (nonatomic, strong) id<Style> currentStyle;

@end

@implementation PreviewView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

+ (instancetype)instantiate
{
    PreviewView *previewView = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    [previewView updateWithStyle:Variant2Style.shared];
    return previewView;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.previewLabel.text = nil;
    self.subNoticeLabel.text = nil;
    
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateHighlighted];
    [self.rightButton setTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] forState:UIControlStateNormal];
    [self.rightButton setTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] forState:UIControlStateHighlighted];
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.previewLabel.numberOfLines = 0;
    self.subNoticeLabel.numberOfLines = 0;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    
    [self updateWithStyle:self.currentStyle];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    self.backgroundColor = style.backgroundColor;
    
    self.previewLabel.textColor = style.primaryTextColor;
    self.subNoticeLabel.textColor = style.secondaryTextColor;
    self.bottomBorderView.backgroundColor = style.secondaryBackgroundColor;
    
    self.leftButton.backgroundColor = style.buttonBorderedBackgroundColor;
    self.leftButton.titleLabel.textColor = style.buttonBorderedTitleColor;
    
    self.rightButton.backgroundColor = style.buttonBorderedBackgroundColor;
    self.rightButton.titleLabel.textColor = style.buttonBorderedTitleColor;
}

- (void)refreshDisplay
{
    // Set the default preview subtitle displayed in case of peeking
    self.subNoticeLabel.text = NSLocalizedStringFromTable(@"room_preview_subtitle", @"Vector", nil);
    
    if (!_roomName)
    {
        _roomName = NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room_default", @"Vector", nil);
    }
    else if (_roomName.length > 30)
    {
        // Would have been nice to get the cropped string displayed by
        // self.displayNameTextField but the value is not accessible.
        // Cut it off by hand
        _roomName = [NSString stringWithFormat:@"%@…",[_roomName substringToIndex:30]];
    }
    
    self.previewLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room", @"Vector", nil), _roomName];
    
    // Force the layout of subviews to update the position of 'bottomBorderView' which is used to define the actual height of the preview container.
    [self layoutIfNeeded];
}

- (void)setRoomName:(NSString *)roomName
{
    _roomName = roomName;
    [self refreshDisplay];
}

@end
