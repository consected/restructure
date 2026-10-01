# frozen_string_literal: true

# Save trigger that iterates over values and executes a nested trigger list for
# each value.
class SaveTriggers::Each < SaveTriggers::SaveTriggersBase
  DEFAULT_ITERATOR_NAME = 'iterator'

  def initialize(config, item)
    super

    @iterator_config = self.config
  end

  def perform
    values = iterator_values
    results = []

    values.each_with_index do |iterator_value, iterator_index|
      store_iterator_context(iterator_index, iterator_value)

      next unless if_evaluates(@iterator_config[:if])

      results << execute_trigger_list(@iterator_config[:do])
    end

    store_trigger_results('each', results)
    results
  end

  private

  def store_iterator_context(iterator_index, iterator_value)
    iterator_prefix = @iterator_config[:iterator_name].presence || DEFAULT_ITERATOR_NAME
    @item.save_trigger_results["#{iterator_prefix}_index"] = iterator_index
    @item.save_trigger_results["#{iterator_prefix}_value"] = iterator_value
  end

  def iterator_values
    values = if @iterator_config[:value]
               FieldDefaults.calculate_default(@item, @iterator_config[:value])
             else
               [nil]
             end

    raise FphsException, "No iterator values were found for save trigger each: #{@iterator_config}" unless values

    values.is_a?(Array) ? values : [values]
  end
end
