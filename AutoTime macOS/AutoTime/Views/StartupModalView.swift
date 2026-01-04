//
//  StartupModalView.swift
//  AutoTime
//
//  Modal for configuring workday settings
//

import SwiftUI

struct StartupModalView: View {
    @ObservedObject var settings = AppSettings.shared
    @Binding var isPresented: Bool
    var onStart: (String, String) -> Void

    @State private var selectedCompany = ""
    @State private var selectedAllocation = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Start Your Workday")
                .font(.title)
                .fontWeight(.bold)

            Text("Configure your session settings")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Company")
                        .font(.headline)

                    Picker("Company", selection: $selectedCompany) {
                        Text("Select Company").tag("")
                        ForEach(settings.companyList, id: \.self) { company in
                            Text(company).tag(company)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Allocation")
                        .font(.headline)

                    Picker("Allocation", selection: $selectedAllocation) {
                        Text("Select Allocation").tag("")
                        ForEach(settings.allocationList, id: \.self) { allocation in
                            Text(allocation).tag(allocation)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Text("You can leave these blank and fill them in manually later")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Begin Tracking") {
                    onStart(selectedCompany, selectedAllocation)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 450)
    }
}
