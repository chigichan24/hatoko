#!/usr/bin/env swift
import Carbon

let bundleID = "com.chigichan24.inputmethod.Hatoko"
let props = [kTISPropertyBundleID: bundleID as CFString] as CFDictionary

guard let sources = TISCreateInputSourceList(props, true)?.takeRetainedValue() as? [TISInputSource] else {
    print("ERROR: No input sources found for \(bundleID)")
    exit(1)
}

for source in sources {
    let id = Unmanaged<CFString>.fromOpaque(
        TISGetInputSourceProperty(source, kTISPropertyInputSourceID)!
    ).takeUnretainedValue() as String

    let status = TISEnableInputSource(source)
    if status == noErr {
        print("Enabled: \(id)")
    } else {
        print("Failed to enable \(id): \(status)")
    }
}

print("Done. Select Hatoko from the menu bar input source.")
