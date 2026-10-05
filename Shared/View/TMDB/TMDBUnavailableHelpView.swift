//
//  TMDBUnavailableHelpView.swift
//  Cronica
//

import SwiftUI

/// Explains TMDB reachability failures (geo-block, ISP/DNS block) without claiming a specific country.
struct TMDBUnavailableHelpView: View {
    var body: some View {
        helpForm
            .navigationTitle("Can't Reach TMDB")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 360, minHeight: 420)
#endif
    }

    @ViewBuilder
    private var helpForm: some View {
        Form {
            Section {
                Text("Cronica loads movies, TV shows, and artwork from The Movie Database (TMDB). If Home is empty or connecting a TMDB account fails, this device cannot reach TMDB — even when other apps work.")
            }

            Section("Why this happens") {
                Text("TMDB blocks access from some countries, including Russia and Belarus. Some internet providers also block TMDB.")
            }

            Section("What you can try") {
                Text("Open themoviedb.org in Safari on this device. If the site does not load, Cronica cannot load the catalog on this network.")
                Text("A VPN or a different DNS server (such as Quad9 or Google) sometimes restores access.")
                Text("Titles, notes, and lists already saved in Cronica stay on this device and in iCloud. Only the online catalog and TMDB account sync need TMDB.")
            }

            Section {
                Link("Open TMDB Website", destination: URL(string: "https://www.themoviedb.org")!)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TMDBUnavailableHelpView()
    }
}
