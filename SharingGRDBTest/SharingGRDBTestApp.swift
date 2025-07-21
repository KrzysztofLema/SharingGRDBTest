//
//  SharingGRDBTestApp.swift
//  SharingGRDBTest
//
//  Created by Krzysztof Lema on 20/07/2025.
//

import SharingGRDB
import SwiftUI

@main
struct ModernPersistenceApp: App {
    @Dependency(\.context) var context
    
    init() {
        if context == .live {
            prepareDependencies {
                $0.defaultDatabase = try! appDatabase()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if context == .live {
                NavigationStack {
                    FinanceTrackerView(
                        store: .init(
                            initialState: FinanceTracker.State(),
                            reducer: {
                                FinanceTracker()
                            }
                        )
                    )
                }
            }
        }
    }
}
