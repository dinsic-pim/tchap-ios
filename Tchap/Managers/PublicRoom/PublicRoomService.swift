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

import Foundation
import RxSwift

/// `PublicRoomService` implementation of `PublicRoomServiceType` is used to get public rooms from Tchap platforms.
final class PublicRoomService: PublicRoomServiceType {
    
    // MARK: - Properties
    
    private let session: MXSession
    private let homeServersStringURL: [String]
    
    private var currentHomeServer: String? {
        return self.session.matrixRestClient.homeserver
    }
    
    // MARK: - Setup
    
    init(homeServersStringURL: [String], session: MXSession) {
        self.homeServersStringURL = homeServersStringURL
        self.session = session
    }
    
    // MARK: - Public
    
    func getPublicRooms(searchText: String? = nil) -> Observable<[MXPublicRoom]> {
        
        let publicRoomsRequests: [Observable<[MXPublicRoom]>] = self.homeServersStringURL.map { (homeServerStringURL) -> Observable<[MXPublicRoom]> in
            
            let homeServer: String?
            
            // If the homeserver is the same as current one, pass nil to request in order to get public rooms from current homeserver
            if self.isCurrentHomeServer(homeServerStringURL) {
                homeServer = nil
            } else {
                homeServer = homeServerStringURL
            }
            
            return self.getPublicRooms(from: homeServer, searchText: searchText)
            .catchError({ (error) -> Observable<[MXPublicRoom]> in
                print("[PublicRoomService]: Fail to retrieve public rooms for homeserver: \(homeServerStringURL)")
                // Return an empty array when request fail
                return Observable.just([])
            })
        }
        
        return Observable.merge(publicRoomsRequests) // Perform all requests in parallel
            .flatMap({ (publicRooms) -> Observable<MXPublicRoom> in // Get one public rooms request response, i.e. [MXPublicRoom], and emits one MXPublicRoom for each item of the array.
                return Observable.from(publicRooms)
            })
            .toArray() // Accumulate previous MXPublicRoom items in one array. Emits one array of MXPublicRoom when all requests complete.
    }
    
    // MARK: - Private

    private func getPublicRooms(from homeServerStringURL: String?, searchText: String? = nil) -> Observable<[MXPublicRoom]> {
        return Observable.create { (observer) -> Disposable in

            let httpOperation = self.session.matrixRestClient.publicRooms(onServer: homeServerStringURL, limit: 20, since: nil, filter: searchText, thirdPartyInstanceId: nil, includeAllNetworks: false) { (response) in
                switch response {
                case .success(let publicRoomsResponse):
                    let publicRooms = publicRoomsResponse.chunk ?? []
                    
                    observer.on(.next(publicRooms))
                    observer.on(.completed)
                case .failure(let error):
                    print("[PublicRoomService]: Fail to retrieve public rooms for homeserver: \(String(describing: homeServerStringURL))")
                    observer.on(.error(error))
                }
            }

            return Disposables.create {
                httpOperation.cancel()
            }
        }
    }
    
    private func isCurrentHomeServer(_ homeServer: String) -> Bool {
        guard let currentHomeServer = self.currentHomeServer else {
            return false
        }
        return currentHomeServer.contains(homeServer)
    }
}