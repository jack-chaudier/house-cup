//
//  ShopRequestView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ShopRequestView: View {
    @Environment(\.dismiss) var dismiss
    @State private var itemName = ""
    @State private var itemDescription = ""
    @State private var suggestedPrice = ""
    @State private var selectedCategory = ShopCategory.other
    @State private var justification = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    
    let db = Firestore.firestore()
    
    var isValid: Bool {
        !itemName.isEmpty &&
        !itemDescription.isEmpty &&
        Int(suggestedPrice) != nil &&
        !justification.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)
                    
                    TextField("Item Description", text: $itemDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ShopCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    HStack {
                        Text("Suggested Price")
                        Spacer()
                        TextField("Points", text: $suggestedPrice)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Justification") {
                    TextField("Why should this item be added to the shop?", text: $justification, axis: .vertical)
                        .lineLimit(4...8)
                }
                
                Section {
                    Text("Your request will be reviewed by an administrator. Once approved, the item will appear in the student shop.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Request Shop Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitRequest()
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .alert("Request Submitted", isPresented: $showingSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your shop item request has been submitted for review.")
            }
        }
    }
    
    private func submitRequest() {
        guard let teacherId = Auth.auth().currentUser?.uid,
              let teacherName = Auth.auth().currentUser?.displayName,
              let price = Int(suggestedPrice) else { return }
        
        isSubmitting = true
        
        let request = ShopRequest(
            teacherId: teacherId,
            teacherName: teacherName,
            itemName: itemName,
            itemDescription: itemDescription,
            suggestedPrice: price,
            category: selectedCategory,
            justification: justification
        )
        
        do {
            try db.collection("shopRequests").document(request.id).setData(from: request) { error in
                isSubmitting = false
                if error == nil {
                    showingSuccessAlert = true
                }
            }
        } catch {
            isSubmitting = false
            print("Error submitting request: \(error)")
        }
    }
}

struct ShopRequestsListView: View {
    @State private var myRequests: [ShopRequest] = []
    @State private var isLoading = true
    @State private var showingNewRequest = false
    
    let db = Firestore.firestore()
    
    var pendingRequests: [ShopRequest] {
        myRequests.filter { $0.status == .pending }
    }
    
    var reviewedRequests: [ShopRequest] {
        myRequests.filter { $0.status != .pending }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !pendingRequests.isEmpty {
                    Section("Pending Requests") {
                        ForEach(pendingRequests) { request in
                            ShopRequestRow(request: request)
                        }
                    }
                }
                
                if !reviewedRequests.isEmpty {
                    Section("Reviewed Requests") {
                        ForEach(reviewedRequests) { request in
                            ShopRequestRow(request: request)
                        }
                    }
                }
                
                if myRequests.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Requests Yet",
                        systemImage: "cart.badge.plus",
                        description: Text("Request new items for the student shop")
                    )
                }
            }
            .navigationTitle("My Shop Requests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewRequest = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewRequest) {
                ShopRequestView()
            }
            .task {
                await loadMyRequests()
            }
        }
    }
    
    private func loadMyRequests() async {
        guard let teacherId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("shopRequests")
                .whereField("teacherId", isEqualTo: teacherId)
                .order(by: "requestDate", descending: true)
                .getDocuments()
            
            myRequests = snapshot.documents.compactMap { doc in
                try? doc.data(as: ShopRequest.self)
            }
            isLoading = false
        } catch {
            print("Error loading requests: \(error)")
            isLoading = false
        }
    }
}

struct ShopRequestRow: View {
    let request: ShopRequest
    
    var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.itemName)
                        .font(.headline)
                    
                    HStack {
                        Label(request.category.rawValue, systemImage: request.category.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Label("\(request.suggestedPrice)", systemImage: "star")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: request.status.icon)
                        .font(.caption)
                    Text(request.status.rawValue)
                        .font(.caption.bold())
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
            }
            
            if request.status != .pending, let adminNotes = request.adminNotes {
                Text("Admin: \(adminNotes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Text(request.requestDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}