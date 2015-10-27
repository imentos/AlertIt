import UIKit

class BarChartViewController: UIViewController, JBBarChartViewDelegate, JBBarChartViewDataSource {
    var route: NSString = ""
    var fromIndex:Int = 2
    var rebalanceJSON:JSON!
    
    private var _chartData: [Double] = []
    private var _chartLegend: [String] = []

    private let _headerHeight:CGFloat = 80
    private let _footerHeight:CGFloat = 40
    private let _padding:CGFloat = 10
    
    private let _barChartView = JBBarChartView()
    private let _headerView = HeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    private let _informationView = ChartInformationView()
    private let _tooltipView = TooltipView()
    private let _tooltipTipView = TooltipTipView()
    private let _footerView = FooterView()
    
    private var timer:NSTimer!
    private let TIMER = 0.1
    private let INC = 50.0
    
    @IBAction func refreshAnimation(sender: AnyObject) {
        _chartData[1] = rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue
        _chartData[fromIndex] = rebalanceJSON["VAR_OUT"][String(fromIndex - 2)]["LOCAL_BOH"].doubleValue
        
        timer = NSTimer.scheduledTimerWithTimeInterval(TIMER, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
    }
    
    func update() {
        let rebalance = rebalanceJSON["VAR_OUT"][String(fromIndex - 2)]["REBALANCE_QTY"].doubleValue        
        if (_chartData[1] >= rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue + rebalance) {
            _chartData[1] = rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue + rebalance
            _chartData[fromIndex] = rebalanceJSON["VAR_OUT"][String(fromIndex - 2)]["LOCAL_BOH"].doubleValue - rebalance
            
            timer.invalidate()
            _barChartView.reloadData()
            return
        }
        
        _chartData[1] += INC
        _chartData[fromIndex] -= INC
        _barChartView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = uicolorFromHex(0x2c2c2c)
        
        _barChartView.translatesAutoresizingMaskIntoConstraints = false
        _informationView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(_barChartView)
        self.view.addSubview(_informationView)
        
        _barChartView.dataSource = self;
        _barChartView.delegate = self;
        _barChartView.backgroundColor = UIColor.darkGrayColor();
        _barChartView.frame = CGRectMake(0, 20, self.view.bounds.width, self.view.bounds.height * 0.5);
        //barChartView.reloadData();
        self.view.addSubview(_barChartView);
        print("Launched");
        
        // Body
        _barChartView.backgroundColor = uicolorFromHex(0x3c3c3c)
        //    _barChartView.frame = CGRectMake(_padding, 80, self.view.bounds.width - _padding * 2, self.view.bounds.height / 2)
        _barChartView.minimumValue = 0
        
        // Header
        _headerView.frame = CGRectMake(_padding,ceil(self.view.bounds.size.height * 0.5) - ceil(_headerHeight * 0.5),self.view.bounds.width - _padding*2, _headerHeight)
        _headerView.titleLabel.text = "Loading..."
        _headerView.subtitleLabel.text = self.route as String
        _barChartView.headerView = _headerView
        
        // Footer
        _footerView.frame = CGRectMake(_padding, ceil(self.view.bounds.size.height * 0.5) - ceil(_footerHeight * 0.5),self.view.bounds.width - _padding*2, _footerHeight)
        _footerView.padding = _padding
        _footerView.leftLabel.textColor = UIColor.whiteColor()
        _footerView.rightLabel.textColor = UIColor.whiteColor()
        _barChartView.footerView = _footerView
        
        // Information View
        _informationView.frame = CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(_barChartView.frame), self.view.bounds.width, self.view.bounds.size.height - CGRectGetMaxY(_barChartView.frame))
        
        // Tooltip
        _tooltipView.alpha = 0.0
        _barChartView.addSubview(_tooltipView)
        _tooltipTipView.alpha = 0.0
        _barChartView.addSubview(_tooltipTipView)
        
        // because jawbone barchart resize the bar based on the biggest value, put extra first and last bar so that animation won't resize
        let maxValue = findMax()
        _chartData.append(maxValue)
        _chartData.append(rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue)
        for index in 0..<rebalanceJSON["VAR_OUT"].count {
            _chartData.append(rebalanceJSON["VAR_OUT"][String(index)]["LOCAL_BOH"].doubleValue)
        }
        _chartData.append(maxValue)
        
        _chartLegend.append("")
        _chartLegend.append(rebalanceJSON["VAR_OUT"]["0"]["CURRENT_LOC"].string!)
        for index in 0..<rebalanceJSON["VAR_OUT"].count {
            _chartLegend.append(rebalanceJSON["VAR_OUT"][String(index)]["ALTERNATIVE_LOC"].string!)
        }
        _chartLegend.append("")
        
        _barChartView.reloadData()
        
        self.barChartView(self._barChartView, didSelectBarAtIndex: 1, touchPoint: CGPoint(x:77.0, y:83.5))
        
        timer = NSTimer.scheduledTimerWithTimeInterval(TIMER, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rotated", name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func rotated() {
        _barChartView.frame = CGRectMake(0, 20, self.view.bounds.width, self.view.bounds.height * 0.5);
        
        _informationView.frame = CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(_barChartView.frame), self.view.bounds.width, self.view.bounds.size.height - CGRectGetMaxY(_barChartView.frame))

        if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            self.barChartView(self._barChartView, didSelectBarAtIndex: 1, touchPoint: CGPoint(x:77.0, y:50))
        } else {
            self.barChartView(self._barChartView, didSelectBarAtIndex: 1, touchPoint: CGPoint(x:140.0, y:50))
        }
        _barChartView.reloadData()
    }
    
    func findMax()->Double {
        var data:[Double] = []
        data.append(rebalanceJSON["VAR_OUT"]["0"]["CURRENT_BOH"].doubleValue)
        for (index, source): (String, JSON) in rebalanceJSON["VAR_OUT"] {
            data.append(source["LOCAL_BOH"].doubleValue)
        }
        return data.maxElement()! * 1.5
    }
    
    /* Called when user selects a bar */
    func barChartView(barChartView: JBBarChartView, didSelectBarAtIndex index: UInt, touchPoint:CGPoint) {
        print(touchPoint)
        if (index == 0 || index == UInt(_chartData.count - 1)) {
            _informationView.setHidden(true, animated: true)
            _tooltipView.alpha = 0.0
            _tooltipTipView.alpha = 0.0
            return
        }
        _informationView.setValueText(NSString(format: "%d", Int(_chartData[Int(index)])))
        _informationView.setTitleText(_chartLegend[Int(index)])
        _informationView.setHidden(false, animated: true)
        
        // Adjust tooltip position
        var convertedTouchPoint:CGPoint = touchPoint
        let minChartX:CGFloat = (_barChartView.frame.origin.x + ceil(_tooltipView.frame.size.width * 0.5))
        if (convertedTouchPoint.x < minChartX)
        {
            convertedTouchPoint.x = minChartX
        }
        let maxChartX:CGFloat = (_barChartView.frame.origin.x + _barChartView.frame.size.width - ceil(_tooltipView.frame.size.width * 0.5))
        if (convertedTouchPoint.x > maxChartX)
        {
            convertedTouchPoint.x = maxChartX
        }
        _tooltipView.frame = CGRectMake(convertedTouchPoint.x - ceil(_tooltipView.frame.size.width * 0.5),
            CGRectGetMaxY(_headerView.frame),
            _tooltipView.frame.size.width,
            _tooltipView.frame.size.height)
        _tooltipView.setText(_chartLegend[Int(index)])
        
        
        var originalTouchPoint:CGPoint = touchPoint
        let minTipX:CGFloat = (_barChartView.frame.origin.x + _tooltipTipView.frame.size.width)
        if (touchPoint.x < minTipX)
        {
            originalTouchPoint.x = minTipX
        }
        let maxTipX = (_barChartView.frame.origin.x + _barChartView.frame.size.width - _tooltipTipView.frame.size.width)
        if (originalTouchPoint.x > maxTipX)
        {
            originalTouchPoint.x = maxTipX
        }
        _tooltipTipView.frame = CGRectMake(originalTouchPoint.x - ceil(_tooltipTipView.frame.size.width * 0.5), CGRectGetMaxY(_tooltipView.frame), _tooltipTipView.frame.size.width, _tooltipTipView.frame.size.height)
        _tooltipView.alpha = 1.0
        _tooltipTipView.alpha = 1.0
    }
    
    func barChartView(barChartView: JBBarChartView, colorForBarViewAtIndex index: UInt) -> UIColor {
        if index == 0 || index == UInt(_chartData.count - 1) {
            return UIColor(white: 1, alpha: 0)
        }
        return (Int(index) % 2 == 0 ) ? uicolorFromHex(0x34b234) : uicolorFromHex(0x08bcef);
    }
    
    func uicolorFromHex(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfBarsInBarChartView(barChartView: JBBarChartView!) -> UInt {
        //println("numberOfBarsInBarChartView");
        return UInt(_chartData.count)
    }
    
    func barChartView(barChartView: JBBarChartView, heightForBarViewAtIndex index: UInt) -> CGFloat {
        //println("barChartView", index);
        //println("height", CGFloat(_chartData[Int(index)]))
        
        return CGFloat(_chartData[Int(index)])
    }
    
}