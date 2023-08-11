// Copyright © 2022 Beldex All rights reserved.
import Foundation
import UIKit
import BChatUIKit

public var navigationflowTag = true
@available(iOS 13.0, *)
class LandingVC: BaseVC {
    
//    @IBOutlet weak var createRef:UIButton!
//    @IBOutlet weak var signRef:UIButton!
//    @IBOutlet weak var TermsRef:UIButton!
//    @IBOutlet weak var gifimg:UIImageView!
//    @IBOutlet weak var btnterms:UIButton!
    
    let gifimg = UIImageView()
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hey there!"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.tintColor = .white
        return label
    }()
    private let titleLabel2: UILabel = {
        let label = UILabel()
        label.text = "Chat Anonymously Now."
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.tintColor = .white
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "The private Web3 messaging app that protects your conversational freedom.Create an account instantly."
        label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.tintColor = .blue
        return label
    }()
    
    
    private let btnterms: UIButton = {
        let button = UIButton()
        button.addTarget(LandingVC.self, action: #selector(TermsAction), for: .touchUpInside)
        return button
    }()
    private let TermsRef: UIButton = {
        let button = UIButton()
        button.setTitle("Terms & Conditions", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        button.addTarget(LandingVC.self, action: #selector(TermsAction), for: .touchUpInside)
        return button
    }()
    //Set up Create account button
    private let createRef: UIButton = {
        let button = UIButton()
        button.setTitle("Create Account", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.backgroundColor =  UIColor(red: 170.0/255, green: 170.0/255, blue: 170.0/255, alpha: 1.0)
        button.layer.cornerRadius = 10
        button.widthAnchor.constraint(equalToConstant: 298).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.addTarget(LandingVC.self, action: #selector(CraeteAction), for: .touchUpInside)
        return button
    }()
    
    
    private let signRef: UIButton = {
        let button = UIButton()
        button.setTitle("Sign In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        button.backgroundColor =  UIColor(red: 59.0/255, green: 57.0/255, blue: 70.0/255, alpha: 1.0)
        button.layer.cornerRadius = 10
        button.addTarget(LandingVC.self, action: #selector(SignINAction), for: .touchUpInside)
        button.widthAnchor.constraint(equalToConstant: 298).isActive = true
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        return button
    }()
    
    
    private let landingStackView: UIStackView = {
        let landingStackView = UIStackView()
        landingStackView.axis = .horizontal
        landingStackView.alignment = .center
        landingStackView.set(.height, to: Values.largeButtonHeight + Values.smallSpacing * 2)
        return landingStackView
    }()
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 20
        return stackView
    }()
    
    
    var flagvalue:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGradientBackground()
        AppModeManager.shared.setCurrentAppMode(to: .dark)
        // Do any additional setup after loading the view.
        guard let navigationBar = navigationController?.navigationBar else { return }
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Colors.navigationBarBackground2
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance;
            navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
        } else {
            navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = false
            navigationBar.barTintColor = Colors.navigationBarBackground2
        }
        self.navigationItem.title = ""
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        signRef.layer.cornerRadius = 6
        createRef.layer.cornerRadius = 6
        
        if isLightMode {
            gifAnimationLightMode()
            termsAndConditionsUtilitiesDark()
        }else {
            gifAnimationDarkMode()
            termsAndConditionsUtilitiesWhite()
        }
        self.gifimg.heightAnchor.constraint(equalToConstant: 300).isActive = true
        self.gifimg.widthAnchor.constraint(equalToConstant: 210).isActive = true
        self.gifimg.loadGif(name: "gifAnimation_dark")
        self.gifimg.contentMode = .scaleAspectFit
        stackView.addArrangedSubview(gifimg)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(titleLabel2)
        stackView.addArrangedSubview(subtitleLabel)
        landingStackView.addArrangedSubview(btnterms)
        landingStackView.addArrangedSubview(TermsRef)
        stackView.addArrangedSubview(landingStackView)
        stackView.addArrangedSubview(createRef)
        stackView.addArrangedSubview(signRef)
        
        
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gifimg.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 89),
            gifimg.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -89),
            signRef.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            signRef.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            createRef.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45),
            createRef.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 142),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -142),
            titleLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 71.67),
            titleLabel2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -71.33),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
//            btnterms.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
//            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            

            
            
            
        ])
        
        
        
    }
    @objc override internal func handleAppModeChangedNotification(_ notification: Notification) {
        super.handleAppModeChangedNotification(notification)
        if isLightMode {
            gifAnimationLightMode()
            termsAndConditionsUtilitiesDark()
        }
        if isSystemDefault {
            if isLightMode {
                gifAnimationLightMode()
                termsAndConditionsUtilitiesDark()
            }else {
                gifAnimationDarkMode()
                termsAndConditionsUtilitiesWhite()
            }
        }
        else {
            gifAnimationDarkMode()
            termsAndConditionsUtilitiesWhite()
        }
    }
    
    // MARK: - Animation
    func gifAnimationLightMode(){
        do {
            let imageData = try Data(contentsOf: Bundle.main.url(forResource: "gifAnimation_white", withExtension: "gif")!)
            gifimg.image = UIImage.gif(data: imageData)
        } catch {
            print(error)
        }
    }
    func gifAnimationDarkMode(){
        do {
            let imageData = try Data(contentsOf: Bundle.main.url(forResource: "gifAnimation_dark", withExtension: "gif")!)
            gifimg.image = UIImage.gif(data: imageData)
        } catch {
            print(error)
        }
    }
    
    // MARK: - TermsAndConditions
    func termsAndConditionsUtilitiesWhite(){
        createRef.backgroundColor = UIColor.lightGray
        let image1 = UIImage(named: "unChecked_dark.png")!
        let tintedImage = image1.withRenderingMode(.alwaysTemplate)
        self.btnterms.setImage(tintedImage, for: .normal)
        btnterms.tintColor = .white
    }
    func termsAndConditionsUtilitiesDark(){
        createRef.backgroundColor = UIColor.lightGray
        let image1 = UIImage(named: "unChecked_dark.png")!
        let tintedImage = image1.withRenderingMode(.alwaysTemplate)
        self.btnterms.setImage(tintedImage, for: .normal)
        btnterms.tintColor = .black
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
        guard let navigationBar = navigationController?.navigationBar else { return }
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Colors.navigationBarBackground2
            appearance.shadowColor = .clear
            navigationBar.standardAppearance = appearance;
            navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
        } else {
            navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = false
            navigationBar.barTintColor = Colors.navigationBarBackground2
        }
        flagvalue = false
        if isLightMode {
            termsAndConditionsUtilitiesDark()
        }else {
            termsAndConditionsUtilitiesWhite()
        }
    }
    
    // MARK: - Create Account
    
    @objc func CraeteAction(sender:UIButton){
        if flagvalue == true {
            let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DisplayNameVC") as! DisplayNameVC
            navigationflowTag = false
            self.navigationController?.pushViewController(vc, animated: true)
        }else{
            _ = CustomAlertController.alert(title: Alert.Alert_BChat_title, message: String(format: Alert.Alert_BChat_Terms_Condition_Message) , acceptMessage:NSLocalizedString(Alert.Alert_BChat_Ok, comment: "") , acceptBlock: {

            })
        }
    }
    // MARK: - Sign InAccount
    @objc func SignINAction(sender:UIButton){
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RecoverySeedVC") as! RecoverySeedVC
        navigationflowTag = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @objc func TermsAction(sender:UIButton){
        let urlAsString: String?
        urlAsString = bchat_TermsConditionUrl_Link
        if let urlAsString = urlAsString {
            let url = URL(string: urlAsString)!
            UIApplication.shared.open(url)
        }
    }
    
    @objc func termsandconditionAction(sender:UIButton){
        btnterms.isSelected = !btnterms.isSelected
        if btnterms.isSelected {
            flagvalue = true
            createRef.backgroundColor = Colors.bchat_button_clr
            let img = UIImage(named: "checked_img.png")!
            let tintedImage = img.withRenderingMode(.alwaysTemplate)
            self.btnterms.setImage(tintedImage, for: .normal)
            btnterms.tintColor = isLightMode ? .black : .white
        }else {
            flagvalue = false
            if isLightMode {
                termsAndConditionsUtilitiesDark()
            }else {
                termsAndConditionsUtilitiesWhite()
            }
        }
    }
    
}
