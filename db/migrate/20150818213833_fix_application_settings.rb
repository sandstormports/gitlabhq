class FixApplicationSettings < ActiveRecord::Migration
  # Sandstorm-only migration.
  # In 20150529111607_add_user_oauth_applications_to_application_settings.rb, a column was
  # added with type "bool", which is not supported by sqlite. Here we change that column's
  # type to "boolean".

  def up

    execute %{
      CREATE TABLE "new_application_settings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "default_projects_limit" integer, "signup_enabled" boolean, "signin_enabled" boolean, "gravatar_enabled" boolean, "sign_in_text" text, "created_at" datetime, "updated_at" datetime, "home_page_url" varchar(255), "default_branch_protection" integer DEFAULT 2, "twitter_sharing_enabled" boolean DEFAULT 1, "restricted_visibility_levels" text, "version_check_enabled" boolean DEFAULT 1, "max_attachment_size" integer DEFAULT 10 NOT NULL, "default_project_visibility" integer, "default_snippet_visibility" integer, "restricted_signup_domains" text, "user_oauth_applications" boolean DEFAULT 1, "after_sign_out_path" varchar(255), "session_expire_delay" integer DEFAULT 10080 NOT NULL, "import_sources" text);
    }

    execute %{
      insert into "new_application_settings" select * from application_settings
    }

    execute %{
      drop table application_settings
    }

    execute %{
      CREATE TABLE "application_settings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "default_projects_limit" integer, "signup_enabled" boolean, "signin_enabled" boolean, "gravatar_enabled" boolean, "sign_in_text" text, "created_at" datetime, "updated_at" datetime, "home_page_url" varchar(255), "default_branch_protection" integer DEFAULT 2, "twitter_sharing_enabled" boolean DEFAULT 1, "restricted_visibility_levels" text, "version_check_enabled" boolean DEFAULT 1, "max_attachment_size" integer DEFAULT 10 NOT NULL, "default_project_visibility" integer, "default_snippet_visibility" integer, "restricted_signup_domains" text, "user_oauth_applications" boolean DEFAULT 1, "after_sign_out_path" varchar(255), "session_expire_delay" integer DEFAULT 10080 NOT NULL, "import_sources" text);
    }

    execute %{
      insert into "application_settings" select * from application_settings
    }

    execute %{
      drop table new_application_settings
    }

  end
end
