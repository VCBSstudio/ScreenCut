//
//  RequestNetwork.swift
//  ScreenCut
//
//  Created by helinyu on 2024/11/7.
//


import Moya
import Combine
import Foundation

// 定义 API
let provider = MoyaProvider<LocalNetworkAPI>()
var networkcancellables = Set<AnyCancellable>()

func LocalRequestPublisher<T: TargetType, R: Decodable>(_ target: T, responseType: R.Type) -> AnyPublisher<R, Error> {
    Future { promise in
        provider.request(target as! LocalNetworkAPI) { result in
            switch result {
            case .success(let response):
                do {
                    let decodedData = try JSONDecoder().decode(R.self, from: response.data)
                    promise(.success(decodedData))
                } catch {
                    promise(.failure(error))
                }
            case .failure(let error):
                promise(.failure(error))
            }
        }
    }
    .eraseToAnyPublisher()
}


