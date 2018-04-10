//: Playground - noun: a place where people can play

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum HttpMethod {
    case get
    case post(body: [String: Any])
    case put(body: [String: Any])
    case delete
    
    var name: String {
        switch self {
        case .delete: return "DELETE"
        case .get: return "GET"
        case .post: return "POST"
        case .put: return "PUT"
        }
    }
    
    var body: [String: Any] {
        switch self {
        case .post(let body): return body
        case .put(let body): return body
        case .delete, .get: return [:]
        }
    }
}

struct Ressource<T> {
    let url: URL
    let method: HttpMethod
    let parse: (Data) throws -> T
}

final class Webservice {
    
    func request<T>(ressource: Ressource<T>, timeout: TimeInterval = 5.0, completion: @escaping (Result<T>) -> Void) {
        var request = URLRequest(url: ressource.url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: timeout)
        request.httpMethod = ressource.method.name
        
        if !ressource.method.body.isEmpty {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ressource.method.body, options: [])
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            let result: Result<T>
            
            if let error = error {
                result = .failure(error)
            } else {
                do {
                    result = .success(try ressource.parse(data!))
                } catch let parseError {
                    result = .failure(parseError)
                }
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }
}
