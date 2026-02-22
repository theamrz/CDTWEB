import Foundation

enum LineChange: Equatable {
    case added(String)
    case removed(String)
    case unchanged(String)
}

enum DiffService {
    // diff sade bar asase CollectionDifference baraye UI statistik
    static func diffLines(old: String, new: String) -> [LineChange] {
        let oldLines = old.components(separatedBy: "\n")
        let newLines = new.components(separatedBy: "\n")
        let difference = newLines.difference(from: oldLines)

        var result: [LineChange] = []
        var i = 0, j = 0

        for change in difference {
            switch change {
            case .remove(let offset, _, _):
                while i < offset {
                    result.append(.unchanged(oldLines[i])); i += 1; j += 1
                }
                result.append(.removed(oldLines[offset])); i += 1
            case .insert(let offset, let element, _):
                while j < offset {
                    if i < oldLines.count {
                        result.append(.unchanged(oldLines[i])); i += 1; j += 1
                    } else { break }
                }
                result.append(.added(element)); j += 1
            }
        }
        while i < oldLines.count && j < newLines.count {
            result.append(.unchanged(oldLines[i])); i += 1; j += 1
        }
        while j < newLines.count {
            result.append(.added(newLines[j])); j += 1
        }
        while i < oldLines.count {
            result.append(.removed(oldLines[i])); i += 1
        }
        return result
    }

    static func stats(_ changes: [LineChange]) -> (added: Int, removed: Int, unchanged: Int) {
        var a = 0, r = 0, u = 0
        for c in changes {
            switch c {
            case .added: a += 1
            case .removed: r += 1
            case .unchanged: u += 1
            }
        }
        return (a, r, u)
    }
}
