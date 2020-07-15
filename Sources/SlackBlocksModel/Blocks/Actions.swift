//
//  Actions.swift
//  SlackBlocksModel
//
//  Created by Helge Heß.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import struct Foundation.URL

public extension Block {
  
  struct Actions: Encodable {

    public static let validInSurfaces : [ BlockSurfaceSet ]
                                      = [ .modals, .messages, .homeTabs ]

    public var id       : BlockID
    public var elements : [ InteractiveElement ]
    
    public init(id: BlockID, elements: [ InteractiveElement ]) {
      self.id       = id
      self.elements = elements
    }
    
    // MARK: - Encoding
    
    enum CodingKeys: String, CodingKey {
      case id = "block_id"
      case type, elements
    }
      
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode("actions", forKey: .type)
      try container.encode(id,        forKey: .id)
      try container.encode(elements,  forKey: .elements)
    }
  }
}

public extension Block.Actions {
  
  @inlinable
  var blocksMarkdownString : String {
    return "[actions cannot be shown by this client]"
  }
}
