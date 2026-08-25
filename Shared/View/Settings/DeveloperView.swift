//
//  DeveloperView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 29/08/22.
//
#if os(iOS) || os(macOS) || os(visionOS)
import SwiftUI
import CoreData

/// This view provides quick information and utilities to the developer.
struct DeveloperView: View {
    @State private var item: ItemContent?
    @State private var person: Person?
    @State private var itemIdField = ""
    @State private var itemMediaType: MediaType = .movie
    @State private var isFetching = false
    @State private var isFetchingAll = false
    @State private var userAccessId = String()
    @State private var userAccessToken = String()
    @State private var v3SessionID = String()
    private let persistence = PersistenceController.shared
    private let service = NetworkService.shared
    @State private var showOnboarding = false
    @AppStorage("launchCount") var launchCount: Int = 0
    @AppStorage("askedForReview") var askedForReview = false
    @State private var isUserSignedInWithTMDB = false
    @State private var cloudKitSchemaMessage = ""
    var body: some View {
        Form {
            Section("Network") {
                TextField("ID", text: $itemIdField)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                Picker("Media Type", selection: $itemMediaType) {
                    ForEach(MediaType.allCases) { media in
                        Text(media.title).tag(media)
                    }
                }
                Button {
                    Task {
                        if !itemIdField.isEmpty {
                            await MainActor.run {
                                withAnimation { isFetching = false }
                            }
                            if itemMediaType != .person {
                                guard let itemId = Int(itemIdField) else { return }
                                let item = try? await service.fetchItem(id: itemId, type: itemMediaType)
                                if let item {
                                    self.item = item
                                }
                            } else {
                                guard let personId = Int(itemIdField) else { return }
                                let person = try? await service.fetchPerson(id: personId)
                                guard let person else { return }
                                self.person = person
                            }
                        }
                        await MainActor.run {
                            withAnimation { isFetching = false }
                        }
                    }
                } label: {
                    if isFetching {
                        CenterHorizontalView {
                            ProgressView()
                        }
                    } else {
                        Text("Fetch")
                    }
                }
#if os(macOS)
                .buttonStyle(.link)
#endif
            }
            
#if !os(macOS)
            Section("Presentation") {
                Button("Show Onboard") {
                    showOnboarding.toggle()
                }
                .sheet(isPresented: $showOnboarding) {
                    NavigationStack {
                        WelcomeView()
                            .interactiveDismissDisabled(false)
                    }
#if os(macOS)
                    .frame(width: 500, height: 700, alignment: .center)
#endif
                }
#if os(macOS)
                .buttonStyle(.link)
#endif
            }
#endif
            
            Section {
                Text("User Region: \(Locale.userRegion)")
                Text("User Lang: \(Locale.userLang)")
                Text("Last maintenance: \(BackgroundManager.shared.lastMaintenance?.convertDateToString() ?? "Nil")")
                Text("Last watching refresh: \(BackgroundManager.shared.lastWatchingRefresh?.convertDateToString() ?? "Nil")")
                Text("Last upcoming refresh: \(BackgroundManager.shared.lastUpcomingRefresh?.convertDateToString() ?? "Nil")")
                Text("Asked for review: \(askedForReview.description)")
                Button("Reset asked for review") { askedForReview = false }
            }

            Section("CloudKit") {
                Text("After adding Core Data attributes (e.g. watchedDate), run Initialize CloudKit Schema once on a signed-in development build, then promote the schema in CloudKit Console for production.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Initialize CloudKit Schema") {
                    cloudKitSchemaMessage = persistence.initializeCloudKitDevelopmentSchema()
                }
                if !cloudKitSchemaMessage.isEmpty {
                    Text(cloudKitSchemaMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
        }
        .navigationTitle("Developer Options")
        .sheet(item: $item) { item in
            NavigationStack {
                ItemContentDetails(title: item.itemTitle, id: item.id, type: item.itemContentMedia, handleToolbar: true)
                    .toolbar {
#if os(iOS)
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack {
                                Button("Done") {
                                    self.item = nil
                                }
                                Menu {
                                    Button {
                                        let watchlist = PersistenceController.shared.fetch(for: item.itemContentID)
                                        if let watchlist {
                                            CronicaTelemetry.shared.handleMessage("WatchlistItem: \(watchlist as Any)",
                                                                                  for: "DeveloperView.printObject")
                                        }
                                        CronicaTelemetry.shared.handleMessage("ItemContent: \(item as Any)",
                                                                              for: "DeveloperView.printObject")
                                    } label: {
                                        Label("Send Object to Developer", systemImage: "hammer.circle.fill")
                                    }
                                } label: {
                                    Image(systemName: "hammer")
                                }
                            }
                        }
#else
                        Button("Done") { self.item = nil }
#endif
                    }
                    .navigationDestination(for: ItemContent.self) { item in
                        ItemContentDetails(title: item.itemTitle, id: item.id, type: item.itemContentMedia)
                    }
                    .navigationDestination(for: Person.self) { item in
                        PersonDetailsView(name: item.name, id: item.id)
                    }
            }
        }
        .sheet(item: $person) { item in
            NavigationStack {
                PersonDetailsView(name: item.name, id: item.id)
                    .toolbar {
                        ToolbarItem {
                            Button("Done") {
                                self.person = nil
                            }
                        }
                    }
                    .navigationDestination(for: ItemContent.self) { item in
                        ItemContentDetails(title: item.itemTitle, id: item.id, type: item.itemContentMedia)
                    }
                    .navigationDestination(for: Person.self) { item in
                        PersonDetailsView(name: item.name, id: item.id)
                    }
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    DeveloperView()
}
#endif
