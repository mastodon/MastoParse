//
//  MastoParseContentBlock.swift
//  MastoParse
//
//  Created by Shannon Hughes on 7/1/25.
//

public func getParseBlocks(from html: String) throws -> [MastoParseContentBlock] {
    let nodes = try buildContentTree(from: html)
    let blocks = getParseBlocks(from: nodes)
    return blocks
}

func getParseBlocks(from nodes: [MastoParseNode]) -> [MastoParseContentBlock] {
    let blocks = toMastoParseAccumulators(nodes, addingTo: nil).flatMap { accumulator in
        if let block = accumulator.contentBlock() {
            return [block]
        } else {
            return accumulator.contentRows(inheritingNestedFormatting: [])
        }
    }
    
    return blocks
}

public class MastoParseContentBlock: Identifiable {
}

public enum MastoParseNestedFormat {
    case topLevelBlockquote
    case subordinateBlockquote
    case listLevel
}

public class MastoParseContentRow: MastoParseContentBlock {
    public enum Style {
        case paragraph
        case code
    }

    public let style: Style
    public let nestedFormatting: [MastoParseNestedFormat]
    public let contents: [MastoParseInlineElement]
    
    public init(contents: [MastoParseInlineElement], style: Style, nestedFormatting: [MastoParseNestedFormat]) {
        self.style = style
        self.contents = contents
        self.nestedFormatting = nestedFormatting
    }
}

public class MastoParseBlockquote: MastoParseContentBlock {
    public let contents: [MastoParseContentRow]
    
    init(contents: [MastoParseContentRow]) {
        self.contents = contents
    }
}

public struct MastoParseInlineElement: Sendable {
    public enum ElementType: Sendable {
        case text
        case code
    }
    
    public let type: ElementType
    public let contents: String
    
    public init(type: ElementType, contents: String) {
        self.type = type
        self.contents = contents
    }
}
