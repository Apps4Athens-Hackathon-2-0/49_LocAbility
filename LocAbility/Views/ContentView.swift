//
//  ContentView.swift
//  LocAbility
//
//  Petros Dhespollari @Copyright 2025
//  Main view with map and accessibility controls
//

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var spotsManager: AccessibilitySpotsManager
    @State private var showingAddSpot = false
    @State private var showingLocationSearch = false
    @State private var selectedFilter: AccessibilityFilter = .all
    @State private var currentNeighborhoodScore: Int = 0

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack(alignment: .bottom) {
                    // Map View
                    MapView(selectedFilter: $selectedFilter)
                        .accessibilityLabel("Interactive map showing accessibility points in Athens")

                    // Bottom Card - Fixed at 35% height
                    VStack(spacing: 0) {
                        // Handle indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Filter Bar
                                FilterBar(selectedFilter: $selectedFilter)
                                    .padding(.vertical, 16)

                                // Neighborhood Score Card
                                NeighborhoodScoreCard(score: currentNeighborhoodScore)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .padding(.bottom, 12)

                                // Nearby Spots List
                                NearbySpotsList()
                                    .padding(.bottom, 40)
                            }
                        }
                    }
                    .frame(height: geometry.size.height * 0.45)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 20, y: -5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
                .navigationTitle("LocAbility")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        AccessibilitySettingsButton()
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button {
                                locationManager.requestLocation()
                            } label: {
                                Label("My Location", systemImage: "location.fill")
                            }

                            Button {
                                Task {
                                    await spotsManager.fetchFromOpenStreetMap(around: locationManager.region.center)
                                }
                            } label: {
                                Label("Load from OpenStreetMap", systemImage: "map")
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .accessibilityLabel("Location options")
                        }
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    // Add Spot FAB - Left side
                    Button {
                        showingAddSpot = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)

                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, geometry.size.height * 0.45 + 20)
                    .accessibilityLabel("Add new accessibility spot")
                    .accessibilityHint("Opens form to report a new accessible feature")
                }
                .overlay(alignment: .bottomTrailing) {
                    // Search FAB - Right side
                    Button {
                        showingLocationSearch = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)

                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .shadow(color: .green.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, geometry.size.height * 0.45 + 20)
                    .accessibilityLabel("Search for locations")
                    .accessibilityHint("Search for any location in the world")
                }
                .sheet(isPresented: $showingAddSpot) {
                    AddSpotView()
                }
                .fullScreenCover(isPresented: $showingLocationSearch) {
                    LocationSearchView(isPresented: $showingLocationSearch)
                }
                .overlay(alignment: .top) {
                    if spotsManager.isLoadingSpots {
                        LoadingIndicator(
                            text: "Updating accessibility data…",
                            size: 42,
                            textColor: .white.opacity(0.9)
                        )
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, geometry.safeAreaInsets.top + 12)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: spotsManager.isLoadingSpots)
                .onAppear {
                    updateNeighborhoodScore()
                }
                .onChange(of: locationManager.region.center.latitude) { _, _ in
                    updateNeighborhoodScore()
                }
                .onChange(of: locationManager.region.center.longitude) { _, _ in
                    updateNeighborhoodScore()
                }
                .onChange(of: spotsManager.spots.count) { _, _ in
                    updateNeighborhoodScore()
                }
            }
        }
    }

    private func updateNeighborhoodScore() {
        // Calculate score based on nearby spots
        currentNeighborhoodScore = spotsManager.calculateAreaScore(
            center: locationManager.region.center,
            radius: 500
        )
    }
}

// Custom corner radius modifier
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(AccessibilitySpotsManager())
}
