import CoreLocation
import OSLog

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  var authorizationStatus: CLAuthorizationStatus = .notDetermined

  // Reachability-retry state (approach B): once a reverse-geocode succeeds we
  // have a real fix; if a geocode fails transiently we stash the coordinates and
  // re-run it when the network returns. `pendingFirstRunFix` covers being offline
  // before we ever obtained a fix at all.
  private var hasRealFix = false
  private var pendingGeocode: CLLocation?
  private var pendingFirstRunFix = false

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    manager.distanceFilter = kCLLocationAccuracyThreeKilometers
    authorizationStatus = manager.authorizationStatus
  }

  func startUpdating() {
    refreshAuthorizationStatus()
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorized, .authorizedAlways:
      manager.startUpdatingLocation()
      manager.startMonitoringSignificantLocationChanges()
    case .denied:
      disableCurrentLocation(failure: .denied)
    case .restricted:
      disableCurrentLocation(failure: .restricted)
    @unknown default:
      break
    }
  }

  func stopUpdating() {
    manager.stopUpdatingLocation()
    manager.stopMonitoringSignificantLocationChanges()
  }

  // MARK: - CLLocationManagerDelegate

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    Task { @MainActor in
      self.handleAuthorizationStatus(status)
    }
  }

  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    guard let location = locations.last,
      location.horizontalAccuracy >= 0,
      location.horizontalAccuracy <= kCLLocationAccuracyThreeKilometers
    else { return }

    manager.stopUpdatingLocation()
    geocodeAndApply(location)
  }

  /// Reverse-geocodes a fix and applies the resolved location. On a transient
  /// geocode failure it stashes the coordinates so `retryPendingGeocodeOnReconnect`
  /// can re-run it once the network returns, then reports the failure.
  nonisolated private func geocodeAndApply(_ location: CLLocation) {
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
      let lat = location.coordinate.latitude
      let lng = location.coordinate.longitude

      guard let placemark = placemarks?.first else {
        let failure = Self.locationFailure(for: error)
        Task { @MainActor in
          self?.pendingGeocode = CLLocation(latitude: lat, longitude: lng)
          NotificationCenter.default.post(name: .locationDidFail, object: failure)
        }
        return
      }

      let city =
        placemark.locality
        ?? placemark.subLocality
        ?? placemark.administrativeArea
        ?? placemark.country
        ?? ""
      let state = placemark.administrativeArea ?? ""
      let country = placemark.isoCountryCode ?? ""
      let countryName = placemark.country ?? ""
      let tz = placemark.timeZone?.identifier ?? TimeZone.current.identifier

      Task { @MainActor in
        self?.applyResolvedLocation(
          latitude: lat, longitude: lng,
          city: city, state: state,
          country: country, countryName: countryName,
          timeZone: tz
        )
      }
    }
  }

  @MainActor
  private func applyResolvedLocation(
    latitude: Double, longitude: Double, city: String, state: String,
    country: String, countryName: String, timeZone: String
  ) {
    Preferences.shared.updateLocation(
      latitude: latitude, longitude: longitude,
      city: city, state: state,
      country: country, countryName: countryName,
      timeZone: timeZone
    )
    hasRealFix = true
    pendingGeocode = nil
    pendingFirstRunFix = false
    NotificationCenter.default.post(name: .locationDidUpdate, object: nil)
  }

  /// Called on the main actor when the network returns (the reachability rising
  /// edge). Re-acquires a fix if we never got one, otherwise re-runs the single
  /// pending label geocode. A repeat failure simply re-arms `pendingGeocode` for
  /// the next reconnect - no polling, no hot loop.
  @MainActor
  func retryPendingGeocodeOnReconnect() {
    guard Preferences.shared.useCurrentLocation else { return }

    if pendingFirstRunFix || !hasRealFix {
      startUpdating()
      return
    }

    guard let location = pendingGeocode else { return }
    geocodeAndApply(location)
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let clError = error as? CLError, clError.code == .denied {
      manager.stopUpdatingLocation()
      manager.stopMonitoringSignificantLocationChanges()
      Task { @MainActor in
        Preferences.shared.useCurrentLocation = false
        NotificationCenter.default.post(name: .locationDidFail, object: LocationFailure.denied)
      }
      return
    }
    Task { @MainActor in
      // Couldn't even acquire a fix. If we never had one, mark a first-run
      // failure so a reconnect re-requests location rather than only re-geocoding.
      if !self.hasRealFix { self.pendingFirstRunFix = true }
      NotificationCenter.default.post(name: .locationDidFail, object: Self.locationFailure(for: error))
    }
  }

  private func refreshAuthorizationStatus() {
    authorizationStatus = manager.authorizationStatus
  }

  /// Re-resolves the city/state/country labels for the currently stored
  /// coordinates in the given locale. Used to refresh placemark strings when
  /// the user changes the app language, since the values returned by
  /// `CLGeocoder` are frozen at fetch-time language. Coordinates, ISO country
  /// code, and stored time zone are left untouched.
  @MainActor
  func refreshGeocodedLabels(in locale: Locale) async {
    let prefs = Preferences.shared
    let lat = prefs.latitude
    let lng = prefs.longitude
    guard lat != 0 || lng != 0 else { return }

    let location = CLLocation(latitude: lat, longitude: lng)
    let geocoder = CLGeocoder()
    let placemarks: [CLPlacemark]
    do {
      placemarks = try await geocoder.reverseGeocodeLocation(
        location, preferredLocale: locale)
    } catch {
      AppLog.location.notice(
        "Re-geocode for language change failed: \(error.localizedDescription, privacy: .public)")
      return
    }
    guard let placemark = placemarks.first else { return }

    let newCity =
      placemark.locality
      ?? placemark.subLocality
      ?? placemark.administrativeArea
      ?? prefs.city
    let newState = placemark.administrativeArea ?? prefs.state
    let newCountryName = placemark.country ?? prefs.countryName

    prefs.batchUpdates {
      if newCity != prefs.city { prefs.city = newCity }
      if newState != prefs.state { prefs.state = newState }
      if newCountryName != prefs.countryName { prefs.countryName = newCountryName }
    }
  }

  private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
    authorizationStatus = status
    if status == .authorized || status == .authorizedAlways {
      manager.startUpdatingLocation()
      manager.startMonitoringSignificantLocationChanges()
    } else if status == .denied {
      disableCurrentLocation(failure: .denied)
    } else if status == .restricted {
      disableCurrentLocation(failure: .restricted)
    }
  }

  private func disableCurrentLocation(failure: LocationFailure) {
    manager.stopUpdatingLocation()
    manager.stopMonitoringSignificantLocationChanges()
    Preferences.shared.useCurrentLocation = false
    NotificationCenter.default.post(name: .locationDidFail, object: failure)
  }

  nonisolated private static func locationFailure(for error: Error?) -> LocationFailure {
    guard let error else { return .unavailable }
    guard let clError = error as? CLError else { return .unavailable }

    switch clError.code {
    case .denied:
      return .denied
    case .network:
      return .network
    default:
      return .unavailable
    }
  }
}
