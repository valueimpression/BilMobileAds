//
//  Helper.swift
//  BilMobileAds
//
//  Created by HNL_MAC on 6/16/20.
//  Copyright © 2020 bil. All rights reserved.
//

import Foundation
import SystemConfiguration

public enum HttpStatus {
    case SUCCESS
    case TIME_OUT
    case BAD_REQUEST
    case NOT_FOUND
    case INTERNAL_SERVER_ERROR
    case METHOD_NOT_ALLOWED
    case FORBIDDEN
    case UNAUTHORIZED
    case INVALID_FINGER_PRINT
    case UNDEFINED
    case NETWORK_CONNECT
}

enum Result<T, U> where U: Error  {
    case success(T)
    case failure(U)
}

class HostAD: Decodable {
    var pbHost: String
    var url: String?
    var pbAccountId: String
    var storedAuctionResponse: String
}
class AdInfor: Decodable {
    var isVideo: Bool
    var host: HostAD
    var configId: String
    var adUnitID: String
}
class AdUnitObj: Decodable {
    var placement: String
    var type: String
    var defaultType: String // Kieu hien thi mac dinh
    var isActive: Bool // -> cho hien thi
    
    var adInfor: [AdInfor]
}
class DataConfig: Decodable {
    var gdprConfirm: Bool?
    var pbServerEndPoint: String
    var adunit: AdUnitObj
}

class Helper: NSObject {
    
    static var dateFormat = "yyyy-MM-dd hh:mm:ssSSS"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    static let shared = Helper()
    
    func getAPI<T: Decodable>(api: String, complete: @escaping (Result<T,Error>) -> Void) {
        let urlPrefix = URL(string:Constants.URL_PREFIX + api)
        var request = URLRequest(url: urlPrefix!)
        request.timeoutInterval = 60
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //        request.addValue(UserDefaults.standard.string(forKey: "token")!, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request){ data, response, error in
            guard error == nil else {
                complete(.failure(error!))
                return
            }
            
            if data == nil {
                complete(.failure(error!))
            }
            
            do {
                let dataObj = try JSONDecoder().decode(T.self, from: data!)
                complete(.success(dataObj))
            } catch let jsonErr {
                complete(.failure(jsonErr))
            }
        }.resume()
    }
    
    func postAPI<T: Decodable>(api: String, paramMD: NSMutableDictionary?, complete: @escaping (Result<[T],Error>) -> Void) {
        
        let newUrl = URL(string:Constants.URL_PREFIX + "/api/" + api)
        var request = URLRequest(url: newUrl!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //        let accessToken = self.getTokenInfo()?.authorization!
        //        if accessToken != nil {
        //            request.addValue(accessToken!, forHTTPHeaderField: "Authorization")
        //        }
        
        if paramMD != nil {
            let body = paramMD
            let data = try! JSONSerialization.data(withJSONObject: body!, options: JSONSerialization.WritingOptions.prettyPrinted)
            let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            print(String(json!))
            request.httpBody = json!.data(using: String.Encoding.utf8.rawValue)
        }
        
    }
    
    func getHttpStatusByError(errCode: Int) -> HttpStatus {
        var status = HttpStatus.UNDEFINED
        switch (errCode) {
        case 500:
            status = HttpStatus.INTERNAL_SERVER_ERROR
            break
        case 400:
            status = HttpStatus.BAD_REQUEST
            break
        case 404:
            status = HttpStatus.NOT_FOUND
            break
        case 405:
            status = HttpStatus.METHOD_NOT_ALLOWED
            break
        case 401:
            status = HttpStatus.UNAUTHORIZED
            break
        case 302:
            status = HttpStatus.INVALID_FINGER_PRINT
            break
        default:
            status = HttpStatus.UNDEFINED
            break
        }
        
        return status
    }
    
    
    static func isInternetAvailable() -> Bool
    {
        guard let reachability: Bool = SCNetworkReachabilityCreateWithName(nil, "www.google.com") as? Bool else {
            return false
        }
        
        let isNetworkReachable = self.isNetworkAvailable()
        
        return (reachability && isNetworkReachable)
    }
    
    static func isNetworkAvailable() -> Bool
    {
        guard let flags = getFlags() else { return false }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    static func getFlags() -> SCNetworkReachabilityFlags?
    {
        guard let reachability = ipv4Reachability() ?? ipv6Reachability() else {
            return nil
        }
        
        var flags = SCNetworkReachabilityFlags()
        
        if !SCNetworkReachabilityGetFlags(reachability, &flags)
        {
            return nil
        }
        
        return flags
    }
    
    static func ipv6Reachability() -> SCNetworkReachability?
    {
        var zeroAddress = sockaddr_in6()
        
        zeroAddress.sin6_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin6_family = sa_family_t(AF_INET6)
        
        return withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
    }
    
    static func ipv4Reachability() -> SCNetworkReachability?
    {
        var zeroAddress = sockaddr_in()
        
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        return withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
    }
    
}
