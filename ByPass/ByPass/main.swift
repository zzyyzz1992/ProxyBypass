//
//  main.swift
//  ByPass
//
//  Created by Zeyang Zhang on 4/4/16.
//  Copyright © 2016 Zeyang Zhang. All rights reserved.
//

import Foundation
import SystemConfiguration
class ByPass {
    static func doByPass() {
        let authFlags: AuthorizationFlags = [.Defaults , .ExtendRights , .InteractionAllowed , .PreAuthorize]
        var authRef: AuthorizationRef = AuthorizationRef.init(nilLiteral: ())
        let fileManager =  NSFileManager()
        let path = fileManager.currentDirectoryPath + "/ByPassList.plist"
        guard fileManager.fileExistsAtPath(path), let byPassList = NSArray.init(contentsOfFile: path) else {
            print("invalid plist / plist path")
            return
        }
        let authErr = AuthorizationCreate(nil, nil, authFlags, &authRef)
        if authErr != noErr{
            print("authErr")
            return
        }
        let prefRef = SCPreferencesCreateWithAuthorization(nil, "ByPass", nil, authRef)!
        let sets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices)!
        var proxies = [NSObject : AnyObject]()
        proxies[kCFNetworkProxiesHTTPEnable] = 0//关闭 http 代理
        proxies[kCFNetworkProxiesHTTPSEnable] = 0
        proxies[kCFNetworkProxiesProxyAutoConfigEnable] = 0
        proxies[kCFNetworkProxiesSOCKSProxy] = "127.0.0.1"//打开 SS 代理
        proxies[kCFNetworkProxiesSOCKSPort] = 1080
        proxies[kCFNetworkProxiesSOCKSEnable] = 1
        proxies[kCFNetworkProxiesExceptionsList] = byPassList //设置例外
        print(sets)
        print("---")
        //// 遍历系统中的网络设备列表，设置 AirPort 和 Ethernet 的代理
        sets.allKeys!.forEach { (key) in
            let dict = sets.objectForKey(key)!
            let hardware = dict.valueForKeyPath("Interface.Hardware") as! NSString
            if ["AirPort","Wi-Fi","Ethernet"].contains(hardware) {
                print("\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)")
                print(SCPreferencesPathSetValue(prefRef, "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)", proxies))//注意这里的路径，一开始少了一个'/'
            }
        }
        SCPreferencesCommitChanges(prefRef)
        SCPreferencesApplyChanges(prefRef)
        SCPreferencesSynchronize(prefRef)
    }
}
ByPass.doByPass()