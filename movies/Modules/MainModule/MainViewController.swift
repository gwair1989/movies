//
//  MainViewController.swift
//  movies
//
//  Created by Oleksandr Khalypa on 31.01.2023.
//

import UIKit

class MainViewController: UIViewController {
    
    private let mainView = MainView()
    private var viewModel: MainViewModelProtocol
    private var timer: Timer?
    
    init(viewModel: MainViewModelProtocol = MainViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
    }
    
    
    private func setupNavBar() {
        title = "Popular Movies"
        if #unavailable(iOS 16) {
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        let image = UIImage(systemName: "arrow.up.arrow.down")
        let filterButton = UIBarButtonItem(image: image, style: .plain,
                                            target: self,
                                            action: #selector(tapFilterButton))
        filterButton.tintColor = .black
        filterButton.menu = addMenu(button: filterButton)
        navigationItem.rightBarButtonItem = filterButton
    }

    
    @objc private func tapFilterButton() {
        self.mainView.isSort.toggle()
    }
    
    private func addMenu(button: UIBarButtonItem) -> UIMenu {
        let menuItems = UIMenu(title: "", options: [.displayInline], children: [
            UIAction(title: "Sort by rating",
                     image: mainView.isSort ? UIImage(systemName: "arrow.down") : UIImage(systemName: "arrow.up"),
                     state: mainView.isSort ? .off : .on,
                     handler: {[weak self] action in
                         guard let self else { return }
                         self.mainView.isSort.toggle()
                         button.menu = self.addMenu(button: button)
            })
        ])
        return menuItems
    }
    
    
    private func bind() {
        viewModel.model.bind { [weak self] movies in
            guard let self,  !movies.isEmpty else { return }
            self.mainView.configure(newMovies: movies)
        }
        
        mainView.getNextMovies = { [weak self] in
            guard let self else { return }
            self.viewModel.filter.page += 1
        }
        
        mainView.didClickCell.bind { [weak self] id in
            guard let self, let id else { return }
            let detailVC = DetailsViewController(id: id)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        
        mainView.searchTerm.bind { [weak self] searchTerm in
            guard let self = self else { return }
            if searchTerm == nil {
                self.mainView.movies = []
                self.viewModel.filter = Filter(typeRequest: .main, page: 1)

            }
            guard let searchTerm = searchTerm else { return }
            if self.timer != nil {
                self.timer?.invalidate()
            }
            
            guard !searchTerm.isEmpty else { return }
            self.mainView.movies = []
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { (_) in
                self.viewModel.query = searchTerm
            })
        }
        
    }
}
