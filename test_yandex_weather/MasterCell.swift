//
//  MasterCell.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit

class MasterCell: UITableViewCell {
    
    var detailItem: City? {
        didSet {
            textLabel?.text = detailItem?.name
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
