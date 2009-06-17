module RPXNow
  module UserIntegration
    def identifiers
      RPXNow.mappings(id)
    end

    def map_identifier(identifier)
      RPXNow.map(identifier, id)
    end

    def unmap_identifier(identifier)
      RPXNow.unmap(identifier, id)
    end
  end
end