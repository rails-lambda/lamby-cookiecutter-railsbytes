# RailsBytes Template: Configure Rails for Lamby (AWS Lambda)
#
# References:
# - PRD: ./docs/PRD.md
# - Tasks: ./docs/TASKS.md
# - Lamby: https://lamby.cloud/
# - Rails Application Templates: https://guides.rubyonrails.org/rails_application_templates.html

say "Welcome to the Lamby App Configurator!", :cyan
say "This template will configure your new Rails application for AWS Lambda deployment with Lamby,"
say "and structure it similarly to the 'my_awesome_lambda' project.", :cyan
puts "-" * 60

# --- Database Selection ---
say "Database Configuration:", :green
say "The 'my_awesome_lambda' project (our source of truth) uses MySQL."
say "For consistency, MySQL is recommended."

db_choices = {
  '1' => { name: 'MySQL', value: 'mysql', gem_name: 'mysql2', gem_version: '~> 0.5' },
  '2' => { name: 'PostgreSQL', value: 'postgresql', gem_name: 'pg', gem_version: nil }, # version handled by rails new
  '3' => { name: 'SQLite3', value: 'sqlite3', gem_name: 'sqlite3', gem_version: '~> 1.4' } # or let rails new handle
}

db_prompt = "Choose a database option:\n"
db_choices.each { |key, db| db_prompt += "  #{key}) #{db[:name]}\n" }
db_prompt += "Enter number (1-3) [default: 1 for MySQL]: "

db_selection_key = ask(db_prompt).strip
db_selection_key = '1' if db_selection_key.empty? # Default to MySQL

selected_db_config = db_choices[db_selection_key]

until selected_db_config
  say "Invalid selection. Please choose a number from 1 to 3.", :red
  db_selection_key = ask(db_prompt).strip
  db_selection_key = '1' if db_selection_key.empty?
  selected_db_config = db_choices[db_selection_key]
end

say "You selected: #{selected_db_config[:name]}", :yellow

# Add the selected database gem
if selected_db_config[:gem_version]
  gem selected_db_config[:gem_name], selected_db_config[:gem_version]
else
  gem selected_db_config[:gem_name]
end
say "Added #{selected_db_config[:gem_name]} to Gemfile."

# Note: The `rails new` command might have already added a database gem
# based on its own `-d` flag if the user provided it. 
# Bundler should resolve this, but it's ideal if the user omits `-d` 
# when using this interactive template for database selection.
# If this template is the sole source of DB gem, then this is fine.

puts "-" * 60

# --- Template Steps --- 

say "Adding Lamby gem..."
gem 'lamby'

# Add gems from my_awesome_lambda
gem "importmap-rails"
gem "sprockets-rails"
gem "stimulus-rails"
gem "turbo-rails"
gem "jbuilder"

gem_group :development, :test do
  gem "debug"
  gem "webrick"
end

gem_group :development do
  gem "web-console"
end

gem_group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

gem_group :production do
  gem 'lograge' # Moved from global
end

say "Lamby and other specified gems have been added to the Gemfile."
say "They will be installed by Bundler when the 'rails new' process completes."

# --- Configure Lamby --- 

say "Configuring Lamby in Rails application..."

# Add commented-out lines from lamby-cookiecutter for review
production_config_comments = <<-'RUBY'

  # Recommended additions from lamby-cookiecutter (commented out for review):
  #
  # Configure headers for files served from public/ (useful for Cache-Control)
  # config.public_file_server.headers = {
  #   'Cache-Control' => "public, max-age=#{30.days.seconds.to_i}",
  #   'X-Lamby-Base64' => '1' # Optional: Hint for Lamby base64 encoding
  # }
  #
  # Enable Lograge for structured JSON logging
  # config.lograge.enabled = true
  # config.lograge.formatter = Lograge::Formatters::Json.new
  #
  # Optional: Add custom payload to Lograge logs
  # config.lograge.custom_payload do |controller|
  #   {
  #     request_id: controller.request.request_id,
  #     # Add other fields like user_id: controller.current_user&.id
  #   }
  # end
RUBY

insert_into_file 'config/environments/production.rb', production_config_comments, before: /^end/, force: false
say "Adding commented-out config suggestions to config/environments/production.rb"

# 3. Create/Overwrite config.ru
say "Creating/Overwriting config.ru (for Lamby Rack handler)"
create_file 'config.ru', force: true do <<-RUBY
# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
Rails.application.load_server
RUBY
end

# 4. Ensure CSRF Protection in ApplicationController
say "Checking app/controllers/application_controller.rb (ensure protect_from_forgery)"
app_controller_path = 'app/controllers/application_controller.rb'
csrf_protection_code = "protect_from_forgery with: :exception"

if File.exist?(app_controller_path)
  unless File.read(app_controller_path).include?(csrf_protection_code)
    insert_into_file app_controller_path, "  #{csrf_protection_code}\n", after: "class ApplicationController < ActionController::Base\n"
    say "Injected: #{csrf_protection_code}"
  else
    say "Skipped: #{csrf_protection_code} already present."
  end
else
  say "Warning: #{app_controller_path} not found, skipping CSRF check."
end

say "Lamby configuration applied."

# --- Create Standard Project Files ---

say "Creating/Overwriting standard project files..."

create_file '.gitattributes', force: true do <<-'TEXT'
# See https://git-scm.com/docs/gitattributes for more about git attribute files.

# Mark the database schema as having been generated.
db/schema.rb linguist-generated

# Mark any vendored files as having been vendored.
vendor/* linguist-vendored
config/credentials/*.yml.enc diff=rails_credentials
config/credentials.yml.enc diff=rails_credentials
TEXT
end
say "Created .gitattributes"

create_file '.rubocop.yml', force: true do <<-'YAML'
# Omakase Ruby styling for Rails
inherit_gem: { rubocop-rails-omakase: rubocop.yml }

# Overwrite or add rules to create your own house style
#
# # Use `[a, [b, c]]` not `[ a, [ b, c ] ]`
# Layout/SpaceInsideArrayLiteralBrackets:
#   Enabled: false
YAML
end
say "Created .rubocop.yml"

create_file '.gitignore', force: true do <<-'IGNORE'
# See https://help.github.com/articles/ignoring-files for more about ignoring files.
#
# Temporary files generated by your text editor or operating system
# belong in git\\'s global ignore instead:
# `$XDG_CONFIG_HOME/git/ignore` or `~/.config/git/ignore`

# Ignore bundler config.
/.bundle

# Ignore all environment files (except templates).
/.env*
!/.env*.erb

# Ignore all logfiles and tempfiles.
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep

# Ignore pidfiles, but keep the directory.
/tmp/pids/*
!/tmp/pids/
!/tmp/pids/.keep

# Ignore storage (uploaded files in development and any SQLite databases).
/storage/*
!/storage/.keep
/tmp/storage/*
!/tmp/storage/
!/tmp/storage/.keep

/public/assets

# Ignore master key for decrypting credentials and more.
/config/master.key

# Lamby
/.aws-sam
.env.*
!.env.development
!.env.test
/vendor/bundle
.ruby-version
IGNORE
end
say "Overwrote .gitignore"

create_file 'Rakefile', force: true do <<-'RUBY'
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks
RUBY
end
say "Overwrote Rakefile"

empty_directory '.circleci'
say "Created .circleci directory"
empty_directory '.devcontainer'
say "Created .devcontainer directory"

# Create .circleci/config.yml
create_file '.circleci/config.yml', force: true do <<-'YAML'
default-machine: &default-machine
  machine:
    image: ubuntu-2204:current
    docker_layer_caching: true
  resource_class: arm.large
version: 2.1
parameters:
  workflow:
    type: enum
    default: test
    description: The workflow to trigger.
    enum: [test, deploy]
commands:
  devcontainer-install:
    steps:
      - run: npm install -g @devcontainers/cli
  devcontainer-build:
    steps:
      - run: devcontainer build --workspace-folder .
  devcontainer-up:
    steps:
      - run: devcontainer up --workspace-folder .
      - run: devcontainer run-user-commands --workspace-folder .
  devcontainer-run:
    parameters:
      cmd: { type: string }
      args: { type: string, default: "" }
      options: { type: string, default: "" }
    steps:
      - run: >
          devcontainer exec \
          --workspace-folder . \
          << parameters.options >> \
          << parameters.cmd >> \
          << parameters.args >>
jobs:
  devcontainer:
    <<: *default-machine
    steps:
      - checkout
      - devcontainer-install
      - devcontainer-build
  test-job:
    <<: *default-machine
    steps:
      - checkout
      - devcontainer-install
      - devcontainer-up
      - devcontainer-run: { cmd: ./bin/setup }
      - devcontainer-run: { cmd: ./bin/test }
  deploy-job:
    <<: *default-machine
    steps:
      - checkout
      - devcontainer-install
      - devcontainer-up
      - devcontainer-run:
          options: >-
            --remote-env AWS_REGION=us-east-1\
            --remote-env AWS_DEFAULT_REGION=us-east-1\
            --remote-env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID\
            --remote-env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
          cmd: ./bin/deploy
workflows:
  test:
    when: { equal: [ test, << pipeline.parameters.workflow >> ] }
    jobs:
      - devcontainer
      - test-job:
          requires: [devcontainer]
  deploy:
    when: { equal: [ deploy, << pipeline.parameters.workflow >> ] }
    jobs:
      - devcontainer
      - deploy-job:
          requires: [devcontainer]
YAML
end
say "Created .circleci/config.yml"

# Create .devcontainer files
create_file '.devcontainer/devcontainer.json', force: true do <<-'JSON'
{
  "service": "app",
  "dockerComposeFile": "docker-compose.yml",
  "features": {
    "ghcr.io/devcontainers/features/common-utils": {},
    "ghcr.io/devcontainers/features/node:latest": {},
    "ghcr.io/devcontainers/features/aws-cli:latest": {},
    "ghcr.io/devcontainers/features/docker-in-docker:latest": {},
    "ghcr.io/devcontainers/features/sshd:latest": {}
  },
  "remoteUser": "vscode",
  "remoteEnv": {
    "COMPOSE_HTTP_TIMEOUT": "300"
  },
  "workspaceFolder": "/workspaces/my_awesome_lambda",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/my_awesome_lambda,type=bind,consistency=cached",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspaces/my_awesome_lambda,type=bind,consistency=cached"
  ]
}
JSON
end
say "Created .devcontainer/devcontainer.json"

create_file '.devcontainer/Dockerfile', force: true do <<-'DOCKER'
# Shared image, envs, packages for both devcontainer & prod.
FROM ruby:3.2-bullseye
RUN apt update

# Temporary multi-platform SAM CLI install method.
# https://github.com/aws/aws-sam-cli/issues/3908
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1
RUN apt-get install -y pip && pip install aws-sam-cli

# Local devcontainer Codespaces compatibility.
RUN mkdir -p /workspaces/my_awesome_lambda
ENV BUNDLE_IGNORE_CONFIG=1
ENV BUNDLE_PATH=./vendor/bundle
ENV BUNDLE_CACHE_PATH=./vendor/cache
DOCKER
end
say "Created .devcontainer/Dockerfile"

create_file '.devcontainer/docker-compose.yml', force: true do <<-'YAML'
services:
  app:
    build: { context: ., dockerfile: Dockerfile }
    command: sleep infinity
    privileged: true
    environment:
      - MYSQL_HOST=mysql
      - MYSQL_ROOT_PASSWORD=root
    depends_on:
      mysql: { condition: service_healthy }
  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root
    volumes: ["data-mysql:/var/lib/mysql"]
    healthcheck:
      test: ["CMD", "mysql", "-h", "127.0.0.1", "-u", "root", "-proot"]
volumes:
  data-mysql:
YAML
end
say "Created .devcontainer/docker-compose.yml"

# --- Create Dummy Secret Key Base Initializer --- 
# !!! SECURITY WARNING !!!
# The following initializer sets a DUMMY secret_key_base and disables Rails encrypted credentials.
# This is NOT secure for production. It might be included for compatibility or specific build steps,
# but ensure a REAL, SECURE SECRET_KEY_BASE is provided via environment variables
# (e.g., through SSM/Secrets Manager in template.yaml/bin/deploy) for any real deployment.
# Failure to do so will leave your application vulnerable.
say "!!! WARNING !!! Creating dummy config/initializers/secret_key_base.rb - review security implications!"
create_file 'config/initializers/secret_key_base.rb' do <<-'RUBY'
# !!! SECURITY WARNING !!!
# This file provides a DUMMY secret_key_base for environments where one might not be otherwise available (like certain build stages).
# It also disables Rails encrypted credentials. DO NOT rely on this for production security.
# Ensure a proper, secure SECRET_KEY_BASE environment variable is set for your actual deployments.

ENV['SECRET_KEY_BASE'] ||= '01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'

Rails.application.configure do
  # Defaults to false on Rails 7.1+, but explicitly set for clarity/older versions
  config.require_master_key = false
  config.read_encrypted_secrets = false
  # Ensure Rails uses the ENV var we (potentially) just set
  config.secret_key_base = ENV['SECRET_KEY_BASE']
end
RUBY
end

# --- Add Deployment Files ---

say "Adding AWS SAM deployment files..."

# 1. Create template.yaml
say "Creating template.yaml (AWS SAM Template)"
create_file 'template.yaml' do <<-YAML
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: MyAwesomeLambda

Parameters:

  RailsEnv:
    Type: String
    Default: staging
    AllowedValues:
      - staging
      - production

Globals:

  Function:
    Architectures:
      - arm64
    AutoPublishAlias: live
    DeploymentPreference:
      Type: AllAtOnce
    Environment:
      Variables:
        RAILS_ENV: !Ref RailsEnv
    Timeout: 30

Resources:

  RailsLambda:
    Type: AWS::Serverless::Function
    Metadata:
      DockerContext: .
      Dockerfile: Dockerfile
      DockerTag: web # Using fixed tag 'web' now
    Properties:
      FunctionUrlConfig:
        AuthType: NONE
      MemorySize: 1792 # Hardcoded memory
      PackageType: Image

Outputs:

  RailsLambdaUrl:
    Description: Lambda Function URL
    # Note: The default resource name for Function URLs is FunctionName + 'Url'
    Value: !GetAtt RailsLambdaUrl.FunctionUrl

YAML
end

# Define a sanitized app name for AWS resources
sanitized_app_name = app_name.downcase.gsub(/[^a-z0-9\-]/, '-')

# 2. Create bin/deploy script
say "Creating bin/deploy (AWS SAM Deployment Script)"
deploy_script_content = <<-BASH
#!/bin/sh
set -e

RAILS_ENV=${RAILS_ENV-production}

AWS_REGION=${AWS_REGION-$(aws configure get region || echo 'us-east-1')}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/#{sanitized_app_name}"

if [ "$CI" != "true" ]; then
  echo "== Cleaning dev dependencies for local deploy. Run ./bin/setup again afterward! =="
  rm -rf ./.bundle \
         ./vendor/bundle
fi

echo '== Create ECR Repo if needed. =='
aws ecr describe-repositories \
  --repository-names "#{sanitized_app_name}" \
  --region "$AWS_REGION" > /dev/null || \
aws ecr create-repository \
  --repository-name "#{sanitized_app_name}" \
  --image-tag-mutability "MUTABLE" \
  --image-scanning-configuration "scanOnPush=true" \
  --region "$AWS_REGION" > /dev/null || true

echo '== Bundle For Deployment =='
bundle config --global silence_root_warning true
bundle config --local deployment true
# Keep development group for assets:precompile, exclude only test
bundle config --local without 'test' 
bundle config --local path './vendor/bundle'
bundle install --quiet --jobs 4

echo "== Asset Hosts & Precompiling =="
NODE_ENV='production' ./bin/rails assets:precompile

if [ "$CI" = "true" ]; then
  echo "== Cleanup Unused Files & Directories =="
  rm -rf \
    log \
    node_modules \
    test \
    tmp \
    vendor/bundle/ruby/*/cache
fi

echo "== SAM build =="
sam build \\
  --use-container \\
  --debug \\
  --build-image public.ecr.aws/sam/build-ruby3.2:1.132.0-20241211194057-arm64 \\
  --parameter-overrides \\
    RailsEnv="${RAILS_ENV}"

echo "== SAM package =="
sam package \
  --region "$AWS_REGION" \
  --template-file ./.aws-sam/build/template.yaml \
  --output-template-file ./.aws-sam/build/packaged.yaml \
  --image-repository "$IMAGE_REPOSITORY"

echo "== SAM deploy =="
sam deploy \
  --region "$AWS_REGION" \
  --template-file ./.aws-sam/build/packaged.yaml \
  --stack-name "#{sanitized_app_name}-${RAILS_ENV}" \
  --image-repository "$IMAGE_REPOSITORY" \
  --capabilities "CAPABILITY_IAM" \
  --parameter-overrides \
    RailsEnv="${RAILS_ENV}"

if [ "$CI" != "true" ]; then
  echo "== Cleaning prod deploy dependencies from local. =="
  rm -rf ./.bundle \
         ./vendor/bundle \
         ./node_modules \
         ./public/assets
fi
BASH

create_file 'bin/deploy', deploy_script_content
chmod "bin/deploy", 0755
say "Made bin/deploy executable"

# 3. Create .dockerignore
say "Creating .dockerignore (To exclude files from SAM build context)"
create_file '.dockerignore' do <<-'IGNORE'
# See https://docs.docker.com/engine/reference/builder/#dockerignore-file for more about ignoring files.

# Ignore git directory.
/.git/
/.gitignore

# Ignore bundler config.
/.bundle

# Ignore all environment files (except templates).
/.env*
!/.env*.erb

# Ignore all default key files.
/config/master.key
/config/credentials/*.key

# Ignore all logfiles and tempfiles.
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep

# Ignore pidfiles, but keep the directory.
/tmp/pids/*
!/tmp/pids/.keep

# Ignore storage (uploaded files in development and any SQLite databases).
/storage/*
!/storage/.keep
/tmp/storage/*
!/tmp/storage/.keep

# Ignore assets.
/node_modules/
/app/assets/builds/*
!/app/assets/builds/.keep
/public/assets

# Ignore CI service files.
/.github

# Ignore development files
/.devcontainer

# Ignore Docker-related files
/.dockerignore
/Dockerfile*
IGNORE
end

# --- Read Ruby Version ---
say "Reading .ruby-version file..."
ruby_version_file = '.ruby-version'
ruby_version_content_to_write = '3.2' # Default content
ruby_version_for_dockerfile = '3.2' # Default for Dockerfile

if File.exist?(ruby_version_file)
  content = File.read(ruby_version_file).strip
  unless content.empty?
    ruby_version_content_to_write = content # Preserve original content with prefix if present
    # Handle potential prefixes like 'ruby-' by taking the part after the last hyphen for Dockerfile
    ruby_version_for_dockerfile = content.include?('-') ? content.split('-').last : content
    say "Using Ruby version #{ruby_version_for_dockerfile} from #{ruby_version_file} for Dockerfile."
  else
    say "Warning: .ruby-version file is empty, will create with default Ruby #{ruby_version_content_to_write}. Defaulting to Ruby #{ruby_version_for_dockerfile} for Dockerfile."
  end
else
  say ".ruby-version file not found, will create with default Ruby #{ruby_version_content_to_write}. Defaulting to Ruby #{ruby_version_for_dockerfile} for Dockerfile."
end

create_file '.ruby-version', ruby_version_content_to_write, force: true
say "Created/Updated .ruby-version with: #{ruby_version_content_to_write}"

# 4. Create Dockerfile (for asset compilation)
say "Creating Dockerfile (For building assets)"
# This Dockerfile prepares the final application image.
# Assumes assets are precompiled and gems are vendored by the deploy script.
create_file 'Dockerfile' do <<-"DOCKER"
# Shared image, envs, packages for both devcontainer & prod.
# Use Ruby version from .ruby-version file
FROM --platform=linux/arm64 ruby:#{ruby_version_for_dockerfile}-bullseye

# Install the AWS Lambda Runtime Interface Client & Crypteia for secure SSM-backed envs.
RUN gem install 'aws_lambda_ric'
COPY --from=ghcr.io/rails-lambda/crypteia-extension-debian:1 /opt /opt
ENTRYPOINT [ "/usr/local/bundle/bin/aws_lambda_ric" ]
ENV LD_PRELOAD=/opt/lib/libcrypteia.so

# Create app directory and secure user
RUN mkdir /app \
    && groupadd -g 10001 app \
    && useradd -u 10000 -g app -d /app app \
    && chown -R app:app /app
USER app
WORKDIR "/app"

# Copy prod application files and set handler.
ENV BUNDLE_IGNORE_CONFIG=1
ENV BUNDLE_PATH=./vendor/bundle
ENV BUNDLE_CACHE_PATH=./vendor/cache
ENV RAILS_SERVE_STATIC_FILES=1
# Note: Gems are expected to be vendored and copied with the app code.
# Assets are also expected to be precompiled and copied.
COPY . .
CMD ["config/environment.Lamby.cmd"]
DOCKER
end

say "Deployment files added."

# --- Update Documentation ---
say "Updating README.md with deployment instructions..."

readme_content = <<-MARKDOWN

## AWS Lambda Deployment (via Lamby)

This application has been configured for deployment to AWS Lambda using the [Lamby gem](https://lamby.cloud/) and the AWS Serverless Application Model (SAM).

Key files added/modified:
*   `Gemfile`: Added `lamby`.
*   `config/application.rb`, `config/environments/production.rb`, `config.ru`: Configured for Lamby.
*   `template.yaml`: AWS SAM template defining the Lambda function, API Gateway, and other resources.
*   `Dockerfile`: Used by SAM to build the application container image with assets precompiled.
*   `bin/deploy`: Script to build and deploy the application using SAM.
*   `.dockerignore`: Excludes unnecessary files from the build context.

### Prerequisites

1.  **AWS Account:** You need an AWS account.
2.  **IAM User/Role:** Configure an IAM user or role with permissions to manage CloudFormation, Lambda, API Gateway, S3, ECR, and IAM.
3.  **AWS CLI:** Install and configure the [AWS CLI](https://aws.amazon.com/cli/) (`aws configure`).
4.  **AWS SAM CLI:** Install the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html).
5.  **Docker:** Install [Docker](https://www.docker.com/get-started) (required for `sam build --use-container`).

### Deployment Steps

1.  **Configure Environment Variables:**
    *   Set `AWS_REGION`: The AWS region to deploy to (e.g., `export AWS_REGION=us-east-1`).
    *   Set `DEPLOY_BUCKET`: An S3 bucket in the target region where SAM can upload deployment artifacts (e.g., `export DEPLOY_BUCKET=my-unique-sam-artifacts-bucket`). **You must create this bucket first.**
    *   **Set `SECRET_KEY_BASE` securely:** The `bin/deploy` script expects `SECRET_KEY_BASE` to be handled via parameter overrides, ideally referencing AWS Secrets Manager or Parameter Store. See comments in `bin/deploy` and `template.yaml` for guidance. **Do not commit your secret key directly.**
    *   Configure any other necessary environment variables (like `DATABASE_URL` source) as parameter overrides in `bin/deploy`.

2.  **Run Deployment Script:**
    ```bash
    ./bin/deploy
    ```
    This script will:
    *   Build the Docker image using `sam build --use-container`.
    *   Package the application.
    *   Deploy the CloudFormation stack using `sam deploy` (it will prompt for confirmation).

3.  **Find API Endpoint:** Once deployment is successful, the API Gateway endpoint URL will be listed in the CloudFormation stack outputs.

MARKDOWN

append_to_file 'README.md', readme_content
say "Appended to README.md"

# --- Update Database Configuration Guidance ---
say "Adding guidance to config/database.yml..."

database_guidance = <<-YAML

  # Production Database Configuration for AWS Lambda:
  #
  # For deployments to AWS Lambda and similar environments, it's recommended to
  # configure the database connection using the DATABASE_URL environment variable.
  # This variable should be set securely in your Lambda function's configuration
  # (e.g., via Parameter Store or Secrets Manager referenced in template.yaml
  # and passed during 'sam deploy' using bin/deploy).
  #
  # Example:
  # url: <%= ENV["DATABASE_URL"] %>
  #
  # Ensure your default production block below is commented out or replaced
  # if you adopt the DATABASE_URL approach.

YAML

# Insert the guidance comment after the line containing 'production:'
insert_into_file 'config/database.yml', database_guidance, after: /production:/, force: false # force: false to avoid error if no production: line

say "Template generation complete!"

# --- Final Notes --- 

say "\nNext Steps:", :yellow
say "1. Review the generated files, especially template.yaml, bin/deploy, and Dockerfile.", :yellow
say "2. Configure your production database (e.g., RDS, Aurora Serverless).", :yellow
say "3. Set up secure handling for SECRET_KEY_BASE and DATABASE_URL (see below).", :yellow
say "4. Create the ECR repository (if it doesn't exist) and S3 artifact bucket referenced in bin/deploy.", :yellow
say "5. Set required environment variables (e.g., AWS_REGION).", :yellow
say "6. Run ./bin/deploy to deploy your application.", :yellow

say "\nImportant Note on SECRET_KEY_BASE:", :red
say "- This template creates a DUMMY secret key in 'config/initializers/secret_key_base.rb' and disables Rails encrypted credentials.", :red
say "- This initializer is NOT secure for production.", :red
say "- For production, you SHOULD remove the dummy ENV['SECRET_KEY_BASE'] line from that initializer.", :red
say "- The included Dockerfile uses Crypteia (LD_PRELOAD) which can fetch secrets from SSM Parameter Store.", :red
say "- Configure your REAL SECRET_KEY_BASE in SSM Parameter Store and ensure your Lambda execution role has permission to read it.", :red
say "- Update template.yaml or bin/deploy if needed to reference the correct SSM parameter name.", :red
