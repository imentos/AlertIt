//
//  PinAnnotation.swift
//  mychart
//
//  Created by i818292 on 4/9/15.
//  Copyright (c) 2015 i818292. All rights reserved.
//

import UIKit
import MapKit

class RouteAnnotation: NSObject, MKAnnotation {
    private var coord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return coord
        }
        set(coord) {
            self.coord = coord
        }
    }
    
    var from:Warehouse!
    
    var title: String? = ""
    var subtitle: String? = ""
}
