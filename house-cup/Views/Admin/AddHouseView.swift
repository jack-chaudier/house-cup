//
//  AddHouseView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI

struct AddHouseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var houseName = ""
    @State private var houseMotto = ""
    @State private var houseMascot = ""
    @State private var selectedColor = Color.red
    @State private var selectedGrade = 9
    let onAdd: (House) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("House Details") {
                    TextField("House Name", text: $houseName)
                    TextField("House Motto (Optional)", text: $houseMotto)
                    TextField("House Mascot (Optional)", text: $houseMascot)
                    
                    Picker("Grade Level", selection: $selectedGrade) {
                        Text("9th Grade").tag(9)
                        Text("10th Grade").tag(10)
                        Text("11th Grade").tag(11)
                        Text("12th Grade").tag(12)
                    }
                }
                
                Section("House Color") {
                    ColorPicker("Select Color", selection: $selectedColor)
                    HStack {
                        Text("Preview")
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedColor)
                            .frame(width: 60, height: 30)
                    }
                }
            }
            .navigationTitle("Add House")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newHouse = House(
                            name: houseName,
                            colorHex: selectedColor.toHex() ?? "#000000",
                            mascot: houseMascot.isEmpty ? nil : houseMascot,
                            motto: houseMotto.isEmpty ? nil : houseMotto,
                            grade: selectedGrade
                        )
                        onAdd(newHouse)
                        dismiss()
                    }
                    .disabled(houseName.isEmpty)
                }
            }
        }
    }
}

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}
