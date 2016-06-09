require 'spec_helper'
describe 'Create sandbox release' do
  before(:all) do
    @client = JIRA::Client.new SimpleConfig.jira.to_h
    @project = @client.Project.find('SNB')
    @release = @client.Issue.build
    @release_type = @client.Issuetype.all.find { |type| type.name == 'Release' }
    begin
      @release.save(fields: {
                      summary: 'SandBox release',
                      issuetype: {
                        id: @release_type.id,
                      },
                      project: {
                        id: @project.id,
                      },
                    })
    rescue JIRA::HTTPError => e
      raise "Fails on create release issue: #{e.response}"
    end
  end
  after(:all) do
    begin
      @release.delete
    rescue JIRA::HTTPError => e
      raise "Fails on delete release issue: #{e.response}"
    end
  end

  it 'create' do
  end
end
