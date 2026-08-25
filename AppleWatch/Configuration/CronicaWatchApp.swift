//
//  CronicaWatchApp.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 02/08/22.
//

import SwiftUI

@main
struct CronicaWatchApp: App {
    var persistence = PersistenceController.shared
    @AppStorage("selectedView") var selectedView: Screens?
    init() {
        CronicaTelemetry.shared.setup()
    }
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(selection: $selectedView) {
                    ForEach(Screens.allCases) { screen in
                        Label(screen.title, systemImage: screen.toSFSymbols).tag(screen)
                    }
                }
            } detail: {
                switch selectedView {
                case .trending: TrendingView().environment(\.managedObjectContext, persistence.container.viewContext)
                case .upcoming: UpcomingListView().environment(\.managedObjectContext, persistence.container.viewContext)
                case .watchlist: WatchlistView().environment(\.managedObjectContext, persistence.container.viewContext)
                case .upNext: UpNextListView().environment(\.managedObjectContext, persistence.container.viewContext)
                default: WatchlistView().environment(\.managedObjectContext, persistence.container.viewContext)
                }
            }
        }
    }
}
