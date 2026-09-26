//
//  Sidebar.swift
//  Listr
//
//  Created by Felix on 10/18/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

enum SidebarItem: Hashable {
    case all
    case status(PostcardStatus)
    case batch(id: String)
}

struct Sidebar: View {
    @Binding var selection: SidebarItem?
    let batches: [PostcardBatch]
    @ObservedObject var auth: AuthService

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                Label("All Postcards", systemImage: "photo.stack")
                    .tag(SidebarItem.all)

                ForEach(PostcardStatus.allCases, id: \.self) { status in
                    Label {
                        Text(status.rawValue.capitalized)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(status.color)
                    }
                    .tag(SidebarItem.status(status))
                }
            }

            Section("Batches") {
                ForEach(batches.prefix(10), id: \.id) { batch in
                    if let id = batch.id {
                        Label(batch.scannedAt.formatted(date: .abbreviated, time: .omitted), systemImage: "tray")
                            .tag(SidebarItem.batch(id: id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()

                SidebarUserProfile(user: auth.user)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            }
            .background(.ultraThinMaterial)
        }
    }
}

private struct SidebarUserProfile: View {
    let user: FirebaseAuth.User?
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 12) {
            SidebarUserProfilePicture(url: user?.photoURL)

            VStack(alignment: .leading, spacing: 0) {
                if let user = user {
                    Text(user.displayName?.components(separatedBy: " ").first ?? "User")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Account Settings")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Sign In")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Sync your postcards")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showSettings = true
        }
        .sheet(isPresented: $showSettings) {
            AccountSettings(showSettings: $showSettings)
        }
    }
}

private struct SidebarUserProfilePicture: View {
    let url: URL?

    var body: some View {
        ZStack {
            if let url {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .controlSize(.small)
                }
            } else {
                Image(systemName: "person.crop.circle.badge.plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Circle())
        .frame(width: 32, height: 32)
    }
}
