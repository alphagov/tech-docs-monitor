require_relative './lib/notifier'
require 'chronic'
require 'fileutils'
require 'yaml'

task default: ["notify:expired"]

namespace :notify do
  pages_urls = [
    "https://www.docs.verify.service.gov.uk/api/pages.json",
    "https://gds-way.cloudapps.digital/api/pages.json",
    "https://verify-team-manual.cloudapps.digital/api/pages.json",
    "https://docs.payments.service.gov.uk/api/pages.json",
    "https://govwifi-dev-docs.cloudapps.digital/api/pages.json",
  ]

  limits = {
  }

  live = ENV.fetch("REALLY_POST_TO_SLACK", 0) == "1"
  slack_url = ENV["SLACK_WEBHOOK_URL"]
  slack_token = ENV["SLACK_TOKEN"]

  if live && (!slack_url && !slack_token) then
    fail "If you want to post to Slack you need to set SLACK_TOKEN or SLACK_WEBHOOK_URL"
  end

  desc "Notifies of all pages which have expired"
  task :expired do
    slack_url = ENV.fetch("SLACK_WEBHOOK_URL")
    notification = Notification::Expired.new

    pages_urls.each do |page_url|
      puts "== #{page_url}"

      Notifier.new(notification, page_url, slack_url, live, limits.fetch(page_url, -1)).run
    end
  end

  desc "Notifies of all pages which will expire soon"
  task :expires, :timeframe do |_, args|
    slack_url = ENV.fetch("SLACK_WEBHOOK_URL")
    args.with_defaults(timeframe: "in 1 month")
    expire_by = Chronic.parse(args[:timeframe]).to_date
    notification = Notification::WillExpireBy.new(expire_by)

    pages_urls.each do |page_url|
      puts "== #{page_url}"

      Notifier.new(notification, page_url, slack_url, live).run
    end
  end
end

namespace "lambda" do
  desc "Builds an AWS Lambda Distribution"
  task :build do
    begin
      # AWS SAM CLI mounts the 'lib' folder, which it views as the Lambda's root directory,
      # as a Volume inside the Docker container which builds the Lambda function.
      # In order to install all the necessary dependencies it requires certain files
      # to be copied in to this directory.
      # In order not to pollute the repository we copy them, run the build and
      # then delete the copies afterwards.
      files_to_copy = %w[Gemfile Gemfile.lock .ruby-version]
      files_to_copy.each { | f | FileUtils.copy(File.join(__dir__, f), "lib/#{f}") }
      Dir.chdir('lib') do
        sh "SAM_CLI_TELEMETRY=0 sam build --use-container -t ../resources/aws-sam-cli/template.yaml --debug"
      end
    ensure
      files_to_copy.each { | f | FileUtils.rm"lib/#{f}" }
    end
  end

  desc "Runs the Lambda function locally"
  task :local, [:event_file, :aws_region] do | _, args |
    args.with_defaults(:aws_region => "eu-west-2")

    if args[:event_file].nil?
      fail "Error: :event_file task parameter not provided.\nUsage: bundle exec rake lambda:local\\[path-to-event-file.json\\]"
    end

    event_file_absolute_path = File.join __dir__, args[:event_file]
    begin
      Dir.chdir('lib') do
        sh "SAM_CLI_TELEMETRY=0 sam local invoke --event #{event_file_absolute_path} --region=#{args[:aws_region]}"
      end
    ensure
    end
  end

  desc "Publish the Lambda artefact to an S3 Bucket."
  task :publish, [:version, :s3_bucket, :s3_prefix, :aws_region] => [:build] do | _, args |
    args.with_defaults(:aws_region => "eu-west-2")

    build_directory_name = "build"
    build_directory_absolute_path = File.join __dir__, build_directory_name
    FileUtils.mkdir_p build_directory_name

    output_file_name = "tech-docs-monitor-template.yaml"
    output_file_absolute_path = File.join build_directory_absolute_path, output_file_name
    Dir.chdir('lib') do
      sh %{
        SAM_CLI_TELEMETRY=0 sam package --region #{args[:aws_region]} \\
          --s3-bucket '#{args[:s3_bucket]}' \\
          --s3-prefix '#{args[:s3_prefix]}' \\
          --output-template-file='#{output_file_absolute_path}'
      }
    end
    aws_sam_s3_file_name = YAML.load_file(output_file_absolute_path)["Resources"]["TechDocsNotifier"]["Properties"]["Code"]["S3Key"].split('/')[-1]
    puts "SAM CLI has published the Lambda artefact as #{aws_sam_s3_file_name}"

    versioned_lambda_file_name = "aws-lambda-tech-docs-monitor.#{args[:version]}.zip"
    versioned_lambda_hash_file_name = "#{versioned_lambda_file_name}.base64sha256"

    lambda_artefact_object_key = "s3://#{args[:s3_bucket]}/#{args[:s3_prefix]}/#{versioned_lambda_file_name}"
    sh %{
      aws s3 cp s3://#{args[:s3_bucket]}/#{args[:s3_prefix]}/#{aws_sam_s3_file_name} \\
        #{lambda_artefact_object_key} \\
        --acl=bucket-owner-full-control
    }
    puts "Renamed Lambda artefact to: #{lambda_artefact_object_key}"

    # Calculate and upload a hash file for the Lambda artefact.
    sh "aws s3 cp '#{lambda_artefact_object_key}' '#{File.join build_directory_absolute_path, versioned_lambda_file_name}'"
    sh "openssl dgst -sha256 -binary 'build/#{versioned_lambda_file_name}' | openssl enc -base64 > '#{File.join build_directory_absolute_path, versioned_lambda_hash_file_name}'"
    sh "aws s3 cp --content-type text/plain '#{File.join build_directory_absolute_path, versioned_lambda_hash_file_name}' 's3://#{args[:s3_bucket]}/#{args[:s3_prefix]}/#{versioned_lambda_hash_file_name}' --acl=bucket-owner-full-control"

    # Delete the inconveniently named file which was uploaded by AWS SAM CLI,
    sh "aws s3 rm s3://#{args[:s3_bucket]}/#{args[:s3_prefix]}/#{aws_sam_s3_file_name}"
    File.delete "build/#{versioned_lambda_file_name}"
  end
end
