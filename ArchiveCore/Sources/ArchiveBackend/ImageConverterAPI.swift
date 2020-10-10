//
//  ImageConverterAPI.swift
//  
//
//  Created by Julian Kahnert on 11.10.20.
//

public protocol ImageConverterAPI: class {
    var totalDocumentCount: Atomic<Int> { get }
    
    func startProcessing()
    func stopProcessing()
    func getOperationCount() -> Int
}
