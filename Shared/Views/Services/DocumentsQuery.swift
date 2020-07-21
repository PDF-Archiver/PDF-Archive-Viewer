////
////  DocumentsQuery.swift
////  PDFArchiver
////
////  Created by Julian Kahnert on 23.08.18.
////  Copyright © 2018 Julian Kahnert. All rights reserved.
////
///*
// Copyright (C) 2016 Apple Inc. All Rights Reserved.
// See LICENSE.txt for this sample’s licensing information
// 
// Abstract:
// This is the Browser Query which manages results form an `NSMetadataQuery` to compute which documents to show in the Browser UI / animations to display when cells move.
// */
//
////import UIKit
//
///// Protocol to handle file changes from the DocumentsQuery class.
/////
///// The delegate protocol implemented by the object that receives our results. We
///// pass the updated list of results as well as a set of animations.
//protocol DocumentsQueryDelegate: AnyObject {
//    func updateWithResults(removedItems: [NSMetadataItem], addedItems: [NSMetadataItem], updatedItems: [NSMetadataItem]) -> Set<Document>
//}
//
///// Receive file changes from the OS.
/////
///// The DocumentBrowserQuery wraps an `NSMetadataQuery` to insulate us from the
///// queueing and animation concerns. It runs the query and computes animations
///// from the results set.
//class DocumentsQuery {
//
//    private let notContainsTempPath = NSPredicate(format: "(NOT (%K CONTAINS[c] %@)) AND (NOT (%K CONTAINS[c] %@))", NSMetadataItemPathKey, "/\(StorageHelper.Paths.tempFolderName)/", NSMetadataItemPathKey, "/.Trash/")
//    private var metadataQuery: NSMetadataQuery
//    private var firstRun = true
//
//    private let workerQueue: OperationQueue = {
//        let workerQueue = OperationQueue()
//
//        workerQueue.name = (Bundle.main.bundleIdentifier ?? "PDFArchiver") + ".browserdatasource.workerQueue"
//        workerQueue.maxConcurrentOperationCount = 1
//
//        return workerQueue
//    }()
//
//    weak var documentsQueryDelegate: DocumentsQueryDelegate?
//
//    // MARK: - Initialization
//
//    init() {
//        metadataQuery = NSMetadataQuery()
//
//        // Filter only documents from the current year and the year before
////        let year = Calendar.current.component(.year, from: Date())
////        let predicate = NSPredicate(format: "(%K LIKE[c] '\(year)-*.pdf') OR (%K LIKE[c] '\(year - 1)-*.pdf')", NSMetadataItemFSNameKey, NSMetadataItemFSNameKey)
//
//        // get all pdf documents
//        let predicate = NSPredicate(format: "%K ENDSWITH[c] '.pdf'", NSMetadataItemFSNameKey)
//
//        metadataQuery.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, notContainsTempPath] )
//
//        // update the file status 5 times per second, while downloading
//        metadataQuery.notificationBatchingInterval = 0.2
//
//        /*
//         Ask for both in-container documents and external documents so that
//         the user gets to interact with all the documents she or he has ever
//         opened in the application, without having to pull the document picker
//         again and again.
//         */
//        metadataQuery.searchScopes = [
//            NSMetadataQueryUbiquitousDocumentsScope
//        ]
//
//        /*
//         We supply our own serializing queue to the `NSMetadataQuery` so that we
//         can perform our own background work in sync with item discovery.
//         Note that the operationQueue of the `NSMetadataQuery` must be serial.
//         */
//        metadataQuery.operationQueue = workerQueue
//
//        NotificationCenter.default.addObserver(self, selector: #selector(DocumentsQuery.finishGathering(notification:)), name: .NSMetadataQueryDidFinishGathering, object: metadataQuery)
//        NotificationCenter.default.addObserver(self, selector: #selector(DocumentsQuery.queryUpdated(notification:)), name: .NSMetadataQueryDidUpdate, object: metadataQuery)
//
////        metadataQuery.start()
//        os_log("Starting the documents query.", log: DocumentsQuery.log, type: .debug)
//    }
//
//    // MARK: - Notifications
//
//    @objc
//    func queryUpdated(notification: NSNotification) {
//
//        os_log("Documents query update.", log: DocumentsQuery.log, type: .debug)
//
//        let changedMetadataItems = (notification.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem]) ?? []
//        let removedMetadataItems = (notification.userInfo?[NSMetadataQueryUpdateRemovedItemsKey] as? [NSMetadataItem]) ?? []
//        let addedMetadataItems = (notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem]) ?? []
//
//        // update the archive
//        _ = documentsQueryDelegate?.updateWithResults(removedItems: removedMetadataItems, addedItems: addedMetadataItems, updatedItems: changedMetadataItems)
//        NotificationCenter.default.post(.documentChanges)
//    }
//
//    @objc
//    func finishGathering(notification: NSNotification) {
//
//        os_log("Documents query finished.", log: DocumentsQuery.log, type: .debug)
//        guard let metadataQueryResults = metadataQuery.results as? [NSMetadataItem] else { return }
//
//        // update the archive
//        _ = documentsQueryDelegate?.updateWithResults(removedItems: [], addedItems: metadataQueryResults, updatedItems: [])
//        NotificationCenter.default.post(.documentChanges)
//
//        // get all pdf documents
////        if firstRun {
////            let predicate = NSPredicate(format: "%K ENDSWITH[c] '.pdf'", NSMetadataItemFSNameKey)
////            metadataQuery.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, notContainsTempPath] )
////            firstRun = false
////        }
//    }
//}
