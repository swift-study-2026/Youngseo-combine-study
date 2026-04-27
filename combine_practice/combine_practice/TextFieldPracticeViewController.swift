//
//  TextFieldPracticeViewController.swift
//  combine_practice
//
//  Created by youngseo on 4/26/26.
//

import UIKit

import Combine
import SnapKit
import Then

final class TextFieldPracticeViewController: UIViewController {

    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let loading = PassthroughSubject<Bool, Never>()

    // MARK: - UI Components
    
    private let textField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.placeholder = "검색어 입력 (5글자 이상)"
    }

    private let emailTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.placeholder = "이메일"
    }

    private let passwordTextField = UITextField().then {
        $0.borderStyle = .roundedRect
        $0.placeholder = "비밀번호 (6자 이상)"
    }

    private let button = UIButton().then {
        $0.setTitle("버튼", for: .normal)
        $0.backgroundColor = .black
        $0.layer.cornerRadius = 8
        $0.isEnabled = false
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
    }

    private func setLayout() {
        [textField, emailTextField, passwordTextField, button, indicator].forEach {
            view.addSubview($0)
        }

        textField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(textField)
            $0.height.equalTo(44)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalTo(textField)
            $0.height.equalTo(44)
        }

        button.snp.makeConstraints {
            $0.top.equalTo(passwordTextField.snp.bottom).offset(24)
            $0.leading.trailing.equalTo(textField)
            $0.height.equalTo(50)
        }

        indicator.snp.makeConstraints {
            $0.top.equalTo(button.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
    }

    // MARK: - Binding
    
    private func bind() {

        let inputPublisher =
        NotificationCenter.default.publisher(
            for: UITextField.textDidChangeNotification,
            object: textField
        )
        .compactMap { ($0.object as? UITextField)?.text }

        inputPublisher

            .handleEvents(receiveOutput: {
                print("1️⃣ 입력:", $0)
            })

            .filter { !$0.isEmpty }
            .handleEvents(receiveOutput: {
                print("5️⃣ 필터:", $0)
            })

            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: {
                print("2️⃣ 최적화:", $0)
            })

            .map { $0.count >= 5 }
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: {
                print("3️⃣ 버튼 상태:", $0)
            })
            .sink { [weak self] isEnabled in
                self?.button.isEnabled = isEnabled
                self?.button.backgroundColor = isEnabled ? .blue : .black
            }
            .store(in: &cancellables)


        let emailPublisher = emailTextField.publisher(for: \.text).compactMap { $0 }
        let passwordPublisher = passwordTextField.publisher(for: \.text).compactMap { $0 }

        Publishers.CombineLatest(emailPublisher, passwordPublisher)
            .map { $0.contains("@") && $1.count >= 6 }
            .receive(on: RunLoop.main)
            .handleEvents(receiveOutput: {
                print("4️⃣ 로그인 가능:", $0)
            })
            .sink { [weak self] isValid in
                self?.button.isEnabled = isValid
                self?.button.backgroundColor = isValid ? .blue : .black
            }
            .store(in: &cancellables)


        inputPublisher
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


        loading
            .handleEvents(receiveOutput: {
                print("7️⃣ 상태:", $0)
            })
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
}
