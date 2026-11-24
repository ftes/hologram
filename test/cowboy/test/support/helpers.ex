defmodule HologramCowboyTests.Helpers do
  import Hologram.Test.FeatureHelpers, only: [track_js_errors: 1]
  import Playwright.Test.Assertions

  alias Hologram.Realtime
  alias Hologram.Realtime.SubscriptionRegistry
  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.Expect
  alias Playwright.Locator
  alias Playwright.Page

  @doc """
  Asserts that the element matching the CSS selector shows the given text.
  """
  def assert_text(page, selector, text) do
    page
    |> Page.locator(selector)
    |> Expect.to_contain_text!(text, use_inner_text: true)

    page
  end

  @doc """
  Clicks the element matching the CSS selector.
  """
  def click(page, selector) do
    page
    |> Page.locator(selector)
    |> Locator.click!()

    page
  end

  @doc """
  Runs the script in the page.
  """
  def execute_script(page, script) do
    Page.evaluate!(page, script)
    page
  end

  @doc """
  Opens a page in a new context of the browser: another user, with cookies and
  storage of its own.
  """
  def new_session(browser) do
    context = Browser.new_context!(browser)
    track_js_errors(context)
    BrowserContext.new_page!(context)
  end

  @doc """
  Blocks until at least `count` (default 1) `SubscriptionRegistry` connections
  hold a binding on `channel`, then returns the `session` so the helper can be
  piped. Raises if the count is not reached within the expect timeout.

  Gate any broadcast whose recipients a test asserts on: subscriptions register
  asynchronously after the page mounts (handshake POST + SSE attach), and
  `Phoenix.PubSub` is fire-and-forget, so a broadcast that fires first reaches
  no one. Pass `count` > 1 to require every participating connection in a
  multi-session test.

  A connection counts once its SSE process can receive broadcasts on `channel`,
  not merely once the registry records the binding.
  """
  def wait_for_subscription(session, channel, count \\ 1) do
    Expect.poll!(
      fn -> subscription_count(channel) end,
      &assert(
        &1 >= count,
        "Timed out waiting for #{count} subscription(s) on #{inspect(channel)}"
      )
    )

    session
  end

  # Whether the connection holds a binding on the channel and its SSE process has
  # subscribed to the channel's PubSub topic. The registry records a binding before
  # the SSE process subscribes, which it does only when it handles the
  # `{:sub, channel}` message the registry sends it, and a broadcast in between
  # reaches no one.
  defp receiving?(entry, channel) do
    Enum.any?(entry.bindings, fn {{ch, _cid}, _user_id} -> ch == channel end) and
      Realtime.channel_topic(channel) in Registry.keys(Hologram.PubSub, entry.sse_pid)
  end

  defp subscription_count(channel) do
    SubscriptionRegistry.ets_table_name()
    |> :ets.tab2list()
    |> Enum.count(fn {_instance_id, entry} -> receiving?(entry, channel) end)
  end
end
