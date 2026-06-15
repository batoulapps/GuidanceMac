import CoreLocation
import MapKit

@MainActor @Observable
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
  var searchText = ""
  var completions: [MKLocalSearchCompletion] = []
  var isSearching = false
  var isResolving = false
  var errorMessage: String?

  private let completer: MKLocalSearchCompleter
  private let geocoder = CLGeocoder()

  override init() {
    completer = MKLocalSearchCompleter()
    super.init()
    completer.resultTypes = .address
    completer.delegate = self
  }

  func updateCompleter() {
    errorMessage = nil
    if searchText.isEmpty {
      completions = []
      completer.queryFragment = ""
      isSearching = false
    } else {
      isSearching = true
      completer.queryFragment = searchText
    }
  }

  func selectCompletion(_ completion: MKLocalSearchCompletion) async {
    isResolving = true
    defer { isResolving = false }

    let request = MKLocalSearch.Request(completion: completion)
    request.resultTypes = .address

    do {
      let response = try await MKLocalSearch(request: request).start()
      guard let item = response.mapItems.first else {
        errorMessage = localizedString("settings.location.searchError.resolve", locale: .app)
        return
      }

      let coordinate = item.placemark.coordinate
      let city =
        item.placemark.locality
        ?? item.placemark.subLocality
        ?? item.placemark.administrativeArea
        ?? completion.title
      let state = item.placemark.administrativeArea ?? ""
      let country = item.placemark.isoCountryCode ?? ""
      let countryName = item.placemark.country ?? ""

      geocoder.cancelGeocode()
      let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let placemarks = try? await geocoder.reverseGeocodeLocation(location)
      let timeZone =
        placemarks?.first?.timeZone?.identifier
        ?? item.placemark.timeZone?.identifier
        ?? TimeZone.current.identifier

      Preferences.shared.updateLocation(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        city: city,
        state: state,
        country: country,
        countryName: countryName,
        timeZone: timeZone
      )
      NotificationCenter.default.post(name: .locationDidUpdate, object: nil)

      searchText = ""
      completions = []
    } catch {
      errorMessage = localizedString("settings.location.searchError.resolveTryAnother", locale: .app)
    }
  }

  func cancel() {
    searchText = ""
    completions = []
    errorMessage = nil
    isSearching = false
    isResolving = false
    completer.queryFragment = ""
    geocoder.cancelGeocode()
  }

  // MARK: - MKLocalSearchCompleterDelegate

  nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task { @MainActor in
      self.completions = self.completer.results
      self.isSearching = false
    }
  }

  nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error)
  {
    Task { @MainActor in
      self.completions = []
      self.isSearching = false
      if !self.searchText.isEmpty {
        self.errorMessage = localizedString("settings.location.searchError.connection", locale: .app)
      }
    }
  }
}
