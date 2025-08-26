//
//  MastoParseAccumulator.swift
//  MastoParse
//
//  Created by Shannon Hughes on 7/1/25.
//

import Foundation

public class MarkdownAccumulator {
    var charactersToTrim: CharacterSet? {
        return nil
    }
    
    func appendInlineElement(_ element: MastoParseInlineElement) {
        fatalError("subclasses must implement")
    }
    
    var canAppendBlocks: Bool {
        return false
    }
    
    func appendBlock(_ block: MarkdownAccumulator) -> Bool {
        fatalError("subclasses must implement")
    }
    
    func contentRows(inheritingNestedFormatting inherited: [MastoParseNestedFormat], withPrefix prefix: String?) -> [MastoParseContentRow] {
        fatalError("subclasses must implement")
    }
    
    func contentBlock() -> MastoParseContentBlock? {
        fatalError("subclasses must implement")
    }
}

private class MarkdownFlowAccumulator: MarkdownAccumulator {
    enum FlowAccumulatorType {
        case paragraph
        case code
    }
    
    let type: FlowAccumulatorType
    var inlineElements = [MastoParseInlineElement]()
    
    init(_ type: FlowAccumulatorType) {
        self.type = type
    }
    
    override var charactersToTrim: CharacterSet? {
        switch type {
        case .code:
            return nil
        case .paragraph:
            return .newlines
        }
    }
    
    override func appendInlineElement(_ element: MastoParseInlineElement) {
        self.inlineElements.append(element)
    }
    
    override func appendBlock(_ block: MarkdownAccumulator) -> Bool {
        return false
    }
    
    override func contentRows(inheritingNestedFormatting inherited: [MastoParseNestedFormat], withPrefix prefix: String?) -> [MastoParseContentRow] {
        switch type {
        case .paragraph:
            if !inlineElements.isEmpty {
                return [MastoParseContentRow(contents: inlineElements, style: .paragraph, listItemPrefix: prefix, nestedFormatting: inherited)]
            }
        case .code:
            if !inlineElements.isEmpty {
                return [MastoParseContentRow(contents: inlineElements, style: .code, listItemPrefix: prefix, nestedFormatting: inherited)]
            }
        }
        return []
    }
    
    override func contentBlock() -> MastoParseContentBlock? {
        return nil
    }
}

class MarkdownBlockAccumulator: MarkdownAccumulator {
    enum BlockType: Equatable {
        case blockquote
        case list(prefix: String?)
        
        var prefix: String? {
            switch self {
            case .blockquote:
                return nil
            case .list(let prefix):
                return prefix
            }
        }
    }
    
    let type: BlockType
    var contents = [MarkdownAccumulator]()
    
    init(_ type: BlockType) {
        self.type = type
    }
    
    override var charactersToTrim: CharacterSet? {
        switch type {
        case .blockquote:
            return .newlines
        case .list:
            return .whitespacesAndNewlines
        }
    }
    
    override func appendInlineElement(_ element: MastoParseInlineElement) {
        if let currentParagraph = contents.last as? MarkdownFlowAccumulator {
            currentParagraph.appendInlineElement(element)
        } else {
            let newParagraph = MarkdownFlowAccumulator(.paragraph)
            newParagraph.appendInlineElement(element)
            contents.append(newParagraph)
        }
    }
    
    override var canAppendBlocks: Bool {
        return true
    }
    
    override func appendBlock(_ block: MarkdownAccumulator) -> Bool {
        contents.append(block)
        return true
    }
    
    override func contentRows(inheritingNestedFormatting inherited: [MastoParseNestedFormat], withPrefix prefix: String?) -> [MastoParseContentRow] {
        let immutableContents = contents.flatMap { accumulator in
            let childFormatting: [MastoParseNestedFormat] = {
                switch type {
                case .blockquote:
                    if inherited.isEmpty {
                        return [.topLevelBlockquote]
                    } else {
                        return inherited + [.subordinateBlockquote]
                    }
                case .list:
                    if let childBlockquote = accumulator as? MarkdownBlockAccumulator, childBlockquote.type == .blockquote {
                        return inherited + [.listLevel, .listLevel]
                    } else {
                        return inherited + [.listLevel]
                    }
                }
            }()
            return accumulator.contentRows(inheritingNestedFormatting: childFormatting, withPrefix: type.prefix)
        }
        return immutableContents
    }
    
    override func contentBlock() -> MastoParseContentBlock? {
        let contents = contentRows(inheritingNestedFormatting: [], withPrefix: nil)
        guard !contents.isEmpty else {
            return nil
        }
        switch type {
        case .blockquote:
            return MastoParseBlockquote(contents: contents)
        case .list:
            return nil
        }
    }
}

private func listItems(_ nodes: [MastoParseNode], ordered: Bool, startingIndex: Int?) -> [MarkdownAccumulator] {
    let listItemContents: [[MastoParseNode]] = nodes.compactMap { node -> [MastoParseNode]? in
        guard case .element(let li) = node, li.name == "li" else { return nil }
        return li.children
    }
    
    var index = startingIndex ?? 1
    
    let accumulatedItems: [MarkdownAccumulator] = listItemContents.map { contents in
        defer { index += 1 }
        let listPrefix = ordered ? "\(index). " : "• "
        let listItem = MarkdownBlockAccumulator(.list(prefix: listPrefix))
        
        _ = toMastoParseAccumulators(contents, addingTo: listItem)
        
        return listItem
    }
    
    return accumulatedItems
}


func toMastoParseAccumulators(_ nodes: [MastoParseNode], addingTo containingAccumulator: MarkdownAccumulator?) -> [MarkdownAccumulator] {
    var accumulatedBlocks = [MarkdownAccumulator]()
    
    var currentAccumulator: MarkdownAccumulator = containingAccumulator ?? MarkdownFlowAccumulator(.paragraph)
    
    for node in nodes {
        func append(_ inlineElement: MastoParseInlineElement.ElementType, contents: String) {
            let trimmed = {
                if let charactersToTrim = currentAccumulator.charactersToTrim {
                    contents.trimmingCharacters(in: charactersToTrim)
                } else {
                    contents
                }
            }()
            currentAccumulator.appendInlineElement(MastoParseInlineElement(type: inlineElement, contents: trimmed))
        }
        
        switch node {
        case .text(let t):
            append(.text, contents: t)
        case .element(let element):
            var skipChildren = false
            
            if isInlineElement(element.name) {
                switch element.name {
                case "br":
                    currentAccumulator.appendInlineElement(MastoParseInlineElement(type: .text, contents: "\n"))
                default:
                    let markdownString = toString([node])
                    append(element.name == "code" ? .code : .text, contents: markdownString)
                }
                skipChildren = true
            } else {
                let newAccumulator: MarkdownAccumulator? = { () -> MarkdownAccumulator? in
                    switch element.name {
                    case "p":
                        return MarkdownFlowAccumulator(.paragraph)
                    case "pre":
                        return MarkdownFlowAccumulator(.code)
                    case "blockquote":
                        let blockquote = MarkdownBlockAccumulator(.blockquote)
                        let contents = toMastoParseAccumulators(element.children, addingTo: nil)
                        blockquote.contents = contents
                        if !currentAccumulator.appendBlock(blockquote) {
                            accumulatedBlocks.append(currentAccumulator)
                            accumulatedBlocks.append(blockquote)
                        }
                        skipChildren = true
                        currentAccumulator = MarkdownFlowAccumulator(.paragraph) // we've taken care of the whole blockquote already, now we wipe the slate clean for a fresh start
                        return nil
                    case "ul", "ol":   // unordered or ordered list
                        var startIndex: Int
                        if let start = element.attributes["start"], let intStart = Int(start) {
                            startIndex = intStart
                        } else {
                            startIndex = 1
                        }
                        
                        let itemAccumulators = listItems(element.children, ordered: element.name == "ol", startingIndex: element.name == "ol" ? startIndex : nil)
                        
                        let appendToCurrent = currentAccumulator.canAppendBlocks
                        if !appendToCurrent {
                            accumulatedBlocks.append(currentAccumulator)
                        }
                        for itemAccumulator in itemAccumulators {
                            if appendToCurrent {
                                _ = currentAccumulator.appendBlock(itemAccumulator)
                            } else {
                                accumulatedBlocks.append(itemAccumulator)
                            }
                        }
                        skipChildren = true
                        currentAccumulator = MarkdownFlowAccumulator(.paragraph) // we've taken care of the whole list already, now we wipe the slate clean for a fresh start
                        return nil
                    case "li":   // list item
                        assertionFailure("list items should be handled by the listItems() function")
                        return nil
                    default:
                        // treat as text
                        let markdownString = toString([node])
                        append(element.name == "code" ? .code : .text, contents: markdownString)
                        skipChildren = true
                        return nil
                    }
                }()
                if let newAccumulator, let currentAccumulator = currentAccumulator as? MarkdownBlockAccumulator, currentAccumulator.appendBlock(newAccumulator) {
                    if !skipChildren {
                        _ = toMastoParseAccumulators(element.children, addingTo: newAccumulator)
                    }
                    continue
                } else if let newAccumulator {
                    accumulatedBlocks.append(currentAccumulator)
                    if !skipChildren {
                        _ = toMastoParseAccumulators(element.children, addingTo: newAccumulator)
                    }
                    currentAccumulator = newAccumulator
                } else {
                    continue
                }
            }
        }
    }
    accumulatedBlocks.append(currentAccumulator)
    
    return accumulatedBlocks
}

private func isInlineElement(_ elementName: String) -> Bool {
    switch elementName {
    case "strong", "b", "em", "i", "u", "del", "s", "code", "a", "br": return true
    default:
        return false
    }
}

private func escapeMarkdown(_ text: String) -> String {
    // Escape Markdown characters unless inside code blocks
    let specialChars = ["\\", "`", "*", "_", "{", "}", "[", "]", "(", ")", "#", "+", "-", ".", "!"]
    var escaped = text
    for char in specialChars {
        escaped = escaped.replacingOccurrences(of: char, with: "\\" + char)
    }
    return escaped
}

func toString(_ nodes: [MastoParseNode]) -> String {
    nodes.map { node in
        switch node {
        case .text(let t):
#if DEBUG && false
            print("toString of text is: \(t)")
#endif
            return escapeMarkdown(t)
            
        case .element(let element):
            if !isInlineElement(element.name) {
                return toString(element.children)
            }
            
            let childrenMarkdown = toString(element.children)
            
            switch element.name {
            case "strong", "b": return "**\(childrenMarkdown)**"
            case "em", "i":     return "_\(childrenMarkdown)_"
            case "u":           return childrenMarkdown // Markdown doesn't support underline
            case "del", "s":    return "~~\(childrenMarkdown)~~"
            case "code":
                if element.attributes["class"]?.contains("language-") == true {
                    return "\n\(childrenMarkdown)\n"
                } else {
                    return "\(childrenMarkdown)"
                }
            case "pre", "blockquote": assertionFailure(); return ""
            case "a":
                let href = element.attributes["href"] ?? "#"
                return "[\(trimUrlStringForDisplay(childrenMarkdown))](\(href))"
            case "br": return "  \n"
            default:
                return childrenMarkdown
            }
        }
    }.joined()
}

func trimUrlStringForDisplay(_ urlString: String) -> String {
    let maxLength: Int = 30
    var trimmed = urlString
    let https = "https://"
    let http = "http://"
    let escapedWww = "www\\."
    let www = "www."
    
    trimmed = trimmed.replacingOccurrences(of: https, with: "", options: .anchored)
    trimmed = trimmed.replacingOccurrences(of: http, with: "", options: .anchored)
    trimmed = trimmed.replacingOccurrences(of: escapedWww, with: "", options: .anchored)
    trimmed = trimmed.replacingOccurrences(of: www, with: "", options: .anchored)
    if trimmed.count > maxLength {
        return String(trimmed.prefix(maxLength)) + "…"
    } else {
        return trimmed
    }
}
