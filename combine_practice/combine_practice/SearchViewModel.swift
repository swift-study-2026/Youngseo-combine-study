//
//  SearchViewModel.swift
//  combine_practice
//
//  Created by youngseo on 4/26/26.
//

import Foundation
import Combine

// MARK: - Model

struct User: Decodable {
    let id: Int
    let login: String
}

// MARK: - ViewState

enum ViewState {
    case idle
    case loading
    case success([User])
    case empty
    case error(String)
}

// MARK: - ViewModel

final class SearchViewModel {

    // MARK: - Input / Output
    
    struct Input {
        let searchText: AnyPublisher<String, Never>
    }

    struct Output {
        let state: AnyPublisher<ViewState, Never>
    }

    // MARK: - Transform
    
    func transform(input: Input) -> Output {

        let state = input.searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()

            .flatMap { query -> AnyPublisher<ViewState, Never> in

                guard !query.isEmpty else {
                    return Just(.idle).eraseToAnyPublisher()
                }

                let urlString = "https://api.github.com/search/users?q=\(query)"
                guard let url = URL(string: urlString) else {
                    return Just(.error("URL 오류")).eraseToAnyPublisher()
                }

                return URLSession.shared.dataTaskPublisher(for: url)
                    .map(\.data)
                    .decode(type: GitHubResponse.self, decoder: JSONDecoder())

                    .map { response -> ViewState in
                        let users = response.items
                        return users.isEmpty ? .empty : .success(users)
                    }

                    .catch { error in
                        Just(.error(error.localizedDescription))
                    }

                    .prepend(.loading)

                    .eraseToAnyPublisher()
            }

            .eraseToAnyPublisher()

        return Output(state: state)
    }
}

// MARK: - API Response

private struct GitHubResponse: Decodable {
    let items: [User]
}
