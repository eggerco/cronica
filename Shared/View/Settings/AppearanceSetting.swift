//
//  AppearanceSetting.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 13/12/22.
//

import SwiftUI

struct AppearanceSetting: View {
    @StateObject private var store = SettingsStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var body: some View {
        Form {
#if os(iOS)
            if horizontalSizeClass == .compact {
                CronicaFormSection("Details Page") {
                    Toggle(isOn: $store.usePostersAsCover) {
                        CronicaFormText("Prefer Poster in Details Page")
                    }
                }
            }
#endif
            
#if !os(tvOS)
            CronicaFormSection("Style Preferences") {
                Picker(selection: $store.sectionStyleType) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    CronicaFormText("Section's Details Style")
                }
                Picker(selection: $store.listsDisplayType) {
                    ForEach(ItemContentListPreferredDisplayType.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    CronicaFormText("Horizontal List Style")
                }

            }
#endif
#if os(iOS)
            if horizontalSizeClass == .compact {
                Section {
                    Toggle(isOn: $store.isCompactUI) {
                        CronicaFormToggleLabel(
                            title: "Compact UI",
                            subtitle: "Reduce some UI elements size to accommodate more items on the screen"
                        )
                    }
                }
            }
#endif
            
#if os(iOS)
            CronicaFormSection("App Theme") {
                Picker(selection: $store.currentTheme) {
                    ForEach(AppTheme.allCases) { item in
                        Text(item.localizableName).tag(item)
                    }
                } label: {
                    CronicaFormText("Theme")
                }
                .pickerStyle(.menu)
            }
            
            CronicaFormSection("Accent Color") {
                accentColor
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
#endif
            
            Section {
                Toggle(isOn: $store.disableTranslucent) {
                    CronicaFormText("Disable Translucent Background")
                }
            }
        }
        .navigationTitle("Appearance")
        .cronicaSettingsForm()
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
