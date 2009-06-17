module RPXNow
  class UserProxy
    def initialize(id)
      @id = id
    end

    def identifiers
      RPXNow.mappings(@id)
    end

    def map(identifier)
      RPXNow.map(identifier, @id)
    end

    def unmap(identifier)
      RPXNow.unmap(identifier, @id)
    end
  end
end