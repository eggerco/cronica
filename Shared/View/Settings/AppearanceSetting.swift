//
//  AppearanceSetting.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 13/12/22.
//

import SwiftUI

struct AppearanceSetting: View {
    @StateObject private var store = SettingsStore.shared
    var body: some View {
        Form {
#if os(iOS)
            if UIDevice.isIPhone {
                Section("Details Page") {
                    Toggle("Prefer Poster in Details Page", isOn: $store.usePostersAsCover)
                }
            }
#endif
            
#if !os(tvOS)
            Section("Style Preferences") {
                Picker(selection: $store.sectionStyleType) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Section's Details Style")
                }
                Picker(selection: $store.listsDisplayType) {
                    ForEach(ItemContentListPreferredDisplayType.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Horizontal List Style")
                }

            }
#endif
#if os(iOS)
            if UIDevice.isIPhone {
                Section {
                    Toggle(isOn: $store.isCompactUI) {
                        Text("Compact UI")
                        Text("Reduce some UI elements size to accommodate more items on the screen")
                    }
                }
            }
#endif
            
#if os(iOS)
            Section("App Theme") {
                Picker(selection: $store.currentTheme) {
                    ForEach(AppTheme.allCases) { item in
                        Text(item.localizableName).tag(item)
                    }
                } label: {
                    Text("Theme")
                }
                .pickerStyle(.menu)
            }
            
            Section("Accent Color") {
                accentColor
            }
            .listRowInsets(EdgeInsets())
#endif
            
            Section {
                Toggle(isOn: $store.disableTranslucent) {
                    Text("Disable Translucent Background")
                }
            }
        }
        .navigationTitle("Appearance")
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private var accentColor: some View {
        VStack(alignment: .leading) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(AppThemeColors.allCases) { item in
                            colorButton(for: item)
                                .padding(.leading, item == AppThemeColors.allCases.first ? 16 : 0)
                                .padding(.trailing, item == AppThemeColors.allCases.last ? 16 : 0)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.vertical, 6)
                    .onAppear {
                        withAnimation { proxy.scrollTo(store.appTheme, anchor: .topLeading) }
                    }
                }
            }
        }
    }
    
    private func colorButton(for item: AppThemeColors) -> some View {
        Button {
            withAnimation {
                store.appTheme = item
            }
        } label: {
            ZStack {
                Circle()
                    .fill(item.color)
                if store.appTheme == item {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .imageScale(.large)
                        .foregroundColor(.white.opacity(0.6))
                        .fontWeight(.black)
                    
                }
            }
            .frame(width: 30)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(item == store.appTheme ? [.isButton, .isSelected] : .isButton )
        .padding(.horizontal, 4)
    }
}

#Preview {
    AppearanceSetting()
}
