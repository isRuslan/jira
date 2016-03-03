require 'simple_config'
require 'jira'
require 'slop'
require './lib/issue'

opts = Slop.parse do |o|
  # Connection settings
  o.string '-u', '--username', 'username', default: SimpleConfig.jira.user
  o.string '-p', '--password', 'password', default: SimpleConfig.jira.pass
  o.string '--site', 'site', default: SimpleConfig.jira.site
  o.string '--context_path', 'context path', default: ''
  o.string '--release', 'release'

  o.bool '--dryrun', 'dont post comments to Jira', default: false

  o.on '--help', 'print the help' do
    puts o
    exit
  end
end

STDOUT.sync = true

options = { auth_type: :basic }.merge(opts.to_hash)
client = JIRA::Client.new(options)
release = client.Issue.find(opts[:release])
release.deploys.each do |issue|
  puts issue.key
  # Transition to Merge Ready
  issue.transition 'Not merged' if issue.has_transition? 'Not merged'
end