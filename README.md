This template is hosted on RailsBytes at: **https://railsbytes.com/templates/zamsdp**


# Rails Lamby Project Template

This repository contains a Ruby on Rails application template (`template.rb`) designed to quickly set up a new or existing Rails project for deployment to AWS Lambda using the [Lamby gem](https://lamby.cloud/). It aims to replicate the structure, configurations, and best practices of a reference project ("lamby-cookiecutter"), providing a robust foundation for serverless Rails applications.


## Features Provided by This Template

When applied to a Rails application, this template will:

*   **Integrate Lamby:**
    *   Add the `lamby` gem to your `Gemfile`.
    *   Add `lograge` for structured JSON logging suitable for AWS CloudWatch.
    *   Configure essential Lamby settings.
    *   (Note: `config.ru` is set to `run Rails.application` to match the reference project. For standard Lamby behavior, you might need to adjust it to `run Lamby.rack(Rails.application)` post-generation if issues arise.)
*   **Database Configuration:**
    *   Prompt the user to select a database (MySQL, PostgreSQL, or SQLite3) during template application.
    *   Recommend and default to MySQL for consistency with the reference project.
    *   Add the appropriate database gem to the `Gemfile`.
    *   Provide guidance in `config/database.yml` for using `DATABASE_URL` in production.
*   **Deployment Files for AWS SAM:**
    *   Generate a `template.yaml` AWS SAM (Serverless Application Model) template for defining the Lambda function, API Gateway (implicitly via Function URL), and other resources.
    *   Create a `Dockerfile` optimized for building the Rails application image for Lambda, including Crypteia for SSM secret fetching.
    *   Include a `bin/deploy` script to automate the SAM build and deployment process (bundling, asset precompilation, SAM commands).
    *   Add a `.dockerignore` file to keep the build context lean.
*   **Development Environment:**
    *   Set up a `.devcontainer/` configuration for a consistent development environment using VS Code Dev Containers. This includes:
        *   `devcontainer.json`
        *   A `Dockerfile` for the dev environment.
        *   `docker-compose.yml` for managing services like MySQL.
*   **CI/CD Configuration:**
    *   Add a `.circleci/config.yml` file for CircleCI, configured to build, test (using the dev container), and deploy the application.
*   **Standard Project Files:**
    *   Create or overwrite `.gitattributes`, `.rubocop.yml` (using `rubocop-rails-omakase`), `.gitignore`, and `Rakefile` to match the reference project's standards.
    *   Generate a `.ruby-version` file.
*   **Security & Configuration:**
    *   Create a dummy `config/initializers/secret_key_base.rb` to ensure Rails can boot in environments where `SECRET_KEY_BASE` might not be immediately available (like some build stages). **This initializer explicitly warns that it's not for production use and that a secure `SECRET_KEY_BASE` (e.g., from SSM) is required for actual deployments.**
*   **Documentation:**
    *   Generate a comprehensive `README.md` *within the new Rails application* detailing setup, development, testing, and AWS Lambda deployment steps.

## How to Use This Template

This template is hosted on RailsBytes at: **https://railsbytes.com/templates/zamsdp**

### For a New Rails Application:

1.  Ensure you have Ruby, Rails, Bundler, AWS CLI, AWS SAM CLI, and Docker installed.
2.  Navigate to the directory where you want to create your new application.
3.  Run the following command, replacing `<your_app_name>` with your desired application name:

    ```bash
    rails new <your_app_name> -m https://railsbytes.com/script/zamsdp
    ```
    *Example:*
    ```bash
    rails new my_lamby_app -m https://railsbytes.com/script/zamsdp
    ```

4.  The template will prompt you to select a database.
5.  Once complete, `cd` into your new application directory (`<your_app_name>`) and follow the instructions in its generated `README.md`.

### For an Existing Rails Application:

1.  Ensure your existing application is under version control (git) as the template will make changes.
2.  Navigate to your application's root directory.
3.  Run the following command:

    ```bash
    rails app:template LOCATION='https://railsbytes.com/script/zamsdp'
    ```

4.  The template will prompt for database selection (though this has more implications for an existing app with an already configured database – review changes carefully).
5.  Carefully review the changes made by the template. You might need to resolve conflicts or adjust configurations based on your existing setup.

## Structure of This Repository

*   `template.rb`: The Rails application template script.
*   `README.md`: This file, explaining the template and its usage.
*   (Optionally, include any supporting files or documentation for the template itself here).

## Customization

After applying the template, you are encouraged to:

*   Review all generated files, especially `template.yaml`, `Dockerfile`, and `bin/deploy`, and customize them for your specific AWS environment and application needs.
*   Securely manage your `SECRET_KEY_BASE`, `DATABASE_URL`, and other sensitive configurations using AWS SSM Parameter Store or other secrets management solutions.
*   Adjust the `.circleci/config.yml` and `.devcontainer/` setups as needed.

## Contributing to This Template

[Provide instructions if you want others to contribute to your `template.rb` itself.]

## License for This Template

[Specify the license for your `template.rb` and this repository, e.g., MIT License.] 