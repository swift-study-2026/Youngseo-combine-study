//
//  SearchViewController.swift
//  combine_practice
//
//  Created by youngseo on 4/26/26.
//

import UIKit

import Combine
import SnapKit
import Then

final class SearchViewController: UIViewController {

    // MARK: - Properties
    
    private let viewModel = SearchViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let searchSubject = PassthroughSubject<String, Never>()
    private var users: [User] = []

    // MARK: - UI Components
    
    private let textField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.placeholder = "깃허브 유저 찾아보기!"
    }

    private let tableView = UITableView().then {
        $0.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private let indicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setLayout()
        bind()
    }

    // MARK: - Setup Methods
    
    private func setUI() {
        view.backgroundColor = .white

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func setLayout() {
        [textField, indicator, tableView].forEach {
            view.addSubview($0)
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        indicator.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(indicator.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Binding
    
    private func bind() {

        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        let input = SearchViewModel.Input(
            searchText: searchSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions
    
    @objc private func textChanged() {
        searchSubject.send(textField.text ?? "")
    }

    // MARK: - Private Methods
    
    private func render(_ state: ViewState) {
        switch state {

        case .idle:
            indicator.stopAnimating()
            tableView.isHidden = false

        case .loading:
            indicator.startAnimating()
            tableView.isHidden = true

        case .success(let users):
            indicator.stopAnimating()
            tableView.isHidden = false
            self.users = users
            tableView.reloadData()

        case .empty:
            indicator.stopAnimating()
            tableView.isHidden = false
            self.users = []
            tableView.reloadData()

        case .error(let message):
            indicator.stopAnimating()
            tableView.isHidden = false
            print("에러:", message)
        }
    }
}

// MARK: - Extensions

extension SearchViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = users[indexPath.row].login
        return cell
    }
}

extension SearchViewController: UITableViewDelegate { }
