//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Paul Smith on 7/9/21.
//

import Foundation

class FlickrClient {
    
    enum MethodTypes : String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    enum Endpoints {
        static let base = "https://flickr.com/services/rest/"
        static let apiKey = "aed601f58a0d640a8059a12c5c063434"
        static let apiKeyPart = "&api_key=\(apiKey)"
        
        case getPhotos(Double, Double)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let lat, let lon) :
                return Endpoints.base + "?method=flickr.photos.search" + Endpoints.apiKeyPart + "&bbox=-10%2C-10%2C10%2C10&content_type=1&lat=\(lat)&lon=\(lon)&page=\(Int.random(in: 0..<10))&per_page=42&format=json&nojsoncallback=1";
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotos(latitude: Double, longitude: Double, completion: @escaping ([PhotoResponse]?, Error?) -> Void) {
        _ = taskForGETRequest(url: Endpoints.getPhotos(latitude, longitude).url, responseType: PhotoResults.self, completion: {
            (response, error) in
            if let response = response {
                completion(response.photos.photo, error)
            }
            else {
                completion([], error)
            }
        })
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, removeSecurity: Bool = false , responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let request = URLRequest(url: url)
        let task = taskForData(urlRequest: request, removeSecurity: removeSecurity, responseType: responseType, completion: completion)
        return task
    }
    
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, body: RequestType, removeSecurity: Bool = false, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        var request = URLRequest(url: url)
        
        request.httpMethod = MethodTypes.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try! encoder.encode(body)
        
        let task = taskForData(urlRequest: request, removeSecurity: removeSecurity, responseType: responseType, completion: completion)
        return task
    }
    
    class func taskForPUTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, body: RequestType, removeSecurity: Bool = false, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        var request = URLRequest(url: url)
        
        request.httpMethod = MethodTypes.put.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try! encoder.encode(body)
        
        let task = taskForData(urlRequest: request, removeSecurity: removeSecurity, responseType: responseType, completion: completion)
        return task
    }
        
    class func taskForDELETERequest<ResponseType: Decodable>(url: URL, removeSecurity: Bool = false, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        var request = URLRequest(url: url)
        
        request.httpMethod = MethodTypes.delete.rawValue
        var xsrfCookie: HTTPCookie? = nil
        for cookie in HTTPCookieStorage.shared.cookies! {
          if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
          request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        
        let task = taskForData(urlRequest: request, removeSecurity: removeSecurity, responseType: responseType, completion: completion)
        return task
    }
    
    @discardableResult class func taskForData<ResponseType: Decodable>(urlRequest: URLRequest, removeSecurity: Bool, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: urlRequest) {
            data, response, error in
            guard var data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            if(removeSecurity) {
                let range : Range = 5..<data.count
                data = data.subdata(in: range)
            }
            do {
                //print(String(data: data, encoding: .utf8)!)
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, error)
                }
            }
            catch {
                do {
                    let errorObject = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorObject)
                    }
                }
                catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
}

