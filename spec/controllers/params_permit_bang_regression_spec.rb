# frozen_string_literal: true

# Regression guard against re-introducing `params.permit!` in controller
# helper methods that materialise a plain Hash for search / SQL-binding
# or cache-key purposes.
#
# `permit!` mutates the underlying ActionController::Parameters object by
# setting `@permitted = true` recursively. Any downstream code in the same
# request reading `params[:x]` could then silently mass-assign to an
# ActiveRecord model, bypassing strong-parameters guardrails. The fix uses
# `to_unsafe_h`, which returns the same plain Hash without altering the
# params object's permitted state.
#
# These specs lock in that behaviour for:
#   - MastersController#search_params         (was permit!.to_h)
#   - MasterHandler#index_cache_key           (was permit!.to_h)
#   - ReportsController#set_search_attrs      (was permit!.to_h.except)
#   - ReportsController#search_attrs_params_hash
#   - Admin::ReportsController#search_attrs_params_hash

require 'rails_helper'
require 'ostruct'

RSpec.describe 'params.permit! regression guards' do
  # Build a controller instance with the given params hash, without going
  # through the routing/dispatch stack. Lets us call private methods and
  # inspect controller.params directly.
  def build_controller(controller_class, params_hash)
    instance = controller_class.new
    instance.request = ActionController::TestRequest.create(controller_class)
    instance.response = ActionDispatch::TestResponse.new
    instance.params = ActionController::Parameters.new(params_hash)
    instance
  end

  describe 'MastersController#search_params' do
    it 'returns a plain Hash without permitting the params object' do
      c = build_controller(MastersController,
                           master: { msid: 'abc' },
                           controller: 'masters',
                           action: 'index')

      result = c.send(:search_params)

      expect(result).to be_a(Hash)
      expect(result).not_to be_a(ActionController::Parameters)
      expect(c.params).not_to be_permitted
      expect(c.params[:master]).not_to be_permitted
    end
  end

  describe 'MasterHandler#index_cache_key (via PlayerInfosController)' do
    it 'builds the cache key digest without permitting the params object' do
      c = build_controller(PlayerInfosController, master_id: '1', controller: 'player_infos', action: 'index')
      c.instance_variable_set(:@master_objects, [])
      allow(c).to receive(:current_user).and_return(nil)

      digest = c.send(:index_cache_key)

      expect(digest).to be_a(String)
      expect(digest.length).to eq(64)
      expect(c.params).not_to be_permitted
    end
  end

  describe 'ReportsController#search_attrs_params_hash' do
    it 'returns a plain Hash without permitting the params object' do
      c = build_controller(ReportsController, search_attrs: { foo: 'bar', baz: 'qux' })
      c.instance_variable_set(:@runner, OpenStruct.new)

      result = c.send(:search_attrs_params_hash)

      expect(result).to eq('foo' => 'bar', 'baz' => 'qux')
      expect(result).not_to be_a(ActionController::Parameters)
      expect(c.params).not_to be_permitted
      expect(c.params[:search_attrs]).not_to be_permitted
    end
  end

  describe 'ReportsController#set_search_attrs' do
    it 'writes a plain Hash into params[:search_attrs] without permitting the params object' do
      c = build_controller(ReportsController,
                           foo: 'bar',
                           controller: 'reports',
                           action: 'show')
      report_options = OpenStruct.new(view_options: OpenStruct.new(use_plain_attribute_names: true))
      c.instance_variable_set(:@report, OpenStruct.new(report_options: report_options))

      c.send(:set_search_attrs)

      # set_search_attrs writes a plain Hash; ActionController::Parameters wraps
      # it back into a Parameters object on assignment, but the key guarantee is
      # that the params object as a whole is still not marked permitted.
      # Use to_unsafe_h because the wrapper remains unpermitted (which is what
      # we want — proving the fix), so .to_h would raise UnfilteredParameters.
      expect(c.params[:search_attrs].to_unsafe_h).to include('foo' => 'bar')
      expect(c.params).not_to be_permitted
      expect(c.params[:search_attrs]).not_to be_permitted
    end
  end

  describe 'Admin::ReportsController#search_attrs_params_hash' do
    it 'returns a plain Hash without permitting the params object' do
      c = build_controller(Admin::ReportsController, search_attrs: { foo: 'bar' })

      result = c.send(:search_attrs_params_hash)

      expect(result).to eq('foo' => 'bar')
      expect(result).not_to be_a(ActionController::Parameters)
      expect(c.params).not_to be_permitted
      expect(c.params[:search_attrs]).not_to be_permitted
    end
  end
end
