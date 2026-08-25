//
//  ItemContentCustomListSelector.swift
//  Cronica
//
//  Created by Alexandre Madeira on 21/03/23.
//

import SwiftUI
import NukeUI

struct ItemContentCustomListSelector: View {
    @State private var item: WatchlistItem?
    let contentID: String
    @Binding var showView: Bool
    let title: String
    let image: URL?
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.isPin, ascending: false),
                                    NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
                  animation: .default) private var lists: FetchedResults<CustomList>
    @State private var selectedList: CustomList?
    @State private var isLoading = false
    @State private var settings = SettingsStore.shared
    var body: some View {
        NavigationStack {
            Form {
                if isLoading {
                    ProgressView()
                } else {
                    
                    Section {
                        VStack(alignment: .center) {
                            HStack(alignment: .center) {
                                LazyImage(url: image) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        ZStack {
                                            Rectangle().fill(.gray.gradient)
                                            Image(systemName: "tv")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 50, alignment: .center)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(width: 150, height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                            }
                            .frame(maxWidth: .infinity)
                            
                            
                            
                            Text(title)
                                .fontWeight(.semibold)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                            
                            if let item  {
                                Text(item.itemMedia.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    
                    if !lists.isEmpty {
                        Section {
                            List {
                                ForEach(lists) { list in
                                    AddToListRow(list: list, item: $item, showView: $showView)
                                        .padding(.vertical, 4)
                                }
                            }
                        } header: { Text("Your Lists") }
                    } else {
                        Section {
                            NavigationLink {
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                                NewCustomListView(presentView: $showView, preSelectedItem: item, newSelectedList: $selectedList)
#elseif os(macOS)
                                NewCustomListView(isPresentingNewList: $showView,
                                                  presentView: $showView,
                                                  preSelectedItem: item,
                                                  newSelectedList: $selectedList)
#endif
                            } label: {
                                ContentUnavailableView("Create a List",
                                                       systemImage: "plus.rectangle.on.rectangle.fill",
                                                       description: Text("To add an item on a list, create a new one."))
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .onAppear(perform: load)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
#if !os(visionOS) && !os(tvOS)
            .scrollContentBackground(settings.disableTranslucent ? .visible : .hidden)
            .background {
                TranslucentBackground(image: image, useLighterMaterial: true)
            }
#endif
#if os(macOS)
            .formStyle(.grouped)
#endif
            .navigationTitle("Add to...")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .nativeSheetDismissToolbar { showView.toggle() }
            .toolbar {
#if os(iOS) || os(visionOS)
                ToolbarItem(placement: .topBarLeading) {
                    if !lists.isEmpty { newList }
                }
#elseif os(macOS)
                ToolbarItem(placement: .automatic) {
                    if !lists.isEmpty { newList }
                }
#endif
            }
        }
#if os(iOS)
        .appTint()
        .appTheme()
#elseif os(macOS)
        .frame(width: 500, height: 600, alignment: .center)
#endif
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private func load() {
        guard let content = PersistenceController.shared.fetch(for: contentID) else { return }
        self.item = content
    }
    
    private var newList: some View {
        NavigationLink {
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
            NewCustomListView(presentView: $showView, preSelectedItem: item, newSelectedList: $selectedList)
#elseif os(macOS)
            NewCustomListView(isPresentingNewList: $showView,
                              presentView: $showView,
                              preSelectedItem: item,
                              newSelectedList: $selectedList)
#endif
        } label: {
            Label("New List", systemImage: "plus.rectangle.on.rectangle")
        }
    }
}

