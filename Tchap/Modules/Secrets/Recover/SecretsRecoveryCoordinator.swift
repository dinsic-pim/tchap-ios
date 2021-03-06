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

final class SecretsRecoveryCoordinator: SecretsRecoveryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let navigationRouter: NavigationRouterType
    private let recoveryMode: SecretsRecoveryMode
    private let recoveryGoal: SecretsRecoveryGoal
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SecretsRecoveryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, recoveryMode: SecretsRecoveryMode, recoveryGoal: SecretsRecoveryGoal, navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.recoveryMode = recoveryMode
        self.recoveryGoal = recoveryGoal
        
        if let navigationRouter = navigationRouter {
            self.navigationRouter = navigationRouter
        } else {
            self.navigationRouter = NavigationRouter(navigationController: TCNavigationController())
        }
    }
    
    // MARK: - Public
    
    func start() {
        
        let rootCoordinator: Coordinator & Presentable
        
        switch self.recoveryMode {
        case .onlyKey:
            rootCoordinator = self.createRecoverFromKeyCoordinator()
        case .passphraseOrKey:
            rootCoordinator = self.createRecoverFromPassphraseCoordinator()
        }
        
        rootCoordinator.start()
        
        self.add(childCoordinator: rootCoordinator)
        
        if self.navigationRouter.modules.isEmpty == false {
            self.navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    private func createRecoverFromKeyCoordinator() -> SecretsRecoveryWithKeyCoordinator {
        let coordinator = SecretsRecoveryWithKeyCoordinator(recoveryService: self.session.crypto.recoveryService, recoveryGoal: self.recoveryGoal)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createRecoverFromPassphraseCoordinator() -> SecretsRecoveryWithPassphraseCoordinator {
        let coordinator = SecretsRecoveryWithPassphraseCoordinator(recoveryService: self.session.crypto.recoveryService, recoveryGoal: self.recoveryGoal)
        coordinator.delegate = self
        return coordinator
    }
    
    private func showRecoverFromKeyCoordinator() {
        let coordinator = self.createRecoverFromKeyCoordinator()
        coordinator.start()
        
        self.navigationRouter.push(coordinator.toPresentable(), animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        self.add(childCoordinator: coordinator)
    }
}

// MARK: - SecretsRecoveryWithKeyCoordinatorDelegate
extension SecretsRecoveryCoordinator: SecretsRecoveryWithKeyCoordinatorDelegate {
    
    func secretsRecoveryWithKeyCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithKeyCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithKeyCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithKeyCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
}

// MARK: - SecretsRecoveryWithPassphraseCoordinatorDelegate
extension SecretsRecoveryCoordinator: SecretsRecoveryWithPassphraseCoordinatorDelegate {
    
    func secretsRecoveryWithPassphraseCoordinatorDidRecover(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidRecover(self)
    }
    
    func secretsRecoveryWithPassphraseCoordinatorDoNotKnowPassphrase(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        self.showRecoverFromKeyCoordinator()
    }
    
    func secretsRecoveryWithPassphraseCoordinatorDidCancel(_ coordinator: SecretsRecoveryWithPassphraseCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorDidCancel(self)
    }
}
