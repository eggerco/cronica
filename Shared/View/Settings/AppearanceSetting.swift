//
//  AppearanceSetting.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 13/12/22.
//

import SwiftUI

struct AppearanceSetting: View {
    @StateObject private var store = SettingsStore.shared
#if os(iOS)
    @StateObject private var icons = IconModel()
#endif
    var body: some View {
        Form {
#if os(iOS) || os(macOS)
            Section {
                Toggle("Prefer Poster in Details Page", isOn: $store.usePostersAsCover)
            } header: {
                Text("Details Page")
            } footer: {
                Text("By default, details use a full-bleed cover image. Turn this on to keep the classic poster layout.")
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
            
            if UIDevice.isIPhone {
                Section("App Icon") {
                    iconsGrid
                }
            }
#endif
            
            Section {
                Toggle(isOn: $store.disableTranslucent) {
                    Text("Disable Translucent Background")
                }
            } footer: {
                Text("Translucent artwork behind details helps set a cinematic mood. Disable it for a flatter look.")
            }
        }
        .navigationTitle("Appearance")
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    /// Prefer cinematic reds that match the popcorn icons; keep the rest after.
    private var accentColorOptions: [AppThemeColors] {
        let preferred: [AppThemeColors] = [.cherry, .rubyRed, .coral, .fireballRed, .burntOrange]
        return preferred + AppThemeColors.allCases.filter { !preferred.contains($0) }
    }

    private var accentColor: some View {
        VStack(alignment: .leading) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(accentColorOptions) { item in
                            colorButton(for: item)
                                .padding(.leading, item == accentColorOptions.first ? 16 : 0)
                                .padding(.trailing, item == accentColorOptions.last ? 16 : 0)
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
        .accessibilityLabel(Text(String(describing: item).capitalized))
        .accessibilityAddTraits(item == store.appTheme ? [.isButton, .isSelected] : .isButton )
        .padding(.horizontal, 4)
    }
    
#if os(iOS)
    private var iconsGrid: some View {
        HStack {
            ForEach(Icon.allCases) { icon in
                Button {
                    withAnimation { icons.updateAppIcon(to: icon) }
                } label: {
                    Image(uiImage: icon.preview)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: CronicaDesign.Radius.media)
                                .stroke(store.appTheme.color, lineWidth: icons.selectedAppIcon == icon ? 6 : 0)
                        )
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous))
                        .padding(.trailing)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(icon.description)
                .accessibilityAddTraits(icons.selectedAppIcon == icon ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.vertical, 4)
    }
#endif
}

#Preview {
    AppearanceSetting()
}
