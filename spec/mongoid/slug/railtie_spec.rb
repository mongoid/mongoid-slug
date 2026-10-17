# frozen_string_literal: true

require 'spec_helper'
require 'rake'
require 'rails/railtie'
require 'mongoid/slug/railtie'

describe Mongoid::Slug::Railtie do
  it 'registers the public slug setup task with Rails' do
    original = Rake.application
    begin
      Rake.application = Rake::Application.new
      described_class.instance.send(:run_tasks_blocks, described_class.instance)

      expect(Rake::Task.task_defined?('mongoid_slug:set')).to eq(true)
      expect(Rake::Task['mongoid_slug:set'].prerequisites).to include('environment')
    ensure
      Rake.application = original
    end
  end
end
