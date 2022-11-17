//
//  MapController.swift
//  Ali Maps
//
//  Created by Ali Eldeeb on 11/11/22.
//

import UIKit
import MapKit
import CoreLocation

class MapController: UIViewController{
    //MARK: - Properties
    private var mapView: MKMapView!
    private let locationRequestController = LocationRequestController()
    private var currentRoute: MKRoute?
    private var selectedAnnotation: MKAnnotation?
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    private lazy var centerMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "location-arrow-flat")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleCenterUserLocation), for: .touchUpInside)
        button.setDimesions(height: 50, width: 50)
        return button
    }()
    
    private lazy var removeOverlayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "baseline_clear_white_36pt_1x")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = .systemRed
        button.addTarget(self, action: #selector(handleRemoveOverlays), for: .touchUpInside)
        button.setDimesions(height: 50, width: 50)
        button.layer.cornerRadius = 25
        return button
    }()
    
    private lazy var searchInputView: SearchInputView = {
        let inputView = SearchInputView()
        inputView.mapController = self 
        inputView.delegate = self
        inputView.setDimesions(height: view.frame.height, width: 0)
        return inputView
    }()
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        enableLocationServices()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centerMapOnUserLocation(loadAnnotations: true)
    }
    //MARK: - Helpers
    private func configureUI(){
        view.backgroundColor = .white
        configureMapView()
        //must be done after mapView is configure or else it will be under it
        view.addSubview(searchInputView)
        searchInputView.anchor(leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingBottom: -(view.frame.height - 100))
        
        view.addSubview(centerMapButton)
        centerMapButton.anchor(bottom: searchInputView.topAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingBottom: 16, paddingTrailing: 16)
        
        view.addSubview(removeOverlayButton)
        removeOverlayButton.anchor(leading: view.safeAreaLayoutGuide.leadingAnchor,bottom: searchInputView.topAnchor, paddingLeading: 16, paddingBottom: 260)
        removeOverlayButton.alpha = 0
    }
    
    private func configureMapView(){
        mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        
        view.addSubview(mapView)
        mapView.addContstraintsToFillView(view: view)
    }
 
    //MARK: - Selectors
    @objc private func handleCenterUserLocation(){
        centerMapOnUserLocation(loadAnnotations: false)
    }
    
    @objc private func handleRemoveOverlays(){
        searchInputView.directionsEnabled = false
        
        UIView.animate(withDuration: 0.5) {
            self.removeOverlayButton.alpha = 0
            self.centerMapButton.alpha = 1
        }

        //so if we have an overlay then we will remove the poly line overlay and then zoomingback out
        if mapView.overlays.count > 0{
            self.mapView.removeOverlay(mapView.overlays[0])
            centerMapOnUserLocation(loadAnnotations: false)
        }
        
        searchInputView.disableViewInteraction(directionsEnabled: false)
        guard let selectedAnnotation = selectedAnnotation else { return }
        mapView.deselectAnnotation(selectedAnnotation, animated: true)
    }
}

//MARK: - SearchCellDelegate
extension MapController: SearchCellDelegate{
    func getDirections(forMapItem mapItem: MKMapItem) {
        //this will open maps and give the driving directions to the map item
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func distanceFromUser(location: CLLocation) -> CLLocationDistance? {
        guard let userLocation = locationManager.location else { return nil}
        return userLocation.distance(from: location)
    }
}


//MARK: - SearchInputViewDelegate
extension MapController: SearchInputViewDelegate{
    func selectedAnnotation(withMapItem mapItem: MKMapItem) {
        mapView.annotations.forEach { annotation in
            if annotation.title == mapItem.name{
                self.mapView.selectAnnotation(annotation, animated: true)
                self.zoomToFit(selectedAnnotation: annotation)
                self.selectedAnnotation = annotation
                UIView.animate(withDuration: 0.5) {
                    self.removeOverlayButton.alpha = 1
                    self.centerMapButton.alpha = 0
                }
                
            }
        }
    }
    
    func addPolyLine(forDestinationMapItem destinationMapItem: MKMapItem) {
        searchInputView.directionsEnabled = true
        searchInputView.disableViewInteraction(directionsEnabled: true)
        generatePolyLine(forDestinationMapItem: destinationMapItem)
    }
    
    func handleSearch(withSearchText searchText: String) {
        //so when we have a new search we immediately remove old MKPoint annotations from a previous search
        removeAnnotations()
        //coordinates is essentially the user location
       presentSearchedAnnotations(searchText: searchText)
    }
    
    func animateCenterMapButton(expansionState: ExpansionState, hideButton: Bool) {
        switch expansionState {
        case .NotExpanded:
            UIView.animate(withDuration: 0.25) {
                self.centerMapButton.frame.origin.y -= 250
            }
            if hideButton{
                self.centerMapButton.alpha = 0
            }else{
                self.centerMapButton.alpha = 1
            }
        case .PartiallyExpanded:
            if hideButton{
                self.centerMapButton.alpha = 0
            }else{
                UIView.animate(withDuration: 0.25) {
                    self.centerMapButton.frame.origin.y += 250
                }
            }
                
        case .FullyExpanded:
            if !hideButton{
                UIView.animate(withDuration: 0.25) {
                    self.centerMapButton.alpha = 1
                }
            }
        }
    }
  
}

//MARK: - CLLocationManagerDelegate
extension MapController: CLLocationManagerDelegate{
    private func enableLocationServices(){
        locationRequestController.delegate = self
        switch locationManager.authorizationStatus{
        case .notDetermined:
            //this needs to be done on the main queue or it wont work
            DispatchQueue.main.async {
                self.present(self.locationRequestController, animated: true)
            }
            
        case .restricted:
            print("Location auth status is  restricted")
        case .denied:
            print("Location auth status is denied")
        case .authorizedAlways:
            print("Location auth status is authorizedAlways")
        case .authorizedWhenInUse:
            print("Location auth status is authorizedWhenInUse")
        @unknown default:
            assertionFailure()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard locationManager.location != nil else{
            print("Error setting location")
            return
        }
    }
}

//MARK: - MKMapViewDelegate
extension MapController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //our overlay is the poly line
        guard let route = self.currentRoute else{ return MKOverlayRenderer() }
        let polyline = route.polyline
        let lineRenderer = MKPolylineRenderer(overlay: polyline)
        lineRenderer.strokeColor = .mainBlue()
        lineRenderer.lineWidth = 10
        return lineRenderer
    }
}


//MARK: - MapKit Helper Functions
extension MapController{
    //We are setting some coordinates based on our user's annotation and the selected annotation then defining a region based on those coordinates that using it to set the region for our mapView.
    
    // FIXME: - Not properly zooming in, bug to fix
    private func zoomToFit(selectedAnnotation: MKAnnotation?){
        if mapView.annotations.count == 0{
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 100)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -100)
        
        if let selectedAnnotation = selectedAnnotation{
            for annotation in mapView.annotations{
                if let userAnno = annotation as? MKUserLocation{
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, userAnno.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, userAnno.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmin(bottomRightCoordinate.longitude, userAnno.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmax(bottomRightCoordinate.latitude, userAnno.coordinate.latitude)
                }
                if annotation.title == selectedAnnotation.title{
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
            var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.65, longitude: topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.65), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 3.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 3.0))
            
            region = mapView.regionThatFits(region)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func generatePolyLine(forDestinationMapItem destinationMapItem: MKMapItem){
        let request = MKDirections.Request()
        //devices current location
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destinationMapItem
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response = response else{ return }
            //.routes gives an array of route objects representing the directions between the start and end points. First element is usually the fastest route
            self.currentRoute = response.routes[0]
            if let polyLine = self.currentRoute?.polyline{
                self.mapView.addOverlay(polyLine)
            }
        }
    }
    
    private func presentSearchedAnnotations(searchText: String){
        guard let coordinates = locationManager.location?.coordinate else{ return }
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 2000, longitudinalMeters: 2000)
        searchBy(naturalLanguageQuery: searchText, region: region, coordinates: coordinates) { response, error in
            response?.mapItems.forEach({ mapItem in
                //creating map annotations
                let annotation = MKPointAnnotation()
                annotation.title = mapItem.name
                annotation.coordinate = mapItem.placemark.coordinate
                self.mapView.addAnnotation(annotation)
            })
            self.searchInputView.recievedResults = response?.mapItems
        }
    }
    
    private func centerMapOnUserLocation(loadAnnotations: Bool){
        guard let coordinates = locationManager.location?.coordinate else{ return }
        let coordinateRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        
        if loadAnnotations{
            loadInitialSearchData(searchQuery: "Food")
        }
    }
    
    private func searchBy(naturalLanguageQuery: String, region: MKCoordinateRegion, coordinates: CLLocationCoordinate2D, completion: @escaping(_ response: MKLocalSearch.Response?,_ error: NSError?) -> ()){
         //creating a local search request so it shows results near you instead of around the world
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = naturalLanguageQuery
        request.region = region
        
        //creating the MKLocalSearch object which takes in a local search request that we created above
        let search = MKLocalSearch(request: request)
        //starts the search and delivers the results of the specified completion handler.
        search.start { response, error in
            guard let response = response else{
                completion(nil, error! as NSError)
                return
            }
            completion(response, nil)
        }
    }
    
    private func removeAnnotations(){
        mapView.annotations.forEach { annotation in
            //we casted it as an MKPointAnnoation since the user location is an MKAnnotation and we dont want to remove that.
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    private func loadInitialSearchData(searchQuery: String){
        presentSearchedAnnotations(searchText: searchQuery)
    }
    
}

//MARK: - LocationRequestControllerDelegate
extension MapController: LocationRequestControllerDelegate{
    func handleRequestLocationAuth() {
        locationManager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.centerMapOnUserLocation(loadAnnotations: false)
        }
        
    }
}

