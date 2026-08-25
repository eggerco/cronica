//
//  EditCustomList.swift
//  Cronica
//
//  Created by Alexandre Madeira on 18/02/23.
//

import SwiftUI

struct EditCustomList: View {
#if os(macOS)
    @Binding var isPresentingNewList: Bool
#endif
    @State var list: CustomList
    @State private var title = String()
    @State private var note = String()
    @State private var hasUnsavedChanges = false
    @State private var disableSaveButton = true
    @Binding var showListSelection: Bool
    @State private var itemsToRemove = Set<WatchlistItem>()
    @State private var showPublishConfirmation = false
    @State private var canPublish = false
    @State private var isPublishing = false
    @State private var pinOnHome = false
    @State private var askConfirmationForDeletion = false
    @State private var isDeleted = false
    @State private var itemsToAdd = Set<WatchlistItem>()
    var body: some View {
        Form {
            if isDeleted {
                Text("This list has been deleted.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else {
                Section {
                    TextField("Title", text: $title)
                    TextField("Description", text: $note)
                }
                
                Section {
                    Toggle("Favorite", isOn: $pinOnHome)
                    Text("Favorite lists appear first when adding titles and on Home.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                NavigationLink("Select Items",
                               destination: NewCustomListItemSelector(itemsToAdd: $itemsToAdd, list: list))
                
                if !list.itemsSet.isEmpty {
                    NavigationLink("Remove Items",
                                   destination: EditCustomListItemSelector(list: list, itemsToRemove: $itemsToRemove))
                }
                
                Section {
                    Button("Delete", role: .destructive) {
                        askConfirmationForDeletion = true
                    }
                    .foregroundColor(.red)
#if os(macOS)
                    .buttonStyle(.link)
#endif
                }
                .confirmationDialog("Are You Sure?",
                                    isPresented: $askConfirmationForDeletion,
                                    titleVisibility: .visible) {
                    Button("Confirm", role: .destructive) {
                        isDeleted = true
                        PersistenceController.shared.deleteList(list, includingWatchlistItems: false)
                    }
                    Button("Confirm and Delete Items", role: .destructive) {
                        isDeleted = true
                        PersistenceController.shared.deleteList(list, includingWatchlistItems: true)
                    }
                }
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
        .onAppear {
            title = list.itemTitle
            note = list.notes ?? ""
            pinOnHome = list.isPin
            if SettingsStore.shared.isUserConnectedWithTMDb && !list.isSyncEnabledTMDB {
                canPublish = true
            }
        }
        .onChange(of: title) { _, newValue in
            if newValue != list.itemTitle {
                disableSaveButton = false
            }
        }
        .onChange(of: itemsToAdd) {
            disableSaveButton = false
        }
        .onChange(of: note) { _, newValue in
            if newValue != list.notes {
                disableSaveButton = false
            }
        }
        .onChange(of: pinOnHome) { _, newValue in
            if newValue != list.isPin { disableSaveButton = false }
        }
        .onChange(of: itemsToRemove) {
            if !itemsToRemove.isEmpty {
                if disableSaveButton != false { disableSaveButton = false }
            }
        }
        .onAppear {
#if os(macOS)
            isPresentingNewList = true
#endif
        }
        .onDisappear {
#if os(macOS)
            isPresentingNewList = false
#endif
        }
        .toolbar {
            Button("Save", action: save).disabled(disableSaveButton)
        }
        .navigationTitle(list.itemTitle)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

extension EditCustomList {
    private func save() {
        let persistence = PersistenceController.shared
        if list.title != title {
            persistence.updateListTitle(of: list, with: title)
        }
        if list.notes != note {
            persistence.updateListNotes(of: list, with: note)
        }
        if !itemsToRemove.isEmpty {
            persistence.removeItemsFromList(of: list, with: itemsToRemove)
        }
        if list.isPin != pinOnHome {
            persistence.updatePinOnHome(of: list)
        }
        if !itemsToAdd.isEmpty {
            persistence.addItemsToList(items: itemsToAdd, list: list)
        }
        showListSelection = false
    }
}


