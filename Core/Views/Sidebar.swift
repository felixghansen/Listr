//
//  Sidebar.swift
//  Listr
//
//  Created by Felix on 10/18/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct Sidebar: View {
    @Binding var selectedTab: Tab
    @ObservedObject var auth: AuthService

    var body: some View {
        List(selection: $selectedTab) {
            NavigationLink(value: Tab.collection) {
                Label("Collection", systemImage: "square.grid.2x2")
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                
                SidebarUserProfile(user: auth.currentUser)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
            }
            .background(.ultraThinMaterial)
        }
    }
}

private struct SidebarUserProfile: View {
    let user: FirebaseAuth.User?
    
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
    }
}

private struct SidebarUserProfilePicture: View {
    let url: URL?
    
    var body: some View {
        ZStack {
            if let url = url {
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
