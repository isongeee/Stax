import Foundation
import ZIPFoundation

enum PPTXTextExtractor {
    nonisolated static func extract(url: URL, title: String) throws -> [ExtractedSourceChunk] {
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ExtractionError.pptxReadFailed(title)
        }

        let entriesByPath = archive.reduce(into: [String: Entry]()) { entries, entry in
            entries[entry.path] = entry
        }

        return archive.compactMap { entry -> ExtractedSourceChunk? in
            guard let index = slideIndex(from: entry.path, under: "ppt/slides/slide") else {
                return nil
            }

            let slideRuns = textRuns(from: entry, in: archive)
            let noteRuns = notePath(
                forSlidePath: entry.path,
                entriesByPath: entriesByPath,
                archive: archive
            )
                .flatMap { entriesByPath[$0] }
                .map { textRuns(from: $0, in: archive) } ?? []
            let combinedText = normalized(slideRuns + noteRuns)
            guard !combinedText.isEmpty else { return nil }

            return ExtractedSourceChunk(
                sourceIndex: index,
                sourceTitle: slideRuns.first,
                text: combinedText
            )
        }
        .sorted { $0.sourceIndex < $1.sourceIndex }
    }

    private nonisolated static func slideIndex(from path: String, under prefix: String) -> Int? {
        guard path.hasPrefix(prefix), path.hasSuffix(".xml") else { return nil }
        let remainder = path.dropFirst(prefix.count).dropLast(4)
        guard !remainder.isEmpty else { return nil }
        return Int(remainder)
    }

    private nonisolated static func textRuns(from entry: Entry, in archive: Archive) -> [String] {
        var data = Data()
        do {
            _ = try archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            return []
        }
        return XMLTextExtractor.textRuns(from: data)
    }

    private nonisolated static func notePath(
        forSlidePath slidePath: String,
        entriesByPath: [String: Entry],
        archive: Archive
    ) -> String? {
        let relationshipsPath = relationshipPath(forSlidePath: slidePath)
        guard let relationshipsEntry = entriesByPath[relationshipsPath] else {
            return nil
        }

        let relationships = relationshipTargets(from: relationshipsEntry, in: archive)
        guard let noteTarget = relationships.first(where: { relationship in
            relationship.type.hasSuffix("/notesSlide")
        })?.target else {
            return nil
        }

        return normalizedRelationshipTarget(noteTarget, relativeTo: parentDirectory(of: slidePath))
    }

    private nonisolated static func relationshipTargets(
        from entry: Entry,
        in archive: Archive
    ) -> [XMLRelationshipExtractor.Relationship] {
        var data = Data()
        do {
            _ = try archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            return []
        }
        return XMLRelationshipExtractor.relationships(from: data)
    }

    private nonisolated static func relationshipPath(forSlidePath slidePath: String) -> String {
        let directory = parentDirectory(of: slidePath)
        let fileName = slidePath.split(separator: "/").last.map(String.init) ?? slidePath
        return "\(directory)/_rels/\(fileName).rels"
    }

    private nonisolated static func parentDirectory(of path: String) -> String {
        var parts = path.split(separator: "/").map(String.init)
        guard parts.count > 1 else { return "" }
        parts.removeLast()
        return parts.joined(separator: "/")
    }

    private nonisolated static func normalizedRelationshipTarget(_ target: String, relativeTo directory: String) -> String {
        guard !target.hasPrefix("/") else {
            return String(target.dropFirst())
        }

        var parts = directory.isEmpty
            ? []
            : directory.split(separator: "/").map(String.init)

        for segment in target.split(separator: "/").map(String.init) {
            switch segment {
            case ".", "":
                continue
            case "..":
                if !parts.isEmpty { parts.removeLast() }
            default:
                parts.append(segment)
            }
        }

        return parts.joined(separator: "/")
    }

    private nonisolated static func normalized(_ runs: [String]) -> String {
        runs.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
