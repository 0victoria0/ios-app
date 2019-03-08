import UIKit

class ChangeNumberVerificationCodeViewController: ChangeNumberViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var verificationCodeField: VerificationCodeField!
    @IBOutlet weak var resendButton: CountDownButton!
    
    private let resendInterval = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = Localized.NAVIGATION_TITLE_ENTER_VERIFICATION_CODE(mobileNumber: context.newNumberRepresentation)
        resendButton.normalTitle = Localized.BUTTON_TITLE_RESEND_CODE
        resendButton.pendingTitleTemplate = Localized.BUTTON_TITLE_RESEND_CODE_PENDING
        resendButton.beginCountDown(resendInterval)
        verificationCodeField.becomeFirstResponder()
        bottomWrapperBottomConstraint.update(offset: -(ChangeNumberViewController.lastKeyboardFrame.height + BottomWrapperView.defaultLayoutInset.bottom))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resendButton.restartTimerIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resendButton.releaseTimer()
    }
    
    deinit {
        ReCaptchaManager.shared.clean()
    }
    
    override func continueAction(_ sender: Any) {
        checkVerificationCodeAction(sender)
    }

    @IBAction func checkVerificationCodeAction(_ sender: Any) {
        let continueButton = bottomWrapperView.continueButton
        let code = verificationCodeField.text
        let context = self.context
        if code.count != verificationCodeField.numberOfDigits {
            continueButton?.isEnabled = false
        } else {
            continueButton?.isEnabled = true
            continueButton?.isBusy = true
            let request = AccountRequest.createAccountRequest(verificationCode: code, registrationId: nil, pin: context.pin, sessionSecret: nil)
            AccountAPI.shared.changePhoneNumber(verificationId: context.verificationId, accountRequest: request, completion: { [weak self] (result) in
                guard let weakSelf = self else {
                    return
                }
                switch result {
                case .success:
                    if let old = AccountAPI.shared.account {
                        let new = Account(withAccount: old, phone: context.newNumber)
                        AccountAPI.shared.account = new
                    }
                    weakSelf.verificationCodeField.resignFirstResponder()
                    weakSelf.alert(nil, message: Localized.PROFILE_CHANGE_NUMBER_SUCCEEDED, handler: { (_) in
                        weakSelf.navigationController?.dismiss(animated: true, completion: nil)
                    })
                case let .failure(error):
                    weakSelf.bottomWrapperView.continueButton.isBusy = false
                    weakSelf.verificationCodeField.clear()
                    weakSelf.alert(error.localizedDescription)
                }
            })
        }
    }

    @IBAction func resendAction(_ sender: Any) {
        resendButton.isBusy = true
        sendCode(reCaptchaToken: nil)
    }
    
    private func sendCode(reCaptchaToken token: String?) {
        AccountAPI.shared.sendCode(to: context.newNumber, reCaptchaToken: token, purpose: .phone) { [weak self] (result) in
            guard let weakSelf = self else {
                return
            }
            switch result {
            case .success(let verification):
                weakSelf.context.verificationId = verification.id
                weakSelf.resendButton.isBusy = false
                weakSelf.resendButton.beginCountDown(weakSelf.resendInterval)
            case let.failure(error):
                if error.code == 10005 {
                    ReCaptchaManager.shared.validate(onViewController: weakSelf) { (result) in
                        switch result {
                        case .success(let token):
                            self?.sendCode(reCaptchaToken: token)
                        default:
                            self?.resendButton.isBusy = false
                        }
                    }
                } else {
                    weakSelf.alert(error.localizedDescription)
                    weakSelf.resendButton.isBusy = false
                }
            }
        }
    }
    
    class func instance(context: ChangeNumberContext) -> ChangeNumberVerificationCodeViewController {
        let vc = Storyboard.contact.instantiateViewController(withIdentifier: "verification_code") as! ChangeNumberVerificationCodeViewController
        vc.context = context
        return vc
    }

}
