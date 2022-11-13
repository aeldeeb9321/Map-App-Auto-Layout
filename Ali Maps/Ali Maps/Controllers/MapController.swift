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
    
    private lazy var searchInputView: SearchInputView = {
        let inputView = SearchInputView()
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
        centerMapOnUserLocation()
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
    }
    
    private func configureMapView(){
        mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        view.addSubview(mapView)
        mapView.addContstraintsToFillView(view: view)
    }
 
    //MARK: - Selectors
    @objc private func handleCenterUserLocation(){
        centerMapOnUserLocation()
    }
}

//MARK: - SearchInputViewDelegate
extension MapController: SearchInputViewDelegate{
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
            UIView.animate(withDuration: 0.25) {
                self.centerMapButton.alpha = 1
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

//MARK: - MapKit Helper Functions
extension MapController{
    func centerMapOnUserLocation(){
        guard let coordinates = locationManager.location?.coordinate else{ return }
        let coordinateRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

//MARK: - LocationRequestControllerDelegate
extension MapController: LocationRequestControllerDelegate{
    func handleRequestLocationAuth() {
        locationManager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.centerMapOnUserLocation()
        }
        
    }
}

