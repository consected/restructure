# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AccuracyScoresController, type: :controller do
  include AccuracyScoreSupport

  def object_class
    Classification::AccuracyScore
  end

  def item
    @accuracy_score
  end

  def edit_form_admin
    @edit_form_admin = 'admin/accuracy_scores/_form'
  end

  def saved_item_template
    'admin/accuracy_scores/_item'
  end

  before(:context) do
    @path_prefix = '/admin'

    Classification::AccuracyScore.where(value: (1001..1010)).update_all(disabled: true, value: -1000)
  end

  it_behaves_like 'a standard admin controller'
end
