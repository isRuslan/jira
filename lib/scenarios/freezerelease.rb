module Scenarios
  ##
  # FreezeRelease scenario
  class FreezeRelease
    def with(instance, &block)
      instance.instance_eval(&block)
      instance
    end

    def run
      puts "Starting freeze_release for #{SimpleConfig.jira.issue}".green
      jira = JIRA::Client.new SimpleConfig.jira.to_h
      issue = jira.Issue.find(SimpleConfig.jira.issue)

      issue.related['branches'].each do |branch|
        unless branch['name'].match "^#{SimpleConfig.jira.issue}-pre"
          puts "Incorrect branch #{branch['name']} name".red
          next
        end
        today = Time.new.strftime('%d.%m.%Y')
        old_branch = branch['name']
        new_branch = "#{SimpleConfig.jira.issue}-release-#{today}"

        repo_path = git_repo(branch['repository']['url'])

        # copy -pre to -release
        puts "Working with #{repo_path.remote.url.repo}".green
        repo_path.fetch
        unless repo_path.is_branch? old_branch
          puts "Branch #{old_branch} doesn't exists".red
          next
        end

        puts "Copying #{old_branch} to #{new_branch} branch".green
        cur_branch = repo_path.current_branch
        with repo_path do
          checkout(old_branch)
          pull
          branch(new_branch).delete if is_branch?(new_branch)
          branch(new_branch).create
          checkout cur_branch
        end

        puts "Pushing #{new_branch} and deleting #{old_branch} branch".green
        with repo_path do
          push(repo_path.remote('origin'), new_branch) # push -release to origin
          branch(old_branch).delete_both if old_branch != 'master' # delete -pre from local/remote
          puts "Creating PR from #{new_branch} to #{cur_branch}".green
          create_pullrequest SimpleConfig.bitbucket.to_h.merge(src: new_branch)
        end
      end
    end
  end
end
