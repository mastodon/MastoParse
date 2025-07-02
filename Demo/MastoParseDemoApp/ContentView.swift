//
//  ContentView.swift
//  MastoParseDemoApp
//
//  Created by Shannon Hughes on 7/2/25.
//

import SwiftUI
import MastoParse

struct DisplayExample: Identifiable {
    let id: Int
    let displayBlocks: [MastoParseContentBlock]
}

@MainActor
let displayExamples: [ DisplayExample ] = {
    examples.enumerated().map { (idx, html) in
        do {
            let blocks = try getParseBlocks(from: html)
            return DisplayExample(id: idx, displayBlocks: blocks)
        } catch {
            let errorItem = MastoParseInlineElement(type: .text, contents: "ERROR: \(error)")
            let block = MastoParseContentRow(contents: [errorItem], style: .paragraph, nestedFormatting: [])
            return DisplayExample(id: idx, displayBlocks: [block])
        }
    }
}()

struct DemoView: View {
    
    @State var emoji: Image?
    static let font: Font.TextStyle = .body // customize this to the font style you wish to use
    @ScaledMetric(relativeTo: font) private var emojiSize: CGFloat = 25
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(displayExamples) { html in
                    VStack(alignment: .leading) {
                        ForEach(html.displayBlocks) { block in
                            if let blockquote = block as? MastoParseBlockquote {
                                BlockquoteView(block: blockquote)
                            } else if let row = block as? MastoParseContentRow {
                                RowView(row: row)
                            } else {
                                Text("CASE NOT HANDLED")
                            }
                        }
                    }
                    .onTapGesture {
                        print("tapped!!!")
                    }
                    Rectangle()
                        .fill(.gray)
                        .frame(width: 300, height: 1)
                }
            }
        }
        .padding()
    }
}

let indent: CGFloat = 16
let nestedBlockQuoteIndicatorWidth: CGFloat = 2
let indicatorToBlockQuoteSpacing: CGFloat = 4

let blockquoteColor = Color.purple.opacity(0.5)
struct BlockquoteView: View {
    let block: MastoParseBlockquote
    
    var body: some View {
        HStack {
            VStack {
                Image(systemName: "quote.opening")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(blockquoteColor)
                
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(block.contents.enumerated()), id: \.offset) { idx, element in
                    RowView(row: element)
                }
            }
        }
    }
}

enum TextElement {
    case image(Image)
    case text(LocalizedStringKey)
    case code(String)
}

struct RowView: View {
    static let font: Font.TextStyle = .body
    @ScaledMetric(relativeTo: font) private var imgBaseline: CGFloat = -5 // without this, the custom emoji sit too high amidst the surrounding text
    
    let row: MastoParseContentRow
    
    var body: some View {
        let totalFormattingSpaceRequired = row.nestedFormatting.reduce(into: CGFloat.zero) { partialResult, format in
            switch format {
            case .listLevel:
                partialResult += indent
            case .subordinateBlockquote:
                partialResult += nestedBlockQuoteIndicatorWidth + indicatorToBlockQuoteSpacing
            case .topLevelBlockquote:
                break
            }
        }
        
        combineElements(row.contents.map({ element in
            switch element.type {
            case .text:
                return .text(LocalizedStringKey(element.contents))
            case .code:
                return .code(element.contents)
            }
            
        }))
        .padding(EdgeInsets(top: 0, leading: totalFormattingSpaceRequired, bottom: 0, trailing: 0))
        .background() {
            // Putting the nested blockquote bar in a background correctly expands its height to match the contents of the row. Trying to include it in the same HStack as the content leaves the bar too short.
            HStack(spacing: 0) {
                ForEach(Array(row.nestedFormatting.enumerated()), id: \.offset) { idx, indicator in
                    switch indicator {
                    case .topLevelBlockquote:
                        EmptyView()
                    case .subordinateBlockquote:
                        blockquoteColor
                            .frame(width: nestedBlockQuoteIndicatorWidth)
                        Spacer()
                            .frame(maxWidth: indicatorToBlockQuoteSpacing)
                    case .listLevel:
                        Spacer()
                            .frame(width: indent)
                    }
                }
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder func combineElements(_ elements: [TextElement]) -> some View {
        let pieces = elements.map { element in
            switch element {
            case .image(let image):
                return Text("\(image)").baselineOffset(imgBaseline)
            case .text(let text):
                return Text(text)
            case .code(let text):
                var attributed = AttributedString(text)
                attributed.backgroundColor = blockquoteColor
                attributed.font = .system(.body, design: .monospaced)
                return Text(attributed)
            }
        }
        pieces.reduce(Text(""), +)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    DemoView()
}

