# Set test mode for command generation
Application.put_env(:pane, :test_mode, true)

ExUnit.start()
