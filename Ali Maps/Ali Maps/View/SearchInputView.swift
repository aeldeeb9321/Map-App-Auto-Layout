//
//  SearchInputView.swift
//  Ali Maps
//
//  Created by Ali Eldeeb on 11/11/22.
//

import UIKit
import MapKit

private let reuseIdentifier = "tvId"

protocol SearchInputViewDelegate: AnyObject{
    func animateCenterMapButton(expansionState: ExpansionState, hideButton: Bool)
    func handleSearch(withSearchText searchText: String)
}

class SearchInputView: UIView{
    //MARK: - Properties
    weak var delegate: SearchInputViewDelegate?
    weak var mapController: MapController?
    var recievedResults: [MKMapItem]?{
        didSet{
            guard let recievedResults = recievedResults else{ return }
            self.searchResults = recievedResults
        }
    }
    private var searchResults: [MKMapItem]?{
        didSet{
            //we need to reload Data or else the recieved map items wont show up in our tableView
            self.tableView.reloadData()
        }
    }
    private var expansionState: ExpansionState!
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 5
        view.alpha = 0.8
        view.setDimesions(height: 8, width: 45)
        return view
    }()
    
    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for  place or address"
        bar.barStyle = .black
        bar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        bar.delegate = self
        return bar
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.rowHeight = 72
        tv.delegate = self
        tv.dataSource = self
        tv.register(SeachCell.self, forCellReuseIdentifier: reuseIdentifier)
        return tv
    }()
    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGroupedBackground
        configureViewUI()
        expansionState = .NotExpanded //initial state set
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Helpers
    private func configureViewUI(){
        addSubview(indicatorView)
        indicatorView.centerX(inView: self)
        indicatorView.anchor(top: safeAreaLayoutGuide.topAnchor, paddingTop: 10)
        
        addSubview(searchBar)
        searchBar.anchor(top: indicatorView.bottomAnchor, leading: safeAreaLayoutGuide.leadingAnchor, trailing: safeAreaLayoutGuide.trailingAnchor, paddingTop: 8, paddingLeading: 12, paddingTrailing: 12)
        
        addSubview(tableView)
        tableView.anchor(top: searchBar.bottomAnchor, leading: safeAreaLayoutGuide.leadingAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, trailing: safeAreaLayoutGuide.trailingAnchor, paddingTop: 8)
        configureGestureRecognizers()
    }
    
    private func configureGestureRecognizers(){
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesutre))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesutre))
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)
    }
    
    private func animateInputView(targetPostion: CGFloat, completion: @escaping(Bool) -> ()){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.frame.origin.y = targetPostion
        } completion: { bool in
            completion(bool)
        }
    }
    
    private func dismissOnSearch(){
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        searchBar.text = nil
        animateInputView(targetPostion: self.frame.origin.y + 450) { _ in
            self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
            self.expansionState = .PartiallyExpanded
        }
    }
    //MARK: - Selectors
    @objc private func handleSwipeGesutre(sender: UISwipeGestureRecognizer){
        if sender.direction == .up{
            if expansionState == .NotExpanded{
                delegate?.animateCenterMapButton(expansionState: expansionState, hideButton: false)
                animateInputView(targetPostion: self.frame.origin.y - 250) { _ in
                    self.expansionState = .PartiallyExpanded
                }
            }else if expansionState == .PartiallyExpanded{
                delegate?.animateCenterMapButton(expansionState: expansionState, hideButton: true)
                animateInputView(targetPostion: self.frame.origin.y - 450) { _ in
                    self.expansionState = .FullyExpanded
                }
            }
        }else if sender.direction == .down{
            
            if expansionState == .FullyExpanded{
                self.searchBar.endEditing(true)
                self.searchBar.showsCancelButton = false
                animateInputView(targetPostion: self.frame.origin.y + 450) { _ in
                    self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
                    self.expansionState = .PartiallyExpanded
                }
            }else if expansionState == .PartiallyExpanded{
                delegate?.animateCenterMapButton(expansionState: expansionState, hideButton: false)
                animateInputView(targetPostion: self.frame.origin.y + 250) { _ in
                    self.expansionState = .NotExpanded
                }
            }
        }
    }
}

//MARK: - UITableViewDataSource/UITableViewDelegate
extension SearchInputView:  UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SeachCell
        if let controller = mapController{
            cell.delegate = controller
        }
        if let searchResults = searchResults{
            cell.mapItem = searchResults[indexPath.row]
            
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //making sure our searchresults exists, otherwise we return 0
        guard let searchResults = searchResults else{ return 0 }
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - UISearchBarDelegate
extension SearchInputView: UISearchBarDelegate{
    //executes when we hit that search button
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        delegate?.handleSearch(withSearchText: searchText)
        dismissOnSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if expansionState == .NotExpanded{
            
            delegate?.animateCenterMapButton(expansionState: expansionState, hideButton: true)
            
            animateInputView(targetPostion: self.frame.origin.y - 700) { _ in
                self.expansionState = .FullyExpanded
            }
        }else if expansionState == .PartiallyExpanded{
            
            delegate?.animateCenterMapButton(expansionState: expansionState, hideButton: true)
            
            animateInputView(targetPostion: self.frame.origin.y - 450) { _ in
                self.expansionState = .FullyExpanded
            }
        }
        searchBar.showsCancelButton = true
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissOnSearch()
            
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
}
