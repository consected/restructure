# frozen_string_literal: true

describe 'ActiveRecord::HasManyThroughOrderError' do
  describe '#has_many and has_one through' do
    Rails.application.eager_load!

    m = DynamicModel.active_model_configurations
    m.map(&:implementation_class).each do |ic|
      %i[has_one has_many].each do |association_kind|
        has_through_associations = ic.descendants.reject(&:abstract_class?).each_with_object({}) do |ar_class, result|
          has_through_associations = ar_class.reflect_on_all_associations(association_kind).select do |association|
            association.options.key? :through
          end
          result[ar_class] = has_through_associations.map(&:name) if has_through_associations.any?
        end
        has_through_associations.each do |ar_class, association_names|
          test_class = ar_class.new
          association_names.each do |association_name|
            context "loading #{ar_class}. #{association_name} should not raise an HasManyThroughOrderError" do
              it 'should be a success' do
                if association_kind == :has_one
                  expect { test_class.send(association_name.to_sym) }.not_to raise_error
                else
                  expect { test_class.send(association_name.to_sym).first }.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
