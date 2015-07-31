require "rails_helper"

RSpec.describe AccuracyScoresController, type: :routing do
  let(:object_name) { 'accuracy_scores' }
  let(:object_path) { '/accuracy_scores'}
  let(:parent_params) { {} }
  
  it_behaves_like 'a standard admin routing'
end
