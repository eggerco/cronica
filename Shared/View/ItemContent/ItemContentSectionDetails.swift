//
//  ItemContentSectionDetails.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 30/11/22.
//

import SwiftUI

struct ItemContentSectionDetails: View {
	let title: String
	let items: [ItemContent]
	@State private var showPopup = false
	@State private var popupType: ActionPopupItems?
	@StateObject private var settings = SettingsStore.shared
	var body: some View {
		VStack {
#if os(tvOS)
			cardStyle
#else
			switch settings.sectionStyleType {
			case .list: listStyle
			case .card: cardStyle
			case .poster: ScrollView { posterStyle }
			}
#endif
		}
		.navigationTitle(title)
        .scrollBounceBehavior(.basedOnSize)
		.actionPopup(isShowing: $showPopup, for: popupType)
#if os(iOS)
		.navigationBarTitleDisplayMode(.large)
#endif
	}
	
	private var listStyle: some View {
		Form {
			Section {
				List {
                    ForEach(items) { item in
                        ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType)
                    }
				}
			}
		}
#if os(macOS)
		.formStyle(.grouped)
#endif
	}
	
	private var cardStyle: some View {
		ScrollView {
			LazyVGrid(columns: DrawingConstants.columns, spacing: 20) {
                ForEach(items) { item in
                    ItemContentCardView(item: item, showPopup: $showPopup, popupType: $popupType)
                        .buttonStyle(.plain)
                }
			}
			.padding()
		}
	}
	
#if !os(tvOS)
	private var posterStyle: some View {
#if os(iOS)
		LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactColumns : DrawingConstants.columns,
				  spacing: settings.isCompactUI ? 10 : 20) {
            ForEach(items) { item in
                ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
            }
		}.padding(.all, settings.isCompactUI ? 10 : nil)
#elseif os(macOS) || os(visionOS)
		LazyVGrid(columns: DrawingConstants.posterColumns, spacing: 20) {
			ForEach(items) { item in
				ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
					.buttonStyle(.plain)
			}
		}
		.padding()
#endif
	}
#endif
}

#Preview {
    ItemContentSectionDetails(title: "Preview Items",
                              items: ItemContent.examples)
}

private struct DrawingConstants {
#if os(macOS) || os(tvOS) || os(visionOS)
	static let columns = [GridItem(.adaptive(minimum: 240))]
#else
	static let columns: [GridItem] = [GridItem(.adaptive(minimum: 160))]
#endif
	static let compactColumns: [GridItem] = [GridItem(.adaptive(minimum: 80))]
#if os(macOS) || os(visionOS)
	static let posterColumns = [GridItem(.adaptive(minimum: 160))]
	static let cardColumns = [GridItem(.adaptive(minimum: 240))]
#endif
}
