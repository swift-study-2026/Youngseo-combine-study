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
        $0.layer.cornerRadius = 10
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
        [emailTextField, passwordTextField, button, indicator].forEach {
            view.addSubview($0)
        }

        emailTextField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(140)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        passwordTextField.snp.makeConstraints {
            $0.top.equalTo(emailTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalTo(emailTextField)
            $0.height.equalTo(44)
        }

        button.snp.makeConstraints {
            $0.top.equalTo(passwordTextField.snp.bottom).offset(24)
            $0.leading.trailing.equalTo(emailTextField)
            $0.height.equalTo(50)
        }

        indicator.snp.makeConstraints {
            $0.top.equalTo(button.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
    }

    // MARK: - Binding
    
    private func bind() {

        let emailPublisher =
        NotificationCenter.default.publisher(
            for: UITextField.textDidChangeNotification,
            object: emailTextField
        )
        .compactMap { ($0.object as? UITextField)?.text }

        let passwordPublisher =
        NotificationCenter.default.publisher(
            for: UITextField.textDidChangeNotification,
            object: passwordTextField
        )
        .compactMap { ($0.object as? UITextField)?.text }

        // 이메일 + 비밀번호 + 로딩 + debounce
        Publishers.CombineLatest(emailPublisher, passwordPublisher)

            // 입력되면 바로 로딩 시작
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loading.send(true)
            })

            // 0.5초 대기
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)

            // 대기 끝 → 로딩 종료
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loading.send(false)
            })

            // 정규식
            .map { email, password in
                email.contains("@") && password.count >= 6
            }

            .receive(on: RunLoop.main)

            .sink { [weak self] isValid in
                self?.button.isEnabled = isValid
                self?.button.backgroundColor = isValid ? .systemPink : .black
            }
            .store(in: &cancellables)

        // 로딩 → 인디케이터
        loading
            .receive(on: RunLoop.main)
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
