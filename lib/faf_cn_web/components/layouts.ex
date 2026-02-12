defmodule FafCnWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use FafCnWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash} current_user={@current_user}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_user, :map, default: nil, doc: "the current logged in user"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 border-b border-base-200">
      <div class="flex-1">
        <a href="/" class="flex items-center gap-2">
          <.icon name="hero-globe-alt" class="w-8 h-8 text-primary" />
          <span class="text-xl font-bold">FAF CN</span>
        </a>
      </div>
      <div class="flex-none">
        <nav class="flex items-center space-x-4">
          <a href={~p"/eco-guides"} class="btn btn-ghost">
            <.icon name="hero-calculator" class="w-5 h-5 mr-1" /> Eco Guide
          </a>
          <a href={~p"/eco-prediction"} class="btn btn-ghost">
            <.icon name="hero-chart-line" class="w-5 h-5 mr-1" /> Eco Prediction
          </a>
          <.settings_link current_user={@current_user} />
          <.user_menu current_user={@current_user} />
          <.theme_toggle />
        </nav>
      </div>
    </header>

    <main>
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders the settings link for super admin users.
  """
  attr :current_user, :map, default: nil

  def settings_link(assigns) do
    ~H"""
    <%= if @current_user && FafCn.Accounts.super_admin?(@current_user) do %>
      <a href={~p"/settings"} class="btn btn-ghost">
        <.icon name="hero-cog-6-tooth" class="w-5 h-5 mr-1" /> Settings
      </a>
    <% end %>
    """
  end

  @doc """
  Renders the user menu - shows login button or user avatar with logout.
  """
  attr :current_user, :map, default: nil

  def user_menu(assigns) do
    ~H"""
    <%= if @current_user do %>
      <div class="dropdown dropdown-end">
        <button class="btn btn-ghost btn-circle avatar" tabindex="0">
          <div class="w-10 rounded-full">
            <%= if @current_user.avatar_url do %>
              <img src={@current_user.avatar_url} alt={@current_user.name || @current_user.email} />
            <% else %>
              <div class="bg-primary text-primary-content flex items-center justify-center w-full h-full">
                <.icon name="hero-user" class="w-6 h-6" />
              </div>
            <% end %>
          </div>
        </button>
        <ul
          tabindex="0"
          class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 mt-4 z-50"
        >
          <li class="menu-title">
            <span>{@current_user.name || @current_user.email}</span>
          </li>
          <li><a href={~p"/logout"}>Logout</a></li>
        </ul>
      </div>
    <% else %>
      <a href={~p"/auth/github"} class="btn btn-ghost">
        <.icon name="hero-arrow-right-end-on-rectangle" class="w-5 h-5 mr-1" /> Login
      </a>
    <% end %>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border border-base-200 bg-base-100 brightness-200 left-0 in-data-[theme=light]:left-1/3 in-data-[theme=dark]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
