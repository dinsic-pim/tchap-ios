// File created from FlowTemplate
// $ createRootCoordinator.sh Favourites Favourites FavouriteMessages
/*
 Copyright 2020 New Vector Ltd
 
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

import Foundation

protocol FavouritesCoordinatorDelegate: class {
    func favouritesCoordinatorDidComplete(_ coordinator: FavouritesCoordinatorType)
    func favouritesCoordinator(_ coordinator: FavouritesCoordinatorType, didShowRoomWithId roomId: String, onEventId eventId: String)
    func favouritesCoordinator(_ coordinator: FavouritesCoordinatorType, handlePermalinkFragment fragment: String) -> Bool
}

/// `FavouritesCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol FavouritesCoordinatorType: Coordinator, Presentable {
    var delegate: FavouritesCoordinatorDelegate? { get }
}
