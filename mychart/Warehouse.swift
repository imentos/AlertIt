//
//  Warehouse.swift
//  mychart
//
//  Created by i818292 on 4/21/15.
//  Copyright (c) 2015 i818292. All rights reserved.
//

import UIKit
import MapKit

class Warehouse : MKCircle {
//    override init() {
//        inventory = 1.0
//        
//    }
    var inventory: Double = 1.0;
    var selected: Bool = false
    var index:Int = 0
    var target: Bool = false
    
    var renderer:WarehouseRenderer?
}