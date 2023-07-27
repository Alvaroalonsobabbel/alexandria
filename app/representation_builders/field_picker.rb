class FieldPicker
  def initialize(presenter)
    @presenter = presenter
    @fields = @presenter.params[:fields]
  end

  def pick
    (validate_fields || pickable).each do |field|
      value = (if @presenter.respond_to?(field)
                 @presenter
               else
                 @presenter.object
               end).send(field)
      @presenter.data[field] = value
    end

    @presenter
  end

  private

  def validate_fields
    return nil if @fields.blank?

    validated = @fields.split(',').reject { |f| !pickable.include?(f) }
    validated.any? ? validated : nil
  end

  def pickable
    @pickable ||= @presenter.class.build_attributes
  end
end
