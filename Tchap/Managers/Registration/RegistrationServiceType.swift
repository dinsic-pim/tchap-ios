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

protocol RegistrationServiceType {     
    
    /// Submit registration verification email and return third PID credentials for registration.
    ///
    /// - Parameters:
    ///   - email: The user email.
    ///   - completion: A closure called when the operation succeeds. Provide the three PID credentials.
    func submitRegistrationEmailVerification(to email: String, completion: @escaping (MXResponse<ThreePIDCredentials>) -> Void)
        
    /// Register user on homeserver.
    ///
    /// - Parameters:
    ///   - threePIDCredentials: The user three PID credentials given by email verification.
    ///   - password: The user password.
    ///   - deviceDisplayName: The current device display name.
    ///   - completion: A closure called when the operation complete. Provide the authenticated user id when succeed.
    func register(with threePIDCredentials: ThreePIDCredentials, password: String, deviceDisplayName: String, completion: @escaping (MXResponse<String>) -> Void)
    
    /// Cancel pending registration request.
    func cancelPendingRegistration()
}
