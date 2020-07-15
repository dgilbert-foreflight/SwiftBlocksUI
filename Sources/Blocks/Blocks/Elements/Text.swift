//
//  Text.swift
//  Blocks
//
//  Created by Helge Heß.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import class Foundation.Formatter
import class Foundation.Bundle
import enum  SlackBlocksModel.Block

/**
 * Allow a String, directly inline. I think that makes sense for
 * a messages based framework.
 */
extension String: Blocks {
  
  public var body: Text { // TBD: we might want to do markdown?
    return Text(self)
  }
}

public struct Text: Equatable {
  
  @inlinable
  public init(verbatim content: String) {
    self.runs = [ .verbatim(content) ]
  }
  @inlinable
  public init<S>(_ content: S) where S : StringProtocol {
    self.init(verbatim: String(content))
  }

  @inlinable
  public init(_     key : LocalizedStringKey,
              tableName : String? = nil, bundle: Bundle? = nil,
              comment   : StaticString? = nil)
  {
    let s = (bundle ?? .main)
            .localizedString(forKey: key.value, value: key.value,
                             table: tableName)
    self.init(verbatim: s)
  }
  
  @inlinable
  public init(_ value: Any?, formatter: Formatter) {
    // TBD: we could support attributed strings!
    #if os(Linux)
      self.init(verbatim: formatter.string(for: value as Any) ?? "??")
    #else
      self.init(verbatim: formatter.string(for: value) ?? "??")
    #endif
  }
  
  private init(runs: [ Run ]) {
    self.runs = runs
  }
  
  @usableFromInline let runs : [ Run ]
  
  @usableFromInline
  enum Run : Equatable, CustomStringConvertible {
    // TODO: Add LocalizedString variants
    case verbatim(String)
    case styled(String, Modifier)

    init(content: String, modifiers: Modifier) {
      if modifiers.isEmpty { self = .verbatim(content) }
      else                 { self = .styled(content, modifiers) }
    }

    var contentString : String {
      switch self {
        case .verbatim(let s):  return s
        case .styled(let s, _): return s
      }
    }
    var isStyled : Bool {
      switch self {
        case .verbatim:  return false
        case .styled(_, let modifier): return !modifier.isEmpty
      }
    }
    
    @usableFromInline
    var description: String {
      switch self {
        case .verbatim(let s): return "Run('\(s)')"
        case .styled(let s, let modifiers):
          return "Run<\(modifiers)>('\(s)')"
      }
    }
  }
  
  var contentString : String {
    return runs.map({ $0.contentString }).joined()
  }
  
  var isStyled : Bool {
    return runs.firstIndex(where: { $0.isStyled }) != nil
  }
  
  @usableFromInline
  typealias Modifier = Block.RichTextElement.Run.FontStyle
  
  // TODO: +(lhs,rhs): smart addition of Text w/ runs
  
  static func +(lhs: Text, rhs: Text) -> Text {
    // FIXME: Make smarter, combine runs
    return Text(runs: lhs.runs + rhs.runs)
  }
  static func +(lhs: Text, rhs: String) -> Text {
    return Text(runs: lhs.runs + [ .verbatim(rhs) ])
  }
}

extension Text: Blocks {
  public typealias Body = Never
}

public extension Text {
  
  private func adding(_ modifier: Modifier) -> Text {
    return Text(runs: runs.map { run in
      switch run {
        case .verbatim(let s):
          return Run(content: s, modifiers: [ modifier ])
        
        case .styled(let s, let modifiers):
          if modifiers.contains(modifier) { return run }
          return Run(content: s, modifiers: modifiers.union(modifier))
      }
    })
  }
  func bold()   -> Text { return adding(.bold)   }
  func italic() -> Text { return adding(.italic) }
  func code()   -> Text { return adding(.code)   }
  func strike() -> Text { return adding(.strike) }
}


extension Text.Run {
  
  var slackMarkdownString: String {
    switch self {
      case .verbatim(let s):
        return s
      
      case .styled(let s, let modifiers):
        guard !modifiers.isEmpty, !s.isEmpty else { return s }
        return modifiers.markdownStyle(s)
    }
  }
}
public extension Text {
  
  var slackMarkdownString: String {
    return runs.map { $0.slackMarkdownString }.joined()
  }
}

public struct LocalizedStringKey: Equatable, ExpressibleByStringInterpolation {

  @usableFromInline let value : String
  
  @inlinable
  public init(_ value: String) {
    self.value = value
  }
  @inlinable
  public init(stringLiteral value: String) {
    self.value = value
  }
  
  // support the interpolation stuff
}
