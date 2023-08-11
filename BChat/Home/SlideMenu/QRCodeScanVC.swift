// Copyright © 2022 Beldex. All rights reserved.

import UIKit

class QRCodeScanVC: BaseVC {
    
    @IBOutlet weak var backgroundMainView:UIView!
    @IBOutlet weak var ScanQRcode:UIButton!
    @IBOutlet weak var shareref:UIButton!
    @IBOutlet weak var qrCodeImageView:UIImageView!
    @IBOutlet weak var backgroundScanView:UIView!
    @IBOutlet weak var backgroundShareView:UIView!
    @IBOutlet weak var shareImh:UIImageView!
    @IBOutlet weak var scanImg:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setUpGradientBackground()
        setUpNavBarStyle()
        backgroundMainView.layer.cornerRadius = 10
        ScanQRcode.layer.cornerRadius = 6
        shareref.layer.cornerRadius = 6
        backgroundScanView.layer.cornerRadius = 6
        backgroundShareView.layer.cornerRadius = 6
        
        let logoName2 = isLightMode ? "share_dark" : "share"
        shareImh.image = UIImage(named: logoName2)!
        let logoName23 = isLightMode ? "scan_QR_dark" : "scan_QR"
        scanImg.image = UIImage(named: logoName23)!
        self.title = "QR Code"
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        let qrCode = QRCode.generate(for: getUserHexEncodedPublicKey(), hasBackground: true)
        qrCodeImageView.image = qrCode
        qrCodeImageView.contentMode = .scaleAspectFit
        let smallLogo = UIImage(named: "bchat_QR")
        smallLogo?.addToCenter(of: qrCodeImageView)
        
    }
    
    @IBAction func shareAction(sender:UIButton){
        let qrCode = QRCode.generate(for: getUserHexEncodedPublicKey(), hasBackground: true)
        let shareVC = UIActivityViewController(activityItems: [ qrCode ], applicationActivities: nil)
        self.navigationController!.present(shareVC, animated: true, completion: nil)
    }
    
    @IBAction func ScanQRAction(sender:UIButton){
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ScannerQRVC") as! ScannerQRVC
        vc.newChatScanflag = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
extension UIImage {
    
    /// place the imageView inside a container view
    /// - parameter superView: the containerView that you want to place the Image inside
    /// - parameter width: width of imageView, if you opt to not give the value, it will take default value of 100
    /// - parameter height: height of imageView, if you opt to not give the value, it will take default value of 30
    func addToCenter(of superView: UIView, width: CGFloat = 120, height: CGFloat = 50) {
        let overlayImageView = UIImageView(image: self)
        
        overlayImageView.translatesAutoresizingMaskIntoConstraints = false
        overlayImageView.contentMode = .scaleAspectFit
        superView.addSubview(overlayImageView)
        
        let centerXConst = NSLayoutConstraint(item: overlayImageView, attribute: .centerX, relatedBy: .equal, toItem: superView, attribute: .centerX, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: overlayImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 120)
        let height = NSLayoutConstraint(item: overlayImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        let centerYConst = NSLayoutConstraint(item: overlayImageView, attribute: .centerY, relatedBy: .equal, toItem: superView, attribute: .centerY, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([width, height, centerXConst, centerYConst])
    }
}
