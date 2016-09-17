public protocol CuratorLocation {
    func asURL() throws -> URL
}

extension CuratorLocation {
    typealias FileExistResult = (fileExist: Bool, isDirectory: Bool)
    func fileExist() throws -> FileExistResult {
        let url = try self.asURL()
        guard url.isFileURL else {
            throw CuratorError.locationIsNotFile
        }
        
        let path = url.path
        guard path.isEmpty == false else {
            throw CuratorError.invalidLocation(url: self)
        }
        
        var isDirectory: ObjCBool = false
        let fileExist = CuratorFileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return (fileExist, isDirectory.boolValue)
    }
    
    func fileReferenceURL() throws -> URL {
        let url = try self.asURL() as NSURL
        
        guard let fileReferenceURL = url.fileReferenceURL() else {
            throw CuratorError.cannotObtainFileReferenceURL(from: self)
        }
        
        return fileReferenceURL as URL
    }
    
    func createDirectory() throws {
        let url = try self.asURL()
        assert(url.isFileURL)
        let directoryURL: URL = {
            if #available(iOS 9.0, OSX 10.11, *) {
                if url.hasDirectoryPath {
                    return url
                }
            } else {
                if url.lastPathComponent.hasSuffix("/") {
                    return url
                }
            }
            
            return url.deletingLastPathComponent()
        }()
        
        let directoryExistResult = try directoryURL.fileExist()
        
        if directoryExistResult.fileExist {
            if directoryExistResult.isDirectory {
                return
            }
            else {
                throw CuratorError.unableToCreateDirectory(for: self)
            }
        }
        
        try CuratorFileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}