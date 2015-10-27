//
//  AlertMapController.swift
//  mychart
//
//  Created by i818292 on 4/9/15.
//  Copyright (c) 2015 i818292. All rights reserved.
//

import UIKit
import MapKit
import Parse

class AlertMapController: UITableViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var centerW:Warehouse!
    var fromW:Warehouse!
    var rebalanceJSON:JSON!
    var planeAnnotation:MKPointAnnotation!
    var curve:MKGeodesicPolyline!
    var position:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action:Selector("handleTap:")))
        self.mapView.delegate = self
        
        //loadRebalanceJSONFromFile(0, file:"rebalance1")
        //loadRebalanceJSONFromEndPoint(1, mm: "1076", loc: "TX01", ww: "201440")
        
        //loadRebalanceFromParse("zAJXFM604N", index:1)
    }
    
    func loadRebalanceJSONFromFile(index:Int, file:String) {
        if let file = NSBundle(forClass:AlertMapController.self).pathForResource(file, ofType: "json") {
            let testData = NSData(contentsOfFile: file)
            rebalanceJSON = JSON(data:testData!)
            self.setupWarehouses(index, rebalanceJSON: self.rebalanceJSON)
        }
    }
    
    func loadRebalanceFromParse(id: String, index:Int) {
        let query = PFQuery(className:"Rebalance")
        query.getObjectInBackgroundWithId(id) {
            (rebalance: PFObject?, error: NSError?) -> Void in
            if error == nil && rebalance != nil {
                self.rebalanceJSON = JSON((rebalance?["data"])!)
                self.setupWarehouses(index, rebalanceJSON: self.rebalanceJSON)
            } else {
                print(error)
            }
        }
    }
    
    func loadRebalanceJSONFromEndPoint(index:Int, mm:String, loc:String, ww:String) {
        //http://bi1-401-04.pal.sap.corp:8010/intelEP/rebalance.xsjs?pDebug=0&pMM=1076&pCurrentLoc=TX01&pSnapshotWW=201440&pMin_WOI=1
        let rebalanceUrl = "http://bi1-401-04:8010/intelEP/rebalance.xsjs?pDebug=0&pMM=" + mm + "&pCurrentLoc=" + loc + "&pSnapshotWW=" + ww + "&pMin_WOI=1"
        print(rebalanceUrl)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let userPasswordString = "system:Manager2"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions([])
        let authString = "Basic \(base64EncodedCredential)"
        config.HTTPAdditionalHeaders = ["Authorization" : authString]
        
        let session = NSURLSession(configuration: config)
        let url: NSURL = NSURL(string: rebalanceUrl)!
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            if error != nil {
                // If there is an error in the web request, print it to the console
                print(error!.localizedDescription)
            }
            
            var err: NSError?
            var jsonResult = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)) as! NSDictionary
            if err != nil {
                // If there is an error parsing JSON, print it to the console
                print("JSON Error \(err!.localizedDescription)")
            }
            
            self.rebalanceJSON = JSON(jsonResult)
            dispatch_async(dispatch_get_main_queue()) {
                self.setupWarehouses(index, rebalanceJSON: self.rebalanceJSON)
            }
        })
        task.resume()
    }
    
    func setupWarehouses(index: Int, rebalanceJSON:JSON) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let currentLocJSON:JSON = rebalanceJSON["VAR_OUT"]["0"]
        let center = CLLocationCoordinate2D(latitude: currentLocJSON["DEST_LON"].doubleValue, longitude: currentLocJSON["DEST_LAT"].doubleValue)
        
        let source:JSON = rebalanceJSON["VAR_OUT"][String(index)]
        let location = CLLocationCoordinate2D(latitude: source["SOURCE_LON"].doubleValue, longitude: source["SOURCE_LAT"].doubleValue)
        let warehouse = addWarehouseOverlay(location, index:index + 2, inventory:source["CURRENT_BOH"].doubleValue)
        warehouse.target = false
        print("source:" + String(index))        
        
        // show map
        let span = MKCoordinateSpanMake(180, 180)
        //let mapCenter = findCenterPoint(loc1: center, loc2: location)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        self.title = currentLocJSON["CURRENT_LOC"].string
        centerW = addWarehouseOverlay(center, index:1, inventory: currentLocJSON["CURRENT_BOH"].doubleValue)
        centerW.target = true
        
        addRouteOverlay(from:warehouse, to:centerW, title: "Action " + String(index + 1))
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        self.resetWarehouses()
    }

    func addRouteOverlay(from from:Warehouse, to:Warehouse, title:String) {
        let annotation = RouteAnnotation()
        annotation.coordinate = from.coordinate//findCenterPoint(loc1:from.coordinate, loc2:to.coordinate)
        annotation.title = title
        annotation.from = from
        mapView.addAnnotation(annotation)
        
        var pointsToUse: [CLLocationCoordinate2D] = []
        pointsToUse.append(to.coordinate)
        pointsToUse.append(from.coordinate)
        curve = MKGeodesicPolyline(coordinates: &pointsToUse, count: 2)
        mapView.addOverlay(curve)
    }
    
    func addWarehouseOverlay(location:CLLocationCoordinate2D, index:Int, inventory:Double)->Warehouse {
        let w = Warehouse(centerCoordinate: location, radius: 100)
        w.inventory = inventory
        w.index = index
        self.mapView.addOverlay(w)
        return w
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
        if annotation is RouteAnnotation {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Attraction")//RouteAnnotationView(annotation: annotation, reuseIdentifier: "Attraction")
            annotationView.canShowCallout = true
            annotationView.calloutOffset = CGPoint(x: -5, y: 5)
            annotationView.leftCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            
            return annotationView
        } else {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView { // 2
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view.image = UIImage(named: "rsz_star")
            return view
        }
    }
    
    func findCenterPoint(loc1 _loc1 :CLLocationCoordinate2D, loc2 _loc2:CLLocationCoordinate2D)->CLLocationCoordinate2D {
        let lon1 = _loc1.longitude * M_PI / 180;
        let lon2 = _loc2.longitude * M_PI / 180;
        
        let lat1 = _loc1.latitude * M_PI / 180;
        let lat2 = _loc2.latitude * M_PI / 180;
        
        let dLon = lon2 - lon1;
        
        let x = cos(lat2) * cos(dLon);
        let y = cos(lat2) * sin(dLon);
        
        var lat3 = atan2( sin(lat1) + sin(lat2), sqrt((cos(lat1) + x) * (cos(lat1) + x) + y * y) );
        var lon3 = lon1 + atan2(y, cos(lat1) + x);
    
        //return CLLocationCoordinate2D(latitude:lat3 * 180 / M_PI, longitude: lon3 * 180 / M_PI)
        return CLLocationCoordinate2D(latitude: (_loc1.latitude + _loc2.latitude) / 2, longitude: (_loc1.longitude + _loc2.longitude) / 2)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 0
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? RouteAnnotation {           
            // reset previous one
            if fromW != nil {
                self.resetWarehouses()
            }
            fromW = annotation.from
            let rebalance:Double = rebalanceJSON["VAR_OUT"][String(fromW.index - 2)]["REBALANCE_QTY"].doubleValue
            annotation.from.inventory = rebalanceJSON["VAR_OUT"][String(fromW.index - 2)]["LOCAL_BOH"].doubleValue - rebalance
            annotation.from.selected = true
            annotation.from.renderer?.setNeedsDisplay()
            
            centerW.selected = true
            centerW.inventory = rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue + rebalance
            centerW.renderer?.setNeedsDisplay()
        }
    }
    
    func resetWarehouses() {
        centerW.inventory = rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue
        centerW.selected = false
        centerW.renderer?.setNeedsDisplay()
        
        if fromW != nil {
            fromW.inventory = rebalanceJSON["VAR_OUT"][String(fromW.index - 2)]["LOCAL_BOH"].doubleValue
            fromW.selected = false
            fromW.renderer?.setNeedsDisplay()
        }
        
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? RouteAnnotation {
            //self.resetWarehouses()
        }
    }


    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? RouteAnnotation {
            self.mapView.deselectAnnotation(view.annotation, animated: true)
            
            self.performSegueWithIdentifier("detail", sender: view)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "detail" {
            let barChart = segue.destinationViewController as! BarChartViewController
            let view = sender as! MKAnnotationView
            let annotation = view.annotation as! RouteAnnotation
            
            barChart.route = annotation.title!
            barChart.fromIndex = annotation.from.index
            barChart.rebalanceJSON = rebalanceJSON
        }
    }

    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            // route dashline
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blueColor()
            renderer.lineWidth = 2
            renderer.lineDashPattern = [2, 5];
            renderer.alpha = 0.5
            return renderer
        }
        
        if overlay is Warehouse {
            let renderer = WarehouseRenderer(overlay: overlay)
            let w:Warehouse = overlay as! Warehouse
            w.renderer = renderer
            return renderer
        }
        
        return nil
    }


}
