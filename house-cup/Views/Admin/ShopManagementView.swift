//
//  ShopManagementView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ShopManagementView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("View", selection: $selectedTab) {
                    Text("Requests").tag(0)
                    Text("Active Items").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    ShopRequestsAdminView()
                } else {
                    ActiveShopItemsView()
                }
            }
            .navigationTitle("Shop Management")
        }
    }
}

struct ShopRequestsAdminView: View {
    @State private var requests: [ShopRequest] = []
    @State private var isLoading = true
    @State private var selectedRequest: ShopRequest?
    @State private var showingReviewSheet = false
    
    let db = Firestore.firestore()
    
    var pendingRequests: [ShopRequest] {
        requests.filter { $0.status == .pending }
    }
    
    var reviewedRequests: [ShopRequest] {
        requests.filter { $0.status != .pending }
    }
    
    var body: some View {
        List {
            if !pendingRequests.isEmpty {
                Section("Pending Approval") {
                    ForEach(pendingRequests) { request in
                        ShopRequestAdminRow(request: request) {
                            selectedRequest = request
                            showingReviewSheet = true
                        }
                    }
                }
            }
            
            if !reviewedRequests.isEmpty {
                Section("Reviewed") {
                    ForEach(reviewedRequests) { request in
                        ShopRequestAdminRow(request: request) {
                            selectedRequest = request
                            showingReviewSheet = true
                        }
                    }
                }
            }
            
            if requests.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Shop Requests",
                    systemImage: "cart",
                    description: Text("Teachers haven't submitted any shop item requests yet")
                )
            }
        }
        .task {
            await loadRequests()
        }
        .sheet(isPresented: $showingReviewSheet) {
            if let request = selectedRequest {
                ReviewShopRequestView(request: request) {
                    Task { await loadRequests() }
                }
            }
        }
    }
    
    private func loadRequests() async {
        do {
            let snapshot = try await db.collection("shopRequests")
                .order(by: "requestDate", descending: true)
                .getDocuments()
            
            requests = snapshot.documents.compactMap { doc in
                try? doc.data(as: ShopRequest.self)
            }
            isLoading = false
        } catch {
            print("Error loading requests: \(error)")
            isLoading = false
        }
    }
}

struct ShopRequestAdminRow: View {
    let request: ShopRequest
    let onTap: () -> Void
    
    var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.itemName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("by \(request.teacherName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: request.status.icon)
                                .font(.caption)
                            Text(request.status.rawValue)
                                .font(.caption.bold())
                        }
                        .foregroundColor(statusColor)
                        
                        Label("\(request.suggestedPrice)", systemImage: "star")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label(request.category.rawValue, systemImage: request.category.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(request.requestDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewShopRequestView: View {
    let request: ShopRequest
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var adminNotes = ""
    @State private var finalPrice: String = ""
    @State private var stockQuantity: String = ""
    @State private var unlimitedStock = true
    @State private var isProcessing = false
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Request Details") {
                    LabeledContent("Item Name", value: request.itemName)
                    LabeledContent("Category", value: request.category.rawValue)
                    LabeledContent("Requested by", value: request.teacherName)
                    LabeledContent("Date", value: request.requestDate.formatted())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(request.itemDescription)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Justification")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(request.justification)
                    }
                }
                
                if request.status == .pending {
                    Section("Approval Settings") {
                        HStack {
                            Text("Final Price")
                            Spacer()
                            TextField("Points", text: $finalPrice)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        Toggle("Unlimited Stock", isOn: $unlimitedStock)
                        
                        if !unlimitedStock {
                            HStack {
                                Text("Stock Quantity")
                                Spacer()
                                TextField("Quantity", text: $stockQuantity)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
                
                Section("Admin Notes") {
                    if request.status == .pending {
                        TextField("Add notes (optional)", text: $adminNotes, axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        Text(request.adminNotes ?? "No notes")
                            .foregroundColor(.secondary)
                    }
                }
                
                if request.status != .pending {
                    Section("Review Details") {
                        LabeledContent("Status", value: request.status.rawValue)
                            .foregroundColor(request.status == .approved ? .green : .red)
                        if let reviewedBy = request.reviewedBy {
                            LabeledContent("Reviewed by", value: reviewedBy)
                        }
                        if let reviewedDate = request.reviewedDate {
                            LabeledContent("Reviewed on", value: reviewedDate.formatted())
                        }
                    }
                }
            }
            .navigationTitle("Review Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                if request.status == .pending {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu("Actions") {
                            Button(action: { approveRequest() }) {
                                Label("Approve", systemImage: "checkmark.circle")
                            }
                            .disabled(finalPrice.isEmpty || (!unlimitedStock && stockQuantity.isEmpty))
                            
                            Button(role: .destructive, action: { rejectRequest() }) {
                                Label("Reject", systemImage: "xmark.circle")
                            }
                        }
                        .disabled(isProcessing)
                    }
                }
            }
        }
        .onAppear {
            finalPrice = String(request.suggestedPrice)
        }
    }
    
    private func approveRequest() {
        guard let adminId = Auth.auth().currentUser?.uid,
              let adminName = Auth.auth().currentUser?.displayName,
              let price = Int(finalPrice) else { return }
        
        isProcessing = true
        
        let batch = db.batch()
        
        // Create the shop item
        let shopItem = ShopItem(
            name: request.itemName,
            description: request.itemDescription,
            price: price,
            category: request.category,
            isActive: true,
            createdBy: request.teacherId,
            approvedBy: adminId,
            approvedAt: Date(),
            stockQuantity: unlimitedStock ? nil : Int(stockQuantity)
        )
        
        let itemRef = db.collection("shopItems").document(shopItem.id)
        try? batch.setData(from: shopItem, forDocument: itemRef)
        
        // Update the request
        let requestRef = db.collection("shopRequests").document(request.id)
        batch.updateData([
            "status": RequestStatus.approved.rawValue,
            "adminNotes": adminNotes.isEmpty ? nil : adminNotes,
            "reviewedBy": adminName,
            "reviewedDate": Date()
        ] as [String : Any], forDocument: requestRef)
        
        batch.commit { error in
            isProcessing = false
            if error == nil {
                onComplete()
                dismiss()
            }
        }
    }
    
    private func rejectRequest() {
        guard let adminId = Auth.auth().currentUser?.uid,
              let adminName = Auth.auth().currentUser?.displayName else { return }
        
        isProcessing = true
        
        db.collection("shopRequests").document(request.id).updateData([
            "status": RequestStatus.rejected.rawValue,
            "adminNotes": adminNotes.isEmpty ? nil : adminNotes,
            "reviewedBy": adminName,
            "reviewedDate": Date()
        ] as [String : Any]) { error in
            isProcessing = false
            if error == nil {
                onComplete()
                dismiss()
            }
        }
    }
}

struct ActiveShopItemsView: View {
    @State private var shopItems: [ShopItem] = []
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        List {
            ForEach(shopItems) { item in
                ShopItemAdminRow(item: item) {
                    toggleItemStatus(item)
                }
            }
            
            if shopItems.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Shop Items",
                    systemImage: "cart",
                    description: Text("No items have been added to the shop yet")
                )
            }
        }
        .task {
            await loadShopItems()
        }
    }
    
    private func loadShopItems() async {
        do {
            let snapshot = try await db.collection("shopItems")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            shopItems = snapshot.documents.compactMap { doc in
                try? doc.data(as: ShopItem.self)
            }
            isLoading = false
        } catch {
            print("Error loading shop items: \(error)")
            isLoading = false
        }
    }
    
    private func toggleItemStatus(_ item: ShopItem) {
        db.collection("shopItems").document(item.id).updateData([
            "isActive": !item.isActive
        ]) { error in
            if error == nil {
                Task { await loadShopItems() }
            }
        }
    }
}

struct ShopItemAdminRow: View {
    let item: ShopItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Label("\(item.price)", systemImage: "star")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let stock = item.remainingStock {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("\(stock) left")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text("Sold: \(item.soldCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("Active", isOn: .constant(item.isActive))
                .labelsHidden()
                .onTapGesture {
                    onToggle()
                }
        }
        .padding(.vertical, 4)
    }
}