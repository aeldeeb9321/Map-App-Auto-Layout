//
//  LocationRequestController.swift
//  Ali Maps
//
//  Created by Ali Eldeeb on 11/11/22.
//

import UIKit

protocol LocationRequestControllerDelegate: AnyObject{
    func handleRequestLocationAuth()
}
class LocationRequestController: UIViewController{
    //MARK: - Properties
    weak var delegate: LocationRequestControllerDelegate?
    
    private let bluePinImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = #imageLiteral(resourceName: "blue-pin")
        iv.setDimesions(height: 200, width: 200)
        return iv
    }()
    
    private let allowLocationLabel: UILabel = {
        let label = UILabel()
        let atts: [NSAttributedString.Key : Any] = [.font: UIFont.boldSystemFont(ofSize: 24)]
        let attributedString = NSMutableAttributedString(string: "Allow Location\n", attributes: atts)
        attributedString.append(NSAttributedString(string: "Please enable location services for map functionality", attributes: [.font : UIFont.systemFont(ofSize: 16)]))
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = attributedString
        return label
    }()
    
    private lazy var enableLocationButton: UIButton = {
        let button = UIButton().makeButton(withTitle: "Enable Location", titleColor: .white, buttonColor: .systemBlue, isRounded: true)
        button.addTarget(self, action: #selector(handleEnableLocationButton), for: .touchUpInside)
        return button
    }()
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    //MARK: - Helpers
    
    private func configureUI(){
        view.backgroundColor = .white
        view.addSubview(bluePinImageView)
        bluePinImageView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 100)
        bluePinImageView.centerX(inView: view)
        
        view.addSubview(allowLocationLabel)
        allowLocationLabel.anchor(top: bluePinImageView.bottomAnchor,leading: view.safeAreaLayoutGuide.leadingAnchor,trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingTop: 32, paddingLeading: 32, paddingTrailing: 32)
     
        view.addSubview(enableLocationButton)
        enableLocationButton.anchor(top: allowLocationLabel.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, paddingTop: 16, paddingLeading: 75, paddingTrailing: 75)
    }
    
    //MARK: - Selectors
    @objc private func handleEnableLocationButton(){
        delegate?.handleRequestLocationAuth()
        dismiss(animated: true)
    }
}
