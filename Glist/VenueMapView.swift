import SwiftUI
import MapKit

struct VenueMapView: View {
    @EnvironmentObject var venueManager: VenueManager
    @EnvironmentObject var socialManager: SocialManager
    @EnvironmentObject var authManager: AuthManager
    
    @StateObject private var locationManager = LocationManager()
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.1972, longitude: 55.2744), // Downtown Dubai
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var selectedVenue: Venue?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position, selection: $selectedVenue) {
                    UserAnnotation(location: locationManager.location)
                    
                    ForEach(venueManager.venues) { venue in
                        Annotation(venue.name, coordinate: venue.coordinate) {
                            VenueMarker(venue: venue, friendsAtVenue: socialManager.getFriendsAt(venueId: venue.id))
                                .onTapGesture {
                                    selectedVenue = venue
                                }
                        }
                        .tag(venue)
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                
                // Overlay for selected venue
                if let venue = selectedVenue {
                    VStack {
                        Spacer()
                        VenueMapCard(venue: venue)
                            .padding(.bottom, 60) // Space for tab bar
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .onAppear {
                locationManager.requestPermission()
                
                // Fetch friends' locations for all venues
                if let user = authManager.user {
                    for venue in venueManager.venues {
                        Task {
                            await socialManager.fetchFriendsGoing(venueId: venue.id, currentUserFollowing: user.following)
                        }
                    }
                }
            }
        }
    }
}

struct VenueMarker: View {
    let venue: Venue
    let friendsAtVenue: [User]
    
    // Calculate heat based on some metric (e.g., friends count + random hype for now)
    var heatColor: Color {
        let hypeScore = friendsAtVenue.count * 2 + Int.random(in: 0...5)
        if hypeScore > 5 { return .red }
        if hypeScore > 2 { return .orange }
        return .green
    }
    
    var body: some View {
        ZStack {
            // Heat Pulse
            Circle()
                .fill(heatColor.opacity(0.3))
                .frame(width: 60, height: 60)
            
            Circle()
                .fill(heatColor)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            // Venue Icon or Friend Avatar
            if let firstFriend = friendsAtVenue.first {
                if let imageUrl = firstFriend.profileImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
                }
            } else {
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            
            // Friend Count Badge
            if friendsAtVenue.count > 1 {
                Text("\(friendsAtVenue.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(Color.black)
                    .clipShape(Circle())
                    .offset(x: 10, y: -10)
            }
        }
    }
}

struct VenueMapCard: View {
    let venue: Venue
    @EnvironmentObject var socialManager: SocialManager
    
    var body: some View {
        NavigationLink(destination: VenueDetailView(venue: venue)) {
            HStack(spacing: 16) {
                Image(venue.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(venue.name.uppercased())
                        .font(Theme.Fonts.display(size: 18))
                        .foregroundStyle(.black)
                    
                    Text(venue.type)
                        .font(Theme.Fonts.body(size: 12))
                        .foregroundStyle(.gray)
                    
                    // Friends indicator
                    let friends = socialManager.getFriendsAt(venueId: venue.id)
                    if !friends.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                            Text("\(friends.count) friends going")
                                .font(Theme.Fonts.body(size: 10))
                        }
                        .foregroundStyle(Color.theme.accent)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
        }
    }
}

struct UserAnnotation: MapContent {
    let location: CLLocation?
    
    var body: some MapContent {
        if let location = location {
            Annotation("My Location", coordinate: location.coordinate) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                }
            }
        }
    }
}
