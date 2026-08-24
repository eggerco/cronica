//
//  ReviewAppBanner.swift
//  Story
//
//  Created by Alexandre Madeira on 03/12/23.
//

import SwiftUI
import StoreKit

#if os(iOS)
struct CallToReviewAppView: View {
    @Environment(\.requestReview) var requestReview
    @Binding var showView: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Enjoying Cronica?")
                    .font(.title3)
                    .fontDesign(.rounded)
                    .padding(.leading)
                    .fontWeight(.semibold)
                Text("Leave a Review on the App Store!")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fontDesign(.rounded)
                    .padding(.leading)
                    .padding(.bottom, 4)
                    .fontWeight(.regular)
                Button("Review App") {
                    requestReview()
                }
                .padding(.leading)
                .padding(.bottom, 4)
            }
            Spacer()
            VStack {
                Button {
                    withAnimation { showView = false }
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding(.trailing)
        }.padding(.vertical)
    }
}

#Preview {
    CallToReviewAppView(showView: .constant(true))
}
#endif
