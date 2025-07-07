//
//  MastoParseTree.swift
//  Created by Shannon Hughes on 7/1/25.
//

import Foundation
import SwiftSoup

// MARK: MastoParseTree

/// Convert Mastodon post contents html into a tree of MastoParseNodes
func buildContentTree(from html: String) throws -> [MastoParseNode] {
    let document = try SwiftSoup.parseBodyFragment(html)
    guard let body = document.body() else { return [] }
    
    return try body.getChildNodes().compactMap { try transform(node: $0) }
}

/// One node in the tree
indirect enum MastoParseNode: CustomDebugStringConvertible {
    case text(String) // leaf
    case element(ElementNode) // internal
    
    var debugDescription: String {
        switch self {
        case .text(let t): return "TEXT: " + #""\#(t)""#
        case .element(let e): return "<\(e.name) \(e.attributes)> (\(e.children.count) children)"
        }
    }
}

struct ElementNode {
    let name: String
    let attributes: [String:String]
    var children: [MastoParseNode]
}


private func transform(node: SwiftSoup.Node) throws -> MastoParseNode? {
    switch node {
    case let textNode as SwiftSoup.TextNode:
        // Collapse any extra carriage returns
        let text = textNode.getWholeText().replacingOccurrences(of: "\r", with: "")
        return text.isEmpty ? nil : .text(text)
        
    case let element as SwiftSoup.Element:
        guard Allowed.elements.contains(element.tagName()) else {
            // Skip unsupported elements but keep their children
            return try wrapChildren(of: element)
        }
        
        let attrs = filteredAttributes(from: element)
        
        let children = try element.getChildNodes().compactMap { try transform(node: $0) }
        return .element(ElementNode(name: element.tagName(),
                                    attributes: attrs,
                                    children: children))
        
    default:
        return nil
    }
}

private func wrapChildren(of element: SwiftSoup.Element) throws -> MastoParseNode? {
    // Flatten an unsupported tag by lifting children one level up
    let converted = try element.getChildNodes().compactMap { try transform(node: $0) }
    return converted.count == 1 ? converted.first : .element(
        ElementNode(name: "span", attributes: [:], children: converted)
    )
}

private func filteredAttributes(from element: SwiftSoup.Element) -> [String:String] {
    guard let attributes = element.getAttributes(), let allowed = Allowed.attributes[element.tagName()] else { return [:] }
    
    return attributes.reduce(into: [String:String]()) { dict, attr in
        if allowed.contains(attr.getKey()) {
            dict[attr.getKey()] = attr.getValue()
        }
    }
}

private enum Allowed {
    
    static let elements: Set<String> = [
        "p","br","span","a","del","s","pre","blockquote","code","b","strong","u","i","em",
        "ul","ol","li","ruby","rt","rp"
    ]
    
    /// attributes per element
    static let attributes: [String: Set<String>] = [
        "a"   : ["href","rel","class","translate"],
        "span": ["class","translate"],
        "ol"  : ["start","reversed"],
        "li"  : ["value"],
        "p"   : ["class"],
    ]
}
