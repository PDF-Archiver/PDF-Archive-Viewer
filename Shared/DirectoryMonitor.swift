//
//  DirectoryMonitor.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 24.06.20.
//

import Foundation

class FolderMonitor {
    // MARK: Properties

    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    /// URL for the directory being monitored.
    let url: URL

    private let folderDidChange: ((URL) -> Void)

    // MARK: Initializers
    init(url: URL, folderDidChange: @escaping ((URL) -> Void)) {
        self.url = url
        self.folderDidChange = folderDidChange

        startMonitoring()
    }

    deinit {
        folderMonitorSource?.cancel()
    }

    // MARK: Monitoring
    /// Listen for changes to the directory (if we are not already).
    private func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return

        }
        // Open the directory referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write, queue: folderMonitorQueue)
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.folderDidChange(self.url)
        }
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }
}
