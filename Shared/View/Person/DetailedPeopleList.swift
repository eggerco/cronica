//
//  DetailedPeopleList.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 21/01/23.
//

import SwiftUI
import NukeUI

struct DetailedPeopleList: View {
    let items: [Person]
    var title: String = String(localized: "Cast & Crew")
    @State private var query = ""
    @State private var filteredItems = [Person]()
    var body: some View {
        Form {
            if query.isEmpty, filteredItems.isEmpty {
                Section {
                    List {
                        ForEach(items, id: \.personListID) { item in
                            PersonItemRow(person: item)
                        }
                    }
                }
            } else {
                if !query.isEmpty, filteredItems.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    Section {
                        List {
                            ForEach(filteredItems, id: \.personListID) { item in
                                PersonItemRow(person: item)
                            }
                        }
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .task(id: query) { await search() }
#if os(iOS)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: items.count > 4 ? .always : .automatic))
#elseif os(macOS)
        .searchable(text: $query, placement: .toolbar)
        .formStyle(.grouped)
#endif
        .autocorrectionDisabled()
    }
    
}

extension DetailedPeopleList {
    private func search() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        if !filteredItems.isEmpty { filteredItems.removeAll() }
        filteredItems.append(contentsOf: items.filter {
            ($0.name.localizedStandardContains(query)) as Bool
            || ($0.name.localizedStandardContains(query)) as Bool
            || ($0.personRole?.localizedStandardContains(query) ?? false) as Bool
        })
    }
}

#Preview {
    DetailedPeopleList(items: ItemContent.example.credits?.cast ?? [])
}

private struct PersonItemRow: View {
    let person: Person
    var body: some View {
        NavigationLink(value: person) {
            HStack {
                LazyImage(url: person.personImage) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.gradient)
                            Image(systemName: "person")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 60, height: 60, alignment: .center)
                    }
                }
                .frame(width: 60)
                .clipShape(Circle())
                .shadow(radius: 2)
                .padding(.trailing)
                VStack(alignment: .leading) {
                    Text(person.name)
                        .lineLimit(1)
                    if let role = person.personRole {
                        Text(role)
                            .lineLimit(1)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 70)
#if os(macOS) || os(iOS)
            .contextMenu {
                ShareLink(item: person.itemURL)
            }
#endif
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(person.name))
    }
}
