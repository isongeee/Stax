import Foundation
import ZIPFoundation

enum PPTXImporter {
    struct Probe {
        let title: String
        let slideCount: Int
    }

    static func probe(url: URL) throws -> Probe {
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ImportError.pptxNotAZip(url)
        }
        let slideCount = archive.reduce(into: 0) { count, entry in
            let path = entry.path
            guard path.hasPrefix("ppt/slides/slide"), path.hasSuffix(".xml") else { return }
            count += 1
        }
        guard slideCount > 0 else { throw ImportError.pptxNoSlides(url) }
        return Probe(
            title: url.deletingPathExtension().lastPathComponent,
            slideCount: slideCount
        )
    }
}
