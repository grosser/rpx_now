module RPXNow
  module UserIntegration
    def rpx
      RPXNow::UserProxy.new(id)
    end
  end
end