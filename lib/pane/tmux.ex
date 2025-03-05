defmodule Pane.Tmux do
  @moduledoc """
  A collection of functions that model tmux commands.
  Each function returns a string representation of the tmux command.

  This module serves as a facade to the specialized tmux modules:
  - Pane.Tmux.Session
  - Pane.Tmux.Window
  - Pane.Tmux.Pane
  - Pane.Tmux.Layout
  """

  # Session Management
  defdelegate session_exists?(session), to: Pane.Tmux.Session, as: :exists?
  defdelegate new_session(session, opts \\ []), to: Pane.Tmux.Session, as: :new
  defdelegate attach_session(opts \\ []), to: Pane.Tmux.Session, as: :attach
  defdelegate list_sessions(), to: Pane.Tmux.Session, as: :list
  defdelegate kill_session(target), to: Pane.Tmux.Session, as: :kill
  defdelegate set_option(option, value, opts), to: Pane.Tmux.Session, as: :set_option

  # Window Management
  defdelegate new_window(name, opts \\ []), to: Pane.Tmux.Window, as: :new
  defdelegate select_window(target), to: Pane.Tmux.Window, as: :select
  defdelegate list_windows(opts \\ []), to: Pane.Tmux.Window, as: :list
  defdelegate kill_window(target), to: Pane.Tmux.Window, as: :kill
  defdelegate set_window_option(option, value, opts), to: Pane.Tmux.Window, as: :set_option

  # Pane Management
  defdelegate split_window(opts \\ []), to: Pane.Tmux.Pane, as: :split
  defdelegate select_pane(target), to: Pane.Tmux.Pane, as: :select
  defdelegate send_keys(keys, opts \\ []), to: Pane.Tmux.Pane, as: :send_keys
  defdelegate kill_pane(target), to: Pane.Tmux.Pane, as: :kill

  # Layout Management
  defdelegate select_layout(layout, opts), to: Pane.Tmux.Layout, as: :select
  defdelegate next_layout(opts), to: Pane.Tmux.Layout, as: :next
  defdelegate previous_layout(opts), to: Pane.Tmux.Layout, as: :previous
end