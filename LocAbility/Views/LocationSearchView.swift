//
//  LocationSearchView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  iOS 26 style search - App Store/Revolut inspired
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var spotsManager: AccessibilitySpotsManager
    @Binding var isPresented: Bool
    @AppStorage("searchHistory") private var searchHistoryData: Data = Data()

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isFetching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearchFieldFocused = false
    @State private var searchHistory: [SearchHistoryItem] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if isFetching {
                        LoadingIndicator(text: "Searching nearby places…", size: 60)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                    } else if !searchResults.isEmpty {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectLocation(item)
                            } label: {
                                SearchResultRow(item: item)
                            }
                            .buttonStyle(.plain)

                            if item != searchResults.last {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    } else if searchText.isEmpty && !searchHistory.isEmpty {
                        // Search History Section
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Recent Searches")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    clearHistory()
                                } label: {
                                    Text("Clear")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)

                            ForEach(searchHistory) { historyItem in
                                Button {
                                    selectHistoryItem(historyItem)
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 20))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(historyItem.name)
                                                .font(.body)
                                                .foregroundStyle(.primary)

                                            if let address = historyItem.address {
                                                Text(address)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer(minLength: 0)

                                        Button {
                                            removeHistoryItem(historyItem)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                                .padding(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if historyItem != searchHistory.last {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                    } else if searchText.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 52, weight: .thin))
                                .foregroundStyle(.secondary.opacity(0.6))
                            Text("Search for cities, landmarks, or addresses")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    } else {
                        VStack(spacing: 14) {
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 52, weight: .thin))
                                .foregroundStyle(.secondary.opacity(0.6))
                            Text("No results found")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismissSearch()
                    }
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearchFieldFocused,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Cities, landmarks, addresses"
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()

                if newValue.isEmpty {
                    searchResults = []
                    isFetching = false
                } else {
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        guard !Task.isCancelled else { return }
                        await performSearch(query: newValue)
                    }
                }
            }
            .onAppear {
                loadHistory()
                // Automatically activate search field and show keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isSearchFieldFocused = true
                }
            }
        }
        .presentationBackground(.thinMaterial)
    }

    private func loadHistory() {
        if let decoded = try? JSONDecoder().decode([SearchHistoryItem].self, from: searchHistoryData) {
            searchHistory = decoded
        }
    }

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            searchHistoryData = encoded
        }
    }

    private func addToHistory(name: String, address: String?, latitude: Double, longitude: Double) {
        let newItem = SearchHistoryItem(
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude
        )

        // Remove if already exists
        searchHistory.removeAll { $0.name == name }

        // Add to beginning
        searchHistory.insert(newItem, at: 0)

        // Keep only last 10 items
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }

        saveHistory()
    }

    private func clearHistory() {
        searchHistory = []
        saveHistory()
    }

    private func removeHistoryItem(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.id == item.id }
        saveHistory()
    }

    private func selectHistoryItem(_ item: SearchHistoryItem) {
        let coordinate = CLLocationCoordinate2D(
            latitude: item.latitude,
            longitude: item.longitude
        )
        locationManager.updateRegion(center: coordinate, updateCamera: true)

        Task {
            await spotsManager.fetchFromOpenStreetMap(around: coordinate)
        }

        isPresented = false
    }

    private func dismissSearch() {
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
                isFetching = false
            }
            return
        }

        await MainActor.run {
            isFetching = true
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            await MainActor.run {
                isFetching = false
                searchResults = response.mapItems
            }
        } catch {
            await MainActor.run {
                isFetching = false
                searchResults = []
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate

        // Add to history
        addToHistory(
            name: item.name ?? "Unknown Location",
            address: formatAddress(item.placemark),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        locationManager.updateRegion(center: coordinate, updateCamera: true)

        Task {
            await spotsManager.fetchFromOpenStreetMap(around: coordinate)
        }

        isPresented = false
    }
}

// MARK: - Search History Model
struct SearchHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let timestamp: Date

    init(name: String, address: String?, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
    }
}

struct SearchResultRow: View {
    let item: MKMapItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.red)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unknown")
                    .font(.body)
                    .foregroundStyle(.primary)

                if let address = formatAddress(item.placemark) {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
}

#Preview {
    LocationSearchView(isPresented: .constant(true))
        .environmentObject(LocationManager())
        .environmentObject(AccessibilitySpotsManager())
}
