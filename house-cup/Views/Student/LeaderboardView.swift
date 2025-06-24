//
//  LeaderboardView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var houses: [House] = []
    @State private var isLoading = false
    private let db = Firestore.firestore()
    
    var sortedHouses: [House] {
        houses.sorted { $0.totalPoints > $1.totalPoints }
    }
    
    var body: some View {
        List {
            ForEach(Array(sortedHouses.enumerated()), id: \.element.id) { index, house in
                HStack {
                    // Rank
                    ZStack {
                        Circle()
                            .fill(colorForRank(index + 1))
                            .frame(width: 40, height: 40)
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // House info
                    VStack(alignment: .leading) {
                        Text(house.name)
                            .font(.headline)
                        Text("\(house.totalPoints) points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Trophy for top 3
                    if index < 3 {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(colorForRank(index + 1))
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadHouses()
        }
        .task {
            await loadHouses()
        }
    }
    
    private func loadHouses() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("houses").getDocuments()
            houses = snapshot.documents.compactMap { doc in
                try? doc.data(as: House.self)
            }
        } catch {
            print("Error loading houses: \(error)")
        }
        isLoading = false
    }
    
    private func colorForRank(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .blue
        }
    }
}
