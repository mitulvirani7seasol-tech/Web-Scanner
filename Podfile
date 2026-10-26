platform :ios, '15.0'

target 'WebScanner' do
  use_frameworks!

  # Pods for WebScanner
  pod 'lottie-ios'
  pod 'Alamofire'
  pod 'AWSS3'
  pod 'SkeletonView'
  pod 'SVProgressHUD'
  pod 'SwiftyJSON'
  pod 'ShimmerSwift'
  pod 'ZIPFoundation', '~> 0.9'
  pod 'Google-Mobile-Ads-SDK'
  pod 'SDWebImage'
  pod 'SDWebImageWebPCoder'
  pod 'FirebaseAnalytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Messaging'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Performance'
  pod "Toaster"
  pod 'Toast-Swift'
end

target 'ExportWpChat' do
  use_frameworks!
  pod 'ZIPFoundation', '~> 0.9'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
        config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        config.build_settings['CLANG_WARN_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'NO'
        config.build_settings['HEADER_SEARCH_PATHS'] ||= '$(inherited) '
        config.build_settings['HEADER_SEARCH_PATHS'] << ' "${PODS_ROOT}/abseil"'
      end
    end
  end
end
