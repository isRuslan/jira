require 'spec_helper'
describe JIRA::PullRequest do
  def create_test_object!(data)
    git_double = double(:git_double).as_null_object
    allow(Git).to receive(:get_branch) { git_double }
    allow(git_double.gtree.diff.stats).to receive(:keys) do
      %w(file1 file2 file3)
    end
    allow(git_double).to receive(:get_attrs).with('file1').and_return(Hash('reviewer.mail' => ['name1']))
    allow(git_double).to receive(:get_attrs).with('file2').and_return(Hash('reviewer.mail' => %w(name1 name2)))
    allow(git_double).to receive(:get_attrs).with('file3').and_return(Hash.new([]))

    allow(git_double).to receive(:fetch)
    allow(git_double).to receive(:merge)

    config_git = { reviewer: 'Reviewer',
                   reviewer_key: 'reviewer.mail',
                   workdir: './workdir' }
    described_class.new config_git, data
  end

  before :each do
    data =
      { 'source' => { 'url' => 'https://bb.org/org/repo/branch/OTT-0003' },
        'destination' => { 'url' => 'https://bb.org/org/repo/branch/master' },
        'author' => { 'name' => 'Andrew Ivanov' },
        'status' => 'CANCEL',
        'url' => 'https://jira.com/issueurl',
        'name' => 'ISSUE-ID' }
    @pr = create_test_object! data
  end

  it '.new returns false with invalid input' do
    data =
      { 'source' => { 'url' => 'https://bb.org/org/repo_one/branch/OTT-0004' },
        'destination' => { 'url' => 'https://bb.org/org/repo_two/branch/master' } }
    @pr = create_test_object! data
    expect(@pr).to be_empty
  end

  it '.src and .dst return URI::Git::Generic' do
    expect(@pr.src.class).to eq(URI::Git::Generic)
    expect(@pr.dst.class).to eq(URI::Git::Generic)
  end

  it '.get_reviewers parse git attrs' do
    expect(@pr.reviewers).to eq %w(name1 name2)
    expect(@pr.changed_files).to eq %w(file1 file2)
  end

  it '.message returns erb message' do
    @pr.send_notify do |msg|
      expect(msg).to include 'https://jira.com/issueurl'
    end
    allow(@pr).to receive(:changed_files) { %w(file1 .gitattributes) }
    @pr.send_notify do |msg|
      expect(msg).to include '.gitattributes'
    end
  end
end