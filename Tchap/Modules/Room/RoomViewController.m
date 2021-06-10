/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
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

#import "RoomViewController.h"

#import "RoomDataSource.h"
#import "RoomBubbleCellData.h"

#import "RoomInputToolbarView.h"
#import "DisabledRoomInputToolbarView.h"

#import "RoomActivitiesView.h"

#import "AttachmentsViewController.h"

#import "EventDetailsView.h"
#import "PreviewView.h"

#import "RoomMemberDetailsViewController.h"

#import "SegmentedViewController.h"

#import "UsersDevicesViewController.h"

#import "ReadReceiptsViewController.h"

#import "JitsiViewController.h"

#import "RoomEmptyBubbleCell.h"

#import "RoomIncomingTextMsgBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomIncomingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomOutgoingTextMsgBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleBubbleCell.h"
#import "RoomOutgoingTextMsgWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.h"
#import "RoomOutgoingAttachmentBubbleCell.h"
#import "RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomOutgoingAttachmentWithPaginationTitleBubbleCell.h"

#import "RoomMembershipBubbleCell.h"
#import "RoomMembershipWithPaginationTitleBubbleCell.h"
#import "RoomMembershipCollapsedBubbleCell.h"
#import "RoomMembershipCollapsedWithPaginationTitleBubbleCell.h"
#import "RoomMembershipExpandedBubbleCell.h"
#import "RoomMembershipExpandedWithPaginationTitleBubbleCell.h"

#import "RoomAttachmentAntivirusScanStatusBubbleCell.h"
#import "RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell.h"
#import "RoomAttachmentAntivirusScanStatusWithPaginationTitleBubbleCell.h"

#import "RoomSelectedStickerBubbleCell.h"
#import "RoomPredecessorBubbleCell.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"

#import "AvatarGenerator.h"
#import "Tools.h"
#import "WidgetManager.h"

#import "GBDeviceInfo_iOS.h"

#import "MXRoom+Riot.h"

#import "IntegrationManagerViewController.h"
#import "WidgetPickerViewController.h"
#import "StickerPickerViewController.h"

#import "EventFormatter.h"
#import <MatrixKit/MXKSlashCommands.h>

#import "MXSession+Riot.h"
#import "RoomPreviewData.h"

#import "GeneratedInterface-Swift.h"

NSString *const RoomErrorDomain = @"RoomErrorDomain";

@interface RoomViewController () <UIGestureRecognizerDelegate, Stylable, UIScrollViewAccessibilityDelegate, RoomTitleViewDelegate, MXServerNoticesDelegate, RoomContextualMenuViewControllerDelegate, ReactionsMenuViewModelCoordinatorDelegate, EditHistoryCoordinatorBridgePresenterDelegate, MXKDocumentPickerPresenterDelegate, EmojiPickerCoordinatorBridgePresenterDelegate, ReactionHistoryCoordinatorBridgePresenterDelegate, CameraPresenterDelegate, MediaPickerCoordinatorBridgePresenterDelegate, RoomDataSourceDelegate>
{
    // The preview header
    PreviewView *previewHeader;
    
    // The customized room data source for Vector
    RoomDataSource *customizedRoomDataSource;
    
    // List of members who are typing in the room.
    NSArray *currentTypingUsers;
    
    // Typing notifications listener.
    id typingNotifListener;
    
    // Missed discussions badge
    NSUInteger missedDiscussionsCount;
    NSUInteger missedHighlightCount;
    UIBarButtonItem *missedDiscussionsButton;
    UILabel *missedDiscussionsBadgeLabel;
    UIView  *missedDiscussionsBadgeLabelBgView;
    UIView  *missedDiscussionsBarButtonCustomView;
    
    // The list of unknown devices that prevent outgoing messages from being sent
    MXUsersDevicesMap<MXDeviceInfo*> *unknownDevices;
    
    // Observe kAppDelegateNetworkStatusDidChangeNotification to handle network status change.
    id kAppDelegateNetworkStatusDidChangeNotificationObserver;

    // Observers to manage MXSession state (and sync errors)
    id kMXSessionStateDidChangeObserver;

    // Observers to manage ongoing conference call banner
    id kMXCallStateDidChangeObserver;
    id kMXCallManagerConferenceStartedObserver;
    id kMXCallManagerConferenceFinishedObserver;

    // Observers to manage widgets
    id kMXKWidgetManagerDidUpdateWidgetObserver;
    
    // Observer kMXRoomSummaryDidChangeNotification to keep updated the missed discussion count
    id mxRoomSummaryDidChangeObserver;

    // Observer for removing the re-request explanation/waiting dialog
    id mxEventDidDecryptNotificationObserver;
    
    // The table view cell in which the read marker is displayed (nil by default).
    MXKRoomBubbleTableViewCell *readMarkerTableViewCell;
    
    // Tell whether the view controller is appeared or not.
    BOOL isAppeared;
    
    // Listener for `m.room.tombstone` event type
    id tombstoneEventNotificationsListener;

    // Homeserver notices
    MXServerNotices *serverNotices;
    
    // Formatted body parser for events
    FormattedBodyParser *formattedBodyParser;
}

// The preview header
@property (weak, nonatomic) IBOutlet UIView *previewHeaderContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeaderContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeaderContainerHeightConstraint;

// The jump to last unread banner
@property (weak, nonatomic) IBOutlet UIView *jumpToLastUnreadBannerContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *jumpToLastUnreadBannerContainerTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *jumpToLastUnreadButton;
@property (weak, nonatomic) IBOutlet UILabel *jumpToLastUnreadLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetReadMarkerButton;
@property (weak, nonatomic) IBOutlet UIView *jumpToLastUnreadBannerSeparatorView;

@property (nonatomic, weak) RoomTitleView *roomTitleView;
@property (nonatomic, strong) id<Style> currentStyle;

// Direct chat target user when create a discussion without associated room
@property (nonatomic, nullable, strong) User *discussionTargetUser;
@property (nonatomic, nullable, strong) RoomService *roomService;
@property (nonatomic, nullable, strong) UserService *userService;

// Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
@property (nonatomic, weak) id kThemeServiceDidChangeThemeNotificationObserver;

@property (nonatomic, weak) IBOutlet UIView *overlayContainerView;


@property (nonatomic, strong) RoomContextualMenuViewController *roomContextualMenuViewController;
@property (nonatomic, strong) RoomContextualMenuPresenter *roomContextualMenuPresenter;
@property (nonatomic, strong) MXKErrorAlertPresentation *errorPresenter;
@property (nonatomic, strong) NSString *textMessageBeforeEditing;
@property (nonatomic, strong) EditHistoryCoordinatorBridgePresenter *editHistoryPresenter;
@property (nonatomic, strong) MXKDocumentPickerPresenter *documentPickerPresenter;
@property (nonatomic, strong) EmojiPickerCoordinatorBridgePresenter *emojiPickerCoordinatorBridgePresenter;
@property (nonatomic, strong) ReactionHistoryCoordinatorBridgePresenter *reactionHistoryCoordinatorBridgePresenter;
@property (nonatomic, strong) CameraPresenter *cameraPresenter;
@property (nonatomic, strong) MediaPickerCoordinatorBridgePresenter *mediaPickerPresenter;
@property (nonatomic, strong) RoomMessageURLParser *roomMessageURLParser;

/**
 Action used to handle some buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end

@implementation RoomViewController
@synthesize roomPreviewData;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (nonnull instancetype)instantiate
{
    RoomViewController *roomViewController = [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                                                            bundle:[NSBundle bundleForClass:self.class]];
    roomViewController.currentStyle = Variant2Style.shared;
    return roomViewController;
}

+ (nonnull instancetype)instantiateWithDiscussionTargetUser:(nonnull User*)discussionTargetUser session:(nonnull MXSession*)session
{
    RoomViewController *roomViewController = [self instantiate];
    roomViewController.discussionTargetUser = discussionTargetUser;
    [roomViewController addMatrixSession:session];
    return roomViewController;
}

#pragma mark -

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Disable auto join
        self.autoJoinInvitedRoom = NO;
        
        // Disable auto scroll to bottom on keyboard presentation
        self.scrollHistoryToTheBottomOnKeyboardPresentation = NO;
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Disable auto join
        self.autoJoinInvitedRoom = NO;
        
        // Disable auto scroll to bottom on keyboard presentation
        self.scrollHistoryToTheBottomOnKeyboardPresentation = NO;
    }
    
    return self;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    formattedBodyParser = [FormattedBodyParser new];
    
    _showMissedDiscussionsBadge = NO;
    
    
    // Listen to the event sent state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeSentState:) name:kMXEventDidChangeSentStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeIdentifier:) name:kMXEventDidChangeIdentifierNotification object:nil];
}

- (void)setupRoomTitleView {
    
    if (!self.roomTitleView) {
        RoomTitleView *roomTitleView = [RoomTitleView instantiateWithStyle:Variant2Style.shared];
        roomTitleView.delegate = self;
        self.navigationItem.titleView = roomTitleView;
        self.roomTitleView = roomTitleView;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register first customized cell view classes used to render bubbles
    [self.bubblesTableView registerClass:RoomIncomingTextMsgBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomIncomingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingAttachmentWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class forCellReuseIdentifier:RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomEmptyBubbleCell.class forCellReuseIdentifier:RoomEmptyBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomMembershipBubbleCell.class forCellReuseIdentifier:RoomMembershipBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipCollapsedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipCollapsedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomMembershipExpandedWithPaginationTitleBubbleCell.class forCellReuseIdentifier:RoomMembershipExpandedWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:RoomSelectedStickerBubbleCell.class forCellReuseIdentifier:RoomSelectedStickerBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:RoomPredecessorBubbleCell.class forCellReuseIdentifier:RoomPredecessorBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerNib:RoomAttachmentAntivirusScanStatusBubbleCell.nib forCellReuseIdentifier:RoomAttachmentAntivirusScanStatusBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerNib:RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell.nib forCellReuseIdentifier:RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerNib:RoomAttachmentAntivirusScanStatusWithPaginationTitleBubbleCell.nib forCellReuseIdentifier:RoomAttachmentAntivirusScanStatusWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    [self.bubblesTableView registerClass:KeyVerificationIncomingRequestApprovalBubbleCell.class forCellReuseIdentifier:KeyVerificationIncomingRequestApprovalBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationRequestStatusBubbleCell.class forCellReuseIdentifier:KeyVerificationRequestStatusBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationRequestStatusWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationRequestStatusWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationConclusionBubbleCell.class forCellReuseIdentifier:KeyVerificationConclusionBubbleCell.defaultReuseIdentifier];
    [self.bubblesTableView registerClass:KeyVerificationConclusionWithPaginationTitleBubbleCell.class forCellReuseIdentifier:KeyVerificationConclusionWithPaginationTitleBubbleCell.defaultReuseIdentifier];
    
    // Replace the default input toolbar view.
    // Note: this operation will force the layout of subviews. That is why cell view classes must be registered before.
    [self updateRoomInputToolbarViewClassIfNeeded];
    
    // set extra area
    [self setRoomActivitiesViewClass:RoomActivitiesView.class];
    
    // Custom the attachmnet viewer
    [self setAttachmentsViewerClass:AttachmentsViewController.class];
    
    // Custom the event details view
    [self setEventDetailsViewClass:EventDetailsView.class];

    // Prepare missed dicussion badge (if any)
    self.showMissedDiscussionsBadge = _showMissedDiscussionsBadge;
    
    [self setupRoomTitleView];
    
    // Set up the room title view according to the data source (if any)
    [self refreshRoomTitle];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    self.roomContextualMenuPresenter = [RoomContextualMenuPresenter new];
    self.errorPresenter = [MXKErrorAlertPresentation new];
    self.roomMessageURLParser = [RoomMessageURLParser new];
    
    // Observe user interface theme change.
    MXWeakify(self);
    _kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self userInterfaceThemeDidChange];
        
    }];
}

- (void)userInterfaceThemeDidChange
{
    [self updateWithStyle:self.currentStyle];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    // @TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = style.overlayBackgroundColor;

    //[self.inputToolbarView customizeViewRendering];
    
    // Prepare jump to last unread banner
    self.jumpToLastUnreadBannerContainer.backgroundColor = style.secondaryBackgroundColor;
    self.jumpToLastUnreadLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"room_jump_to_first_unread", @"Vector", nil) attributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle), NSUnderlineColorAttributeName:style.secondaryTextColor, NSForegroundColorAttributeName:style.secondaryTextColor}];
    
    self.jumpToLastUnreadBannerSeparatorView.backgroundColor = style.secondaryBackgroundColor;
    
    self.previewHeaderContainer.backgroundColor = style.backgroundColor;
    if (previewHeader)
    {
        [previewHeader customizeViewRendering];
    }
    
    missedDiscussionsBadgeLabel.textColor = style.primaryTextColor;
    missedDiscussionsBadgeLabel.font = [UIFont boldSystemFontOfSize:14];
    missedDiscussionsBadgeLabel.backgroundColor = [UIColor clearColor];
    
    // Check the table view style to select its bg color.
    self.bubblesTableView.backgroundColor = style.backgroundColor;
    self.view.backgroundColor = self.bubblesTableView.backgroundColor;
    
    if (self.bubblesTableView.dataSource)
    {
        [self.bubblesTableView reloadData];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"ChatRoom"];
    
    // Refresh tool bar if the room data source is set.
    if (self.roomDataSource)
    {
        [self refreshRoomInputToolbar];
    }
    
    [self listenTypingNotifications];
    [self listenCallNotifications];
    [self listenWidgetNotifications];
    [self listenTombstoneEventNotifications];
    [self listenMXSessionStateChangeNotifications];
    
    [self userInterfaceThemeDidChange];
    
    if ([self.roomDataSource.roomId isEqualToString:[AppDelegate theDelegate].lastNavigatedRoomIdFromPush])
    {
        [self startActivityIndicator];
        [self.roomDataSource reload];
    }
    [AppDelegate theDelegate].lastNavigatedRoomIdFromPush = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // hide action
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    [self removeTypingNotificationsListener];
    
    if (customizedRoomDataSource)
    {
        // Cancel potential selected event (to leave edition mode)
        if (customizedRoomDataSource.selectedEventId)
        {
            [self cancelEventSelection];
        }
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];
    [self removeMXSessionStateChangeNotificationsListener];

    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    isAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    isAppeared = YES;
    [self checkReadMarkerVisibility];
    
    if (self.roomDataSource)
    {
        // Set visible room id
        [AppDelegate theDelegate].visibleRoomId = self.roomDataSource.roomId;
    }
    
    // Observe network reachability
    kAppDelegateNetworkStatusDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateNetworkStatusDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self refreshActivitiesViewDisplay];
        
    }];
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
    
    // Observe missed notifications
    mxRoomSummaryDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomSummaryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        MXRoomSummary *roomSummary = notif.object;

        if ([roomSummary.roomId isEqualToString:self.roomDataSource.roomId])
        {
            [self refreshMissedDiscussionsCount:NO];
            [self refreshRoomTitle];
        }
    }];
    [self refreshMissedDiscussionsCount:YES];
    
    [self refreshRoomTitle];
    
    self.keyboardHeight = MAX(self.keyboardHeight, 0);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Hide contextual menu if needed
    [self hideContextualMenuAnimated:NO];
    
    // Reset visible room id
    [AppDelegate theDelegate].visibleRoomId = nil;
    
    if (kAppDelegateNetworkStatusDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateNetworkStatusDidChangeNotificationObserver];
        kAppDelegateNetworkStatusDidChangeNotificationObserver = nil;
    }
    
    if (mxRoomSummaryDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }

    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets contentInset = self.bubblesTableView.contentInset;
    contentInset.bottom = self.bottomLayoutGuide.length;
    self.bubblesTableView.contentInset = contentInset;
    
    // Check here whether a subview has been added or removed
    if (eventDetailsView)
    {
        if (!eventDetailsView.superview)
        {
            // Reset
            eventDetailsView = nil;
        }
    }

    // Check whether the preview header is visible
    if (previewHeader)
    {
        // Adjust the top constraint of the bubbles table
        CGRect frame = previewHeader.bottomBorderView.frame;
        self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;

        self.bubblesTableViewTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant - self.bubblesTableView.mxk_adjustedContentInset.top;
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.previewHeaderContainerHeightConstraint.constant;
    }
    else
    {
        self.bubblesTableViewTopConstraint.constant = 0;
        self.jumpToLastUnreadBannerContainerTopConstraint.constant = self.bubblesTableView.mxk_adjustedContentInset.top;
    }
    
    [self refreshMissedDiscussionsCount:YES];
}


#pragma mark - Accessibility

// Handle scrolling when VoiceOver is on because it does not work well if we let the system do:
// VoiceOver loses the focus on the tableview
- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction
{
    BOOL canScroll = YES;

    // Scroll by one page
    CGFloat tableViewHeight = self.bubblesTableView.frame.size.height;

    CGPoint offset = self.bubblesTableView.contentOffset;
    switch (direction)
    {
        case UIAccessibilityScrollDirectionUp:
            offset.y -= tableViewHeight;
            break;

        case UIAccessibilityScrollDirectionDown:
            offset.y += tableViewHeight;
            break;

        default:
            break;
    }

    if (offset.y < 0 && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionBackwards])
    {
        // Can't paginate more. Let's stick on the first item
        UIView *focusedView = [self firstCellWithAccessibilityDataInCells:self.bubblesTableView.visibleCells.objectEnumerator];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, focusedView);
        canScroll = NO;
    }
    else if (offset.y > self.bubblesTableView.contentSize.height - tableViewHeight
             && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionForwards])
    {
        // Can't paginate more. Let's stick on the last item with accessibility
        UIView *focusedView = [self firstCellWithAccessibilityDataInCells:self.bubblesTableView.visibleCells.reverseObjectEnumerator];
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, focusedView);
        canScroll = NO;
    }
    else
    {
        // Disable VoiceOver while scrolling
        self.bubblesTableView.accessibilityElementsHidden = YES;

        [self setBubbleTableViewContentOffset:offset animated:NO];

        NSEnumerator<UITableViewCell*> *cells;
        if (direction == UIAccessibilityScrollDirectionUp)
        {
            cells = self.bubblesTableView.visibleCells.objectEnumerator;
        }
        else
        {
            cells = self.bubblesTableView.visibleCells.reverseObjectEnumerator;
        }
        UIView *cell = [self firstCellWithAccessibilityDataInCells:cells];

        self.bubblesTableView.accessibilityElementsHidden = NO;

        // Force VoiceOver to focus on a visible item
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell);
    }

    // If we cannot scroll, let VoiceOver indicates the border
    return canScroll;
}

- (UIView*)firstCellWithAccessibilityDataInCells:(NSEnumerator<UITableViewCell*>*)cells
{
    UIView *view;

    for (UITableViewCell *cell in cells)
    {
        if (![cell isKindOfClass:[RoomEmptyBubbleCell class]])
        {
            view = cell;
            break;
        }
    }

    return view;
}

#pragma mark - Override MXKRoomViewController

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    // Re-enable the read marker display, and disable its update.
    self.roomDataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
}

- (void)displayRoom:(MXKRoomDataSource *)dataSource
{
    // Remove potential preview Data
    if (roomPreviewData)
    {
        roomPreviewData = nil;
        [self removeMatrixSession:self.mainSession];
        [self showPreviewHeader:NO];
    }
    
    // Set potential discussion target user to nil, now use the dataSource to populate the view
    self.discussionTargetUser = nil;
    
    // Enable the read marker display, and disable its update.
    dataSource.showReadMarker = YES;
    self.updateRoomReadMarker = NO;
    
    [super displayRoom:dataSource];
    
    customizedRoomDataSource = nil;
    
    if (self.roomDataSource)
    {
        // Issue: when the room has been already rendered once, a partial reload of the table is observed during [super displayRoom:].
        // This triggers a scroll to bottom and reset the flag shouldScrollToBottomOnTableRefresh whereas the view controller does not appeared yet.
        // Patch: Force the flag to scroll to bottom the bubble history if the table is not visible yet.
        if (self.bubblesTableView.isHidden)
        {
            shouldScrollToBottomOnTableRefresh = YES;
        }
        
        [self listenToServerNotices];

        self.eventsAcknowledgementEnabled = YES;
        
        // Set room title view
        [self refreshRoomTitle];
        
        // Store ref on customized room data source
        if ([dataSource isKindOfClass:RoomDataSource.class])
        {
            customizedRoomDataSource = (RoomDataSource*)dataSource;
        }
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    [self refreshRoomInputToolbar];
}

- (void)updateViewControllerAppearanceOnRoomDataSourceState
{
    [super updateViewControllerAppearanceOnRoomDataSourceState];
    
    if (self.isRoomPreview)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        // Remove input tool bar if any
        if (self.inputToolbarView)
        {
            [super setRoomInputToolbarViewClass:nil];
        }
        
        if (previewHeader)
        {
            previewHeader.roomName = self.roomPreviewData.roomName;
        }
    }
    else if (self.isNewDiscussion)
    {
        [self refreshRoomInputToolbar];
    }
    else
    {
        [self showPreviewHeader:NO];
        
        self.navigationItem.rightBarButtonItem.enabled = (self.roomDataSource != nil);
        
        if (self.roomDataSource)
        {
            // Restore tool bar view and room activities view if none
            [self updateRoomInputToolbarViewClassIfNeeded];
            [self refreshRoomInputToolbar];
            
            if (!self.activitiesView)
            {
                // And the extra area
                [self setRoomActivitiesViewClass:RoomActivitiesView.class];
            }
        }
    }
}

- (void)leaveRoomOnEvent:(MXEvent*)event
{
    // Disable the tap gesture handling in the title view by removing the delegate.
    self.roomTitleView.delegate = nil;
    
    // Hide the potential read marker banner.
    self.jumpToLastUnreadBannerContainer.hidden = YES;
    
    [super leaveRoomOnEvent:event];
}

// Set the input toolbar according to the current display
- (void)updateRoomInputToolbarViewClassIfNeeded
{
    Class roomInputToolbarViewClass = RoomInputToolbarView.class;
    
    BOOL shouldDismissContextualMenu = NO;
    
    // Check the user has enough power to post message
    if (self.roomDataSource.roomState)
    {
        MXRoomPowerLevels *powerLevels = self.roomDataSource.roomState.powerLevels;
        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
        
        BOOL canSend = (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:kMXEventTypeStringRoomMessage]);
        BOOL isRoomObsolete = self.roomDataSource.roomState.isObsolete;
        BOOL isResourceLimitExceeded = [self.roomDataSource.mxSession.syncError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded];
        
        if (isRoomObsolete || isResourceLimitExceeded)
        {
            roomInputToolbarViewClass = nil;
            shouldDismissContextualMenu = YES;
        }
        else if (!canSend)
        {
            roomInputToolbarViewClass = DisabledRoomInputToolbarView.class;
            shouldDismissContextualMenu = YES;
        }
    }
    
    // Do not show toolbar in case of preview
    if (self.isRoomPreview)
    {
        roomInputToolbarViewClass = nil;
        shouldDismissContextualMenu = YES;
    }
    
    if (shouldDismissContextualMenu)
    {
        [self hideContextualMenuAnimated:NO];
    }
    
    // Change inputToolbarView class only if given class is different from current one
    if (!self.inputToolbarView || ![self.inputToolbarView isMemberOfClass:roomInputToolbarViewClass])
    {
        [super setRoomInputToolbarViewClass:roomInputToolbarViewClass];
        [self updateInputToolBarViewHeight];
    }
}

// Get the height of the current room input toolbar
- (CGFloat)inputToolbarHeight
{
    CGFloat height = 0;

    if ([self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        height = ((RoomInputToolbarView*)self.inputToolbarView).mainToolbarHeightConstraint.constant;
    }
    else if ([self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        height = ((DisabledRoomInputToolbarView*)self.inputToolbarView).mainToolbarMinHeightConstraint.constant;
    }

    return height;
}

- (void)setRoomActivitiesViewClass:(Class)roomActivitiesViewClass
{
    // Do not show room activities in case of preview (FIXME: show it when live events will be supported during peeking)
    if (self.isRoomPreview)
    {
        roomActivitiesViewClass = nil;
    }
    
    [super setRoomActivitiesViewClass:roomActivitiesViewClass];
}

- (BOOL)isIRCStyleCommand:(NSString*)string
{
    // Do not support IRC-style command in direct chat (discussion)
    if (self.roomDataSource.room.isDirect)
    {
        return NO;
    }
    
    // Override the default behavior for `/join` command in order to open automatically the joined room
    if ([string hasPrefix:kMXKSlashCmdJoinRoom])
    {
        // Join a room
        NSString *roomAlias;
        
        // Sanity check
        if (string.length > kMXKSlashCmdJoinRoom.length)
        {
            roomAlias = [string substringFromIndex:kMXKSlashCmdJoinRoom.length + 1];
            
            // Remove white space from both ends
            roomAlias = [roomAlias stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        
        // Check
        if (roomAlias.length)
        {
            // TODO: /join command does not support via parameters yet
            [self.mainSession joinRoom:roomAlias viaServers:nil success:^(MXRoom *room) {
                
                // Show the room
                if (self.delegate)
                {
                    [self.delegate roomViewController:self showRoom:room.roomId];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[RoomVC] Join roomAlias (%@) failed", roomAlias);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                
            }];
        }
        else
        {
            // Display cmd usage in text input as placeholder
            self.inputToolbarView.placeholder = @"Usage: /join <room_alias>";
        }
        return YES;
    }
    else if ([string hasPrefix:kMXKSlashCmdChangeDisplayName])
    {
        // The user is not allowed to change his display name
        return NO;
    }
        
    return [super isIRCStyleCommand:string];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight
{
    [super setKeyboardHeight:keyboardHeight];
    
    // Make the activity indicator follow the keyboard
    // At runtime, this creates a smooth animation
    CGPoint activityIndicatorCenter = self.activityIndicator.center;
    activityIndicatorCenter.y = self.view.center.y - keyboardHeight / 2;
    self.activityIndicator.center = activityIndicatorCenter;
}

- (void)dismissTemporarySubViews
{
    [super dismissTemporarySubViews];
}

- (void)setBubbleTableViewDisplayInTransition:(BOOL)bubbleTableViewDisplayInTransition
{
    if (self.isBubbleTableViewDisplayInTransition != bubbleTableViewDisplayInTransition)
    {
        [super setBubbleTableViewDisplayInTransition:bubbleTableViewDisplayInTransition];
        
        // Refresh additional displays when the table is ready.
        if (!bubbleTableViewDisplayInTransition && !self.bubblesTableView.isHidden)
        {
            [self refreshActivitiesViewDisplay];
            
            [self checkReadMarkerVisibility];
            [self refreshJumpToLastUnreadBannerDisplay];
        }
    }
}

- (void)sendTextMessage:(NSString*)msgTxt
{
    // Re-invite the left member before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createOrRestoreDiscussionIfNeeded:^(BOOL success) {
        MXStrongifyAndReturnIfNil(self);
        if (success)
        {
            if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeReply && self->customizedRoomDataSource.selectedEventId)
            {
                [self.roomDataSource sendReplyToEventWithId:self->customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
                    // Just log the error. The message will be displayed in red in the room history
                    NSLog(@"[RoomViewController] sendTextMessage failed.");
                }];
            }
            else if (self.inputToolBarSendMode == RoomInputToolbarViewSendModeEdit && self->customizedRoomDataSource.selectedEventId)
            {
                [self.roomDataSource replaceTextMessageForEventWithId:self->customizedRoomDataSource.selectedEventId withTextMessage:msgTxt success:nil failure:^(NSError *error) {
                    // Just log the error. The message will be displayed in red
                    NSLog(@"[RoomViewController] sendTextMessage failed.");
                }];
            }
            else
            {
                // Let the datasource send it and manage the local echo
                [self.roomDataSource sendTextMessage:msgTxt success:nil failure:^(NSError *error)
                 {
                     // Just log the error. The message will be displayed in red in the room history
                     NSLog(@"[RoomViewController] sendTextMessage failed.");
                 }];
            }
        }
        
        [self cancelEventSelection];
    }];
}

- (void)sendImage:(NSData*)imageData withMimeType:(NSString*)mimetype
{
    // Re-invite the left member before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createOrRestoreDiscussionIfNeeded:^(BOOL success) {
        MXStrongifyAndReturnIfNil(self);
        if (success)
        {
            // Let the datasource send it and manage the local echo
            [self.roomDataSource sendImage:imageData
                                  mimeType:mimetype
                                   success:nil
                                   failure:^(NSError *error) {
                                       // Nothing to do. The image is marked as unsent in the room history by the datasource
                                       NSLog(@"[RoomViewController] sendImage with mimetype failed.");
                                   }];
        }
    }];
}

- (void)sendVideo:(NSURL*)videoLocalURL
{
    // Re-invite the left member before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createOrRestoreDiscussionIfNeeded:^(BOOL success) {
        MXStrongifyAndReturnIfNil(self);
        if (success)
        {
            // Let the datasource send it and manage the local echo
            [(RoomDataSource*)self.roomDataSource sendVideo:videoLocalURL
                                                    success:nil
                                                    failure:^(NSError *error) {
                                                        // Nothing to do. The video is marked as unsent in the room history by the datasource
                                                        NSLog(@"[RoomViewController] sendVideo failed.");
                                                    }];
        }
    }];
}

- (void)sendFile:(NSURL *)fileLocalURL withMimeType:(NSString*)mimetype
{
    // Re-invite the left member before sending the message in case of a discussion (direct chat)
    MXWeakify(self);
    [self createOrRestoreDiscussionIfNeeded:^(BOOL success) {
        MXStrongifyAndReturnIfNil(self);
        if (success)
        {
            // Let the datasource send it and manage the local echo
            [self.roomDataSource sendFile:fileLocalURL
                                 mimeType:mimetype
                                  success:nil
                                  failure:^(NSError *error) {
                                      // Nothing to do. The file is marked as unsent in the room history by the datasource
                                      NSLog(@"[RoomViewController] sendFile failed.");
                                  }];
        }
    }];
}

- (void)dealloc
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (customizedRoomDataSource)
    {
        customizedRoomDataSource.selectedEventId = nil;
        customizedRoomDataSource = nil;
    }
    
    [self removeTypingNotificationsListener];
    
    if (_kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_kThemeServiceDidChangeThemeNotificationObserver];
    }
    if (kAppDelegateNetworkStatusDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateNetworkStatusDidChangeNotificationObserver];
        kAppDelegateNetworkStatusDidChangeNotificationObserver = nil;
    }
    if (mxRoomSummaryDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxRoomSummaryDidChangeObserver];
        mxRoomSummaryDidChangeObserver = nil;
    }
    if (mxEventDidDecryptNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxEventDidDecryptNotificationObserver];
        mxEventDidDecryptNotificationObserver = nil;
    }
    
    [self removeCallNotificationsListeners];
    [self removeWidgetNotificationsListeners];
    [self removeTombstoneEventNotificationsListener];
    [self removeMXSessionStateChangeNotificationsListener];
    [self removeServerNoticesListener];

    if (previewHeader)
    {
        // Here [destroy] is called before [viewWillDisappear:]
        NSLog(@"[RoomVC] destroyed whereas it is still visible");
        
        [previewHeader removeFromSuperview];
        previewHeader = nil;
        
        // Hide preview header container to ignore [self showPreviewHeader:NO] call (if any).
        self.previewHeaderContainer.hidden = YES;
    }
    
    roomPreviewData = nil;
    
    missedDiscussionsBarButtonCustomView = nil;
    missedDiscussionsBadgeLabelBgView = nil;
    missedDiscussionsBadgeLabel = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeSentStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:nil];
    
    self.roomService = nil;
    self.userService = nil;
}

#pragma mark - Tchap

/**
 Check whether the current room is a direct chat left by the other member.
 */
- (void)isDirectChatLeftByTheOther:(void (^)(BOOL isEmptyDirect))onComplete
{
    // In the case of a direct chat, we check if the other member has left the room.
    if (self.roomDataSource)
    {
        NSString *directUserId = self.roomDataSource.room.directUserId;
        if (directUserId)
        {
            [self.roomDataSource.room members:^(MXRoomMembers *roomMembers) {
                MXRoomMember *directUserMember = [roomMembers memberWithUserId:directUserId];
                if (directUserMember)
                {
                    MXMembership directUserMembership = directUserMember.membership;
                    if (directUserMembership != MXMembershipJoin && directUserMembership != MXMembershipInvite)
                    {
                        onComplete(YES);
                    }
                    else
                    {
                        onComplete(NO);
                    }
                }
                else
                {
                    NSLog(@"[RoomViewController] isEmptyDirectChat: the direct user has disappeared");
                    onComplete(YES);
                }
            } failure:^(NSError *error) {
                NSLog(@"[RoomViewController] isEmptyDirectChat: cannot get all room members");
                onComplete(NO);
            }];
            return;
        }
    }
    
    // This is not a direct chat
    onComplete(NO);
}

/**
 Check whether the current room is a direct chat left by the other member.
 In this case, this method will invite again the left member.
 */
- (void)restoreDiscussionIfNeed:(void (^)(BOOL success))onComplete
{
    [self isDirectChatLeftByTheOther:^(BOOL isEmptyDirect) {
        if (isEmptyDirect)
        {
            NSString *directUserId = self.roomDataSource.room.directUserId;
            
            // Check whether the left member has deactivated his account
            self.userService = [[UserService alloc] initWithSession:self.mainSession];
            MXHTTPOperation * operation;
            MXWeakify(self);
            NSLog(@"[RoomViewController] restoreDiscussionIfNeed: check left member %@", directUserId);
            
            operation = [self.userService isAccountDeactivatedFor:directUserId success:^(BOOL isDeactivated) {
                if (isDeactivated)
                {
                    NSLog(@"[RoomViewController] restoreDiscussionIfNeed: the left member has deactivated his account");
                    NSError *error = [NSError errorWithDomain:RoomErrorDomain
                                                         code:0
                                                     userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"tchap_cannot_invite_deactivated_account_user", @"Tchap", nil)}];
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                    onComplete(NO);
                }
                else
                {
                    // Invite again the direct user
                    MXStrongifyAndReturnIfNil(self);
                    NSLog(@"[RoomViewController] restoreDiscussionIfNeed: invite again %@", directUserId);
                    [self.roomDataSource.room inviteUser:directUserId success:^{
                        // Delay the completion in order to display the invite before the local echo of the new message.
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            onComplete(YES);
                        });
                    } failure:^(NSError *error) {
                        NSLog(@"[RoomViewController] restoreDiscussionIfNeed: invite failed");
                        // Alert user
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                        onComplete(NO);
                    }];
                }
                self.userService = nil;
            } failure:^(NSError *error) {
                NSLog(@"[RoomViewController] restoreDiscussionIfNeed: check member status failed");
                // Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
                onComplete(NO);
                self.userService = nil;
            }];
        }
        else
        {
            // Nothing to do
            onComplete(YES);
        }
    }];
}

/**
 Create a direct chat with given user.
 */
- (void)createDiscussionWithUser:(User*)user completion:(void (^)(BOOL success))onComplete
{
    MXWeakify(self);
    
    [self startActivityIndicator];
    
    self.roomService = [[RoomService alloc] initWithSession:self.mainSession];
    MXHTTPOperation * operation;
    
    operation = [self.roomService createDiscussionWith:user.userId success:^(NSString * _Nonnull roomId) {
        MXStrongifyAndReturnIfNil(self);
        
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];
        
        [roomDataSourceManager roomDataSourceForRoom:roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
            
            [self stopActivityIndicator];
            self.roomService = nil;
            
            if (roomDataSource.room.summary.isDirect == NO)
            {
                // TODO: Display an error, and retry to set room as direct otherwise quit the room
                NSLog(@"[RoomViewController] Fail to create room as direct chat");
            }
            //            else
            //            {
            //                // Set discussion target user to nil and now use RoomDataSource for updating view
            [self displayRoom:roomDataSource];
            //            }
            
            onComplete(YES);
        }];
    } failure:^(NSError * _Nonnull error) {
        MXStrongifyAndReturnIfNil(self);
        [self stopActivityIndicator];
        self.roomService = nil;
        
        // TODO: Present error without using AppDelegate
        [[AppDelegate theDelegate] showErrorAsAlert:error];
        onComplete(NO);
    }];
}

/**
 Check whether the current room is a direct chat left by the other member.
 In this case, this method will invite again the left member.
 */
- (void)createOrRestoreDiscussionIfNeeded:(void (^)(BOOL success))onComplete
{
    // Disable the input tool bar during this operation. This prevents us from creating several discussions, or
    // trying to send several invites.
    self.inputToolbarView.userInteractionEnabled = false;
    
    void(^completion)(BOOL) = ^(BOOL success) {
        self.inputToolbarView.userInteractionEnabled = true;
        if (onComplete) {
            onComplete(success);
        }
    };
    
    if (self.discussionTargetUser)
    {
        [self createDiscussionWithUser:self.discussionTargetUser completion:completion];
    }
    else
    {
        [self restoreDiscussionIfNeed:completion];
    }
}

#pragma mark -

- (void)setShowMissedDiscussionsBadge:(BOOL)showMissedDiscussionsBadge
{
    _showMissedDiscussionsBadge = showMissedDiscussionsBadge;
    
    if (_showMissedDiscussionsBadge && !missedDiscussionsBarButtonCustomView)
    {
        // Prepare missed dicussion badge
        missedDiscussionsBarButtonCustomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 21)];
        missedDiscussionsBarButtonCustomView.backgroundColor = [UIColor clearColor];
        missedDiscussionsBarButtonCustomView.clipsToBounds = NO;
        
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBarButtonCustomView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:21];
        
        missedDiscussionsBadgeLabelBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 21, 21)];
        [missedDiscussionsBadgeLabelBgView.layer setCornerRadius:10];
        
        [missedDiscussionsBarButtonCustomView addSubview:missedDiscussionsBadgeLabelBgView];
        missedDiscussionsBarButtonCustomView.accessibilityIdentifier = @"RoomVCMissedDiscussionsBarButton";
        
        missedDiscussionsBadgeLabel = [[UILabel alloc]initWithFrame:CGRectMake(2, 2, 17, 17)];
        missedDiscussionsBadgeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [missedDiscussionsBadgeLabelBgView addSubview:missedDiscussionsBadgeLabel];
        
        NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBadgeLabel
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:missedDiscussionsBadgeLabelBgView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1.0
                                                                              constant:0];
        NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:missedDiscussionsBadgeLabel
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:missedDiscussionsBadgeLabelBgView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:0];
        
        [NSLayoutConstraint activateConstraints:@[heightConstraint, centerXConstraint, centerYConstraint]];
    }
    else
    {
        missedDiscussionsBarButtonCustomView = nil;
        missedDiscussionsBadgeLabelBgView = nil;
        missedDiscussionsBadgeLabel = nil;
    }
}

- (void)setForceHideInputToolBar:(BOOL)forceHideInputToolBar
{
    _forceHideInputToolBar = forceHideInputToolBar;
    
    [self refreshRoomInputToolbar];
}

#pragma mark - Internals

- (void)forceLayoutRefresh
{
    // Sanity check: check whether the table view data source is set.
    if (self.bubblesTableView.dataSource)
    {
        [self.view layoutIfNeeded];
    }
}

- (BOOL)isRoomPreview
{
    // Check whether some preview data are defined.
    if (roomPreviewData)
    {
        return YES;
    }
    return NO;
}

// Indicates if a new discussion with a target user (without associated room) is occuring.
- (BOOL)isNewDiscussion
{
    return self.discussionTargetUser != nil;
}

- (BOOL)isEncryptionEnabled
{
    return self.roomDataSource.room.summary.isEncrypted && self.mainSession.crypto != nil;
}

- (void)refreshRoomTitle
{
    MXSession *session = self.mainSession;
    if (!session)
    {
        return;
    }
    
    RoomTitleViewModelBuilder *roomTitleViewModelBuilder = [[RoomTitleViewModelBuilder alloc] initWithSession:session];
    RoomTitleViewModel *roomTitleViewModel;
    
    BOOL showRoomPreviewHeader = NO;
    
    if (self.isRoomPreview)
    {
        showRoomPreviewHeader = YES;
        
        if (self.roomPreviewData)
        {
            roomTitleViewModel = [roomTitleViewModelBuilder buildFromRoomPreviewData:self.roomPreviewData];
        }
    }
    else if (self.isNewDiscussion)
    {
        roomTitleViewModel = [roomTitleViewModelBuilder buildFromUser:self.discussionTargetUser];
    }
    else
    {
        MXRoomSummary *roomSummary = self.roomDataSource.room.summary;
        
        if (roomSummary)
        {
            roomTitleViewModel = [roomTitleViewModelBuilder buildFromRoomSummary:roomSummary];
        }
    }
    
    [self showPreviewHeader:showRoomPreviewHeader];
    
    if (roomTitleViewModel)
    {
        [self.roomTitleView fillWithRoomTitleViewModel:roomTitleViewModel];
    }
}

- (void)updateInputToolBarVisibility
{
    BOOL hideInputToolBar = NO;
    
    if (self.forceHideInputToolBar)
    {
        hideInputToolBar = YES;
    }    
    else if (self.roomDataSource)
    {
        hideInputToolBar = (self.roomDataSource.state != MXKDataSourceStateReady);
    }
    
    self.inputToolbarView.hidden = hideInputToolBar;
}

- (void)refreshRoomInputToolbar
{
    // Show or hide input tool bar
    [self updateInputToolBarVisibility];
    
    // Check whether the input toolbar is ready before updating it.
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        
        // Check whether the call option is supported
        roomInputToolbarView.supportCallOption = BuildSettings.allowVoIPUsage && self.roomDataSource.mxSession.callManager && self.roomDataSource.room.summary.membersCount.joined >= 2;
        
        // Show the hangup button if there is an active call or an active jitsi
        // conference call in the current room
        MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
        if ((callInRoom && callInRoom.state != MXCallStateEnded)
            || [[AppDelegate theDelegate].jitsiViewController.widget.roomId isEqualToString:self.roomDataSource.roomId])
        {
            roomInputToolbarView.activeCall = YES;
        }
        else
        {
            roomInputToolbarView.activeCall = NO;
            
            // Hide the call button if there is an active call in another room
            roomInputToolbarView.supportCallOption &= ([[AppDelegate theDelegate] callStatusBarWindow] == nil);
        }
        
        // Update encryption decoration if needed
        [self updateEncryptionDecorationForRoomInputToolbar:roomInputToolbarView];
    }
    else if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:DisabledRoomInputToolbarView.class])
    {
        DisabledRoomInputToolbarView *roomInputToolbarView = (DisabledRoomInputToolbarView*)self.inputToolbarView;

        // For the moment, there is only one reason to use `DisabledRoomInputToolbarView`
        [roomInputToolbarView setDisabledReason:NSLocalizedStringFromTable(@"room_do_not_have_permission_to_post", @"Vector", nil)];
    }
}

- (void)setInputToolBarSendMode:(RoomInputToolbarViewSendMode)sendMode
{
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        roomInputToolbarView.sendMode = sendMode;
    }
}

- (RoomInputToolbarViewSendMode)inputToolBarSendMode
{
    RoomInputToolbarViewSendMode sendMode = RoomInputToolbarViewSendModeSend;
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        sendMode = roomInputToolbarView.sendMode;
    }

    return sendMode;
}

- (void)onSwipeGesture:(UISwipeGestureRecognizer*)swipeGestureRecognizer
{
    UIView *view = swipeGestureRecognizer.view;
    
    if (view == self.activitiesView)
    {
        // Dismiss the keyboard when user swipes down on activities view.
        [self.inputToolbarView dismissKeyboard];
    }
}

- (void)updateInputToolBarViewHeight
{
    // Update the inputToolBar height.
    CGFloat height = [self inputToolbarHeight];
    // Disable animation during the update
    [UIView setAnimationsEnabled:NO];
    [self roomInputToolbarView:self.inputToolbarView heightDidChanged:height completion:nil];
    [UIView setAnimationsEnabled:YES];
}

- (UIImage*)roomEncryptionBadgeImage
{
    UIImage *encryptionIcon;
    
    if (self.isEncryptionEnabled)
    {
        encryptionIcon = [UIImage imageNamed:@"private_room"];
//        RoomEncryptionTrustLevel roomEncryptionTrustLevel = ((RoomDataSource*)self.roomDataSource).encryptionTrustLevel;
//
//        encryptionIcon = [EncryptionTrustLevelBadgeImageHelper roomBadgeImageFor:roomEncryptionTrustLevel];
    }
    else
    {
        encryptionIcon = [UIImage imageNamed:@"e2e_unencrypted"];
    }
    
    return encryptionIcon;
}

- (void)updateInputToolbarEncryptionDecoration
{
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:RoomInputToolbarView.class])
    {
        RoomInputToolbarView *roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
        [self updateEncryptionDecorationForRoomInputToolbar:roomInputToolbarView];
    }
}

- (void)updateEncryptionDecorationForRoomInputToolbar:(RoomInputToolbarView*)roomInputToolbarView
{
    roomInputToolbarView.isEncryptionEnabled = self.isEncryptionEnabled;
    roomInputToolbarView.encryptedRoomIcon.image = self.roomEncryptionBadgeImage;
}

- (void)handleLongPressFromCell:(id<MXKCellRendering>)cell withTappedEvent:(MXEvent*)event
{
    if (event && !customizedRoomDataSource.selectedEventId)
    {
        [self showContextualMenuForEvent:event fromSingleTapGesture:NO cell:cell animated:YES];
    }
}

- (void)showReactionHistoryForEventId:(NSString*)eventId animated:(BOOL)animated
{
    if (self.reactionHistoryCoordinatorBridgePresenter.isPresenting)
    {
        return;
    }
    
    ReactionHistoryCoordinatorBridgePresenter *presenter = [[ReactionHistoryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession roomId:self.roomDataSource.roomId eventId:eventId];
    presenter.delegate = self;
    
    [presenter presentFrom:self animated:animated];
    
    self.reactionHistoryCoordinatorBridgePresenter = presenter;
}

- (void)showCameraControllerAnimated:(BOOL)animated
{
    CameraPresenter *cameraPresenter = [CameraPresenter new];
    cameraPresenter.delegate = self;
    [cameraPresenter presentCameraFrom:self with:@[MXKUTI.image, MXKUTI.movie] animated:YES];

    self.cameraPresenter = cameraPresenter;
}


- (void)showMediaPickerAnimated:(BOOL)animated
{
    MediaPickerCoordinatorBridgePresenter *mediaPickerPresenter = [[MediaPickerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession mediaUTIs:@[MXKUTI.image, MXKUTI.movie] allowsMultipleSelection:YES];
    mediaPickerPresenter.delegate = self;
    
    UIView *sourceView;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (roomInputToolbarView)
    {
        sourceView = roomInputToolbarView.attachMediaButton;
    }
    else
    {
        sourceView = self.inputToolbarView;
    }

    [mediaPickerPresenter presentFrom:self sourceView:sourceView sourceRect:sourceView.bounds animated:YES];
    
    self.mediaPickerPresenter = mediaPickerPresenter;
}

#pragma mark - Hide/Show preview header

- (void)showPreviewHeader:(BOOL)isVisible
{
    if (self.previewHeaderContainer && self.previewHeaderContainer.isHidden == isVisible)
    {
        if (isVisible)
        {
            previewHeader = [PreviewView instantiate];
            [previewHeader.leftButton addTarget:self action:@selector(onJoinPressed:) forControlEvents:UIControlEventTouchUpInside];
            [previewHeader.rightButton addTarget:self action:@selector(onCancelPressed:) forControlEvents:UIControlEventTouchUpInside];
            previewHeader.translatesAutoresizingMaskIntoConstraints = NO;
            [self.previewHeaderContainer addSubview:previewHeader];
            // Force preview header in full width
            NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                              attribute:NSLayoutAttributeLeading
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.previewHeaderContainer
                                                                              attribute:NSLayoutAttributeLeading
                                                                             multiplier:1.0
                                                                               constant:0];
            NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                               attribute:NSLayoutAttributeTrailing
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.previewHeaderContainer
                                                                               attribute:NSLayoutAttributeTrailing
                                                                              multiplier:1.0
                                                                                constant:0];
            // Vertical constraints are required for iOS > 8
            NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                             attribute:NSLayoutAttributeTop
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.previewHeaderContainer
                                                                             attribute:NSLayoutAttributeTop
                                                                            multiplier:1.0
                                                                              constant:0];
            NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:previewHeader
                                                                                attribute:NSLayoutAttributeBottom
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:self.previewHeaderContainer
                                                                                attribute:NSLayoutAttributeBottom
                                                                               multiplier:1.0
                                                                                 constant:0];
            
            [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, bottomConstraint]];
            
            previewHeader.roomName = self.roomPreviewData.roomName;
            
            CGRect frame = previewHeader.bottomBorderView.frame;
            self.previewHeaderContainerHeightConstraint.constant = frame.origin.y + frame.size.height;
            
            self.previewHeaderContainer.hidden = NO;
        }
        else
        {
            [previewHeader removeFromSuperview];
            previewHeader = nil;
            
            self.previewHeaderContainer.hidden = YES;
        }
    }

    self.navigationController.navigationBar.translucent = isVisible;
}

- (void)onJoinPressed:(id)sender
{
    [self.delegate roomViewControllerPreviewDidTapJoin:self];
}

- (void)onCancelPressed:(id)sender
{
    // Cancel de preview
    [self.delegate roomViewControllerPreviewDidTapCancel:self];
}

#pragma mark - Preview

- (void)displayRoomPreview:(nonnull RoomPreviewData *)previewData
{
    // Release existing room data source or preview
    [self displayRoom:nil];
    
    self.eventsAcknowledgementEnabled = NO;
    
    [self addMatrixSession:previewData.mxSession];
    
    roomPreviewData = previewData;
    
    [self refreshRoomTitle];
    
    if (roomPreviewData.roomDataSource)
    {
        [super displayRoom:roomPreviewData.roomDataSource];
    }
}

#pragma mark - New discussion

- (void)displayNewDiscussionWithTargetUser:(nonnull User*)discussionTargetUser session:(nonnull MXSession*)session
{
    // Release existing room data source or preview
    [self displayRoom:nil];
    
    self.eventsAcknowledgementEnabled = NO;
    
    [self addMatrixSession:session];
    
    self.discussionTargetUser = discussionTargetUser;
    
    [self refreshRoomTitle];
    [self refreshRoomInputToolbar];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class cellViewClass = nil;
    
    // Sanity check
    if ([cellData conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)])
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
        
        // Select the suitable table view cell class
        if (bubbleData.showAntivirusScanStatus)
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                cellViewClass = RoomAttachmentAntivirusScanStatusWithPaginationTitleBubbleCell.class;
            }
            else if (bubbleData.shouldHideSenderInformation)
            {
                cellViewClass = RoomAttachmentAntivirusScanStatusWithoutSenderInfoBubbleCell.class;
            }
            else
            {
                cellViewClass = RoomAttachmentAntivirusScanStatusBubbleCell.class;
            }
        }
        else if (bubbleData.hasNoDisplay)
        {
            cellViewClass = RoomEmptyBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagRoomCreateWithPredecessor)
        {
            cellViewClass = RoomPredecessorBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationRequestIncomingApproval)
        {
            cellViewClass = bubbleData.isPaginationFirstBubble ? KeyVerificationIncomingRequestApprovalWithPaginationTitleBubbleCell.class : KeyVerificationIncomingRequestApprovalBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationRequest)
        {
            cellViewClass = bubbleData.isPaginationFirstBubble ? KeyVerificationRequestStatusWithPaginationTitleBubbleCell.class : KeyVerificationRequestStatusBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagKeyVerificationConclusion)
        {
            cellViewClass = bubbleData.isPaginationFirstBubble ? KeyVerificationConclusionWithPaginationTitleBubbleCell.class : KeyVerificationConclusionBubbleCell.class;
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagMembership)
        {
            if (bubbleData.collapsed)
            {
                if (bubbleData.nextCollapsableCellData)
                {
                    cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipCollapsedWithPaginationTitleBubbleCell.class : RoomMembershipCollapsedBubbleCell.class;
                }
                else
                {
                    // Use a normal membership cell for a single membership event
                    cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
                }
            }
            else if (bubbleData.collapsedAttributedTextMessage)
            {
                // The cell (and its series) is not collapsed but this cell is the first
                // of the series. So, use the cell with the "collapse" button.
                cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipExpandedWithPaginationTitleBubbleCell.class : RoomMembershipExpandedBubbleCell.class;
            }
            else
            {
                cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
            }
        }
        else if (bubbleData.tag == RoomBubbleCellDataTagNotice)
        {
            cellViewClass = bubbleData.isPaginationFirstBubble ? RoomMembershipWithPaginationTitleBubbleCell.class : RoomMembershipBubbleCell.class;
        }
        else if (bubbleData.isIncoming)
        {
            if (bubbleData.isAttachmentWithThumbnail)
            {
                // Check whether the provided celldata corresponds to a selected sticker
                if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
                {
                    cellViewClass = RoomSelectedStickerBubbleCell.class;
                }
                else if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass = RoomIncomingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass = RoomIncomingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomIncomingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = RoomIncomingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomIncomingTextMsgBubbleCell.class;
                }
            }
        }
        else
        {
            // Handle here outgoing bubbles
            if (bubbleData.isAttachmentWithThumbnail)
            {
                // Check whether the provided celldata corresponds to a selected sticker
                if (customizedRoomDataSource.selectedEventId && (bubbleData.attachment.type == MXKAttachmentTypeSticker) && [bubbleData.attachment.eventId isEqualToString:customizedRoomDataSource.selectedEventId])
                {
                    cellViewClass = RoomSelectedStickerBubbleCell.class;
                }
                else if (bubbleData.isPaginationFirstBubble)
                {
                    cellViewClass = RoomOutgoingAttachmentWithPaginationTitleBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingAttachmentWithoutSenderInfoBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomOutgoingAttachmentBubbleCell.class;
                }
            }
            else
            {
                if (bubbleData.isPaginationFirstBubble)
                {
                    if (bubbleData.shouldHideSenderName)
                    {
                        cellViewClass = RoomOutgoingTextMsgWithPaginationTitleWithoutSenderNameBubbleCell.class;
                    }
                    else
                    {
                        cellViewClass = RoomOutgoingTextMsgWithPaginationTitleBubbleCell.class;
                    }
                }
                else if (bubbleData.shouldHideSenderInformation)
                {
                    cellViewClass = RoomOutgoingTextMsgWithoutSenderInfoBubbleCell.class;
                }
                else if (bubbleData.shouldHideSenderName)
                {
                    cellViewClass = RoomOutgoingTextMsgWithoutSenderNameBubbleCell.class;
                }
                else
                {
                    cellViewClass = RoomOutgoingTextMsgBubbleCell.class;
                }
            }
        }
    }
    
    return cellViewClass;
}

#pragma mark - MXKDataSource delegate

- (void)dataSource:(MXKDataSource *)dataSource didRecognizeAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo
{
    // Handle here user actions on bubbles for Vector app
    if (customizedRoomDataSource)
    {
        id<MXKRoomBubbleCellDataStoring> bubbleData;
        
        if ([cell isKindOfClass:[MXKRoomBubbleTableViewCell class]])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            bubbleData = roomBubbleTableViewCell.bubbleData;
        }
        
        
        if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAvatarView])
        {
            MXRoomMember *selectedRoomMember = [self.roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            if (selectedRoomMember && self.delegate)
            {
                [self.delegate roomViewController:self showMemberDetails:selectedRoomMember];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnAvatarView])
        {
            // Add the member display name in text input
            MXRoomMember *roomMember = [self.roomDataSource.roomState.members memberWithUserId:userInfo[kMXKRoomBubbleCellUserIdKey]];
            if (roomMember)
            {
                [self mention:roomMember];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnMessageTextView] || [actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnContentView])
        {
            // Retrieve the tapped event
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            // Check whether a selection already exist or not
            if (customizedRoomDataSource.selectedEventId)
            {
                [self cancelEventSelection];
            }
            else if (tappedEvent)
            {
                if (tappedEvent.eventType == MXEventTypeRoomCreate)
                {
                    // Handle tap on RoomPredecessorBubbleCell
                    MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:tappedEvent.content];
                    NSString *predecessorRoomId = createContent.roomPredecessorInfo.roomId;
                    
                    if (predecessorRoomId)
                    {
                        // Show predecessor room
                        [self.delegate roomViewController:self showRoom:predecessorRoomId];
                    }
//                    else
//                    {
//                        // Show contextual menu on single tap if bubble is not collapsed
//                        if (bubbleData.collapsed)
//                        {
//                            [self showRoomCreationModalWithBubbleData:bubbleData];
//                        }
//                        else
//                        {
//                            [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:YES cell:cell animated:YES];
//                        }
//                    }
                }
                else
                {
                    // Show contextual menu on single tap if bubble is not collapsed
                    if (bubbleData.collapsed)
                    {
                        [self selectEventWithId:tappedEvent.eventId];
                    }
                    else
                    {
                        [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:YES cell:cell animated:YES];
                    }
                }
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnOverlayContainer])
        {
            // Cancel the current event selection
            [self cancelEventSelection];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellRiotEditButtonPressed])
        {
            [self dismissKeyboard];
            
            MXEvent *selectedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (selectedEvent)
            {
                [self showContextualMenuForEvent:selectedEvent fromSingleTapGesture:YES cell:cell animated:YES];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellKeyVerificationIncomingRequestAcceptPressed])
        {
            NSString *eventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            
            RoomDataSource *roomDataSource = (RoomDataSource*)self.roomDataSource;
            
            [roomDataSource acceptVerificationRequestForEventId:eventId success:^{

            } failure:^(NSError *error) {
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellKeyVerificationIncomingRequestDeclinePressed])
        {
            NSString *eventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            
            RoomDataSource *roomDataSource = (RoomDataSource*)self.roomDataSource;
            
            [roomDataSource declineVerificationRequestForEventId:eventId success:^{
                
            } failure:^(NSError *error) {
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnAttachmentView])
        {
            if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventSentState == MXEventSentStateFailed)
            {
                // Shortcut: when clicking on an unsent media, show the action sheet to resend it
                NSString *eventId = ((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId;
                MXEvent *selectedEvent = [self.roomDataSource eventWithEventId:eventId];
                
                if (selectedEvent)
                {
                    [self dataSource:dataSource didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed inCell:cell userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
                }
                else
                {
                    NSLog(@"[RoomViewController] didRecognizeAction:inCell:userInfo tap on attachment with event state MXEventSentStateFailed. Selected event is nil for event id %@", eventId);
                }
            }
            else if (((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.type == MXKAttachmentTypeSticker)
            {
                // We don't open the attachments viewer when the user taps on a sticker.
                // We consider this tap like a selection.
                
                // Check whether a selection already exist or not
                if (customizedRoomDataSource.selectedEventId)
                {
                    [self cancelEventSelection];
                }
                else
                {
                    // Highlight this event in displayed message
                    [self selectEventWithId:((MXKRoomBubbleTableViewCell*)cell).bubbleData.attachment.eventId];
                }
            }
            else
            {
                // Keep default implementation
                [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellTapOnReceiptsContainer])
        {
            MXKReceiptSendersContainer *container = userInfo[kMXKRoomBubbleCellReceiptsContainerKey];
            [ReadReceiptsViewController openInViewController:self fromContainer:container withSession:self.mainSession];
        }
        else if ([actionIdentifier isEqualToString:kRoomMembershipExpandedBubbleCellTapOnCollapseButton])
        {
            // Reset the selection before collapsing
            customizedRoomDataSource.selectedEventId = nil;
            
            [self.roomDataSource collapseRoomBubble:((MXKRoomBubbleTableViewCell*)cell).bubbleData collapsed:YES];
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnEvent])
        {
            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
            
            if (!bubbleData.collapsed)
            {
                [self handleLongPressFromCell:cell withTappedEvent:tappedEvent];
            }
        }
        else if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellLongPressOnReactionView])
        {
            NSString *tappedEventId = userInfo[kMXKRoomBubbleCellEventIdKey];
            if (tappedEventId)
            {
                [self showReactionHistoryForEventId:tappedEventId animated:YES];
            }
        }
        else
        {
            // Keep default implementation for other actions
            [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
        }
    }
    else
    {
        // Keep default implementation for other actions
        [super dataSource:dataSource didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

// Display the additiontal event actions menu
- (void)showAdditionalActionsMenuForEvent:(MXEvent*)selectedEvent inCell:(id<MXKCellRendering>)cell animated:(BOOL)animated
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    __weak __typeof(self) weakSelf = self;
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Add actions for a failed event
    if (selectedEvent.sentState == MXEventSentStateFailed)
    {
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_resend", @"Vector", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               // Let the datasource resend. It will manage local echo, etc.
                                                               [self.roomDataSource resendEventWithEventId:selectedEvent.eventId success:nil failure:nil];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_delete", @"Vector", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                           }
                                                           
                                                       }]];
    }
    
    // Add actions for text message
    if (!attachment)
    {
        // Retrieved data related to the selected event
        NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
        MXKRoomBubbleComponent *selectedComponent;
        for (selectedComponent in components)
        {
            if ([selectedComponent.event.eventId isEqualToString:selectedEvent.eventId])
            {
                break;
            }
            selectedComponent = nil;
        }
        

        // Check status of the selected event
        if (selectedEvent.sentState == MXEventSentStatePreparing ||
            selectedEvent.sentState == MXEventSentStateEncrypting ||
            selectedEvent.sentState == MXEventSentStateSending)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_send", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action)
                                     {
                                         if (weakSelf)
                                         {
                                             typeof(self) self = weakSelf;
                                             
                                             self->currentAlert = nil;
                                             
                                             // Cancel and remove the outgoing message
                                             [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                                             [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                             
                                             [self cancelEventSelection];
                                         }
                                         
                                     }]];
        }

        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_quote", @"Vector", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               // Quote the message a la Markdown into the input toolbar composer
                                                               self.inputToolbarView.textMessage = [NSString stringWithFormat:@"%@\n>%@\n\n", self.inputToolbarView.textMessage, selectedComponent.textMessage];
                                                               
                                                               // And display the keyboard
                                                               [self.inputToolbarView becomeFirstResponder];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_forward", @"Tchap", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                [self.delegate roomViewController:self forwardContent:selectedEvent.content];
            }
            
        }]];

        if (BuildSettings.messageDetailsAllowShare)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self cancelEventSelection];
                    
                    NSArray *activityItems = @[selectedComponent.textMessage];
                    
                    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];

                    if (activityViewController)
                    {
                        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                        activityViewController.popoverPresentationController.sourceView = roomBubbleTableViewCell;
                        activityViewController.popoverPresentationController.sourceRect = roomBubbleTableViewCell.bounds;

                        [self presentViewController:activityViewController animated:YES completion:nil];
                    }
                }
                
            }]];
        }
    }
    else // Add action for attachment
    {
        if (BuildSettings.messageDetailsAllowSave)
        {
            if (attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeVideo)
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_save", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        [self cancelEventSelection];
                        
                        [self startActivityIndicator];
                        
                        [attachment save:^{
                            
                            __strong __typeof(weakSelf)self = weakSelf;
                            [self stopActivityIndicator];
                            
                        } failure:^(NSError *error) {
                            
                            __strong __typeof(weakSelf)self = weakSelf;
                            [self stopActivityIndicator];
                            
                            //Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                            
                        }];
                        
                        // Start animation in case of download during attachment preparing
                        [roomBubbleTableViewCell startProgressUI];
                    }
                    
                }]];
            }
        }
            
        // Check status of the selected event
        if (selectedEvent.sentState == MXEventSentStatePreparing ||
            selectedEvent.sentState == MXEventSentStateEncrypting ||
            selectedEvent.sentState == MXEventSentStateUploading ||
            selectedEvent.sentState == MXEventSentStateSending)
        {
            // Upload id is stored in attachment url (nasty trick)
            NSString *uploadId = roomBubbleTableViewCell.bubbleData.attachment.contentURL;
            if ([MXMediaManager existingUploaderWithId:uploadId])
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_send", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   // Get again the loader
                                                                   MXMediaLoader *loader = [MXMediaManager existingUploaderWithId:uploadId];
                                                                   if (loader)
                                                                   {
                                                                       [loader cancel];
                                                                   }
                                                                   // Hide the progress animation
                                                                   roomBubbleTableViewCell.progressView.hidden = YES;
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Remove the outgoing message and its related cached file.
                                                                       [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.cacheFilePath error:nil];
                                                                       [[NSFileManager defaultManager] removeItemAtPath:roomBubbleTableViewCell.bubbleData.attachment.thumbnailCachePath error:nil];
                                                                       
                                                                       // Cancel and remove the outgoing message
                                                                       [self.roomDataSource.room cancelSendingOperation:selectedEvent.eventId];
                                                                       [self.roomDataSource removeEventWithEventId:selectedEvent.eventId];
                                                                       
                                                                       [self cancelEventSelection];
                                                                   }
                                                                   
                                                               }]];
            }
        }

        if (attachment.type != MXKAttachmentTypeSticker)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_forward", @"Tchap", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    [self.delegate roomViewController:self forwardContent:selectedEvent.content];
                }
                
            }]];
            
            if (BuildSettings.messageDetailsAllowShare)
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_share", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        [self cancelEventSelection];
                        
                        [attachment prepareShare:^(NSURL *fileURL) {
                            
                            __strong __typeof(weakSelf)self = weakSelf;
                            self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                            [self->documentInteractionController setDelegate:self];
                            self->currentSharedAttachment = attachment;
                            
                            if (![self->documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES])
                            {
                                self->documentInteractionController = nil;
                                [attachment onShareEnded];
                                self->currentSharedAttachment = nil;
                            }
                            
                        } failure:^(NSError *error) {
                            
                            //Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                            
                        }];
                        
                        // Start animation in case of download during attachment preparing
                        [roomBubbleTableViewCell startProgressUI];
                    }
                    
                }]];
            }
        }
    }
    
    // Check status of the selected event
    if (selectedEvent.sentState == MXEventSentStateSent)
    {
        // Check whether download is in progress
        if (selectedEvent.isMediaAttachment)
        {
            NSString *downloadId = roomBubbleTableViewCell.bubbleData.attachment.downloadId;
            if ([MXMediaManager existingDownloaderWithIdentifier:downloadId])
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_cancel_download", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       // Get again the loader
                                                                       MXMediaLoader *loader = [MXMediaManager existingDownloaderWithIdentifier:downloadId];
                                                                       if (loader)
                                                                       {
                                                                           [loader cancel];
                                                                       }
                                                                       // Hide the progress animation
                                                                       roomBubbleTableViewCell.progressView.hidden = YES;
                                                                   }
                                                                   
                                                               }]];
            }
        }
        
#ifdef ENABLE_EDITION
        // Do not allow to redact the event that enabled encryption (m.room.encryption)
        // because it breaks everything
        // Tchap: Do not allow to redact the state events
        if (!selectedEvent.isState) //(selectedEvent.eventType != MXEventTypeRoomEncryption)
        {
            // Check whether the user has the power to redact this event
            MXRoomPowerLevels *powerLevels = self.roomDataSource.roomState.powerLevels;
            NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
            if (userPowerLevel >= powerLevels.redact || [selectedEvent.sender isEqualToString:self.mainSession.myUser.userId])
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_redact", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       
                                                                       [self cancelEventSelection];
                                                                       
                                                                       [self startActivityIndicator];
                                                                       
                                                                       [self.roomDataSource.room redactEvent:selectedEvent.eventId reason:nil success:^{
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           __strong __typeof(weakSelf)self = weakSelf;
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           NSLog(@"[RoomVC] Redact event (%@) failed", selectedEvent.eventId);
                                                                           //Alert user
                                                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                           
                                                                       }];
                                                                   }
                                                                   
                                                               }]];
            }
        }
#endif
        
        if (!selectedEvent.isState)
        {
            NSString *titleKey;
            if (![self.roomDataSource.room.accountData getTaggedEventInfo:selectedEvent.eventId withTag:kMXRoomTagFavourite])
            {
                titleKey = @"room_event_action_add_favourite";
            }
            else
            {
                titleKey = @"room_event_action_remove_favourite";
            }
            [currentAlert addAction:[UIAlertAction actionWithTitle: NSLocalizedStringFromTable(titleKey, @"Tchap", nil)
              style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self cancelEventSelection];
                    
                    [self startActivityIndicator];
                    
                    MXWeakify(self);
                    if ([titleKey isEqualToString:@"room_event_action_add_favourite"])
                    {
                        [self.roomDataSource.room tagEvent:selectedEvent withTag:kMXTaggedEventFavourite andKeywords:nil success:^{
                            MXStrongifyAndReturnIfNil(self);
                            [self stopActivityIndicator];
                        } failure:^(NSError *error) {
                            MXStrongifyAndReturnIfNil(self);
                            [self stopActivityIndicator];
                            
                            NSLog(@"[RoomVC] Tag event (%@) failed", selectedEvent.eventId);
                            //Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                        }];
                    }
                    else
                    {
                        [self.roomDataSource.room untagEvent:selectedEvent withTag:kMXTaggedEventFavourite success:^{
                            MXStrongifyAndReturnIfNil(self);
                            [self stopActivityIndicator];
                        } failure:^(NSError *error) {
                            MXStrongifyAndReturnIfNil(self);
                            [self stopActivityIndicator];
                            
                            NSLog(@"[RoomVC] Tag event (%@) failed", selectedEvent.eventId);
                            //Alert user
                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                        }];
                    }
                }
            }]];
        }
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_permalink", @"Vector", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               // Create a Tchap permalink
                                                               NSString *permalink = [Tools permalinkToEvent:selectedEvent.eventId inRoom:selectedEvent.roomId];
                                                               if (permalink)
                                                               {
                                                                   [[UIPasteboard generalPasteboard] setString:permalink];
                                                               }
                                                               else
                                                               {
                                                                   NSLog(@"[RoomViewController] Contextual menu permalink action failed. Permalink is nil room id/event id: %@/%@", selectedEvent.roomId, selectedEvent.eventId);
                                                               }
                                                               
                                                           }
                                                           
                                                       }]];
        
        // Add reaction history if event contains reactions
        if (roomBubbleTableViewCell.bubbleData.reactions[selectedEvent.eventId].aggregatedReactionsWithNonZeroCount)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_reaction_history", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               [self cancelEventSelection];
                                                               
                                                               // Show reaction history
                                                               [self showReactionHistoryForEventId:selectedEvent.eventId animated:YES];
                                                           }]];
        }
        
        if (BuildSettings.messageDetailsAllowViewSource)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_source", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self cancelEventSelection];
                    
                    // Display event details
                    [self showEventDetails:selectedEvent];
                }
                
            }]];
        

            // Add "View Decrypted Source" for e2ee event we can decrypt
            if (selectedEvent.isEncrypted && selectedEvent.clearEvent)
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_view_decrypted_source", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        [self cancelEventSelection];
                        
                        // Display clear event details
                        [self showEventDetails:selectedEvent.clearEvent];
                    }
                    
                }]];
            }
        }
        
        if (![selectedEvent.sender isEqualToString:self.mainSession.myUser.userId])
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_event_action_report", @"Vector", nil)
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self cancelEventSelection];
                    
                    // Prompt user to enter a description of the problem content.
                    self->currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_report_prompt_reason", @"Vector", nil)  message:nil preferredStyle:UIAlertControllerStyleAlert];
                    
                    [self->currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                        textField.secureTextEntry = NO;
                        textField.placeholder = nil;
                        textField.keyboardType = UIKeyboardTypeDefault;
                    }];
                    
                    [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            NSString *text = [self->currentAlert textFields].firstObject.text;
                            self->currentAlert = nil;
                            
                            [self startActivityIndicator];
                            
                            [self.roomDataSource.room reportEvent:selectedEvent.eventId score:-100 reason:text success:^{
                                
                                __strong __typeof(weakSelf)self = weakSelf;
                                [self stopActivityIndicator];
                                
                                // Prompt user to ignore content from this user
                                self->currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_action_report_prompt_ignore_user", @"Vector", nil)  message:nil preferredStyle:UIAlertControllerStyleAlert];
                                
                                [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                    
                                    if (weakSelf)
                                    {
                                        typeof(self) self = weakSelf;
                                        self->currentAlert = nil;
                                        
                                        [self startActivityIndicator];
                                        
                                        // Add the user to the blacklist: ignored users
                                        [self.mainSession ignoreUsers:@[selectedEvent.sender] success:^{
                                            
                                            __strong __typeof(weakSelf)self = weakSelf;
                                            [self stopActivityIndicator];
                                            
                                        } failure:^(NSError *error) {
                                            
                                            __strong __typeof(weakSelf)self = weakSelf;
                                            [self stopActivityIndicator];
                                            
                                            NSLog(@"[RoomVC] Ignore user (%@) failed", selectedEvent.sender);
                                            //Alert user
                                            [[AppDelegate theDelegate] showErrorAsAlert:error];
                                            
                                        }];
                                    }
                                    
                                }]];
                                
                                [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                    
                                    if (weakSelf)
                                    {
                                        typeof(self) self = weakSelf;
                                        self->currentAlert = nil;
                                    }
                                    
                                }]];
                                
                                [self presentViewController:self->currentAlert animated:YES completion:nil];
                                
                            } failure:^(NSError *error) {
                                
                                __strong __typeof(weakSelf)self = weakSelf;
                                [self stopActivityIndicator];
                                
                                NSLog(@"[RoomVC] Report event (%@) failed", selectedEvent.eventId);
                                //Alert user
                                [[AppDelegate theDelegate] showErrorAsAlert:error];
                                
                            }];
                        }
                        
                    }]];
                    
                    [self->currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                        
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            self->currentAlert = nil;
                        }
                        
                    }]];
                    
                    [self presentViewController:self->currentAlert animated:YES completion:nil];
                }
                
            }]];

        }
    }
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           [self hideContextualMenuAnimated:YES];
                                                       }
                                                       
                                                   }]];
    
    // Do not display empty action sheet
    if (currentAlert.actions.count > 1)
    {
        NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:selectedEvent.eventId];
        
        CGRect sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCEventMenuAlert"];
        [currentAlert popoverPresentationController].sourceView = roomBubbleTableViewCell;
        [currentAlert popoverPresentationController].sourceRect = sourceRect;
        [self presentViewController:currentAlert animated:animated completion:nil];
    }
    else
    {
        currentAlert = nil;
    }
}

- (BOOL)dataSource:(MXKDataSource *)dataSource shouldDoAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue
{
    BOOL shouldDoAction = defaultValue;
    
    if ([actionIdentifier isEqualToString:kMXKRoomBubbleCellShouldInteractWithURL])
    {
        // Try to catch universal link supported by the app
        NSURL *url = userInfo[kMXKRoomBubbleCellUrl];
        // Retrieve the type of interaction expected with the URL (See UITextItemInteraction)
        NSNumber *urlItemInteractionValue = userInfo[kMXKRoomBubbleCellUrlItemInteraction];
        
        RoomMessageURLType roomMessageURLType = RoomMessageURLTypeUnknown;
        
        if (url)
        {
            roomMessageURLType = [self.roomMessageURLParser parseURL:url];
        }
        
        // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
        // to be able to convert it into a legal URL string.
        NSString *absoluteURLString = [url.absoluteString stringByRemovingPercentEncoding];
        
        // Check whether this is a permalink to handle it directly into the app
        if ([Tools isPermaLink:url])
        {
            // Patch: catch up all the permalinks even if they are not all supported by Tchap for the moment,
            // like the permalinks with a userid.
            shouldDoAction = NO;
            
            // iOS Patch: fix urls before using it
            NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:url];
            // In some cases (for example when the url has multiple '#'), the '%' character has been espaced twice in the provided url (we got %2524 for '$').
            // We decided to remove percent encoding on all the fragment here. A second attempt will take place during the parameters parsing.
            NSString *fragment = [fixedURL.fragment stringByRemovingPercentEncoding];
            if (fragment && self.delegate)
            {
                [self.delegate roomViewController:self handlePermalinkFragment:fragment];
            }
        }
        // Open a detail screen about the clicked user
        else if ([MXTools isMatrixUserIdentifier:absoluteURLString])
        {
            // We display details only for the room members
            NSString *userId = absoluteURLString;
            MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:userId];
            if (member && self.delegate)
            {
                shouldDoAction = NO;
                [self.delegate roomViewController:self showMemberDetails:member];
            }
        }
        // Open the clicked room
        else if ([MXTools isMatrixRoomIdentifier:absoluteURLString] || [MXTools isMatrixRoomAlias:absoluteURLString])
        {
            // Note: Presently we may fail to display correctly the rooms which are not joined by the user
            // TODO: Support all roomId and alias to preview the room when the user doesn't join the room...
            NSString *roomId = absoluteURLString;
            if ([MXTools isMatrixRoomAlias:absoluteURLString])
            {
                // Translate the alias into the room id
                // We don't support for the moment the alias of the rooms which are not joined
                MXRoom *room = [self.mainSession roomWithAlias:absoluteURLString];
                if (room)
                {
                    roomId = room.roomId;
                }
            }
            
            if (roomId && self.delegate)
            {
                shouldDoAction = NO;
                [self.delegate roomViewController:self showRoom:roomId];
            }
        }
//        // Preview the clicked group
//        else if ([MXTools isMatrixGroupIdentifier:absoluteURLString])
//        {
//            shouldDoAction = NO;
//
//            // Open the group or preview it
//            NSString *fragment = [NSString stringWithFormat:@"/group/%@", [absoluteURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//            [[AppDelegate theDelegate] handleUniversalLinkFragment:fragment];
//        }
        // ReRequest keys
        else if ([absoluteURLString hasPrefix:EventFormatterOnReRequestKeysLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:EventFormatterLinkActionSeparator];
            if (arguments.count > 1)
            {
                NSString *eventId = arguments[1];
                MXEvent *event = [self.roomDataSource eventWithEventId:eventId];

                if (event)
                {
                    [self reRequestKeysAndShowExplanationAlert:event];
                }
            }
            shouldDoAction = NO;
        }
        else if ([absoluteURLString hasPrefix:EventFormatterEditedEventLinkAction])
        {
            NSArray<NSString*> *arguments = [absoluteURLString componentsSeparatedByString:EventFormatterLinkActionSeparator];
            if (arguments.count > 1)
            {
                NSString *eventId = arguments[1];
                [self showEditHistoryForEventId:eventId animated:YES];
            }
            shouldDoAction = NO;
        }
        else if (url && urlItemInteractionValue)
        {
            // Fallback case for external links
            switch (urlItemInteractionValue.integerValue) {
                case UITextItemInteractionInvokeDefaultAction:
                {
                    switch (roomMessageURLType) {
                        case RoomMessageURLTypeAppleDataDetector:
                            // Keep the default OS behavior on single tap when UITextView data detector detect a known type.
                            shouldDoAction = YES;
                            break;
                        case RoomMessageURLTypeDummy:
                            // Do nothing for dummy links
                            shouldDoAction = NO;
                            break;
                        default:
                        {
                            MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
                            NSString *format = tappedEvent.content[@"format"];
                            NSString *formattedBody = tappedEvent.content[@"formatted_body"];
                            //  if an html formatted body exists
                            if ([format isEqualToString:kMXRoomMessageFormatHTML] && formattedBody)
                            {
                                NSURL *visibleURL = [formattedBodyParser getVisibleURLForURL:url inFormattedBody:formattedBody];
                                
                                if (visibleURL && ![url isEqual:visibleURL])
                                {
                                    //  urls are different, show confirmation alert
                                    NSString *formatStr = NSLocalizedStringFromTable(@"external_link_confirmation_message", @"Vector", nil);
                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"external_link_confirmation_title", @"Vector", nil) message:[NSString stringWithFormat:formatStr, visibleURL.absoluteString, url.absoluteString] preferredStyle:UIAlertControllerStyleAlert];
                                    
                                    UIAlertAction *continueAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"continue", @"Vector", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                        // Try to open the link
                                        [[UIApplication sharedApplication] vc_open:url completionHandler:^(BOOL success) {
                                            if (!success)
                                            {
                                                [self showUnableToOpenLinkErrorAlert];
                                            }
                                        }];
                                    }];
                                    
                                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:UIAlertActionStyleCancel handler:nil];
                                    
                                    [alert addAction:continueAction];
                                    [alert addAction:cancelAction];
                                    
                                    [self presentViewController:alert animated:YES completion:nil];
                                    return NO;
                                }
                            }
                            // Try to open the link
                            [[UIApplication sharedApplication] vc_open:url completionHandler:^(BOOL success) {
                                if (!success)
                                {
                                    [self showUnableToOpenLinkErrorAlert];
                                }
                            }];
                            shouldDoAction = NO;
                            break;
                        }
                    }                                        
                }
                    break;
                case UITextItemInteractionPresentActions:
                {
                    // Retrieve the tapped event
                    MXEvent *tappedEvent = userInfo[kMXKRoomBubbleCellEventKey];
                    
                    if (tappedEvent)
                    {
                        // Long press on link, present room contextual menu.
                        [self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:NO cell:cell animated:YES];
                    }
                    
                    shouldDoAction = NO;
                }
                    break;
                case UITextItemInteractionPreview:
                    // Force touch on link, let MXKRoomBubbleTableViewCell UITextView use default peek and pop behavior.
                    break;
                default:
                    break;
            }
        }
        else
        {
            [self showUnableToOpenLinkErrorAlert];
        }
    }
    
    return shouldDoAction;
}

- (void)selectEventWithId:(NSString*)eventId
{
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeSend showTimestamp:YES];
}

- (void)selectEventWithId:(NSString*)eventId inputToolBarSendMode:(RoomInputToolbarViewSendMode)inputToolBarSendMode showTimestamp:(BOOL)showTimestamp
{
    [self setInputToolBarSendMode:inputToolBarSendMode];
    
    customizedRoomDataSource.showBubbleDateTimeOnSelection = showTimestamp;
    customizedRoomDataSource.selectedEventId = eventId;
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)cancelEventSelection
{
    [self setInputToolBarSendMode:RoomInputToolbarViewSendModeSend];
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    customizedRoomDataSource.showBubbleDateTimeOnSelection = YES;
    customizedRoomDataSource.selectedEventId = nil;
    
    [self restoreTextMessageBeforeEditing];
    
    // Force table refresh
    [self dataSource:self.roomDataSource didCellChange:nil];
}

- (void)showUnableToOpenLinkErrorAlert
{
    [[AppDelegate theDelegate] showAlertWithTitle:[NSBundle mxk_localizedStringForKey:@"error"]
                                          message:NSLocalizedStringFromTable(@"room_message_unable_open_link_error_message", @"Vector", nil)];
}

- (void)editEventContentWithId:(NSString*)eventId
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (roomInputToolbarView)
    {
        self.textMessageBeforeEditing = roomInputToolbarView.textMessage;
        roomInputToolbarView.textMessage = [self.roomDataSource editableTextMessageForEvent:event];
    }
    
    [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeEdit showTimestamp:YES];
}

- (void)restoreTextMessageBeforeEditing
{
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    
    if (self.textMessageBeforeEditing)
    {
        roomInputToolbarView.textMessage = self.textMessageBeforeEditing;
    }
    
    self.textMessageBeforeEditing = nil;
}

- (RoomInputToolbarView*)inputToolbarViewAsRoomInputToolbarView
{
    RoomInputToolbarView *roomInputToolbarView;
    
    if (self.inputToolbarView && [self.inputToolbarView isKindOfClass:[RoomInputToolbarView class]])
    {
        roomInputToolbarView = (RoomInputToolbarView*)self.inputToolbarView;
    }
    
    return roomInputToolbarView;
}


#pragma mark - RoomDataSourceDelegate

- (void)roomDataSource:(RoomDataSource *)roomDataSource didUpdateEncryptionTrustLevel:(RoomEncryptionTrustLevel)roomEncryptionTrustLevel
{
    [self updateInputToolbarEncryptionDecoration];
}

#pragma mark - RoomInputToolbarViewDelegate

- (void)roomInputToolbarViewPresentStickerPicker:(MXKRoomInputToolbarView*)toolbarView
{
    // Search for the sticker picker widget in the user account
    Widget *widget = [[WidgetManager sharedManager] userWidgets:self.roomDataSource.mxSession ofTypes:@[kWidgetTypeStickerPicker]].firstObject;

    if (widget)
    {
        // Display the widget
        [widget widgetUrl:^(NSString * _Nonnull widgetUrl) {

            StickerPickerViewController *stickerPickerVC = [[StickerPickerViewController alloc] initWithUrl:widgetUrl forWidget:widget];

            stickerPickerVC.roomDataSource = self.roomDataSource;

            [self.navigationController pushViewController:stickerPickerVC animated:YES];
        } failure:^(NSError * _Nonnull error) {

            NSLog(@"[RoomVC] Cannot display widget %@", widget);
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
    else
    {
        // The Sticker picker widget is not installed yet. Propose the user to install it
        __weak typeof(self) weakSelf = self;

        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        NSString *alertMessage = [NSString stringWithFormat:@"%@\n%@",
                                  NSLocalizedStringFromTable(@"widget_sticker_picker_no_stickerpacks_alert", @"Vector", nil),
                                  NSLocalizedStringFromTable(@"widget_sticker_picker_no_stickerpacks_alert_add_now", @"Vector", nil)
                                  ];

        currentAlert = [UIAlertController alertControllerWithTitle:nil message:alertMessage preferredStyle:UIAlertControllerStyleAlert];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action)
        {
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
            }

        }]];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
        {
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;

                // Show the sticker picker settings screen
                IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc]
                                                               initForMXSession:self.roomDataSource.mxSession
                                                               inRoom:self.roomDataSource.roomId
                                                               screen:[IntegrationManagerViewController screenForWidget:kWidgetTypeStickerPicker]
                                                               widgetId:nil];

                [self presentViewController:modularVC animated:NO completion:nil];
            }
        }]];

        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCStickerPickerAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }
}

#pragma mark - MXKRoomInputToolbarViewDelegate

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView isTyping:(BOOL)typing
{
    [super roomInputToolbarView:toolbarView isTyping:typing];

    // Cancel potential selected event (to leave edition mode)
    NSString *selectedEventId = customizedRoomDataSource.selectedEventId;
    if (typing && selectedEventId && ![self.roomDataSource canReplyToEventWithId:selectedEventId])
    {
        [self cancelEventSelection];
    }
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo:(BOOL)video
{
    __weak __typeof(self) weakSelf = self;

    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];

    // Check app permissions first
    [MXKTools checkAccessForCall:video
     manualChangeMessageForAudio:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"microphone_access_not_granted_for_call"], appDisplayName]
     manualChangeMessageForVideo:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"camera_access_not_granted_for_call"], appDisplayName]
       showPopUpInViewController:self completionHandler:^(BOOL granted) {

           if (weakSelf)
           {
               typeof(self) self = weakSelf;

               if (granted)
               {
                   [self roomInputToolbarView:toolbarView placeCallWithVideo2:video];
               }
               else
               {
                   NSLog(@"RoomViewController: Warning: The application does not have the perssion to place the call");
               }
           }
       }];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView placeCallWithVideo2:(BOOL)video
{
     __weak __typeof(self) weakSelf = self;

    // If there is already a jitsi widget, join it
    Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];
    if (jitsiWidget)
    {
        [[AppDelegate theDelegate] displayJitsiViewControllerWithWidget:jitsiWidget andVideo:video];
    }

    // If enabled, create the conf using jitsi widget and open it directly
    else if (RiotSettings.shared.createConferenceCallsWithJitsi
             && self.roomDataSource.room.summary.membersCount.joined > 2)
    {
        [self startActivityIndicator];

        [[WidgetManager sharedManager] createJitsiWidgetInRoom:self.roomDataSource.room
                                                     withVideo:video
                                                       success:^(Widget *jitsiWidget)
         {
             if (weakSelf)
             {
                 typeof(self) self = weakSelf;
                 [self stopActivityIndicator];

                 [[AppDelegate theDelegate] displayJitsiViewControllerWithWidget:jitsiWidget andVideo:video];
             }
         }
                                                       failure:^(NSError *error)
         {
             if (weakSelf)
             {
                 typeof(self) self = weakSelf;
                 [self stopActivityIndicator];

                 [self showJitsiErrorAsAlert:error];
             }
         }];
    }
    // Classic conference call is not supported in encrypted rooms
    else if (self.roomDataSource.room.summary.isEncrypted && self.roomDataSource.room.summary.membersCount.joined > 2)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"room_no_conference_call_in_encrypted_rooms"]  message:nil preferredStyle:UIAlertControllerStyleAlert];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
                                     if (weakSelf)
                                     {
                                         typeof(self) self = weakSelf;
                                         self->currentAlert = nil;
                                     }

                                 }]];

        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCCallAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }

    // In case of conference call, check that the user has enough power level
    else if (self.roomDataSource.room.summary.membersCount.joined > 2 &&
             ![MXCallManager canPlaceConferenceCallInRoom:self.roomDataSource.room roomState:self.roomDataSource.roomState])
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];

        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"room_no_power_to_create_conference_call"]  message:nil preferredStyle:UIAlertControllerStyleAlert];

        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
                                 {
                                     if (weakSelf)
                                     {
                                         typeof(self) self = weakSelf;
                                         self->currentAlert = nil;
                                     }
                                 }]];

        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCCallAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }

    // Classic 1:1 or group call can be done
    else
    {
        [self.roomDataSource.room placeCallWithVideo:video success:nil failure:nil];
    }
}

- (void)roomInputToolbarViewHangupCall:(MXKRoomInputToolbarView *)toolbarView
{
    MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
    if (callInRoom)
    {
        [callInRoom hangup];
    }
    else if ([[AppDelegate theDelegate].jitsiViewController.widget.roomId isEqualToString:self.roomDataSource.roomId])
    {
        [[AppDelegate theDelegate].jitsiViewController hangup];
    }

    [self refreshActivitiesViewDisplay];
    [self refreshRoomInputToolbar];
}

- (void)roomInputToolbarView:(MXKRoomInputToolbarView*)toolbarView heightDidChanged:(CGFloat)height completion:(void (^)(BOOL finished))completion
{
    if (self.roomInputToolbarContainerHeightConstraint.constant != height)
    {
        // Hide temporarily the placeholder to prevent its distorsion during height animation
        if (!savedInputToolbarPlaceholder)
        {
            savedInputToolbarPlaceholder = toolbarView.placeholder.length ? toolbarView.placeholder : @"";
        }
        toolbarView.placeholder = nil;
        
        [super roomInputToolbarView:toolbarView heightDidChanged:height completion:^(BOOL finished) {
            
            if (completion)
            {
                completion (finished);
            }
            
            // Consider here the saved placeholder only if no new placeholder has been defined during the height animation.
            if (!toolbarView.placeholder)
            {
                // Restore the placeholder if any
                toolbarView.placeholder =  savedInputToolbarPlaceholder.length ? savedInputToolbarPlaceholder : nil;
            }
            savedInputToolbarPlaceholder = nil;
        }];
    }
}

- (void)roomInputToolbarViewDidTapFileUpload:(MXKRoomInputToolbarView *)toolbarView
{
    MXKDocumentPickerPresenter *documentPickerPresenter = [MXKDocumentPickerPresenter new];
    documentPickerPresenter.delegate = self;
                                      
    NSArray<MXKUTI*> *allowedUTIs = @[MXKUTI.data];
    [documentPickerPresenter presentDocumentPickerWith:allowedUTIs from:self animated:YES completion:nil];
    
    self.documentPickerPresenter = documentPickerPresenter;
}

- (void)roomInputToolbarViewDidTapCamera:(MXKRoomInputToolbarView*)toolbarView
{
    [self showCameraControllerAnimated:YES];
}

- (void)roomInputToolbarViewDidTapMediaLibrary:(MXKRoomInputToolbarView*)toolbarView
{
    [self showMediaPickerAnimated:YES];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.jumpToLastUnreadButton)
    {
        // Dismiss potential keyboard.
        [self dismissKeyboard];

        // Jump to the last unread event by using a temporary room data source initialized with the last unread event id.
        MXWeakify(self);
        [RoomDataSource loadRoomDataSourceWithRoomId:self.roomDataSource.roomId initialEventId:self.roomDataSource.room.accountData.readMarkerEventId andMatrixSession:self.mainSession onComplete:^(id roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            [roomDataSource finalizeInitialization];

            // Center the bubbles table content on the bottom of the read marker event in order to display correctly the read marker view.
            self.centerBubblesTableViewContentOnTheInitialEventBottom = YES;
            [self displayRoom:roomDataSource];

            // Give the data source ownership to the room view controller.
            self.hasRoomDataSourceOwnership = YES;
        }];
    }
    else if (sender == self.resetReadMarkerButton)
    {
        // Move the read marker to the current read receipt position.
        [self.roomDataSource.room forgetReadMarker];
        
        // Hide the banner
        self.jumpToLastUnreadBannerContainer.hidden = YES;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = self.currentStyle.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        if (roomBubbleTableViewCell.readMarkerView)
        {
            readMarkerTableViewCell = roomBubbleTableViewCell;
            
            [self checkReadMarkerVisibility];
        }
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (cell == readMarkerTableViewCell)
    {
        readMarkerTableViewCell = nil;
    }
    
    [super tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    [self checkReadMarkerVisibility];
    
    // Switch back to the live mode when the user scrolls to the bottom of the non live timeline.
    if (!self.roomDataSource.isLive && ![self isRoomPreview])
    {
        CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.mxk_adjustedContentInset.bottom;
        if (contentBottomPosY >= self.bubblesTableView.contentSize.height && ![self.roomDataSource.timeline canPaginate:MXTimelineDirectionForwards])
        {
            [self goBackToLive];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    
    if (decelerate == NO)
    {
        [self refreshActivitiesViewDisplay];
        [self refreshJumpToLastUnreadBannerDisplay];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndDecelerating:)])
    {
        [super scrollViewDidEndDecelerating:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if ([MXKRoomViewController instancesRespondToSelector:@selector(scrollViewDidEndScrollingAnimation:)])
    {
        [super scrollViewDidEndScrollingAnimation:scrollView];
    }
    
    [self refreshActivitiesViewDisplay];
    [self refreshJumpToLastUnreadBannerDisplay];
}

#pragma mark - RoomTitleViewDelegate

- (void)roomTitleViewDidTapped:(RoomTitleView *)roomTitleView
{
    if (self.delegate)
    {
        // Open room settings
        [self.delegate roomViewControllerShowRoomDetails:self];
    }
}

#pragma mark - Typing management

- (void)removeTypingNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (typingNotifListener)
        {
            MXWeakify(self);
            [self.roomDataSource.room liveTimeline:^(MXEventTimeline *liveTimeline) {
                MXStrongifyAndReturnIfNil(self);

                [liveTimeline removeListener:self->typingNotifListener];
                self->typingNotifListener = nil;
            }];
        }
    }
    
    currentTypingUsers = nil;
}

- (void)listenTypingNotifications
{
    if (self.roomDataSource)
    {
        // Add typing notification listener
        MXWeakify(self);
        self->typingNotifListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            // Handle only live events
            if (direction == MXTimelineDirectionForwards)
            {
                // Retrieve typing users list
                NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
                // Remove typing info for the current user
                NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
                if (index != NSNotFound)
                {
                    [typingUsers removeObjectAtIndex:index];
                }

                // Ignore this notification if both arrays are empty
                if (self->currentTypingUsers.count || typingUsers.count)
                {
                    self->currentTypingUsers = typingUsers;
                    [self refreshActivitiesViewDisplay];
                }
            }
        }];

        // Retrieve the current typing users list
        NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.roomDataSource.room.typingUsers];
        // Remove typing info for the current user
        NSUInteger index = [typingUsers indexOfObject:self.mainSession.myUser.userId];
        if (index != NSNotFound)
        {
            [typingUsers removeObjectAtIndex:index];
        }
        currentTypingUsers = typingUsers;
        [self refreshActivitiesViewDisplay];
    }
}

- (void)refreshTypingNotification
{
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        // Prepare here typing notification
        NSString* text = nil;
        NSUInteger count = currentTypingUsers.count;
        
        // get the room member names
        NSMutableArray *names = [[NSMutableArray alloc] init];
        
        // keeps the only the first two users
        for(int i = 0; i < MIN(count, 2); i++)
        {
            NSString* name = currentTypingUsers[i];
            
            MXRoomMember* member = [self.roomDataSource.roomState.members memberWithUserId:name];
            
            if (member && member.displayname.length)
            {
                name = member.displayname;
            }
            
            // sanity check
            if (name)
            {
                [names addObject:name];
            }
        }
        
        if (0 == names.count)
        {
            // something to do ?
        }
        else if (1 == names.count)
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_one_user_is_typing", @"Vector", nil), names[0]];
        }
        else if (2 == names.count)
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_two_users_are_typing", @"Vector", nil), names[0], names[1]];
        }
        else
        {
            text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_many_users_are_typing", @"Vector", nil), names[0], names[1]];
        }
        
        [((RoomActivitiesView*) self.activitiesView) displayTypingNotification:text];
    }
}

#pragma mark - Call notifications management

- (void)removeCallNotificationsListeners
{
    if (kMXCallStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallStateDidChangeObserver];
        kMXCallStateDidChangeObserver = nil;
    }
    if (kMXCallManagerConferenceStartedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallManagerConferenceStartedObserver];
        kMXCallManagerConferenceStartedObserver = nil;
    }
    if (kMXCallManagerConferenceFinishedObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXCallManagerConferenceFinishedObserver];
        kMXCallManagerConferenceFinishedObserver = nil;
    }
}

- (void)listenCallNotifications
{
    kMXCallStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallStateDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXCall *call = notif.object;
        if ([call.room.roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
    kMXCallManagerConferenceStartedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceStarted object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
        }
    }];
    kMXCallManagerConferenceFinishedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXCallManagerConferenceFinished object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSString *roomId = notif.object;
        if ([roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
        }
    }];
}


#pragma mark - Server notices management

- (void)removeServerNoticesListener
{
    if (serverNotices)
    {
        [serverNotices close];
        serverNotices = nil;
    }
}

- (void)listenToServerNotices
{
    if (!serverNotices)
    {
        serverNotices = [[MXServerNotices alloc] initWithMatrixSession:self.roomDataSource.mxSession];
        serverNotices.delegate = self;
    }
}

- (void)serverNoticesDidChangeState:(MXServerNotices *)serverNotices
{
    [self refreshActivitiesViewDisplay];
}

#pragma mark - Widget notifications management

- (void)removeWidgetNotificationsListeners
{
    if (kMXKWidgetManagerDidUpdateWidgetObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXKWidgetManagerDidUpdateWidgetObserver];
        kMXKWidgetManagerDidUpdateWidgetObserver = nil;
    }
}

- (void)listenWidgetNotifications
{
    kMXKWidgetManagerDidUpdateWidgetObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kWidgetManagerDidUpdateWidgetNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        Widget *widget = notif.object;
        if (widget.mxSession == self.roomDataSource.mxSession
            && [widget.roomId isEqualToString:customizedRoomDataSource.roomId])
        {
            // Jitsi conference widget existence is shown in the bottom bar
            // Update the bar
            [self refreshActivitiesViewDisplay];
            [self refreshRoomInputToolbar];
            [self refreshRoomTitle];
        }
    }];
}

- (void)showJitsiErrorAsAlert:(NSError*)error
{
    // Customise the error for permission issues
    if ([error.domain isEqualToString:WidgetManagerErrorDomain] && error.code == WidgetManagerErrorCodeNotEnoughPower)
    {
        error = [NSError errorWithDomain:error.domain
                                    code:error.code
                                userInfo:@{
                                           NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"room_conference_call_no_power", @"Vector", nil)
                                           }];
    }

    // Alert user
    [[AppDelegate theDelegate] showErrorAsAlert:error];
}

- (NSUInteger)widgetsCount:(BOOL)includeUserWidgets
{
    NSUInteger widgetsCount = [[WidgetManager sharedManager] widgetsNotOfTypes:@[kWidgetTypeJitsiV1, kWidgetTypeJitsiV2]
                                                                        inRoom:self.roomDataSource.room
                                                                 withRoomState:self.roomDataSource.roomState].count;
    if (includeUserWidgets)
    {
        widgetsCount += [[WidgetManager sharedManager] userWidgets:self.roomDataSource.room.mxSession].count;
    }

    return widgetsCount;
}

#pragma mark - Unreachable Network Handling

- (void)refreshActivitiesViewDisplay
{
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*)self.activitiesView;

        // Reset gesture recognizers
        while (roomActivitiesView.gestureRecognizers.count)
        {
            [roomActivitiesView removeGestureRecognizer:roomActivitiesView.gestureRecognizers[0]];
        }

        Widget *jitsiWidget = [customizedRoomDataSource jitsiWidget];

        if ([self.roomDataSource.mxSession.syncError.errcode isEqualToString:kMXErrCodeStringResourceLimitExceeded])
        {
            [roomActivitiesView showResourceLimitExceededError:self.roomDataSource.mxSession.syncError.userInfo onAdminContactTapped:^(NSURL *adminContactURL) {
                [[UIApplication sharedApplication] vc_open:adminContactURL completionHandler:^(BOOL success) {
                   if (!success)
                   {
                        NSLog(@"[RoomVC] refreshActivitiesViewDisplay: adminContact(%@) cannot be opened", adminContactURL);
                   }
                }];
            }];
        }
        else if ([AppDelegate theDelegate].isOffline)
        {
            [roomActivitiesView displayNetworkErrorNotification:NSLocalizedStringFromTable(@"room_offline_notification", @"Vector", nil)];
        }
        else if (customizedRoomDataSource.roomState.isObsolete)
        {
            if (self.delegate)
            {
                MXWeakify(self);
                [roomActivitiesView displayRoomReplacementWithRoomLinkTappedHandler:^{
                    MXStrongifyAndReturnIfNil(self);
                    
                    MXEvent *stoneTombEvent = [self->customizedRoomDataSource.roomState stateEventsWithType:kMXEventTypeStringRoomTombStone].lastObject;
                    
                    NSString *replacementRoomId = self->customizedRoomDataSource.roomState.tombStoneContent.replacementRoomId;
                    if ([self.roomDataSource.mxSession roomWithRoomId:replacementRoomId])
                    {
                        // Open the room if it is already joined
                        [self.delegate roomViewController:self showRoom:replacementRoomId];
                    }
                    else
                    {
                        // Else auto join it via the server that sent the event
                        NSLog(@"[RoomVC] Auto join an upgraded room: %@ -> %@. Sender: %@",                              self->customizedRoomDataSource.roomState.roomId,
                              replacementRoomId, stoneTombEvent.sender);
                        
                        NSString *viaSenderServer = [MXTools serverNameInMatrixIdentifier:stoneTombEvent.sender];
                        
                        if (viaSenderServer)
                        {
                            [self startActivityIndicator];
                            [self.roomDataSource.mxSession joinRoom:replacementRoomId viaServers:@[viaSenderServer] success:^(MXRoom *room) {
                                [self stopActivityIndicator];
                                
                                [self.delegate roomViewController:self showRoom:replacementRoomId];
                                
                            } failure:^(NSError *error) {
                                [self stopActivityIndicator];
                                
                                NSLog(@"[RoomVC] Failed to join an upgraded room. Error: %@",
                                      error);
                                [[AppDelegate theDelegate] showErrorAsAlert:error];
                            }];
                        }
                    }
                }];
            }
        }
        else if (customizedRoomDataSource.roomState.isOngoingConferenceCall)
        {
            // Show the "Ongoing conference call" banner only if the user is not in the conference
            MXCall *callInRoom = [self.roomDataSource.mxSession.callManager callInRoom:self.roomDataSource.roomId];
            if (callInRoom && callInRoom.state != MXCallStateEnded)
            {
                if ([self checkUnsentMessages] == NO)
                {
                    [self refreshTypingNotification];
                }
            }
            else
            {
                [roomActivitiesView displayOngoingConferenceCall:^(BOOL video) {
                    
                    NSLog(@"[RoomVC] onOngoingConferenceCallPressed");
                    
                    // Make sure there is not yet a call
                    if (![customizedRoomDataSource.mxSession.callManager callInRoom:customizedRoomDataSource.roomId])
                    {
                        [customizedRoomDataSource.room placeCallWithVideo:video success:nil failure:nil];
                    }
                } onClosePressed:nil];
            }
        }
        else if (jitsiWidget)
        {
            // The room has an active jitsi widget
            // Show it in the banner if the user is not already in
            LegacyAppDelegate *appDelegate = [AppDelegate theDelegate];
            if ([appDelegate.jitsiViewController.widget.widgetId isEqualToString:jitsiWidget.widgetId])
            {
                if ([self checkUnsentMessages] == NO)
                {
                    [self refreshTypingNotification];
                }
            }
            else
            {
                [roomActivitiesView displayOngoingConferenceCall:^(BOOL video) {

                    NSLog(@"[RoomVC] onOngoingConferenceCallPressed (jitsi)");

                    __weak __typeof(self) weakSelf = self;
                    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];

                    // Check app permissions first
                    [MXKTools checkAccessForCall:video
                     manualChangeMessageForAudio:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"microphone_access_not_granted_for_call"], appDisplayName]
                     manualChangeMessageForVideo:[NSString stringWithFormat:[NSBundle mxk_localizedStringForKey:@"camera_access_not_granted_for_call"], appDisplayName]
                       showPopUpInViewController:self completionHandler:^(BOOL granted) {

                           if (weakSelf)
                           {
                               if (granted)
                               {
                                   // Present the Jitsi view controller
                                   [appDelegate displayJitsiViewControllerWithWidget:jitsiWidget andVideo:video];
                               }
                               else
                               {
                                   NSLog(@"[RoomVC] onOngoingConferenceCallPressed: Warning: The application does not have the perssion to join the call");
                               }
                           }
                       }];

                } onClosePressed:^{

                    [self startActivityIndicator];

                    // Close the widget
                    __weak __typeof(self) weakSelf = self;
                    [[WidgetManager sharedManager] closeWidget:jitsiWidget.widgetId inRoom:self.roomDataSource.room success:^{

                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;
                            [self stopActivityIndicator];

                            // The banner will automatically leave thanks to kWidgetManagerDidUpdateWidgetNotification
                        }

                    } failure:^(NSError *error) {
                        if (weakSelf)
                        {
                            typeof(self) self = weakSelf;

                            [self showJitsiErrorAsAlert:error];
                            [self stopActivityIndicator];
                        }
                    }];
                }];
            }
        }
        else if ([self checkUnsentMessages] == NO)
        {
            // Show "scroll to bottom" icon when the most recent message is not visible,
            // or when the timelime is not live (this icon is used to go back to live).
            // Note: we check if `currentEventIdAtTableBottom` is set to know whether the table has been rendered at least once.
            if (!self.roomDataSource.isLive || (currentEventIdAtTableBottom && [self isBubblesTableScrollViewAtTheBottom] == NO))
            {
                // Retrieve the unread messages count
                NSUInteger unreadCount = self.roomDataSource.room.summary.localUnreadEventCount;
                
                if (unreadCount == 0)
                {
                    // Refresh the typing notification here
                    // We will keep visible this notification (if any) beside the "scroll to bottom" icon.
                    [self refreshTypingNotification];
                }
                
                [roomActivitiesView displayScrollToBottomIcon:unreadCount onIconTapGesture:^{
                    
                    [self goBackToLive];
                    
                }];
            }
            else if (serverNotices.usageLimit && serverNotices.usageLimit.isServerNoticeUsageLimit)
            {
                [roomActivitiesView showResourceUsageLimitNotice:serverNotices.usageLimit onAdminContactTapped:^(NSURL *adminContactURL) {                    
                    [[UIApplication sharedApplication] vc_open:adminContactURL completionHandler:^(BOOL success) {
                       if (!success)
                       {
                            NSLog(@"[RoomVC] refreshActivitiesViewDisplay: adminContact(%@) cannot be opened", adminContactURL);
                       }
                    }];
                }];
            }
            else
            {
                [self refreshTypingNotification];
            }
        }
        
        // Recognize swipe downward to dismiss keyboard if any
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeGesture:)];
        [swipe setNumberOfTouchesRequired:1];
        [swipe setDirection:UISwipeGestureRecognizerDirectionDown];
        [roomActivitiesView addGestureRecognizer:swipe];
    }
}

- (void)goBackToLive
{
    if (!self.roomDataSource)
    {
        return;
    }
    
    if (self.roomDataSource.isLive)
    {
        // Enable the read marker display, and disable its update (in order to not mark as read all the new messages by default).
        self.roomDataSource.showReadMarker = YES;
        self.updateRoomReadMarker = NO;
        
        [self scrollBubblesTableViewToBottomAnimated:YES];
    }
    else
    {
        // Switch back to the room live timeline managed by MXKRoomDataSourceManager
        MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];

        MXWeakify(self);
        [roomDataSourceManager roomDataSourceForRoom:self.roomDataSource.roomId create:YES onComplete:^(MXKRoomDataSource *roomDataSource) {
            MXStrongifyAndReturnIfNil(self);

            // Scroll to bottom the bubble history on the display refresh.
            self->shouldScrollToBottomOnTableRefresh = YES;

            [self displayRoom:roomDataSource];

            // The room view controller do not have here the data source ownership.
            self.hasRoomDataSourceOwnership = NO;

            [self refreshActivitiesViewDisplay];
            [self refreshJumpToLastUnreadBannerDisplay];

            if (self.saveProgressTextInput)
            {
                // Restore the potential message partially typed before jump to last unread messages.
                self.inputToolbarView.textMessage = roomDataSource.partialTextMessage;
            }
        }];
    }
}

#pragma mark - Missed discussions handling

- (NSUInteger)missedDiscussionsCount
{
    return [self.mainSession vc_missedDiscussionsCount];
}

- (NSUInteger)missedHighlightDiscussionsCount
{
    return [self.mainSession missedHighlightDiscussionsCount];
}

- (void)refreshMissedDiscussionsCount:(BOOL)force
{
    // Ignore this action when no room is displayed
    if (!self.roomDataSource || !missedDiscussionsBarButtonCustomView)
    {
        return;
    }
    
    NSUInteger highlightCount = 0;
    NSUInteger missedCount = [self missedDiscussionsCount];
    
    // Compute the missed notifications count of the current room by considering its notification mode in Riot.
    NSUInteger roomNotificationCount = self.roomDataSource.room.summary.notificationCount;
    if (self.roomDataSource.room.isMentionsOnly)
    {
        // Only the highlighted missed messages must be considered here.
        roomNotificationCount = self.roomDataSource.room.summary.highlightCount;
    }
    
    // Remove the current room from the missed discussion counter.
    if (missedCount && roomNotificationCount)
    {
        missedCount--;
    }
    
    if (missedCount)
    {
        // Compute the missed highlight count
        highlightCount = [self missedHighlightDiscussionsCount];
        if (highlightCount && self.roomDataSource.room.summary.highlightCount)
        {
            // Remove the current room from the missed highlight counter
            highlightCount--;
        }
    }
    
    if (force || missedDiscussionsCount != missedCount || missedHighlightCount != highlightCount)
    {
        missedDiscussionsCount = missedCount;
        missedHighlightCount = highlightCount;
        
        NSMutableArray *leftBarButtonItems = [NSMutableArray arrayWithArray: self.navigationItem.leftBarButtonItems];
        
        if (missedCount)
        {
            // Refresh missed discussions count label
            if (missedCount > 99)
            {
                missedDiscussionsBadgeLabel.text = @"99+";
            }
            else
            {
                missedDiscussionsBadgeLabel.text = [NSString stringWithFormat:@"%tu", missedCount];
            }
            
            [missedDiscussionsBadgeLabel sizeToFit];
            
            // Update the label background view frame
            CGRect frame = missedDiscussionsBadgeLabelBgView.frame;
            frame.size.width = round(missedDiscussionsBadgeLabel.frame.size.width + 18);
            
            if ([GBDeviceInfo deviceInfo].osVersion.major < 11)
            {
                // Consider the main navigation controller if the current view controller is embedded inside a split view controller.
                UINavigationController *mainNavigationController = self.navigationController;
                if (self.splitViewController.isCollapsed && self.splitViewController.viewControllers.count)
                {
                    mainNavigationController = self.splitViewController.viewControllers.firstObject;
                }
                UINavigationItem *backItem = mainNavigationController.navigationBar.backItem;
                UIBarButtonItem *backButton = backItem.backBarButtonItem;
                
                if (backButton && !backButton.title.length)
                {
                    // Shift the badge on the left to be close the back icon
                    frame.origin.x = ([GBDeviceInfo deviceInfo].displayInfo.display > GBDeviceDisplay4Inch ? -35 : -25);
                }
                else
                {
                    frame.origin.x = 0;
                }
            }
            
            // Caution: set label background view frame only in case of changes to prevent from looping on 'viewDidLayoutSubviews'.
            if (!CGRectEqualToRect(missedDiscussionsBadgeLabelBgView.frame, frame))
            {
                missedDiscussionsBadgeLabelBgView.frame = frame;
            }
            
            // Set the right background color
            if (highlightCount)
            {
                missedDiscussionsBadgeLabelBgView.backgroundColor = ThemeService.shared.theme.noticeColor;
            }
            else
            {
                missedDiscussionsBadgeLabelBgView.backgroundColor = ThemeService.shared.theme.noticeSecondaryColor;
            }
            
            if (!missedDiscussionsButton || [leftBarButtonItems indexOfObject:missedDiscussionsButton] == NSNotFound)
            {
                missedDiscussionsButton = [[UIBarButtonItem alloc] initWithCustomView:missedDiscussionsBarButtonCustomView];
                
                // Add it in left bar items
                [leftBarButtonItems addObject:missedDiscussionsButton];
            }
        }
        else if (missedDiscussionsButton)
        {
            [leftBarButtonItems removeObject:missedDiscussionsButton];
            missedDiscussionsButton = nil;
        }
        
        self.navigationItem.leftBarButtonItems = leftBarButtonItems;
    }
}

#pragma mark - Unsent Messages Handling

-(BOOL)checkUnsentMessages
{
    BOOL hasUnsent = NO;
    BOOL hasUnsentDueToUnknownDevices = NO;
    
    if ([self.activitiesView isKindOfClass:RoomActivitiesView.class])
    {
        NSArray<MXEvent*> *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
        
        for (MXEvent *event in outgoingMsgs)
        {
            if (event.sentState == MXEventSentStateFailed)
            {
                hasUnsent = YES;
                
                // Check if the error is due to unknown devices
                if ([event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
                    && event.sentError.code == MXEncryptingErrorUnknownDeviceCode)
                {
                    hasUnsentDueToUnknownDevices = YES;
                    break;
                }
            }
        }
        
        if (hasUnsent)
        {
            NSString *notification = hasUnsentDueToUnknownDevices ?
            NSLocalizedStringFromTable(@"room_unsent_messages_unknown_devices_notification", @"Vector", nil) :
            NSLocalizedStringFromTable(@"room_unsent_messages_notification", @"Vector", nil);
            
            RoomActivitiesView *roomActivitiesView = (RoomActivitiesView*) self.activitiesView;
            [roomActivitiesView displayUnsentMessagesNotification:notification withResendLink:^{
                
                [self resendAllUnsentMessages];
                
            } andCancelLink:^{
                
                [self cancelAllUnsentMessages];
                
            } andIconTapGesture:^{
                
                if (currentAlert)
                {
                    [currentAlert dismissViewControllerAnimated:NO completion:nil];
                }
                
                __weak __typeof(self) weakSelf = self;
                currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_resend_unsent_messages", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       [self resendAllUnsentMessages];
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"room_delete_unsent_messages", @"Vector", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       [self cancelAllUnsentMessages];
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCUnsentMessagesMenuAlert"];
                [currentAlert popoverPresentationController].sourceView = roomActivitiesView;
                [currentAlert popoverPresentationController].sourceRect = roomActivitiesView.bounds;
                [self presentViewController:currentAlert animated:YES completion:nil];
                
            }];
        }
    }
    
    return hasUnsent;
}

- (void)eventDidChangeSentState:(NSNotification *)notif
{
    // We are only interested by event that has just failed in their encryption
    // because of unknown devices in the room
    MXEvent *event = notif.object;
    if (event.sentState == MXEventSentStateFailed &&
        [event.roomId isEqualToString:self.roomDataSource.roomId]
        && [event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
        && event.sentError.code == MXEncryptingErrorUnknownDeviceCode
        && !unknownDevices)   // Show the alert once in case of resending several events
    {
        MXWeakify(self);
        
        [self dismissTemporarySubViews];
        
        // List all unknown devices
        unknownDevices  = [[MXUsersDevicesMap alloc] init];
        
        NSArray<MXEvent*> *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
        for (MXEvent *event in outgoingMsgs)
        {
            if (event.sentState == MXEventSentStateFailed
                && [event.sentError.domain isEqualToString:MXEncryptingErrorDomain]
                && event.sentError.code == MXEncryptingErrorUnknownDeviceCode)
            {
                MXUsersDevicesMap<MXDeviceInfo*> *eventUnknownDevices = event.sentError.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey];
                
                [unknownDevices addEntriesFromMap:eventUnknownDevices];
            }
        }
        
        // Tchap: automatically accept unknown devices for the moment, we will change this later.
        // Acknowledge the existence of all devices
        [self startActivityIndicator];
        [self.mainSession.crypto setDevicesKnown:self->unknownDevices complete:^{
            
            MXStrongifyAndReturnIfNil(self);
            self->unknownDevices = nil;
            [self stopActivityIndicator];
            
            // And resend pending messages
            [self resendAllUnsentMessages];
        }];
        
//        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert_title"]
//                                                           message:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert"]
//                                                    preferredStyle:UIAlertControllerStyleAlert];
//        
//        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_verify"]
//                                                         style:UIAlertActionStyleDefault
//                                                       handler:^(UIAlertAction * action) {
//                                                           
//                                                           MXStrongifyAndReturnIfNil(self);
//                                                           self->currentAlert = nil;
//                                                           UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//                                                           UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"UsersDevicesNavigationControllerStoryboardId"];
//                                                           
//                                                           UsersDevicesViewController *usersDevicesViewController = navigationController.childViewControllers.firstObject;
//                                                           [usersDevicesViewController displayUsersDevices:self->unknownDevices andMatrixSession:self.roomDataSource.mxSession onComplete:nil];
//                                                           
//                                                           self->unknownDevices = nil;
//                                                           [self presentViewController:navigationController animated:YES completion:nil];
//                                                           
//                                                       }]];
//        
//        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_send_anyway"]
//                                                         style:UIAlertActionStyleDefault
//                                                       handler:^(UIAlertAction * action) {
//                                                           
//                                                           MXStrongifyAndReturnIfNil(self);
//                                                           self->currentAlert = nil;
//                                                           
//                                                           // Acknowledge the existence of all devices
//                                                           [self startActivityIndicator];
//                                                           [self.mainSession.crypto setDevicesKnown:self->unknownDevices complete:^{
//                                                               
//                                                               self->unknownDevices = nil;
//                                                               [self stopActivityIndicator];
//                                                               
//                                                               // And resend pending messages
//                                                               [self resendAllUnsentMessages];
//                                                           }];
//                                                           
//                                                       }]];
//        
//        [currentAlert mxk_setAccessibilityIdentifier:@"RoomVCUnknownDevicesAlert"];
//        [self presentViewController:currentAlert animated:YES completion:nil];
    }
}

- (void)eventDidChangeIdentifier:(NSNotification *)notif
{
    MXEvent *event = notif.object;
    NSString *previousId = notif.userInfo[kMXEventIdentifierKey];

    if ([customizedRoomDataSource.selectedEventId isEqualToString:previousId])
    {
        NSLog(@"[RoomVC] eventDidChangeIdentifier: Update selectedEventId");
        customizedRoomDataSource.selectedEventId = event.eventId;
    }
}


- (void)resendAllUnsentMessages
{
    // List unsent event ids
    NSArray *outgoingMsgs = self.roomDataSource.room.outgoingMessages;
    NSMutableArray *failedEventIds = [NSMutableArray arrayWithCapacity:outgoingMsgs.count];
    
    for (MXEvent *event in outgoingMsgs)
    {
        if (event.sentState == MXEventSentStateFailed)
        {
            [failedEventIds addObject:event.eventId];
        }
    }
    
    // Launch iterative operation
    [self resendFailedEvent:0 inArray:failedEventIds];
}

- (void)resendFailedEvent:(NSUInteger)index inArray:(NSArray*)failedEventIds
{
    if (index < failedEventIds.count)
    {
        NSString *failedEventId = failedEventIds[index];
        NSUInteger nextIndex = index + 1;
        
        // Let the datasource resend. It will manage local echo, etc.
        [self.roomDataSource resendEventWithEventId:failedEventId success:^(NSString *eventId) {
            
            [self resendFailedEvent:nextIndex inArray:failedEventIds];
            
        } failure:^(NSError *error) {
            
            [self resendFailedEvent:nextIndex inArray:failedEventIds];
            
        }];
        
        return;
    }
    
    // Refresh activities view
    [self refreshActivitiesViewDisplay];
}

- (void)cancelAllUnsentMessages
{
    // Remove unsent event ids
    for (NSUInteger index = 0; index < self.roomDataSource.room.outgoingMessages.count;)
    {
        MXEvent *event = self.roomDataSource.room.outgoingMessages[index];
        if (event.sentState == MXEventSentStateFailed)
        {
            [self.roomDataSource removeEventWithEventId:event.eventId];
        }
        else
        {
            index ++;
        }
    }
}

#pragma mark - Read marker handling

- (void)checkReadMarkerVisibility
{
    if (readMarkerTableViewCell && isAppeared && !self.isBubbleTableViewDisplayInTransition)
    {
        // Check whether the read marker is visible
        CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.mxk_adjustedContentInset.top;
        CGFloat readMarkerViewPosY = readMarkerTableViewCell.frame.origin.y + readMarkerTableViewCell.readMarkerView.frame.origin.y;
        if (contentTopPosY <= readMarkerViewPosY)
        {
            // Compute the max vertical position visible according to contentOffset
            CGFloat contentBottomPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.frame.size.height - self.bubblesTableView.mxk_adjustedContentInset.bottom;
            if (readMarkerViewPosY <= contentBottomPosY)
            {
                // Launch animation
                [self animateReadMarkerView];
                
                // Disable the read marker display when it has been rendered once.
                self.roomDataSource.showReadMarker = NO;
                [self refreshJumpToLastUnreadBannerDisplay];
                
                // Update the read marker position according the events acknowledgement in this view controller.
                self.updateRoomReadMarker = YES;
                
                if (self.roomDataSource.isLive)
                {
                    // Move the read marker to the current read receipt position.
                    [self.roomDataSource.room forgetReadMarker];
                }
            }
        }
    }
}

- (void)animateReadMarkerView
{
    // Check whether the cell with the read marker is known and if the marker is not animated yet.
    if (readMarkerTableViewCell && readMarkerTableViewCell.readMarkerView.isHidden)
    {
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)readMarkerTableViewCell.bubbleData;
        
        // Do not display the marker if this is the last message.
        if (cellData.containsLastMessage && readMarkerTableViewCell.readMarkerView.tag == cellData.mostRecentComponentIndex)
        {
            readMarkerTableViewCell.readMarkerView.hidden = YES;
            readMarkerTableViewCell = nil;
        }
        else
        {
            readMarkerTableViewCell.readMarkerView.hidden = NO;
            
            // Animate the layout to hide the read marker
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     
                                     readMarkerTableViewCell.readMarkerViewLeadingConstraint.constant = readMarkerTableViewCell.readMarkerViewTrailingConstraint.constant = readMarkerTableViewCell.bubbleOverlayContainer.frame.size.width / 2;
                                     readMarkerTableViewCell.readMarkerView.alpha = 0;
                                     
                                     // Force to render the view
                                     [readMarkerTableViewCell.bubbleOverlayContainer layoutIfNeeded];
                                     
                                 }
                                 completion:^(BOOL finished){
                                     
                                     readMarkerTableViewCell.readMarkerView.hidden = YES;
                                     readMarkerTableViewCell.readMarkerView.alpha = 1;
                                     
                                     readMarkerTableViewCell = nil;
                                 }];
                
            });
        }
    }
}

- (void)refreshJumpToLastUnreadBannerDisplay
{
    // This banner is only displayed when the room timeline is in live (and no peeking).
    // Check whether the read marker exists and has not been rendered yet.
    if (self.roomDataSource.isLive && !self.roomDataSource.isPeeking && self.roomDataSource.showReadMarker && self.roomDataSource.room.accountData.readMarkerEventId)
    {
        UITableViewCell *cell = [self.bubblesTableView visibleCells].firstObject;
        if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            // Check whether the read marker is inside the first displayed cell.
            if (roomBubbleTableViewCell.readMarkerView)
            {
                // The read marker display is still enabled (see roomDataSource.showReadMarker flag),
                // this means the read marker was not been visible yet.
                // We show the banner if the marker is located in the top hidden part of the cell.
                CGFloat contentTopPosY = self.bubblesTableView.contentOffset.y + self.bubblesTableView.mxk_adjustedContentInset.top;
                CGFloat readMarkerViewPosY = roomBubbleTableViewCell.frame.origin.y + roomBubbleTableViewCell.readMarkerView.frame.origin.y;
                self.jumpToLastUnreadBannerContainer.hidden = (contentTopPosY < readMarkerViewPosY);
            }
            else
            {
                // Check whether the read marker event is anterior to the first event displayed in the first rendered cell.
                MXKRoomBubbleComponent *component = roomBubbleTableViewCell.bubbleData.bubbleComponents.firstObject;
                MXEvent *firstDisplayedEvent = component.event;
                MXEvent *currentReadMarkerEvent = [self.roomDataSource.mxSession.store eventWithEventId:self.roomDataSource.room.accountData.readMarkerEventId inRoom:self.roomDataSource.roomId];
                
                if (!currentReadMarkerEvent || (currentReadMarkerEvent.originServerTs < firstDisplayedEvent.originServerTs))
                {
                    self.jumpToLastUnreadBannerContainer.hidden = NO;
                }
                else
                {
                    self.jumpToLastUnreadBannerContainer.hidden = YES;
                }
            }
        }
    }
    else
    {
        self.jumpToLastUnreadBannerContainer.hidden = YES;
        
        // Initialize the read marker if it does not exist yet, only in case of live timeline.
        if (!self.roomDataSource.room.accountData.readMarkerEventId && self.roomDataSource.isLive && !self.roomDataSource.isPeeking)
        {
            // Move the read marker to the current read receipt position by default.
            [self.roomDataSource.room forgetReadMarker];
        }
    }
}
                                     
#pragma mark - Re-request encryption keys

- (void)reRequestKeysAndShowExplanationAlert:(MXEvent*)event
{
    MXWeakify(self);
    __block UIAlertController *alert;

    // Make the re-request
    [self.mainSession.crypto reRequestRoomKeyForEvent:event];

    // Observe kMXEventDidDecryptNotification to remove automatically the dialog
    // if the user has shared the keys from another device
    mxEventDidDecryptNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXEventDidDecryptNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        MXStrongifyAndReturnIfNil(self);

        MXEvent *decryptedEvent = notif.object;

        if ([decryptedEvent.eventId isEqualToString:event.eventId])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
            self->mxEventDidDecryptNotificationObserver = nil;

            if (self->currentAlert == alert)
            {
                [self->currentAlert dismissViewControllerAnimated:YES completion:nil];
                self->currentAlert = nil;
            }
        }
    }];

    // Show the explanation dialog
    alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"rerequest_keys_alert_title", @"Vector", nil)
                                                       message:NSLocalizedStringFromTable(@"rerequest_keys_alert_message", @"Vector", nil)
                                                preferredStyle:UIAlertControllerStyleAlert];
    currentAlert = alert;


    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 MXStrongifyAndReturnIfNil(self);

                                 [[NSNotificationCenter defaultCenter] removeObserver:self->mxEventDidDecryptNotificationObserver];
                                 self->mxEventDidDecryptNotificationObserver = nil;

                                 self->currentAlert = nil;
                             }]];

    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark Tombstone event

- (void)listenTombstoneEventNotifications
{
    // Room is already obsolete do not listen to tombstone event
    if (self.roomDataSource.roomState.isObsolete)
    {
        return;
    }
    
    MXWeakify(self);
    
    tombstoneEventNotificationsListener = [self.roomDataSource.room listenToEventsOfTypes:@[kMXEventTypeStringRoomTombStone] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Update activitiesView with room replacement information
        [self refreshActivitiesViewDisplay];
        // Hide inputToolbarView
        [self updateRoomInputToolbarViewClassIfNeeded];
    }];
}

- (void)removeTombstoneEventNotificationsListener
{
    if (self.roomDataSource)
    {
        // Remove the previous live listener
        if (tombstoneEventNotificationsListener)
        {
            [self.roomDataSource.room removeListener:tombstoneEventNotificationsListener];
            tombstoneEventNotificationsListener = nil;
        }
    }
}

#pragma mark MXSession state change

- (void)listenMXSessionStateChangeNotifications
{
    kMXSessionStateDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:self.roomDataSource.mxSession queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        if (self.roomDataSource.mxSession.state == MXSessionStateSyncError
            || self.roomDataSource.mxSession.state == MXSessionStateRunning)
        {
            [self refreshActivitiesViewDisplay];

            // update inputToolbarView
            [self updateRoomInputToolbarViewClassIfNeeded];
            [self refreshRoomInputToolbar];
        }
    }];
}

- (void)removeMXSessionStateChangeNotificationsListener
{
    if (kMXSessionStateDidChangeObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kMXSessionStateDidChangeObserver];
        kMXSessionStateDidChangeObserver = nil;
    }
}

#pragma mark - Contextual Menu

- (NSArray<RoomContextualMenuItem*>*)contextualMenuItemsForEvent:(MXEvent*)event andCell:(id<MXKCellRendering>)cell
{
    NSString *eventId = event.eventId;
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell *)cell;
    MXKAttachment *attachment = roomBubbleTableViewCell.bubbleData.attachment;
    
    MXWeakify(self);
    
    // Copy action
    
    BOOL isCopyActionEnabled = !attachment || attachment.type != MXKAttachmentTypeSticker;
    
    if (attachment && !BuildSettings.messageDetailsAllowCopyMedia)
    {
        isCopyActionEnabled = NO;
    }
    
    if (isCopyActionEnabled)
    {
        switch (event.eventType) {
            case MXEventTypeRoomMessage:
            {
                NSString *messageType = event.content[@"msgtype"];
                
                if ([messageType isEqualToString:kMXMessageTypeKeyVerificationRequest])
                {
                    isCopyActionEnabled = NO;
                }
                break;
            }
            case MXEventTypeKeyVerificationStart:
            case MXEventTypeKeyVerificationAccept:
            case MXEventTypeKeyVerificationKey:
            case MXEventTypeKeyVerificationMac:
            case MXEventTypeKeyVerificationDone:
            case MXEventTypeKeyVerificationCancel:
                isCopyActionEnabled = NO;
                break;
            default:
                break;
        }
    }
    
    RoomContextualMenuItem *copyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionCopy];
    copyMenuItem.isEnabled = isCopyActionEnabled;
    copyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        if (!attachment)
        {
            NSArray *components = roomBubbleTableViewCell.bubbleData.bubbleComponents;
            MXKRoomBubbleComponent *selectedComponent;
            for (selectedComponent in components)
            {
                if ([selectedComponent.event.eventId isEqualToString:event.eventId])
                {
                    break;
                }
                selectedComponent = nil;
            }
            NSString *textMessage = selectedComponent.textMessage;
            
            if (textMessage)
            {
                MXKPasteboardManager.shared.pasteboard.string = textMessage;
            }
            else
            {
                NSLog(@"[RoomViewController] Contextual menu copy failed. Text is nil for room id/event id: %@/%@", selectedComponent.event.roomId, selectedComponent.event.eventId);
            }
            
            [self hideContextualMenuAnimated:YES];
        }
        else if (attachment.type != MXKAttachmentTypeSticker)
        {
            [self hideContextualMenuAnimated:YES completion:^{
                [self startActivityIndicator];
                
                [attachment copy:^{
                    
                    [self stopActivityIndicator];
                    
                } failure:^(NSError *error) {
                    
                    [self stopActivityIndicator];
                    
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }];
                
                // Start animation in case of download during attachment preparing
                [roomBubbleTableViewCell startProgressUI];
            }];
        }
    };
    
    // Reply action
    
    RoomContextualMenuItem *replyMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionReply];
    replyMenuItem.isEnabled = [self.roomDataSource canReplyToEventWithId:eventId];
    replyMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self selectEventWithId:eventId inputToolBarSendMode:RoomInputToolbarViewSendModeReply showTimestamp:NO];

        // And display the keyboard
        [self.inputToolbarView becomeFirstResponder];
    };
#ifdef ENABLE_EDITION
    // Edit action
    
    RoomContextualMenuItem *editMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionEdit];
    editMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES cancelEventSelection:NO completion:nil];
        [self editEventContentWithId:eventId];

        // And display the keyboard
        [self.inputToolbarView becomeFirstResponder];
    };
    
    editMenuItem.isEnabled = [self.roomDataSource canEditEventWithId:eventId];
#else
    // Redact action
    
    RoomContextualMenuItem *redactMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionRedact];
    redactMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES];
        
        [self startActivityIndicator];
        
        MXWeakify(self);
        [self.roomDataSource.room redactEvent:eventId reason:nil success:^{
            
            MXStrongifyAndReturnIfNil(self);
            [self stopActivityIndicator];
            
        } failure:^(NSError *error) {
            
            MXStrongifyAndReturnIfNil(self);
            [self stopActivityIndicator];
            
            NSLog(@"[RoomVC] Redact event (%@) failed", eventId);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
            
        }];
    };
    
    // Do not allow to redact the state events, and event from others except if the user has the power.
    MXRoomPowerLevels *powerLevels = self.roomDataSource.roomState.powerLevels;
    NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    redactMenuItem.isEnabled = (!event.isState && (userPowerLevel >= powerLevels.redact || [event.sender isEqualToString:self.mainSession.myUser.userId]));
#endif
    
    // More action
    
    RoomContextualMenuItem *moreMenuItem = [[RoomContextualMenuItem alloc] initWithMenuAction:RoomContextualMenuActionMore];
    moreMenuItem.action = ^{
        MXStrongifyAndReturnIfNil(self);
        [self hideContextualMenuAnimated:YES completion:nil];
        [self showAdditionalActionsMenuForEvent:event inCell:cell animated:YES];
    };
    
    // Actions list
    
    NSArray<RoomContextualMenuItem*> *actionItems = @[
                                                      copyMenuItem,
                                                      replyMenuItem,
#ifdef ENABLE_EDITION
                                                      editMenuItem,
#else
                                                      redactMenuItem,
#endif
                                                      moreMenuItem
                                                      ];
    
    return actionItems;
}

- (void)showContextualMenuForEvent:(MXEvent*)event fromSingleTapGesture:(BOOL)usedSingleTapGesture cell:(id<MXKCellRendering>)cell animated:(BOOL)animated
{
    if (self.roomContextualMenuPresenter.isPresenting)
    {
        return;
    }
    
    NSString *selectedEventId = event.eventId;
    
    NSArray<RoomContextualMenuItem*>* contextualMenuItems = [self contextualMenuItemsForEvent:event andCell:cell];
    ReactionsMenuViewModel *reactionsMenuViewModel;
    CGRect bubbleComponentFrameInOverlayView = CGRectNull;
    
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && [self.roomDataSource canReactToEventWithId:event.eventId])
    {
        MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
        MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
        NSArray *bubbleComponents = bubbleCellData.bubbleComponents;
        
        NSInteger foundComponentIndex = [bubbleCellData bubbleComponentIndexForEventId:event.eventId];
        CGRect bubbleComponentFrame;
        
        if (bubbleComponents.count > 0)
        {
            NSInteger selectedComponentIndex = foundComponentIndex != NSNotFound ? foundComponentIndex : 0;
            bubbleComponentFrame = [roomBubbleTableViewCell surroundingFrameInTableViewForComponentIndex:selectedComponentIndex];
        }
        else
        {
            bubbleComponentFrame = roomBubbleTableViewCell.frame;
        }
        
        bubbleComponentFrameInOverlayView = [self.bubblesTableView convertRect:bubbleComponentFrame toView:self.overlayContainerView];
        
        NSString *roomId = self.roomDataSource.roomId;
        MXAggregations *aggregations = self.mainSession.aggregations;
        MXAggregatedReactions *aggregatedReactions = [aggregations aggregatedReactionsOnEvent:selectedEventId inRoom:roomId];
        
        reactionsMenuViewModel = [[ReactionsMenuViewModel alloc] initWithAggregatedReactions:aggregatedReactions eventId:selectedEventId];
        reactionsMenuViewModel.coordinatorDelegate = self;
    }
    
    if (!self.roomContextualMenuViewController)
    {
        self.roomContextualMenuViewController = [RoomContextualMenuViewController instantiate];
        self.roomContextualMenuViewController.delegate = self;
    }
    
    [self.roomContextualMenuViewController updateWithContextualMenuItems:contextualMenuItems reactionsMenuViewModel:reactionsMenuViewModel];
    
    [self enableOverlayContainerUserInteractions:YES];
    
    [self.roomContextualMenuPresenter presentWithRoomContextualMenuViewController:self.roomContextualMenuViewController
                                                                             from:self
                                                                               on:self.overlayContainerView
                                                              contentToReactFrame:bubbleComponentFrameInOverlayView
                                                             fromSingleTapGesture:usedSingleTapGesture
                                                                         animated:animated
                                                                       completion:^{
                                                                       }];
    
    preventBubblesTableViewScroll = YES;
    [self selectEventWithId:selectedEventId];    
}

- (void)hideContextualMenuAnimated:(BOOL)animated
{
    [self hideContextualMenuAnimated:animated completion:nil];
}

- (void)hideContextualMenuAnimated:(BOOL)animated completion:(void(^)(void))completion
{
    [self hideContextualMenuAnimated:animated cancelEventSelection:YES completion:completion];
}

- (void)hideContextualMenuAnimated:(BOOL)animated cancelEventSelection:(BOOL)cancelEventSelection completion:(void(^)(void))completion
{
    if (!self.roomContextualMenuPresenter.isPresenting)
    {
        return;
    }
    
    if (cancelEventSelection)
    {
        [self cancelEventSelection];
    }
    
    preventBubblesTableViewScroll = NO;
    
    [self.roomContextualMenuPresenter hideContextualMenuWithAnimated:animated completion:^{
        [self enableOverlayContainerUserInteractions:NO];
        
        if (completion)
        {
            completion();
        }
    }];
}

- (void)enableOverlayContainerUserInteractions:(BOOL)enableOverlayContainerUserInteractions
{
    self.inputToolbarView.editable = !enableOverlayContainerUserInteractions;
    self.bubblesTableView.scrollsToTop = !enableOverlayContainerUserInteractions;
    self.overlayContainerView.userInteractionEnabled = enableOverlayContainerUserInteractions;
}

#pragma mark - RoomContextualMenuViewControllerDelegate

- (void)roomContextualMenuViewControllerDidTapBackgroundOverlay:(RoomContextualMenuViewController *)viewController
{
    [self hideContextualMenuAnimated:YES];
}

#pragma mark - ReactionsMenuViewModelCoordinatorDelegate

- (void)reactionsMenuViewModel:(ReactionsMenuViewModel *)viewModel didAddReaction:(NSString *)reaction forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [self hideContextualMenuAnimated:YES completion:^{
        
        [self.roomDataSource addReaction:reaction forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
}

- (void)reactionsMenuViewModel:(ReactionsMenuViewModel *)viewModel didRemoveReaction:(NSString *)reaction forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [self hideContextualMenuAnimated:YES completion:^{
        
        [self.roomDataSource removeReaction:reaction forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
        
    }];
}

- (void)reactionsMenuViewModelDidTapMoreReactions:(ReactionsMenuViewModel *)viewModel forEventId:(NSString *)eventId
{
    [self hideContextualMenuAnimated:YES];
    
    EmojiPickerCoordinatorBridgePresenter *emojiPickerCoordinatorBridgePresenter = [[EmojiPickerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession roomId:self.roomDataSource.roomId eventId:eventId];
    emojiPickerCoordinatorBridgePresenter.delegate = self;
    
    NSInteger cellRow = [self.roomDataSource indexOfCellDataWithEventId:eventId];
    
    UIView *sourceView;
    CGRect sourceRect = CGRectNull;
    
    if (cellRow >= 0)
    {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellRow inSection:0];        
        UITableViewCell *cell = [self.bubblesTableView cellForRowAtIndexPath:cellIndexPath];
        sourceView = cell;
        
        if ([cell isKindOfClass:[MXKRoomBubbleTableViewCell class]])
        {
            MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = (MXKRoomBubbleTableViewCell*)cell;
            NSInteger bubbleComponentIndex = [roomBubbleTableViewCell.bubbleData bubbleComponentIndexForEventId:eventId];
            sourceRect = [roomBubbleTableViewCell componentFrameInContentViewForIndex:bubbleComponentIndex];
        }
        
    }
    
    [emojiPickerCoordinatorBridgePresenter presentFrom:self sourceView:sourceView sourceRect:sourceRect animated:YES];
    self.emojiPickerCoordinatorBridgePresenter = emojiPickerCoordinatorBridgePresenter;
}

#pragma mark -

- (void)showEditHistoryForEventId:(NSString*)eventId animated:(BOOL)animated
{
    MXEvent *event = [self.roomDataSource eventWithEventId:eventId];
    EditHistoryCoordinatorBridgePresenter *presenter = [[EditHistoryCoordinatorBridgePresenter alloc] initWithSession:self.roomDataSource.mxSession event:event];
    
    presenter.delegate = self;
    [presenter presentFrom:self animated:animated];
    
    self.editHistoryPresenter = presenter;
}

#pragma mark - EditHistoryCoordinatorBridgePresenterDelegate

- (void)editHistoryCoordinatorBridgePresenterDelegateDidComplete:(EditHistoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.editHistoryPresenter = nil;
}

#pragma mark - DocumentPickerPresenterDelegate

- (void)documentPickerPresenterWasCancelled:(MXKDocumentPickerPresenter *)presenter
{
    self.documentPickerPresenter = nil;
}

- (void)documentPickerPresenter:(MXKDocumentPickerPresenter *)presenter didPickDocumentsAt:(NSURL *)url
{
    self.documentPickerPresenter = nil;
    
    MXKUTI *fileUTI = [[MXKUTI alloc] initWithLocalFileURL:url];
    NSString *mimeType = fileUTI.mimeType;
    
    if (fileUTI.isImage)
    {
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        
        [self sendImage:imageData withMimeType:mimeType];
    }
    else if (fileUTI.isVideo)
    {
        [self sendVideo:url];
    }
    else if (fileUTI.isFile)
    {
        [self sendFile:url withMimeType:mimeType];
    }
    else
    {
        NSLog(@"[RoomViewController] File upload using MIME type %@ is not supported.", mimeType);
        
        [[AppDelegate theDelegate] showAlertWithTitle:NSLocalizedStringFromTable(@"file_upload_error_title", @"Vector", nil)
                                              message:NSLocalizedStringFromTable(@"file_upload_error_unsupported_file_type_message", @"Vector", nil)];
    }
}

#pragma mark - EmojiPickerCoordinatorBridgePresenterDelegate

- (void)emojiPickerCoordinatorBridgePresenter:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didAddEmoji:(NSString *)emoji forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self.roomDataSource addReaction:emoji forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

- (void)emojiPickerCoordinatorBridgePresenter:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didRemoveEmoji:(NSString *)emoji forEventId:(NSString *)eventId
{
    MXWeakify(self);
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        
        [self.roomDataSource removeReaction:emoji forEventId:eventId success:^{
            
        } failure:^(NSError *error) {
            MXStrongifyAndReturnIfNil(self);
            
            [self.errorPresenter presentErrorFromViewController:self forError:error animated:YES handler:nil];
        }];
    }];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

- (void)emojiPickerCoordinatorBridgePresenterDidCancel:(EmojiPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.emojiPickerCoordinatorBridgePresenter = nil;
}

#pragma mark - ReactionHistoryCoordinatorBridgePresenterDelegate

- (void)reactionHistoryCoordinatorBridgePresenterDelegateDidClose:(ReactionHistoryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        self.reactionHistoryCoordinatorBridgePresenter = nil;
    }];
}

#pragma mark - CameraPresenterDelegate

- (void)cameraPresenterDidCancel:(CameraPresenter *)cameraPresenter
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
}

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedImage:imageData withMimeType:uti.mimeType andCompressionMode:BuildSettings.roomInputToolbarCompressionMode isPhotoLibraryAsset:NO];
    }
}

- (void)cameraPresenter:(CameraPresenter *)cameraPresenter didSelectVideoAt:(NSURL *)url
{
    [cameraPresenter dismissWithAnimated:YES completion:nil];
    self.cameraPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedVideo:url isPhotoLibraryAsset:NO];
    }
}

#pragma mark - MediaPickerCoordinatorBridgePresenterDelegate

- (void)mediaPickerCoordinatorBridgePresenterDidCancel:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedImage:imageData withMimeType:uti.mimeType andCompressionMode:BuildSettings.roomInputToolbarCompressionMode isPhotoLibraryAsset:YES];
    }
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectVideoAt:(NSURL *)url
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedVideo:url isPhotoLibraryAsset:YES];
    }
}

- (void)mediaPickerCoordinatorBridgePresenter:(MediaPickerCoordinatorBridgePresenter *)coordinatorBridgePresenter didSelectAssets:(NSArray<PHAsset *> *)assets
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.mediaPickerPresenter = nil;
    
    RoomInputToolbarView *roomInputToolbarView = [self inputToolbarViewAsRoomInputToolbarView];
    if (roomInputToolbarView)
    {
        [roomInputToolbarView sendSelectedAssets:assets withCompressionMode:BuildSettings.roomInputToolbarCompressionMode];
    }
}

@end

