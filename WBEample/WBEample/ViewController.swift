//
//  ViewController.swift
//  WBEample
//
//  Created by GK on 2018/8/1.
//  Copyright © 2018年 com.gk. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

class ViewController: UIViewController, AVAssetDownloadDelegate {

    @IBOutlet weak var playerView: VideoPlayerView!
    
    private struct ObserverContexts {
        static var playerStatus = 0
        
        static var playerStatusKey = "status"
        
        static var currentItem = 0
        
        static var currentItemKey = "currentItem"
        
        static var currentItemStatus = 0
        
        static var currentItemStatusKey = "currentItem.status"
        
        static var urlAssetDurationKey = "duration"
        
        static var urlAssetPlayableKey = "playable"
        
        static var availableMetadataFormatsKey = "availableMetadataFormats"
        
        static var chapterLocalesKey = "availableChapterLocales"

    }
    
    private var isObserving = false
    
    var asset: AVAsset!
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var timeObserverToken: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //
        //https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8
        
        let audioURL =  Bundle.main.path(forResource: "best", ofType: "mp3")!
        
        let videoURL = URL(string:"https://wolverine.raywenderlich.com/content/ios/tutorials/video_streaming/foxVillage.m3u8")!
        
       // let mediaURL = URL(fileURLWithPath: audioURL)
        
        asset = AVAsset(url: videoURL)
        
        //下载HLS资源
        setupAssetDownload()
        
        //获取asset的持续时间，判断asset是否可以播放

        asset.loadValuesAsynchronously(forKeys: [ObserverContexts.urlAssetDurationKey, ObserverContexts.urlAssetPlayableKey,ObserverContexts.availableMetadataFormatsKey,ObserverContexts.chapterLocalesKey]) {
            
            var durationError: NSError?
            let durationStatus = self.asset.statusOfValue(forKey: ObserverContexts.urlAssetDurationKey, error: &durationError)
            guard durationStatus == .loaded else {
                fatalError("Failed to load duration property with error: \(String(describing: durationError))")
            }
            
            var playableError: NSError?
            let playableStatus = self.asset.statusOfValue(forKey: ObserverContexts.urlAssetPlayableKey, error: &playableError)
            guard playableStatus == .loaded else { fatalError("Failed to read playable duration property with error: \(String(describing: playableError))") }
            
            guard self.asset.isPlayable  else {
                print("asset is not playable")
                return
            }
            
            guard CMTimeCompare(self.asset.duration, CMTime(value: 1, timescale: 100)) >= 0 else {
                print("Can not play since asset duration too short,duration is \(CMTimeGetSeconds(self.asset.duration)) seconds");
                return
            }
            
            //load metadata
            var metadataError: NSError?
            let metadataStatus = self.asset.statusOfValue(forKey: ObserverContexts.availableMetadataFormatsKey, error: &metadataError)
            if metadataStatus == .loaded {
                for format in self.asset.availableMetadataFormats {
                    let metadata = self.asset.metadata(forFormat: format)
                    print(metadata)
                }
            }
            
            //load Chapter Markers
            var chapterMarkersError: NSError?
            let chapterMarkersStatus = self.asset.statusOfValue(forKey: ObserverContexts.chapterLocalesKey, error: &chapterMarkersError)
            
            if chapterMarkersStatus == .loaded {
                let languages = Locale.preferredLanguages
                let chapterMetadata = self.asset.chapterMetadataGroups(bestMatchingPreferredLanguages: languages)
                
                let chapters = self.convertTimeMetadataGroupsToChapters(groups: chapterMetadata)
                print(chapters)
            }
            
            DispatchQueue.main.async {
                print("asset playable status: \(playableStatus), duration time \(CMTimeGetSeconds(self.asset.duration)) seconds")
                self.playerItem = AVPlayerItem(asset: self.asset)
                self.player = AVPlayer(playerItem: self.playerItem)
                self.playerView.player = self.player
            }
        }
    }
    func addSystemNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        //观察AAudioSession中断通知
        NotificationCenter.default.addObserver(self,
                                       selector: #selector(handleInterruption),
                                       name: .AVAudioSessionInterruption,
                                       object: nil)
        
        NotificationCenter.default.addObserver(self,
                                       selector: #selector(handleRouteChange),
                                       name: .AVAudioSessionRouteChange,
                                       object: nil)
        
    }
    func removeSystemNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    // route change 发生的时候的通知
   @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortBluetoothA2DP {
               // headphonesConnected = true
                player.play()
                break
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                
                
                for output in previousRoute.outputs where output.portType == AVAudioSessionPortBluetoothA2DP {
                    // headphonesConnected = false
                    player.pause()
                    break
                }
            }
        default: ()
        }
    }
    //中断发生的时候的处理
   @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        
        if type == .began {
            //中断开始
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                    
                } else {
                    // Interruption Ended - playback should NOT resume
                }
            }
        }
    }
    //从Metadata获取title
    func retrieveMetadataTitle(_ asset: AVAsset) {
       let metadata = asset.commonMetadata
       let titleId  = AVMetadataIdentifier.commonIdentifierTitle
       let titleItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: titleId)
        if let item = titleItems.first {
            //diaplay the title
        }
    }
    func retriveMetadataArtwork(_ asset: AVAsset) {
        let metadata = asset.commonMetadata
        let artworkItems = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierArtist)
        if let artworkItem = artworkItems.first {
            //转换为NSData
            if let imageData = artworkItem.dataValue {
                let image = UIImage(data: imageData)
                //处理image
            }
        }
    }
    @IBAction func playClicked(_ sender: UIButton) {
        stop()
        startObserving()
        addPeriodicTimeObserver()
        addBoundaryTimeObserver()
        
        //background 播放配置
        setupRemoteTransportControls()
        setupNowPlaying()
        addSystemNotification()
        player.play()
        
    }
    @IBAction func stopClicked(_ sender: UIButton) {
        stop()
    }
    
    func stop() {
        player.pause()
        removeSystemNotification()
        removePeriodicTimeObserver()
        removeBoundaryTimeObserver()
        stopObserving()
    }
    private func startObserving() {
        guard let player = player, !isObserving else { return }
        
        player.addObserver(self, forKeyPath: ObserverContexts.playerStatusKey, options: .new, context: &ObserverContexts.playerStatus)
        player.addObserver(self, forKeyPath: ObserverContexts.currentItemStatusKey, options: .new, context: &ObserverContexts.currentItemStatus)
        
        isObserving = true
    }
    
    private func stopObserving() {
        guard let player = player, isObserving else { return }
        
        player.removeObserver(self, forKeyPath: ObserverContexts.playerStatusKey, context: &ObserverContexts.playerStatus)
        player.removeObserver(self, forKeyPath: ObserverContexts.currentItemStatusKey, context: &ObserverContexts.currentItemStatus)
        isObserving = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &ObserverContexts.playerStatus {
            guard let newPlayerStatus = change?[.newKey] as? AVPlayerStatus else { return }
            if newPlayerStatus == AVPlayerStatus.failed {
                print("End looping since player has failed with error \(String(describing: player.error))")
                stop()
            }
            
        } else if context == &ObserverContexts.currentItemStatus {
            guard let newPlayerItemStatus = change?[.newKey] as? AVPlayerItemStatus else { return }
            if newPlayerItemStatus == .failed {
                print("End play since player item has failed with error: \(String(describing: player?.currentItem?.error))")
                stop()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    @IBOutlet weak var currentPlayTimeLabel: UILabel!
    //周期性的观察播放时间
    //每半秒去执行block
    func addPeriodicTimeObserver() {
        // Notify every half second

        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main, using: { [weak self] time in
            // update player transport UI
            DispatchQueue.main.async {
                self?.currentPlayTimeLabel.text = "\(CMTimeGetSeconds(time)) seconds"
            }
        })
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = self.timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    // Boundary Observations 边界观察播放时间,观察某些感兴趣的时间点
    @IBOutlet weak var interestTime: UILabel!
    func addBoundaryTimeObserver() {
        // Divide the asset's duration into quarters.
        let interval = CMTimeMultiplyByFloat64(asset.duration, 0.25)
        var currentTime = kCMTimeZero
        var times = [NSValue]()
        
        // Calculate boundary times
        while currentTime < asset.duration {
            currentTime = currentTime + interval
            times.append(NSValue(time:currentTime))
        }
        
        timeObserverToken = player.addBoundaryTimeObserver(forTimes: times, queue: .main, using: {
            //update UI
            DispatchQueue.main.async {
                self.interestTime.text = "总长度的1/4时更新"
            }
        })
    }
    func removeBoundaryTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    //seeking media
    //不是很精确，跳转的位置不太精确
    func seekMedia() {
        
        // Seek to the 2 minute mark

        let time = CMTime(value: 120, timescale: 1)
        player.seek(to: time)
    }
    //精确的时间控制
    func preciseSeekMedia() {
        // Seek to the first frame at 3:25 mark

        let seekTime = CMTime(seconds: 205, preferredTimescale: Int32(NSEC_PER_SEC))
        player.seek(to: seekTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)

    }
    
    //Presenting Chapter Markers
    // AVTimedMetadataGroup  CMTimeRange AVMetadataItem thumbnail image
    func convertTimeMetadataGroupsToChapters(groups: [AVTimedMetadataGroup]) -> [Chapter] {
       return groups.map { group -> Chapter in
            //获取AVMetadataCommonIdentifierTitle metadata items
            let titleItems = AVMetadataItem.metadataItems(from: group.items, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierTitle)
            let artworkItems = AVMetadataItem.metadataItems(from: group.items, filteredByIdentifier: AVMetadataIdentifier.commonIdentifierArtwork)
            
            var title = "Default Title"
            var image = UIImage(named: "placeholder")
            
            if let titleValue = titleItems.first?.stringValue {
                title = titleValue
            }
            
            if let imagData = artworkItems.first?.dataValue, let imageValue = UIImage(data: imagData) {
                image = imageValue
            }
            return Chapter(time: group.timeRange.start, title: title, image: image!)
        }
    }
    //background播放video and audio
   @objc func applicationDidEnterBackground(_ application: UIApplication) {
        // Disconnect the AVPlayer from the presentation when entering background
        
        // If presenting video with AVPlayerViewController
//        playerViewController.player = nil
//
          playerView.player = nil
    }
    
   @objc func applicationWillEnterForeground(_ application: UIApplication) {
        // Reconnect the AVPlayer to the presentation when returning to foreground
         playerView.player = player
    }
    //控制background Audio
    //为远程控制添加播放和暂停
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.player.play()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }
    }
    //
    func setupNowPlaying() {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "最好"
        if let image = UIImage(named: "best") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerItem.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // 下载HLS资源
    var downloadSession: AVAssetDownloadURLSession!
    
    func setupAssetDownload() {
        let configuration =  URLSessionConfiguration.background(withIdentifier: "HLSDownloadURLSessionIdentifier")
        downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
        
        let videoURL = URL(string:"https://wolverine.raywenderlich.com/content/ios/tutorials/video_streaming/foxVillage.m3u8")!
        let asset = AVURLAsset(url: videoURL)
        
        let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset, assetTitle: "HLSStream", assetArtworkData: nil, options: nil)
        
        downloadTask?.resume()

    }
    //恢复没有下载完成的任务
    @IBOutlet weak var downloadPercentLabel: UILabel!
    func restorePendingDownloads() {
        //创建一个和并下载任务相同Identifier的URLSessionConfiguration
        let newConfiguration = URLSessionConfiguration.background(withIdentifier: "HLSDownloadURLSessionIdentifier")
        
        downloadSession = AVAssetDownloadURLSession(configuration: newConfiguration,
                                                    assetDownloadDelegate: self,
                                                    delegateQueue: OperationQueue.main)

        //获取所有与所关联的download session的没有下载完成的任务
        downloadSession.getAllTasks { tasksArray in
            //对每一个task,重新恢复stats
            for task in tasksArray {
                guard let downloadTask = task as? AVAssetDownloadTask else {
                    break
                }
                
                //恢复下载的进度，状态
                let asset = downloadTask.urlAsset
                
            }
        }
        

    }
    
    //mark -AVAssetDownloadDelegate
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        
        for value in loadedTimeRanges {
            let loadedTimeRange = value.timeRangeValue
            percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
        }
        percentComplete *= 100
        //用percentComplete来更新UI进度
        DispatchQueue.main.async {
            self.downloadPercentLabel.text = "当前已经下载了\(percentComplete)"
        }
    }
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        // Do not move the asset from the download location
        UserDefaults.standard.set(location.relativePath, forKey: "assetPath")
        print("download url: \(location)")
    }
    //Adopting PiP in a Custom Player
    
    //确保PiP被硬件支持
//    func setupPictureInPicture() {
//        // Ensure PiP is supported by current device
//        if AVPictureInPictureController.isPictureInPictureSupported() {
//            // Create new controller passing reference to the AVPlayerLayer
//            pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
//            pictureInPictureController.delegate = self
//            let keyPath = #keyPath(AVPictureInPictureController.isPictureInPicturePossible)
//            pictureInPictureController.addObserver(self,
//                                                   forKeyPath: keyPath,
//                                                   options: [.initial, .new],
//                                                   context: &pictureInPictureControllerContext)
//        } else {
//            // PiP not supported by current device. Disable PiP button.
//            pictureInPictureButton.isEnabled = false
//        }
//    }
//    @IBOutlet weak var startButton: UIButton!
//    @IBOutlet weak var stopButton: UIButton!
   
//    These methods return system default images that you can present in your UI:
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let startImage = AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil)
//        let stopImage = AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: nil)
//
//        startButton.setImage(startImage, for: .normal)
//        stopButton.setImage(stopImage, for: .normal)
//    }
    //决定是否播放PiP视频
//    @IBAction func togglePictureInPictureMode(_ sender: UIButton) {
//        if pictureInPictureController.isPictureInPictureActive {
//            pictureInPictureController.stopPictureInPicture()
//        } else {
//            pictureInPictureController.startPictureInPicture()
//        }
//    }
    
    //当用户从PiP返回App时，默认将终止播放视频，但可以通过实现来恢复视频的播放
//    func picture(_ pictureInPictureController: AVPictureInPictureController,
//                 restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
//        // Restore user interface
//        completionHandler(true)
//    }
//    While PiP is active, dismiss playback controls in your main player and present artwork inside its bounds to indicate that PiP is under way. To implement this functionality, you can use the pictureInPictureControllerWillStartPictureInPicture: and pictureInPictureControllerDidStopPictureInPicture: delegate methods and take the required actions as shown in the following example:
//
//    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        // hide playback controls
//        // show placeholder artwork
//    }
//
//    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        // hide placeholder artwork
//        // show playback controls
//    }

}

