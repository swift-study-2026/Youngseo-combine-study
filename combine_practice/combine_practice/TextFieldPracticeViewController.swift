//
//  TextFieldPracticeViewController.swift
//  combine_practice
//
//  Created by youngseo on 4/26/26.
//

import UIKit
import Combine

final class TextFieldPracticeViewController: UIViewController {

    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let loading = PassthroughSubject<Bool, Never>()

    // MARK: - UI Components
    
    private let textField = UITextField()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let button = UIButton()
    private let indicator = UIActivityIndicatorView(style: .medium)

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

        [textField, emailTextField, passwordTextField].forEach {
            $0.borderStyle = .roundedRect
        }

        textField.placeholder = "Search"
        emailTextField.placeholder = "Email"
        passwordTextField.placeholder = "Password"

        button.setTitle("Button", for: .normal)
        button.backgroundColor = .black
        button.isEnabled = false
    }

    private func setLayout() {
        let stack = UIStackView(arrangedSubviews: [
            textField,
            emailTextField,
            passwordTextField,
            button,
            indicator
        ])

        stack.axis = .vertical
        stack.spacing = 12

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Binding
    
    private func bind() {

        textField.publisher(for: \.text)
            .compactMap { $0 }

            // Step 1
            .handleEvents(receiveOutput: {
                print("1️⃣ 입력:", $0)
            })

            // Step 5
            .filter { !$0.isEmpty }
            .handleEvents(receiveOutput: {
                print("5️⃣ 필터 통과:", $0)
            })

            // Step 2
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: {
                print("2️⃣ 최적화:", $0)
            })

            // Step 3
            .map { $0.count >= 5 }
            .handleEvents(receiveOutput: {
                print("3️⃣ 버튼 상태:", $0)
            })

            .sink { [weak self] isEnabled in
                self?.button.isEnabled = isEnabled
            }
            .store(in: &cancellables)


        // Step 4 — 검증 (CombineLatest)
        let emailPublisher = emailTextField.publisher(for: \.text)
            .compactMap { $0 }

        let passwordPublisher = passwordTextField.publisher(for: \.text)
            .compactMap { $0 }

        Publishers.CombineLatest(emailPublisher, passwordPublisher)
            .map { email, password in
                email.contains("@") && password.count >= 6
            }
            .handleEvents(receiveOutput: {
                print("4️⃣ 로그인 가능:", $0)
            })
            .sink { [weak self] isValid in
                self?.button.backgroundColor = isValid ? .blue : .black
            }
            .store(in: &cancellables)


        // Step 6 — 사이드 이펙트
        textField.publisher(for: \.text)
            .compactMap { $0 }
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)

            .handleEvents(receiveOutput: { [weak self] _ in
                print("6️⃣ 로딩 시작")
                self?.loading.send(true)
            })

            .sink { [weak self] query in
                print("6️⃣ API 요청:", query)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("6️⃣ 로딩 종료")
                    self?.loading.send(false)
                }
            }
            .store(in: &cancellables)


        // Step 7 — 상태 전파
        loading
            .handleEvents(receiveOutput: {
                print("7️⃣ 로딩 상태:", $0)
            })
            .sink { [weak self] isLoading in
                isLoading
                ? self?.indicator.startAnimating()
                : self?.indicator.stopAnimating()
            }
            .store(in: &cancellables)
    }
}
