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

import UIKit
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PushNotificationServiceDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    
    private var appCoordinator: AppCoordinatorType!
    private var rootRouter: RootRouterType!
    
    private var legacyAppDelegate: LegacyAppDelegate {
        return AppDelegate.theDelegate()
    }
    
    // MARK: - Public
    
    /// Call the Riot legacy AppDelegate
    @objc class func theDelegate() -> LegacyAppDelegate {
        return LegacyAppDelegate.the()
    }
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return self.legacyAppDelegate.application(application, willFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Setup window
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        // Call legacy AppDelegate
        self.legacyAppDelegate.window = window
        self.legacyAppDelegate.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Create AppCoordinator
        self.rootRouter = RootRouter(window: window)
        self.appCoordinator = AppCoordinator(router: self.rootRouter)
        self.appCoordinator.start()
        
        // Setup default UIAppearance
        Appearance.setup()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.legacyAppDelegate.applicationDidBecomeActive(application)        
        
        self.appCoordinator.checkMinAppVersionRequirements()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {        
        self.legacyAppDelegate.applicationWillResignActive(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.legacyAppDelegate.applicationDidEnterBackground(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.legacyAppDelegate.applicationWillEnterForeground(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.legacyAppDelegate.applicationWillTerminate(application)
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        self.legacyAppDelegate.applicationDidReceiveMemoryWarning(application)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return self.appCoordinator.handleUserActivity(userActivity, application: application)
    }
    
    // MARK: - Push Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.legacyAppDelegate.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.legacyAppDelegate.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.legacyAppDelegate.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    @objc func pushNotificationService(_ pushNotificationService: PushNotificationService, shouldNavigateToRoomWithId roomId: String) {
        self.legacyAppDelegate.lastNavigatedRoomIdFromPush = roomId
        _ = self.appCoordinator.resumeBySelectingRoom(with: roomId)
    }
}
