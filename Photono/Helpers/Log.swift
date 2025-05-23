//
//  Log.swift
//  Photono
//
//  Created by mio kato on 2025/05/24.
//

import Foundation

enum LogType: String {
    case error = "ERROR"
    case warning = "WARN"
    case info = "INFO"
    case debug = "DEBUG"
}

func log(
    _ message: String,
    with logType: LogType = .info,
    error: Error? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let fileName = (file as NSString).lastPathComponent
    let formattedMessage = "[[\(logType.rawValue)]] \(fileName):\(line) \(function) - \(message)"
    
    #if DEBUG
    print(formattedMessage)
    #endif
}
