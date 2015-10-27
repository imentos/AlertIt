

import UIKit
import MapKit

class WarehouseRenderer : MKOverlayRenderer {
    
    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext) {
        let w:Warehouse = self.overlay as! Warehouse
        
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetLineWidth(context, 1.2/zoomScale)
        
        let theMapRect:MKMapRect = self.overlay.boundingMapRect
        let theRect:CGRect = self.rectForMapRect(theMapRect);
        
        let radius = CGFloat((theRect.size.width - 10)/2) * CGFloat(w.inventory)
        
        // draw area
        CGContextSetFillColorWithColor(context, w.target ? UIColor.redColor().CGColor : UIColor.blueColor().CGColor)
        CGContextSetAlpha(context, 0.5)
        CGContextAddArc(context, CGFloat((theRect.size.width)/2), CGFloat(theRect.size.height/2), radius, 0.0, CGFloat(M_PI * 2.0), 1)
        CGContextDrawPath(context, CGPathDrawingMode.FillStroke);
        
        // draw center
        CGContextSetFillColorWithColor(context,UIColor.grayColor().CGColor)
        CGContextSetAlpha(context, 1)
        CGContextAddArc(context, CGFloat((theRect.size.width)/2), CGFloat(theRect.size.height/2), radius / 10, 0.0, CGFloat(M_PI * 2.0), 1)
        CGContextDrawPath(context, CGPathDrawingMode.FillStroke);
        
        // draw selection
        if (w.selected) {
            CGContextSetLineWidth(context, 5/zoomScale)
            CGContextSetStrokeColorWithColor(context, w.target ? UIColor.redColor().CGColor : UIColor.blueColor().CGColor)
            CGContextSetAlpha(context, 0.5)
            //CGContextSetLineDash(context, 0, [1000000, 200000], 2);
            CGContextAddArc(context, CGFloat((theRect.size.width)/2), CGFloat(theRect.size.height/2), radius * 1.3, 0.0, CGFloat(M_PI * 2.0), 1)
            CGContextDrawPath(context, CGPathDrawingMode.Stroke);
        }
    }
}



