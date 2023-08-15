module Alexandria
  class EntitySerializer
    def initialize(presenter, actions)
      @presenter = presenter
      @entity = @presenter.object
      @actions = actions
    end

    def serialize
      @presenter.build(@actions)
    end

    def key
      @key ||= Digest::SHA1.hexdigest(build_key)
    end

    def cache?
      @presenter.class.cached?
    end

    private

    def build_key
      updated_at = @entity.updated_at.to_datetime
      cache_key = "model/#{@entity.class}/#{@entity.id}/#{updated_at}"

      cache_key << "/fields:#{@presenter.validated_fields}" if @presenter.validated_fields.present?

      cache_key << "/embeds:#{@presenter.validated_embeds}" if @presenter.validated_embeds.present?

      cache_key
    end
  end
end
