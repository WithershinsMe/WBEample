#  HTTP Live Stream

    根据用户的网络情况选择合适的master index file
        150K stream for cellular varient playlist is recommended
        240k or 440k stream for wifi variant playlist is recommended
      指定stream variants 的bitrates，BANDWIDTH Attributes要和stream的实际带宽相匹配
      Http Live Stream 根据网络带宽动态的在stream alternates之间切换
      视频播放超过10分钟或者5分钟内传输5M的数据，建议用HTTP Live Stream
      如果app是在蜂窝网络下，需要提供至少一个stream 64kbps,甚至更低宽带的stream如 audio only or audio with image
      提供备用的Stream
      AVPlayerItem可以用timedMetaData属性获取stream的metadata
      也可以写自己的segmenter,也可以读取stream metadata
      
      A frame rate of 10 fps is recommended for video streams under 200 kbps
      Encode video using H.264 compression
      Encode audio 用HE-AAC or AAC_LC. MP3
      最小的audio 采样率是22.05kHz,audio bit rate of 40 kbps
      
      提供不同的bit rates的编码的stream ,variants
         provide different encodings of the same presentation
         
      You should always provide a master playlist,
      Encode your media variants,recommend creating separate I-frame variants for trick play support.
      Create a master playlist
      one stream at 192 kb/s or lower bandwidth
      
      默认情况下  
      锁屏下不允许app播放音频
      当app播放音频时，其他的background audio将会停止播放
      the Ring/Silent switch to silent mode silences any audio being played by the app
       
      app audio category定义了通用的audio 行为，设定category为AVAudioSessionCategoryPlayback.允许app在the Ring/Silent switch to silent mode时继续播放，要启用这项特征，app需要启用play background audio capacities
      建议在需要播放的时候在active the audio session,防止终止别的background audio
      AVAsset 由许多AVAssetTrack对象组成，最常用的Track类型是audio和video类型，可以通过访问tracks属性获取所有的tracks
      AVAsset的属性可以获取到持续时间，创建日期和metadata
      创建AVAsset之后并不会自动的load这些属性，只有在请求的时候才能为这些属性赋值，属性的获取是同步的
      load an asset’s properties asynchronously
      
      AVAsset和AVAssetTrack采纳AVAsynchronousKeyValueLoading协议，这个协议定义了查询当前load state和异步的load属性值的接口
      
      AVFoundation 用AVMetadataItem来获取metal data
      可以用AVAsset的属性metadata来获取format-specific metadata的集合
      Common key space: 包括movie的创建日期
      可以用AVAsset的属性commonMetadata来获取创建日期等Common Key Space
      
      metadata由两种格式：format-specific metadata  Common Key Space
      决定AVAsset是包含那种格式用availableMetadataFormats
      可以用metadataForFormat:来获取指定格式的metadata
      
      let url = Bundle.main.url(forResource: "audio", withExtension: "m4a")!
      let asset = AVAsset(url: url)
      let formatsKey = "availableMetadataFormats"
      asset.loadValuesAsynchronously(forKeys: [formatsKey]) {
      var error: NSError? = nil
      let status = asset.statusOfValue(forKey: formatsKey, error: &error)
      if status == .loaded {
      for format in asset.availableMetadataFormats {
      let metadata = asset.metadata(forFormat: format)
      // process format-specific metadata collection
      }
      }
      }
      
      
      获取指定的Metadata values
      最容易获取specific metadata items是用identifier来过滤
      
      AVPlayer 是播放的核心，用来管理播放和media asset的时间，
      可以用AVQuenePlayer来播放多个media asset
      
      AVAsset 表示的是media的static aspects,例如持续时间，创建日期，不能用avplayer直接播放
      为了播放AVAsset，需要创建AVPlayerItem的动态部分，它表示了AVPlayer播放的asset的state和timing
      用AVPlayerItem 可以 seek to various times in the media，determine its presentation size, identify its current time
      
      AVPlayer和AVPlayerItem都是非视觉对象，也就是不能直接呈现Asset到屏幕上，iOS上有两种呈现方式
      用AVPlayerViewController 
      用AVPlayerLayer,CALayer的子类，可以直接添加到Layer的分层结构中
      
      观察播放状态  用KVO来获取AVPlayer和AVPlayerItem的状态
      
      AVPlayerItem中最重要的属性是status. status显示player item准备去播放
      AVPlayerItemStatusUnknown：当第一次创建player item时，AVPlayerItem的状态，意味着media没有被loaded或没有被添加到播放队列中
      AVPlayerItemStatusReadyToPlay：当把PlayerItem和AVplayer关联起来以后的状态
      
      播放的时间是NSTimeInterval对象，单位秒，但在media中time 通常需要考虑sample-accurate timing，所以用CMTime
      通常情况下CMTime are its value and timescale，代表the media’s frame rate or sample rate
      
      // 0.25 seconds 
      let quarterSecond = CMTime(value: 1, timescale: 4)
      
      // 10 second mark in a 44.1 kHz audio file
      let tenSeconds = CMTime(value: 441000, timescale: 44100)

      // 3 seconds into a 30fps video
      let cursor = CMTime(value: 90, timescale: 30)
       
      观察播放时间  通过观察播放时间，更新播放位置，同步用户桌面的状态，KVO不能观察持续的状态的改变
      AVPlayer提供两种方式观察播放时间的改变：
      periodic observations 
      通过周期性的间隔观察，来更新屏幕上显示的时间
      boundary observations
      边界观察，就是在各种感兴趣的时间点去回调block,用的比较少
      
      Seeking Media  
      想要快速到达感兴趣的时间点，从改时间点观看视频
      AVPlayer和AVPlayerItem由许多方式去实现seeking media,最常用的就是调用方法seekToTime
      seekToTime是最快的方式，但是精度不太准确
      如果想要实现精确的时间跳转precise seeking behavior，用seekToTime:toleranceBefore:toleranceAfter:
      which lets you indicate the tolerated amount of deviation from your target time (before and after). If you need to provide sample-accurate seeking behavior, you can indicate that zero tolerance is allowed:
      
      Picture in Picture (iOS) iOS9开始
      可以添加PiP播放用AVPlayerViewController
      可以添加PiP播放用AVPictureInPictureController Class
      
      为了使app有使用PiP的能力，需要配置app的audio session https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/ConfiguringAudioSettings/ConfiguringAudioSettings.html#//apple_ref/doc/uid/TP40016757-CH9-SW1
      
      A user can disable automatic invocation for PiP in Settings > General > Multitasking > Persistent Video Overla
      
      默认情况下，从PiP贴换到原屏幕，media暂停播放，有代理方法可以restore your video player’s interface
      
      Adoping PiP in a Custom Player
      给custom layer 添加PiP用AVPictureInPictureController
      1 添加UI给custom player 界面，使能用户开始PiP播放
      2 使得UI和系统的AVPlayerViewController的PiPUI一致
      3 通过API获取PiP播放的图片
      4 检查PiP可用性
      5 观察PiP的生命周期需 实现协议AVPictureInPictureControllerDelegate，观察pictureInPicturePossible属性，该属性显示了是否在当前环境下可用PiP，如face time,根据这个属性的值去设定PiP button的enable
      6 添加按钮让用户决定是否需要播放PiP中的视频
      
     当用户从PiP返回App时，默认将终止播放视频，但可以通过实现pictureInPictureController:restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:来恢复视频的播放
     
      Presenting Chapter Markers
      CHapter markers enable users to quickly navigate,直接获取数据创建section interface
      
      Chapter markers are a type of timed metadata
      需要异步的获取availableChapterLocales之后，才能调用chapterMetadataGroupsBestMatchingPreferredLanguages:方法获取Chapter Markers
      这个方法返回的是AVTimedMetadataGroup对象，是由CMTimeRange对象组成的集合对象
      
      播放背景Audio
      需要开启APP capabilities background
      对于video,需要做额外的设置，通常情况下，当app进入到background时会停止播放，如果想要在background播放，需要，断开avplayer然后在background重连
<!--      func applicationDidEnterBackground(_ application: UIApplication) {-->
<!--      // Disconnect the AVPlayer from the presentation when entering background-->
<!--      -->
<!--      // If presenting video with AVPlayerViewController-->
<!--      playerViewController.player = nil-->
<!--      -->
<!--      // If presenting video with AVPlayerLayer-->
<!--      playerLayer.player = nil-->
<!--      }-->
<!--      -->
<!--      func applicationWillEnterForeground(_ application: UIApplication) {-->
<!--      // Reconnect the AVPlayer to the presentation when returning to foreground-->
<!--      -->
<!--      // If presenting video with AVPlayerViewController-->
<!--      playerViewController.player = player-->
<!--      -->
<!--      // If presenting video with AVPlayerLayer-->
<!--      playerLayer.player = player-->
<!--      }-->

      //对中断做出响应
      核心类是AVAudioSession,终端开始和结束的时候，对注册过的观察者发送通知
      AVPlayer自动的对中断事件做出响应
      用KVO观察AVPlayer的rate属性，当AVPlayer暂停和恢复
      
      也可以直接观察AVAudioSession的中断通知
      
      对Route change做出响应
      AVAudioSession对路径的改变做出响应
      route change 如 蓝牙丢失
      
      当route change发生的时候，AVAudioSession会发出通知
      观察AVPlayer的rate属性
      直接注册AVAudioSession的route change 通知
      
      HTTP Live Stream是最理想的方式对媒体文件的播放，用HLS客户端可以根据网络情况动态的选择合适的stream来进行播放
      
      播放离线的HLS 内容
      从iOS10开始，可以AVFoundation下载 HLS asset到iOS设备上
      用AVAssetDownloadURLSession来管理Asset下载的执行，是URLSession的子类，通常用来创建和执行asets下载任务
      通过传NSURLSessionConfiguration来创建AVAssetDownloadURLSession实例
      Session configuration是background configuration
      创建AVAssetDownloadURLSession时需要一个协议，一个operation queue,下载的进度将会在指定的线程调用delegate的方法中
      下载的任务可能持续的执行在背景下，应该要考虑任务可能随时被终止，在app重新打开时考虑恢复任务
      为了恢复任务，需要重新创建一个和下载任务相同的identifier创建的新的Configuration
      ,用新的configuration重新生成AVAssetURLSession对象
      用AVAssetURLSession对象的方法getAllTasks获取所有没有完成的下载任务
      通过任务，来获取下载进度等
      
      追踪下载进度
      实现协议URLSession:assetDownloadTask:didLoadTimeRange:totalTimeRangesLoaded:timeRangeExpectedToLoad:来追踪下载进度
      下载进度用时间来表示，用这个方法返回的time range value来计算下载进度
      
      保存下载位置
      当asset下载完成或者下载任务被取消，协议方法URLSession:assetDownloadTask:didFinishDownloadingToURL:被调用
      clients should not move downloaded assets
      Downloaded HLS assets are stored on disk in a private bundle format. This bundle format may change over time, and developers should not attempt to access or store files within the bundle directly, but should instead use AVFoundation and other iOS APIs to interact with downloaded assets.
      
      
      AVPlayerItem由一些属性loadedTimeRanges，可以帮助决定当前的播放状态，
      
      accessLog：  从远程服务器播放asset网络相关的日志
      AVPlayerItemAccessLog，Log事件的获取用events属性，返回AVPlayerItemAccessLogEvents数组，每一个都是一个log entry,可以获取
      当前播放资源的URL,播放时间，当一个新的log entry产生的时候，AVPlayerItemNewAccessLogEntryNotification通知被发出
      
      errorLog: AVPlayerItem的错误log
      
      
      
      
