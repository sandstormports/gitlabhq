class EnableSslVerificationForWebHooks < ActiveRecord::Migration
  def up
    # Sandstorm: prevent 'no such column' error.
    # TODO: Figure out why this column does not exist.
    #execute("UPDATE web_hooks SET enable_ssl_verification = true")
  end

  def down
  end
end
