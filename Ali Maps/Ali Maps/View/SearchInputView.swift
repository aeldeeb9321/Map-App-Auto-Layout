//
//  SearchInputView.swift
//  Ali Maps
//
//  Created by Ali Eldeeb on 11/11/22.
//

import UIKit

private let reuseIdentifier = "tvId"

class SearchInputView: UIView{
    //MARK: - Properties
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
    //MARK: - Selectors
    @objc private func handleSwipeGesutre(sender: UISwipeGestureRecognizer){
        if sender.direction == .up{
            if expansionState == .NotExpanded{
                animateInputView(targetPostion: self.frame.origin.y - 250) { _ in
                    self.expansionState = .PartiallyExpanded
                }
            }else if expansionState == .PartiallyExpanded{
                animateInputView(targetPostion: self.frame.origin.y - 500) { _ in
                    self.expansionState = .FullyExpanded
                }
            }
        }else if sender.direction == .down{
            if expansionState == .FullyExpanded{
                animateInputView(targetPostion: self.frame.origin.y + 500) { _ in
                    self.expansionState = .PartiallyExpanded
                }
            }else if expansionState == .PartiallyExpanded{
                animateInputView(targetPostion: self.frame.origin.y + 250) { _ in
                    self.expansionState = .NotExpanded
                }
            }
        }
    }
}

extension SearchInputView:  UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SeachCell
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
