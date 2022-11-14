//
//  SearchCell.swift
//  Ali Maps
//
//  Created by Ali Eldeeb on 11/11/22.
//

import UIKit
import MapKit

protocol SearchCellDelegate: AnyObject{
    func distanceFromUser(location: CLLocation) -> CLLocationDistance?
}

class SeachCell: UITableViewCell{
    //MARK: - Properties
    weak var delegate: SearchCellDelegate?
    var mapItem: MKMapItem? {
        didSet{
            configureCell()
        }
    }
    private lazy var imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .mainPink()
        view.addSubview(locationImageView)
        locationImageView.centerX(inView: view)
        locationImageView.centerY(inView: view)
        locationImageView.setDimesions(height: 20, width: 20)
        view.setDimesions(height: 38, width: 38)
        return view
    }()
    
    private let locationImageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .mainPink()
        iv.image = #imageLiteral(resourceName: "baseline_location_on_white_24pt_3x")
        return iv
    }()
    
    private let locationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    private let locationDistanceLabel: UILabel = {
        let label = UILabel().makeLabel(textColor: .lightGray, withFont: UIFont.systemFont(ofSize: 14))
        return label
    }()
    
    //MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCellComponents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Helpers
    private func configureCellComponents(){
        addSubview(imageContainerView)
        imageContainerView.centerY(inView: self)
        imageContainerView.anchor(leading: safeAreaLayoutGuide.leadingAnchor, paddingLeading: 8)
        imageContainerView.layer.cornerRadius = 19
        
        let locationInfoStack = UIStackView(arrangedSubviews: [locationTitleLabel, locationDistanceLabel])
        locationInfoStack.axis = .vertical
        locationInfoStack.alignment = .leading
        locationInfoStack.spacing = 2
        locationInfoStack.distribution = .fillProportionally
        addSubview(locationInfoStack)
        locationInfoStack.centerY(inView: self)
        locationInfoStack.anchor(leading: imageContainerView.trailingAnchor, paddingLeading: 5)
    }
    
    private func configureCell(){
        guard let mapItem = mapItem else{ return }
        self.locationTitleLabel.text = mapItem.name
        
        let distanceFormatter = MKDistanceFormatter()
        distanceFormatter.unitStyle = .abbreviated
        //We need to get the location of our map item, get user location, then calculate the distance between the two and then set Our locationDistance text
        guard let mapItemLocation = mapItem.placemark.location else{ return }
        guard let distanceFromUser = delegate?.distanceFromUser(location: mapItemLocation) else{ return }
        //creates a string representation from the specified distance
        let distanceAsString = distanceFormatter.string(fromDistance: distanceFromUser)
        self.locationDistanceLabel.text = distanceAsString
    }
}
