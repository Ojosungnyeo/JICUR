import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    @Bindable var store: StoreOf<MapFeature>

    var body: some View {
        ZStack {
            Group {
                if store.usesGoogleMaps {
                    JicurMapView(scene: store.scene) { _ in }
                } else {
                    IllustratedMapView(scene: store.scene)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                routeSearchPanel
                Spacer()
                if let message = store.message { statusCard(message) }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .task { store.send(.task) }
    }

    private var routeSearchPanel: some View {
        VStack(spacing: 0) {
            endpointField(.origin, title: "출발지", symbol: "circle.fill", color: .jicurGreen)
            Divider().padding(.leading, 48)
            endpointField(.destination, title: "도착지", symbol: "mappin.circle.fill", color: .orange)

            if store.origin != nil && store.destination != nil {
                Divider().padding(.horizontal, 14)
                Button { store.send(.routeButtonTapped) } label: {
                    HStack(spacing: 8) {
                        if store.isLoadingRoute {
                            ProgressView().tint(.white).controlSize(.small)
                        } else {
                            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                        }
                        Text(store.isLoadingRoute ? "동선 계산 중" : "동선 보기")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.jicurGreen, in: RoundedRectangle(cornerRadius: 14))
                    .padding(10)
                }
                .buttonStyle(.plain)
                .disabled(store.isLoadingRoute)
            }

            if !store.searchResults.isEmpty {
                Divider().padding(.horizontal, 14)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.searchResults) { place in
                            Button { store.send(.placeSelected(place)) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin")
                                        .frame(width: 22)
                                        .foregroundStyle(store.activeEndpoint == .origin ? Color.jicurGreen : Color.orange)
                                    Text(place.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 15)
                                .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.1), radius: 18, y: 7)
    }

    private func endpointField(_ endpoint: RouteEndpoint, title: String, symbol: String, color: Color) -> some View {
        let query = endpoint == .origin ? store.originQuery : store.destinationQuery
        return HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(endpoint == .origin ? .caption : .title3)
                .foregroundStyle(color)
                .frame(width: 20)
            TextField(title, text: Binding(
                get: { endpoint == .origin ? store.originQuery : store.destinationQuery },
                set: { store.send(.queryChanged(endpoint, $0)) }
            ))
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .onSubmit { store.send(.searchSubmitted(endpoint)) }

            if store.isSearching && store.activeEndpoint == endpoint {
                ProgressView().controlSize(.small)
            } else if !query.isEmpty {
                Button { store.send(.clear(endpoint)) } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button("검색") { store.send(.searchSubmitted(endpoint)) }
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .padding(.horizontal, 15)
        .frame(height: 54)
    }

    private func statusCard(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
    }
}

extension Color {
    static let jicurGreen = Color(red: 0.16, green: 0.55, blue: 0.34)
    static let jicurMint = Color(red: 0.38, green: 0.82, blue: 0.58)
}

#Preview {
    ContentView(store: Store(initialState: MapFeature.State()) { MapFeature() })
}
