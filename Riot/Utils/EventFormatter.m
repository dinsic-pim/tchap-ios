/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "EventFormatter.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "WidgetManager.h"

//#import "DecryptionFailureTracker.h"

#import "GeneratedInterface-Swift.h"

#import "EventFormatter+DTCoreTextFix.h"

#pragma mark - Constants definitions

NSString *const EventFormatterOnReRequestKeysLinkAction = @"EventFormatterOnReRequestKeysLinkAction";
NSString *const EventFormatterLinkActionSeparator = @"/";
NSString *const EventFormatterEditedEventLinkAction = @"EventFormatterEditedEventLinkAction";

static NSString *const kEventFormatterTimeFormat = @"HH:mm";

@interface EventFormatter ()
{
    /**
     The calendar used to retrieve the today date.
     */
    NSCalendar *calendar;
}
@end

@implementation EventFormatter

+ (void)load
{
    [self fixDTCoreTextFont];
}

- (void)initDateTimeFormatters
{
    [super initDateTimeFormatters];
    
    timeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [timeFormatter setDateFormat:kEventFormatterTimeFormat];
}

- (NSAttributedString *)attributedStringFromEvent:(MXEvent *)event withRoomState:(MXRoomState *)roomState error:(MXKEventFormatterError *)error
{
    BOOL isEventSenderMyUser = [event.sender isEqualToString:mxSession.myUserId];
    
    // Build strings for widget events
    if (event.eventType == MXEventTypeCustom
        && ([event.type isEqualToString:kWidgetMatrixEventTypeString]
            || [event.type isEqualToString:kWidgetModularEventTypeString]))
    {
        NSString *displayText;

        Widget *widget = [[Widget alloc] initWithWidgetEvent:event inMatrixSession:mxSession];
        if (widget)
        {
            // Prepare the display name of the sender
            NSString *senderDisplayName = roomState ? [self senderDisplayNameForEvent:event withRoomState:roomState] : event.sender;

            if (widget.isActive)
            {
                if ([widget.type isEqualToString:kWidgetTypeJitsiV1]
                    || [widget.type isEqualToString:kWidgetTypeJitsiV2])
                {
                    // This is an alive jitsi widget
                    if (isEventSenderMyUser)
                    {
                        displayText = NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_added_by_you", @"Vector", nil);
                    }
                    else
                    {
                        displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_added", @"Vector", nil), senderDisplayName];
                    }
                }
                else
                {
                    if (isEventSenderMyUser)
                    {
                        displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_widget_added_by_you", @"Vector", nil),
                        widget.name ? widget.name : widget.type];
                    }
                    else
                    {
                        displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_widget_added", @"Vector", nil),
                        widget.name ? widget.name : widget.type,
                        senderDisplayName];
                    }
                }
            }
            else
            {
                // This is a closed widget
                // Check if it corresponds to a jitsi widget by looking at other state events for
                // this jitsi widget (widget id = event.stateKey).
                // Get all widgets state events in the room
                NSMutableArray<MXEvent*> *widgetStateEvents = [NSMutableArray arrayWithArray:[roomState stateEventsWithType:kWidgetMatrixEventTypeString]];
                [widgetStateEvents addObjectsFromArray:[roomState stateEventsWithType:kWidgetModularEventTypeString]];

                for (MXEvent *widgetStateEvent in widgetStateEvents)
                {
                    if ([widgetStateEvent.stateKey isEqualToString:widget.widgetId])
                    {
                        Widget *activeWidget = [[Widget alloc] initWithWidgetEvent:widgetStateEvent inMatrixSession:mxSession];
                        if (activeWidget.isActive)
                        {
                            if ([activeWidget.type isEqualToString:kWidgetTypeJitsiV1]
                                || [activeWidget.type isEqualToString:kWidgetTypeJitsiV2])
                            {
                                // This was a jitsi widget
                                if (isEventSenderMyUser)
                                {
                                    displayText = NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_removed_by_you", @"Vector", nil);
                                }
                                else
                                {
                                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_jitsi_widget_removed", @"Vector", nil), senderDisplayName];
                                }
                            }
                            else
                            {
                                if (isEventSenderMyUser)
                                {
                                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_widget_removed_by_you", @"Vector", nil),
                                                   activeWidget.name ? activeWidget.name : activeWidget.type];
                                }
                                else
                                {
                                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_widget_removed", @"Vector", nil),
                                                   activeWidget.name ? activeWidget.name : activeWidget.type,
                                                   senderDisplayName];
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }

        if (displayText)
        {
            if (error)
            {
                *error = MXKEventFormatterErrorNone;
            }

            // Build the attributed string with the right font and color for the events
            return [self renderString:displayText forEvent:event];
        }
    }
    
    switch (event.eventType)
    {
        case MXEventTypeRoomCreate:
        {
            MXRoomCreateContent *createContent = [MXRoomCreateContent modelFromJSON:event.content];
            
            NSString *roomPredecessorId = createContent.roomPredecessorInfo.roomId;
            
            if (roomPredecessorId)
            {
                return [self roomCreatePredecessorAttributedStringWithPredecessorRoomId:roomPredecessorId];
            }
            else
            {
                NSAttributedString *string = [super attributedStringFromEvent:event withRoomState:roomState error:error];
                NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"· "];
                [result appendAttributedString:string];
                return result;
            }
        }
            break;
        case MXEventTypeRoomRetention:
        {
            // Check whether a retention period is defined
            uint periodInDays = RoomService.undefinedRetentionValueInDays;
            if (event.content[RoomService.roomRetentionContentMaxLifetimeKey])
            {
                UInt64 maxLifetime = UINT64_MAX;
                MXJSONModelSetUInt64(maxLifetime, event.content[RoomService.roomRetentionContentMaxLifetimeKey]);
                periodInDays = [Tools numberOfDaysFromDurationInMs:maxLifetime];
            }
            
            NSString *displayText = nil;
            if ([event.sender isEqualToString:mxSession.myUserId])
            {
                if (periodInDays != RoomService.undefinedRetentionValueInDays)
                {
                    NSString *period = [RoomService getDisplayLabelForRetentionPeriodInDays:periodInDays];
                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"notice_room_retention_changed_by_you", @"Tchap", nil), period];
                }
                else
                {
                    displayText = NSLocalizedStringFromTable(@"notice_room_retention_removed_by_you", @"Tchap", nil);
                }
            }
            else
            {
                NSString *displayName = roomState ? [roomState.members memberName:event.sender] : [UserService displayNameFrom:event.sender];
                if (periodInDays != RoomService.undefinedRetentionValueInDays)
                {
                    NSString *period = [RoomService getDisplayLabelForRetentionPeriodInDays:periodInDays];
                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"notice_room_retention_changed", @"Tchap", nil), displayName, period];
                }
                else
                {
                    displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"notice_room_retention_removed", @"Tchap", nil), displayName];
                }
            }
            
            // Build the attributed string with the right font and color for the events
            return [self renderString:displayText forEvent:event];
        }
            break;
        case MXEventTypeRoomMember:
        {
            if (event.isUserProfileChange)
            {
                // Check whether the profile change must be hidden or not
                if (!RiotSettings.shared.showProfileUpdateEvents)
                {
                    return nil;
                }
            }
            else if (!RiotSettings.shared.showJoinLeaveEvents)
            {
                // Hide the join and leave events
                NSString* membership;
                MXJSONModelSetString(membership, event.content[@"membership"]);
                if ([membership isEqualToString:kMXMembershipStringJoin] || [membership isEqualToString:kMXMembershipStringLeave])
                {
                    return nil;
                }
            }
        }
            break;
        case MXEventTypeCallCandidates:
        case MXEventTypeCallAnswer:
        //case MXEventTypeCallSelectAnswer:
        case MXEventTypeCallHangup:
        //case MXEventTypeCallNegotiate:
        //case MXEventTypeCallReplaces:
        //case MXEventTypeCallRejectReplacement:
            //  Do not show call events except invite and reject in timeline
            return nil;
        case MXEventTypeCallInvite:
        {
            MXCallInviteEventContent *content = [MXCallInviteEventContent modelFromJSON:event.content];
            MXCall *call = [mxSession.callManager callWithCallId:content.callId];
            if (call && call.isIncoming && call.state == MXCallStateRinging)
            {
                //  incoming call UI will be handled by CallKit (or incoming call screen if CallKit disabled)
                //  do not show a bubble for this case
                return nil;
            }
        }
            break;
        case MXEventTypeKeyVerificationCancel:
        case MXEventTypeKeyVerificationDone:
            // Make event types MXEventTypeKeyVerificationCancel and MXEventTypeKeyVerificationDone visible in timeline.
            // TODO: Find another way to keep them visible and avoid instantiate empty NSMutableAttributedString.
            return [NSMutableAttributedString new];
        default:
            break;
    }
    
    NSAttributedString *attributedString = [super attributedStringFromEvent:event withRoomState:roomState error:error];

    if (event.sentState == MXEventSentStateSent
        && [event.decryptionError.domain isEqualToString:MXDecryptingErrorDomain])
    {
//        // Track e2e failures
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[DecryptionFailureTracker sharedInstance] reportUnableToDecryptErrorForEvent:event withRoomState:roomState myUser:mxSession.myUser.userId];
//        });

        if (event.decryptionError.code == MXDecryptingErrorUnknownInboundSessionIdCode)
        {
            // Append to the displayed error an attibuted string with a tappable link
            // so that the user can try to fix the UTD
            NSMutableAttributedString *attributedStringWithRerequestMessage = [attributedString mutableCopy];
            [attributedStringWithRerequestMessage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

            NSString *linkActionString = [NSString stringWithFormat:@"%@%@%@", EventFormatterOnReRequestKeysLinkAction,
                                          EventFormatterLinkActionSeparator,
                                          event.eventId];
            
            [attributedStringWithRerequestMessage appendAttributedString:
             [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"event_formatter_rerequest_keys_part1", @"Vector", nil)
                                             attributes:@{
                                                          NSForegroundColorAttributeName: self.sendingTextColor,
                                                          NSFontAttributeName: self.encryptedMessagesTextFont
                                                          }]];

            [attributedStringWithRerequestMessage appendAttributedString:
             [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"event_formatter_rerequest_keys_part2_link", @"Vector", nil)
                                             attributes:@{
                                                          NSLinkAttributeName: linkActionString,
                                                          NSForegroundColorAttributeName: self.sendingTextColor,
                                                          NSFontAttributeName: self.encryptedMessagesTextFont
                                                          }]];

            attributedString = attributedStringWithRerequestMessage;
        }
    }
    else if (self.showEditionMention && event.contentHasBeenEdited)
    {
        NSMutableAttributedString *attributedStringWithEditMention = [attributedString mutableCopy];
        
        NSString *linkActionString = [NSString stringWithFormat:@"%@%@%@", EventFormatterEditedEventLinkAction,
                                      EventFormatterLinkActionSeparator,
                                      event.eventId];
        
        [attributedStringWithEditMention appendAttributedString:
         [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", NSLocalizedStringFromTable(@"event_formatter_message_edited_mention", @"Vector", nil)]
                                         attributes:@{
                                                      NSLinkAttributeName: linkActionString,
                                                      // NOTE: Color is curretly overidden by UIText.tintColor as we use `NSLinkAttributeName`.
                                                      // If we use UITextView.linkTextAttributes to set link color we will also have the issue that color will be the same for all kind of links.
                                                      NSForegroundColorAttributeName: self.editionMentionTextColor,
                                                      NSFontAttributeName: self.editionMentionTextFont
                                                      }]];
        
        attributedString = attributedStringWithEditMention;
    }

    return attributedString;
}

- (NSAttributedString*)attributedStringFromEvents:(NSArray<MXEvent*>*)events withRoomState:(MXRoomState*)roomState error:(MXKEventFormatterError*)error
{
    NSString *displayText;

    if (events.count)
    {
        MXEvent *roomCreateEvent = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", kMXEventTypeStringRoomCreate]].firstObject;
        
        if (roomCreateEvent)
        {
            MXKEventFormatterError tmpError;
            displayText = [super attributedStringFromEvent:roomCreateEvent withRoomState:roomState error:&tmpError].string;

            NSAttributedString *rendered = [self renderString:displayText forEvent:roomCreateEvent];
            NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@"· "];
            [result appendAttributedString:rendered];
            [result setAttributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:13],
                NSForegroundColorAttributeName: ThemeService.shared.theme.textSecondaryColor
            } range:NSMakeRange(0, result.length)];
            //  add one-char space
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            //  add more link
            NSAttributedString *linkMore = [[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"more", @"Vector", nil) attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:13],
                NSForegroundColorAttributeName: ThemeService.shared.theme.tintColor
            }];
            [result appendAttributedString:linkMore];
            return result;
        }
        else if (events[0].eventType == MXEventTypeRoomMember)
        {
            // This is a series for cells tagged with RoomBubbleCellDataTagMembership
            // TODO: Build a complete summary like Riot-web
            displayText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"event_formatter_member_updates", @"Vector", nil), events.count];
        }
    }

    if (displayText)
    {
        // Build the attributed string with the right font and color for the events
        return [self renderString:displayText forEvent:events[0]];
    }

    return [super attributedStringFromEvents:events withRoomState:roomState error:error];
}

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        // Use the secondary bg color to set the background color in the default CSS.
        NSUInteger bgColor = [MXKTools rgbValueWithColor:ThemeService.shared.theme.headerBackgroundColor];
        self.defaultCSS = [NSString stringWithFormat:@" \
                           pre,code { \
                           background-color: #%06lX; \
                           display: inline; \
                           font-family: monospace; \
                           white-space: pre; \
                           -coretext-fontname: Menlo-Regular; \
                           font-size: small; \
                           }", (unsigned long)bgColor];
        
        self.defaultTextColor = ThemeService.shared.theme.textPrimaryColor;
        self.subTitleTextColor = ThemeService.shared.theme.textSecondaryColor;
        self.prefixTextColor = ThemeService.shared.theme.textSecondaryColor;
        self.bingTextColor = ThemeService.shared.theme.noticeColor;
        self.encryptingTextColor = ThemeService.shared.theme.tintColor;
        self.sendingTextColor = ThemeService.shared.theme.textSecondaryColor;
        self.errorTextColor = ThemeService.shared.theme.warningColor;
        self.showEditionMention = YES;
        self.editionMentionTextColor = ThemeService.shared.theme.textSecondaryColor;
        
        self.defaultTextFont = [UIFont systemFontOfSize:15];
        self.prefixTextFont = [UIFont boldSystemFontOfSize:15];
        self.bingTextFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        self.stateEventTextFont = [UIFont italicSystemFontOfSize:15];
        self.callNoticesTextFont = [UIFont italicSystemFontOfSize:15];
        self.encryptedMessagesTextFont = [UIFont italicSystemFontOfSize:15];
        self.emojiOnlyTextFont = [UIFont systemFontOfSize:48];
        self.editionMentionTextFont = [UIFont systemFontOfSize:12];
    }
    return self;
}

- (NSDictionary*)stringAttributesForEventTimestamp
{
    return @{
             NSForegroundColorAttributeName : [UIColor lightGrayColor],
             NSFontAttributeName: [UIFont systemFontOfSize:10]
             };
}

#pragma mark event sender info

- (NSString*)senderDisplayNameForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    NSString *senderName = [super senderDisplayNameForEvent:event withRoomState:roomState];
    
    // Remove the domain from this display name.
    // FIXME: We should use "DisplayNameComponents" struct here in Swift.
    NSRange range = [senderName rangeOfString:@"["];
    if (range.location != NSNotFound)
    {
        senderName = [senderName substringToIndex:range.location];
        senderName = [senderName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return senderName;
}

- (NSString*)senderAvatarUrlForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState
{
    // Override this method to ignore the identicons defined by default in matrix kit.
    
    // Consider first the avatar url defined in provided room state (Note: this room state is supposed to not take the new event into account)
    NSString *senderAvatarUrl = [roomState.members memberWithUserId:event.sender].avatarUrl;
    
    // Check whether this avatar url is updated by the current event (This happens in case of new joined member)
    NSString* membership = event.content[@"membership"];
    if (membership && [membership isEqualToString:@"join"] && [event.content[@"avatar_url"] length])
    {
        // Use the actual avatar
        senderAvatarUrl = event.content[@"avatar_url"];
    }
    
    // We ignore non mxc avatar url (The identicons are removed here).
    if (senderAvatarUrl && [senderAvatarUrl hasPrefix:kMXContentUriScheme] == NO)
    {
        senderAvatarUrl = nil;
    }
    
    return senderAvatarUrl;
}

#pragma mark - Timestamp formatting

- (NSString*)dateStringFromDate:(NSDate *)date withTime:(BOOL)time
{
    // Check the provided date
    if (!date)
    {
        return nil;
    }
    
    // Retrieve today date at midnight
    NSDate *today = [calendar startOfDayForDate:[NSDate date]];
    
    NSTimeInterval interval = -[date timeIntervalSinceDate:today];
    
    if (interval > 60*60*24*364)
    {
        [dateFormatter setDateFormat:@"MMM dd yyyy"];
        
        // Ignore time information here
        return [super dateStringFromDate:date withTime:NO];
    }
    else if (interval > 60*60*24*6)
    {
        [dateFormatter setDateFormat:@"MMM dd"];
        
        // Ignore time information here
        return [super dateStringFromDate:date withTime:NO];
    }
    else if (interval > 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:@"EEE"];
        }
        else
        {
            [dateFormatter setDateFormat:@"EEEE"];
        }
        
        return [super dateStringFromDate:date withTime:time];
    }
    else if (interval > 0)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"%@ %@", NSLocalizedStringFromTable(@"yesterday", @"Vector", nil), [super dateStringFromDate:date withTime:YES]];
        }
        return NSLocalizedStringFromTable(@"yesterday", @"Vector", nil);
    }
    else if (interval > - 60*60*24)
    {
        if (time)
        {
            [dateFormatter setDateFormat:nil];
            return [NSString stringWithFormat:@"%@", [super dateStringFromDate:date withTime:YES]];
        }
        return NSLocalizedStringFromTable(@"today", @"Vector", nil);
    }
    else
    {
        // Date in future
        [dateFormatter setDateFormat:@"EEE MMM dd yyyy"];
        return [super dateStringFromDate:date withTime:time];
    }
}

#pragma mark - Room create predecessor

- (NSAttributedString*)roomCreatePredecessorAttributedStringWithPredecessorRoomId:(NSString*)predecessorRoomId
{
    NSDictionary *roomPredecessorReasonAttributes = @{
                                                      NSFontAttributeName : self.defaultTextFont
                                                      };
    
    NSDictionary *roomLinkAttributes = @{
                                         NSFontAttributeName : self.defaultTextFont,
                                         NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)
                                         };
    
    NSMutableAttributedString *roomPredecessorAttributedString = [NSMutableAttributedString new];
    
    NSString *roomPredecessorReasonString = [NSString stringWithFormat:@"%@\n", NSLocalizedStringFromTable(@"room_predecessor_information", @"Vector", nil)];
    NSAttributedString *roomPredecessorReasonAttributedString = [[NSAttributedString alloc] initWithString:roomPredecessorReasonString attributes:roomPredecessorReasonAttributes];
    
    NSString *predecessorRoomLinkString = NSLocalizedStringFromTable(@"room_predecessor_link", @"Vector", nil);
    NSAttributedString *predecessorRoomLinkAttributedString = [[NSAttributedString alloc] initWithString:predecessorRoomLinkString attributes:roomLinkAttributes];
    
    [roomPredecessorAttributedString appendAttributedString:roomPredecessorReasonAttributedString];
    [roomPredecessorAttributedString appendAttributedString:predecessorRoomLinkAttributedString];
    
    NSRange wholeStringRange = NSMakeRange(0, roomPredecessorAttributedString.length);
    [roomPredecessorAttributedString addAttribute:NSForegroundColorAttributeName value:self.defaultTextColor range:wholeStringRange];
    
    return roomPredecessorAttributedString;
}

#pragma mark - MXRoomSummaryUpdating

- (BOOL)session:(MXSession*)session updateRoomSummary:(MXRoomSummary*)summary withServerRoomSummary:(MXRoomSyncSummary*)serverRoomSummary roomState:(MXRoomState*)roomState
{
    BOOL updated = [super session:session updateRoomSummary:summary withServerRoomSummary:serverRoomSummary roomState:roomState];
    
    // Tchap:
    // - Direct chat: the discussion must keep the display name and the avatar of the other member, even if this member has left.
    // - Room: Do not use by default a member avatar for the room avatar.
    // Note: The boolean `updated` is not modified below because it is already true when we need to apply our changes.
    if (summary.room.isDirect)
    {
        NSArray<MXRoomMember *> *leftMembers = [roomState.members membersWithMembership:MXMembershipLeave];
        if (leftMembers.count)
        {
            MXRoomMember *leftMember = leftMembers.firstObject;
            // The left member display name is available in prevContent.
            NSString *leftMemberDisplayname;
            NSString *leftMemberAvatar;
            MXJSONModelSetString(leftMemberDisplayname, leftMember.originalEvent.prevContent[@"displayname"]);
            MXJSONModelSetString(leftMemberAvatar, leftMember.originalEvent.prevContent[@"avatar_url"]);
            summary.displayname = leftMemberDisplayname;
            summary.avatar = leftMemberAvatar;
        }
        
        // When an invite by email to a direct has been accepted but not joined yet,
        // the displayname of the room is a matrix id
        // We change it here with a more friendly string
        if ([MXTools isMatrixUserIdentifier:summary.displayname])
        {
            summary.displayname = [UserService displayNameFrom:summary.displayname];
        }
    }
    else if (!summary.tc_isServerNotice)
    {
        // Remove the potential member avatar used as the room avatar
        if (!roomState.avatar && summary.avatar)
        {
            summary.avatar = nil;
        }
    }
    
    return updated;
}

- (BOOL)session:(MXSession *)session updateRoomSummary:(MXRoomSummary *)summary withStateEvents:(NSArray<MXEvent *> *)stateEvents roomState:(MXRoomState *)roomState
{
    BOOL ret = [super session:session updateRoomSummary:summary withStateEvents:stateEvents roomState:roomState];
    
    // Store in the room summary some additional information
    ret |= [summary tc_updateWithStateEvents:stateEvents];
    
    return ret;
}

@end
