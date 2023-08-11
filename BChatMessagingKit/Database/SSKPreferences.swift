//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
public class SSKPreferences: NSObject {
    // Never instantiate this class.
    private override init() {}

    private static let collection = "SSKPreferences"

    // MARK: -

    private static let areLinkPreviewsEnabledKey = "areLinkPreviewsEnabled"

    @objc
    public static var areLinkPreviewsEnabled: Bool {
        get {
            return getBool(key: areLinkPreviewsEnabledKey, defaultValue: true)
        }
        set {
            setBool(newValue, key: areLinkPreviewsEnabledKey)
        }
    }
    
    // MARK: -
    private static let areCallsEnabledKey = "areCallsEnabled"

    @objc
    public static var areCallsEnabled: Bool {
        get {
            return getBool(key: areCallsEnabledKey, defaultValue: false)
        }
        set {
            setBool(newValue, key: areCallsEnabledKey)
        }
    }
    
    @objc
    public static var isCallKitSupported: Bool {
        let userLocale = NSLocale.current
        
        guard let regionCode = userLocale.regionCode else { return false }
        
        if regionCode.contains("CN") ||
            regionCode.contains("CHN") {
            return false
        } else {
            return true
        }
    }

    // MARK: -

    private static let hasSavedThreadKey = "hasSavedThread"

    @objc
    public static var hasSavedThread: Bool {
        get {
            return getBool(key: hasSavedThreadKey)
        }
        set {
            setBool(newValue, key: hasSavedThreadKey)
        }
    }

    @objc
    public class func setHasSavedThread(value: Bool, transaction: YapDatabaseReadWriteTransaction) {
        transaction.setBool(value,
                            forKey: hasSavedThreadKey,
                            inCollection: collection)
    }

    // MARK: -

    private class func getBool(key: String, defaultValue: Bool = false) -> Bool {
        return OWSPrimaryStorage.dbReadConnection().bool(forKey: key, inCollection: collection, defaultValue: defaultValue)
    }

    private class func setBool(_ value: Bool, key: String) {
        OWSPrimaryStorage.dbReadWriteConnection().setBool(value, forKey: key, inCollection: collection)
    }
}
