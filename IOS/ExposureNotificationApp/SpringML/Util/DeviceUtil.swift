//
//  DeviceUtil.swift
//  ExposureNotificationApp
//
//

import Foundation
import DeviceCheck

class DeviceUtil {
    static func getDeviceCheckTokenAsData(_ cb: @escaping (Data?) -> ()) {
        let device = DCDevice.current
        if !device.isSupported {
            cb(nil)
            return
        }
        device.generateToken { (data, error) in
            if let error = error {
                cb(nil)
                return
            }
            else {
                cb(data)
                return
            }
        }
    }
    static func getDeviceCheckTokenAsB64String(_ cb: @escaping (String?) -> ()) {
        DeviceUtil.getDeviceCheckTokenAsData({ (data) in
            if let data = data {
                cb(data.base64EncodedString())
            }
            else {
                cb(nil)
            }
        })
    }
}
