//
//  DocumentCameraViewController.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 02.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUI
import VisionKit

public struct DocumentCameraView: UIViewControllerRepresentable, Log {

    private let controller = VNDocumentCameraViewController()
    private let isShown: Binding<Bool>
    private let imageHandler: ([UIImage]) -> Void

    public init(isShown: Binding<Bool>, imageHandler: @escaping ([UIImage]) -> Void) {
        self.isShown = isShown
        self.imageHandler = imageHandler
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) { }

    public func makeCoordinator() -> Coordinator {
        Coordinator(isShown: isShown, imageHandler: imageHandler)
    }

    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {

        private let isShown: Binding<Bool>
        private let imageHandler: ([UIImage]) -> Void

        fileprivate init(isShown: Binding<Bool>, imageHandler: @escaping ([UIImage]) -> Void) {
            self.isShown = isShown
            self.imageHandler = imageHandler
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            self.isShown.wrappedValue = false

            DispatchQueue.global(qos: .userInitiated).async {
                var images = [UIImage]()
                for index in 0..<scan.pageCount {
                    let image = scan.imageOfPage(at: index)
                    images.append(image)
                }
                self.imageHandler(images)
            }
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            self.isShown.wrappedValue = false
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            log.error("Scan did fail with error.", metadata: ["error": "\(error.localizedDescription)"])
            self.isShown.wrappedValue = false
        }
    }
}
