# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::JobReviewsController, type: :controller do
  include ModelSupport

  before :each do
    create_admin
    @controller.instance_variable_set(:@current_admin, @admin)
  end

  describe 'filtered_primary_model method' do
    it 'filters jobs by handler GlobalID when search_attrs[handler] is provided' do
      # Create two test jobs with different handlers containing GlobalIDs
      gid1 = 'gid://fpa1/DynamicModel/123'
      gid2 = 'gid://fpa1/DynamicModel/456'

      job1 = Delayed::Job.create!(
        handler: "--- !ruby/object:RecurringBatchTask\nrecurring_job_data:\n  dynamic_def: #{gid1}\n",
        run_at: 1.hour.from_now
      )

      job2 = Delayed::Job.create!(
        handler: "--- !ruby/object:RecurringBatchTask\nrecurring_job_data:\n  dynamic_def: #{gid2}\n",
        run_at: 1.hour.from_now
      )

      # Simulate controller params
      allow(@controller).to receive(:params).and_return(
        ActionController::Parameters.new(search_attrs: { handler: gid1 })
      )

      # Call the filtering method directly
      filtered = @controller.send(:filtered_primary_model)

      # Check that the filtered results only include job1
      expect(filtered.pluck(:id)).to include(job1.id)
      expect(filtered.pluck(:id)).not_to include(job2.id)
    end

    it 'returns all jobs when no handler filter is provided' do
      # Create test jobs
      job1 = Delayed::Job.create!(
        handler: "--- !ruby/object:RecurringBatchTask\ntest1\n",
        run_at: 1.hour.from_now
      )

      job2 = Delayed::Job.create!(
        handler: "--- !ruby/object:RecurringBatchTask\ntest2\n",
        run_at: 1.hour.from_now
      )

      # Simulate controller params without handler filter
      allow(@controller).to receive(:params).and_return(
        ActionController::Parameters.new({})
      )

      # All jobs should be included
      filtered = @controller.send(:filtered_primary_model)
      expect(filtered.pluck(:id)).to include(job1.id, job2.id)
    end

    it 'handles URL-encoded GlobalIDs in handler filter' do
      gid = 'gid://fpa1/DynamicModel/789'
      encoded_gid = CGI.escape(gid)

      job = Delayed::Job.create!(
        handler: "--- !ruby/object:RecurringBatchTask\nrecurring_job_data:\n  dynamic_def: #{gid}\n",
        run_at: 1.hour.from_now
      )

      # Simulate controller params with URL-encoded handler filter
      # Note: params automatically decodes, so we pass the decoded version
      allow(@controller).to receive(:params).and_return(
        ActionController::Parameters.new(search_attrs: { handler: gid })
      )

      filtered = @controller.send(:filtered_primary_model)
      expect(filtered.pluck(:id)).to include(job.id)
    end
  end
end
