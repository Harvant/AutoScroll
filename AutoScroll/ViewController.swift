//
//  ViewController.swift
//  AutoScroll
//
//  Created by okumura on 2017/03/01.
//  Copyright © 2017 akariokumura. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {
    // PageControl
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!

    var offsetX: CGFloat = 0.0
    var pageControllTimer = Timer()
    var pageArray = ["pink", "lightgray", "pink", "lightgray", "pink", "lightgray"]

    // Ticker View
    @IBOutlet weak var tickerScrollView: UIScrollView!
    @IBOutlet weak var messageLabel: UILabel!

    var messageArray = ["xxxxxxxxxxxxxxxxx", "zzzzzzzzzzzzzzzz"]
    var messageId = 0
    var changeFlag: Bool = true
    var tickerTimer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.scrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)

        self.initPageControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.pageControllTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.slidePage(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(self.pageControllTimer, forMode: .commonModes) // スクロール時にTimerが止まるので、別スレッドで実行する

        self.tickerTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.updateTicker(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(self.tickerTimer, forMode: .commonModes)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.pageControllTimer.invalidate()
        self.tickerTimer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.adjustScrollViewFrame()
    }

    deinit {
        self.scrollView.removeObserver(self, forKeyPath: "contentOffset")
    }

    // MARK: UIPageControll

    func initPageControl() {
        self.pageControl.numberOfPages = self.pageArray.count
        self.pageControl.currentPage = 0

        self.scrollView.delegate = self
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.isPagingEnabled = true
        self.scrollView.isScrollEnabled = true
        self.scrollView.backgroundColor = UIColor.clear

        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(self.pageArray.count), height: self.scrollView.frame.size.height)

        for i in 0 ..< self.pageArray.count {
            let imageView = UIImageView(frame: setImageViewFrameWithIndex(i))
            imageView.image = UIImage(named: self.pageArray[i])
            imageView.contentMode = .scaleToFill
            self.scrollView.addSubview(imageView)
        }
    }

    // for iPad
    func adjustScrollViewFrame() {
        let subviews = self.scrollView.subviews
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width * CGFloat(subviews.count), height: self.scrollView.frame.size.height)

        for (i, view) in subviews.enumerated() {
            guard let imageview = view as? UIImageView else { continue }
            imageview.frame = setImageViewFrameWithIndex(i)
        }
    }

    func setImageViewFrameWithIndex(_ index: Int) -> CGRect {
        let frame = CGRect(x: self.scrollView.frame.size.width * CGFloat(index), y: 0.0, width: self.scrollView.frame.size.width, height: self.scrollView.frame.size.height)
        return frame
    }

    func slidePage(_ timer: Timer) {
        let pageWidth = self.scrollView.frame.width
        let maxWidth = pageWidth * CGFloat(self.pageArray.count)
        let contentOffset = self.scrollView.contentOffset.x

        var slideToX = contentOffset + pageWidth
        if  contentOffset + pageWidth == maxWidth {
            slideToX = 0
        }

        self.scrollView.scrollRectToVisible(CGRect(x: slideToX, y: 0.0, width: pageWidth, height: self.scrollView.frame.height), animated: true)
    }

    override func observeValue(forKeyPath keyPath: String?, of objectOrNil: Any?, change changeOrNil: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = changeOrNil, let object = objectOrNil else {
            return
        }
        if !self.scrollView.isEqual(object) {
            return
        }
        guard let n = (change[NSKeyValueChangeKey.newKey] as? NSValue)?.cgPointValue,
            let o = (change[NSKeyValueChangeKey.oldKey] as? NSValue)?.cgPointValue else {
                return
        }
        if n.x == o.x && n.y == o.y {
            return
        }

        let pageWidth = self.scrollView.frame.width
        let page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        self.pageControl.currentPage = Int(page)
    }

    // MARK: UIScrollViewDelegate methods

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = self.scrollView.frame.size.width
        let pageNum = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        self.pageControl.currentPage = Int(pageNum)
    }

    // MARK: Ticker View

    func updateTicker(_ timer: Timer) {
        if self.changeFlag == true {
            var offset = self.tickerScrollView.contentOffset
            offset.x = -self.view.frame.size.width
            self.tickerScrollView.contentOffset = offset

            self.messageLabel.text = self.messageArray[self.messageId]
            self.messageId += 1
            if self.messageId >= self.messageArray.count {
                self.messageId = 0
            }

            self.messageLabel.sizeToFit()
            self.offsetX = self.messageLabel.frame.size.width

            self.changeFlag = false

        } else {
            UIView.animate(withDuration: 1.2, animations: {
                var offset = self.tickerScrollView.contentOffset
                offset.x += 40.0;
                if self.offsetX < offset.x {
                    self.changeFlag = true
                }
                self.tickerScrollView.contentOffset = offset
            }) { (finished) in
                
            }
        }
    }
}

