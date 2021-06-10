/*
 Copyright 2019 New Vector Ltd
 
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

import UIKit

@objcMembers class ShareRoomsDiscussionCell: RoomsCell {

    @IBOutlet private weak var domainLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.tc_makeCircle()
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        if let displayName = self.roomCellData?.roomDisplayname {
            let displayNameComponents = DisplayNameComponents(displayName: displayName)
            self.titleLabel.text = displayNameComponents.name
            self.domainLabel.text = displayNameComponents.domain
        }
    }
    
    override func update(style: Style) {
        super.update(style: style)
        self.domainLabel.textColor = style.primarySubTextColor
        
        self.contentView.backgroundColor = style.backgroundColor
    }
    
    func renderedCellData() -> MXKCellData! {
        return (roomCellData as! MXKCellData)
    }
}