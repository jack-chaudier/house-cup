//
//  HouseManagement.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore

struct HouseManagementView: View {
    @State private var houses: [House] = []
    @State private var showAddHouse = false
    @State private var isLoading = false
    private let db = Firestore.firestore()
    
    var body: some View {
        List {
            ForEach(houses) { house in
                HouseRow(house: house)
            }
            .onDelete(perform: deleteHouses)
        }
        .navigationTitle("Manage Houses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddHouse = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddHouse) {
            AddHouseView { newHouse in
                Task {
                    await addHouse(newHouse)
                }
            }
        }
        .task {
            await loadHouses()
        }
    }
    
    private func loadHouses() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("houses").getDocuments()
            houses = snapshot.documents.compactMap { doc -> House? in
                try? doc.data(as: House.self)
            }
        } catch {
            print("Error loading houses: \(error)")
        }
        isLoading = false
    }
    
    private func addHouse(_ house: House) async {
        do {
            try db.collection("houses").document(house.id).setData(from: house)
            await loadHouses()
        } catch {
            print("Error adding house: \(error)")
        }
    }
    
    private func deleteHouses(at offsets: IndexSet) {
        // Implementation for deleting houses
    }
}

struct HouseRow: View {
    let house: House
    
    var body: some View {
        HStack {
            Circle()
                .fill(house.color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(house.name)
                    .font(.headline)
                if let motto = house.motto {
                    Text(motto)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(house.totalPoints)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
