//
//  GiftMessageCell.swift
//  MatChat
//
//  Created by admin on 2023/5/24.
//

import UIKit

class GiftMessageCell: MessageCell {
    
    override class var reuseId: String {
        String(describing: GiftMessageCell.self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    lazy var sendLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.avenirNextDemiBoldFont(ofSize: 16)
        label.textColor = UIColor.white
        return label
    }()
    
    lazy var coinLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.avenirNextRegularFont(ofSize: 13)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        return label
    }()
    
    lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.avenirNextMediumFont(ofSize: 12)
        label.textColor = UIColor.black.withAlphaComponent(0.3)
        return label
    }()
    
    lazy var giftImgView: UIImageView = {
        let imgview = UIImageView()
        imgview.contentMode = .scaleAspectFill
        return imgview
    }()
    
    private var layerView: UIView!
    private var bottomView: UIView!
    
    override func setUp() {
        super.setUp()
        
        
        layerView = UIView()
        layerView.frame = CGRect(x: 0, y: 0, width: 230, height: 76)
        containerView.addSubview(layerView)
        
        layerView.addSubview(sendLabel)
        layerView.addSubview(coinLabel)
        
        bottomView = UIView()
        bottomView.layer.cornerRadius = 12
        bottomView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        bottomView.backgroundColor = UIColor.white
        bottomView.isUserInteractionEnabled = true
        bottomView.frame = CGRect(x: 0, y: 76, width: 230, height: 40)
        containerView.addSubview(bottomView)
        
        bottomView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        
        let bottomTap = UITapGestureRecognizer(target: self, action: #selector(bottomViewAction))
        bottomView.addGestureRecognizer(bottomTap)

        layerView.addSubview(giftImgView)
        
        
        
    }
    
    @objc func bottomViewAction() {
        NotificationCenter.default.post(name: MCNoti.keepGivingGiftNoti, object: nil)
    }
    
    override func updateContent() {
        super.updateContent()
        
        guard let messageVM = messageVM as? GiftMessageViewModel, let model = messageVM.giftMessageModel else { return }
        sendLabel.text = "Sent \(model.giftName~) to you"
        let coins = model.giftPrice * model.giftNum
        coinLabel.text = "(\(coins) coins)"
        giftImgView.mc_setImageURL(url: model.giftImage, placeholder: UIImage(named: ""))
        
        layerView.removeGradientLayer()

        if messageVM.message.info.direction == .send {
            
            let layer = layerView.addGradientLayer(colors: [UIColor.hexColor("#B27CFF").cgColor,
                                                            UIColor.hexColor("#416FFF").cgColor],
                                                   startPoint: CGPoint(x: 0, y: 0.5),
                                                   endPoint: CGPoint(x: 1, y: 0.5),
                                                   size: CGSize(width: 230, height: 76))
            layer.cornerRadius = 12
            
            
            sendLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
            }
            
            coinLabel.snp.remakeConstraints { make in
                make.right.equalTo(sendLabel)
                make.top.equalTo(sendLabel.snp.bottom).offset(2.5)
            }
            
            bottomView.isHidden = false
            tipLabel.text = "Keep giving gifts".localized
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            
            
            giftImgView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(-15)
                make.width.height.equalTo(56)
            }
            
        } else {
            let layer = layerView.addGradientLayer(colors: [UIColor.hexColor("#416FFF").cgColor,
                                                UIColor.hexColor("#B27CFF").cgColor],
                                       startPoint: CGPoint(x: 0, y: 0.5),
                                       endPoint: CGPoint(x: 1, y: 0.5),
                                       size: CGSize(width: 230, height: 76))
            layer.cornerRadius = 12
            
            sendLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.left.equalToSuperview().offset(16)
            }
            
            coinLabel.snp.remakeConstraints { make in
                make.left.equalTo(sendLabel)
                make.top.equalTo(sendLabel.snp.bottom).offset(2.5)
            }
            
            bottomView.isHidden = true
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            
            giftImgView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(15)
                make.width.height.equalTo(56)
            }
        }
    }

}
