//
//  LocationSearchView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Clean and fast search view
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var spotsManager: AccessibilitySpotsManager
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSearch()
                    }

                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 17))

                            TextField("Search locations", text: $searchText)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .focused($isSearchFocused)
                                .submitLabel(.search)
                                .onChange(of: searchText) { _, newValue in
                                    searchTask?.cancel()

                                    if newValue.isEmpty {
                                        searchResults = []
                                        isSearching = false
                                    } else {
                                        searchTask = Task {
                                            try? await Task.sleep(nanoseconds: 300_000_000)
                                            guard !Task.isCancelled else { return }
                                            await performSearch(query: newValue)
                                        }
                                    }
                                }

                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    searchResults = []
                                    isSearching = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 17))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button("Cancel") {
                            dismissSearch()
                        }
                        .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)

                    // Results
                    if isSearching {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.regularMaterial)
                    } else if !searchResults.isEmpty {
                        List {
                            ForEach(searchResults, id: \.self) { item in
                                Button {
                                    selectLocation(item)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(.red)
                                            .font(.title3)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name ?? "Unknown")
                                                .font(.body)
                                                .foregroundStyle(.primary)

                                            if let address = formatAddress(item.placemark) {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(.regularMaterial)
                    } else if searchText.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Search for cities, landmarks, or addresses")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.regularMaterial)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No results found")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.regularMaterial)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private func dismissSearch() {
        isSearchFocused = false
        searchTask?.cancel()
        isPresented = false
    }

    private func formatAddress(_ placemark: MKPlacemark) -> String? {
        var components: [String] = []

        if let locality = placemark.locality {
            components.append(locality)
        }
        if let country = placemark.country {
            components.append(country)
        }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }

        await MainActor.run {
            isSearching = true
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            await MainActor.run {
                isSearching = false
                searchResults = response.mapItems
            }
        } catch {
            await MainActor.run {
                isSearching = false
                searchResults = []
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        isSearchFocused = false
        locationManager.updateRegion(center: item.placemark.coordinate, updateCamera: true)

        Task {
            await spotsManager.fetchFromOpenStreetMap(around: item.placemark.coordinate)
        }

        isPresented = false
    }
}

#Preview {
    LocationSearchView(isPresented: .constant(true))
        .environmentObject(LocationManager())
        .environmentObject(AccessibilitySpotsManager())
}
