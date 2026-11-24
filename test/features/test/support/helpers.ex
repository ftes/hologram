defmodule HologramFeatureTests.Helpers do
  import Playwright.Test.Assertions
  import Hologram.Test.FeatureHelpers, only: [take_js_error: 1, track_js_errors: 1, visit: 3]

  alias Hologram.Assets.PageDigestRegistry
  alias Hologram.Realtime
  alias Hologram.Realtime.SSE
  alias Hologram.Realtime.SubscriptionRegistry
  alias Hologram.Reflection
  alias Hologram.Router.Helpers, as: RouterHelpers
  alias HologramFeatureTestsWeb.Endpoint
  alias HologramFeatureTestsWeb.Plugs.SlowPageBundle
  alias Playwright.Browser
  alias Playwright.BrowserContext
  alias Playwright.Clock
  alias Playwright.Expect
  alias Playwright.Keyboard
  alias Playwright.Locator
  alias Playwright.Page

  @doc """
  Asserts that `fun` raises an error in the client: an uncaught error of the
  given Hologram exception module, whose message is `expected_msg` (or matches it,
  when it's a regex). The error is read from the page, which keeps the whole of
  it.
  """
  def assert_client_error(page, expected_module, expected_msg, fun) do
    take_js_error(fun)

    result = script_result(page, "return globalThis.Hologram?.['lastBoxedError'];")

    assert result["module"] == inspect(expected_module),
           "Expected exception #{inspect(expected_module)} but got #{result["module"]} (#{result["message"]})"

    message = fn expected_display, actual_msg ->
      """
      Wrong message for #{inspect(expected_module)}
      expected:
        "#{expected_display}"
      actual:
        "#{actual_msg}"\
      """
    end

    assert_client_error_message(result["message"], expected_msg, message)

    page
  end

  # A regex is matched rather than compared, and shows as its source - it has no
  # string form to interpolate.
  defp assert_client_error_message(actual_msg, %Regex{} = expected_msg, message) do
    source = Regex.source(expected_msg)
    assert actual_msg =~ expected_msg, message.(source, actual_msg)
  end

  defp assert_client_error_message(actual_msg, expected_msg, message) do
    assert actual_msg == expected_msg, message.(expected_msg, actual_msg)
  end

  def assert_count(page, selector, count) do
    assert_has(page, selector, count: count)
  end

  @doc """
  Asserts that the CSS selector matches exactly one visible element, or `count:`
  visible elements (`:any` for at least one). `text:` narrows the matches to the elements containing it.
  """
  def assert_has(page, selector, opts \\ []) do
    locator = visible(page, selector, opts)

    case opts[:count] do
      nil ->
        Expect.to_be_visible!(locator)

      :any ->
        locator
        |> Locator.first()
        |> Expect.to_be_visible!()

      count ->
        Expect.to_have_count!(locator, count)
    end

    page
  end

  @doc """
  Asserts that the element matching the CSS selector has focus.
  """
  def assert_focused(page, selector) do
    page
    |> Page.locator(selector)
    |> Expect.to_be_focused!()

    page
  end

  def assert_input_value(page, selector, expected_value) do
    page
    |> Page.locator(selector)
    |> Expect.to_have_value!(expected_value)

    page
  end

  @doc """
  Asserts that `fun` raises an uncaught error in the page whose message contains
  `expected_msg` (or matches it, when it's a regex).
  """
  def assert_js_error(page, expected_msg, fun) do
    message =
      fun
      |> take_js_error()
      |> Exception.message()

    assert message =~ expected_msg,
           "Expected an uncaught JavaScript error matching #{inspect(expected_msg)}, got: #{message}"

    page
  end

  def assert_public_comment(page, comment) do
    regex = ~r/<!\-\-\s*#{Regex.escape(comment)}\s*\-\->/

    assert Page.content!(page) =~ regex,
           "Expected to find public comment \"#{comment}\" in page content, but it was not found"

    page
  end

  def assert_scroll_position(page, x, y) do
    assert_script_result(page, "return [window.scrollX, window.scrollY]", [x, y])
  end

  @doc """
  Asserts that the script's result becomes `expected_result`, retrying the script
  until it does.
  """
  def assert_script_result(page, script, expected_result) do
    Expect.poll!(fn -> script_result(page, script) end, &assert(&1 == expected_result))
    page
  end

  @doc """
  Asserts that no element matches the CSS selector, visible or not.
  """
  def assert_none(page, selector) do
    page
    |> Page.locator(selector)
    |> Expect.to_have_count!(0)

    page
  end

  @doc """
  Asserts that the page, or the element matching the CSS selector, shows the text
  (or text matching the regex).
  """
  def assert_text(page, text) do
    assert_text(page, "body", text)
  end

  def assert_text(page, selector, text) do
    page
    |> locator(selector)
    |> Expect.to_contain_text!(text, use_inner_text: true)

    page
  end

  @doc """
  Asserts that the page's URL becomes the given one, or matches the regex.
  """
  def assert_url(page, url) do
    Expect.to_have_url!(page, url)
    page
  end

  @doc """
  Returns whether the given JavaScript bundle defines the given function.

  A bundle can name a module without holding its code (a protocol's dispatcher
  names every implementation), so the name alone says nothing.
  """
  @spec bundle_defines?(String.t(), mfa) :: boolean
  def bundle_defines?(bundle, {module, function, arity}) do
    String.contains?(
      bundle,
      ~s/defineElixirFunction("#{inspect(module)}","#{function}",#{arity},/
    )
  end

  @doc """
  Returns whether the chunk bundle with the given digest defines the given
  function (see `bundle_defines?/2`).
  """
  @spec chunk_bundle_defines?(String.t(), mfa) :: boolean
  def chunk_bundle_defines?(digest, mfa) do
    digest
    |> read_chunk_bundle()
    |> bundle_defines?(mfa)
  end

  @doc """
  Returns the digests of every chunk bundle the compiler wrote, sorted.
  """
  @spec chunk_digests() :: [String.t()]
  def chunk_digests do
    Reflection.bundles_dir()
    |> Path.join("chunk-????????.js")
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".js"))
    |> Enum.map(&String.replace_prefix(&1, "chunk-", ""))
    |> Enum.sort()
  end

  @doc """
  Clicks the element matching the CSS selector (or the locator).
  """
  def click(page, selector) do
    page
    |> locator(selector)
    |> Locator.click!()

    page
  end

  @doc """
  Clicks the button with the given accessible name.
  """
  def click_button(page, name) do
    page
    |> Page.get_by_role(:button, name: name, exact: true)
    |> Locator.click!()

    page
  end

  @doc """
  Clicks the link with the given accessible name.
  """
  def click_link(page, name) do
    page
    |> Page.get_by_role(:link, name: name, exact: true)
    |> Locator.click!()

    page
  end

  @doc """
  Returns the cookies of the page's context, sorted by name.
  """
  def cookies(page) do
    page
    |> Page.context()
    |> BrowserContext.cookies!()
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Returns the `instance_id` of the given page's browser.

  Read from the browser's own JS context rather than from the registry, so it
  holds however many connections are registered, and keeps working when this
  one has no registry entry - after `simulate_sse_disconnect/1`, or before the
  stream has attached.
  """
  @spec current_instance_id(Page.t()) :: String.t()
  def current_instance_id(page) do
    script_result(page, "return globalThis.Hologram.instanceId;")
  end

  @doc """
  Returns the `session_id` recorded for the given page's connection, or `nil`
  when it has no registry entry.
  """
  @spec current_session_id(Page.t()) :: term
  def current_session_id(page) do
    case registry_entry(page) do
      nil -> nil
      entry -> entry.session_id
    end
  end

  @doc """
  Returns the `user_id` recorded for the given page's connection, or `nil` when
  it has no registry entry.

  Returning `nil` rather than raising lets a poller keep waiting through the
  window where a connection has not attached yet, or has just been reaped.
  """
  @spec current_user_id(Page.t()) :: term
  def current_user_id(page) do
    case registry_entry(page) do
      nil -> nil
      entry -> entry.user_id
    end
  end

  @doc """
  Returns the digests of the chunks the document of the given page names: the
  ones the server tells a browser to load before the page mounts. The document
  is the one the server answers a request for the page with, before any script
  has run.
  """
  @spec document_chunk_digests(module) :: [String.t()]
  def document_chunk_digests(page_module) do
    path = RouterHelpers.page_path(page_module)

    document =
      :get
      |> Plug.Test.conn(path)
      |> Endpoint.call(Endpoint.init([]))
      |> Map.fetch!(:resp_body)

    [_match, boot_data_json] =
      Regex.run(~r'<script[^>]* id="hologram-boot-data"[^>]*>(.*?)</script>'s, document)

    boot_data_json
    |> Jason.decode!()
    |> Map.fetch!("chunks")
  end

  @doc """
  Runs the script in the page, as the body of a function: `return` gives its
  result, and `args` are its `arguments`.
  """
  def execute_script(page, script, args \\ []) do
    script_result(page, script, args)
    page
  end

  @doc """
  Fills the field matching the CSS selector with the value.
  """
  def fill_in(page, selector, with: value) do
    page
    |> locator(selector)
    |> Locator.fill!(to_string(value))

    page
  end

  def go_back(page) do
    Page.go_back!(page)
    page
  end

  def go_forward(page) do
    Page.go_forward!(page)
    page
  end

  def hover(page, selector) do
    page
    |> locator(selector)
    |> Locator.hover!()

    page
  end

  @doc """
  Marks the document the `page` shows, so that `wait_for_unmarked_document/1` can tell when
  the browser has replaced it with a new one.
  """
  def mark_document(page) do
    execute_script(page, "globalThis.__hologramMarkedDocument = true;")
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
  Returns the content of the chunk bundle with the given digest.
  """
  @spec read_chunk_bundle(String.t()) :: String.t()
  def read_chunk_bundle(digest) do
    digest
    |> RouterHelpers.chunk_bundle_path()
    |> bundle_file_path()
    |> File.read!()
  end

  @doc """
  Returns the content of the given page's bundle.
  """
  @spec read_page_bundle(module) :: String.t()
  def read_page_bundle(page_module) do
    digest = PageDigestRegistry.lookup(page_module)

    page_module
    |> RouterHelpers.page_bundle_path(digest)
    |> bundle_file_path()
    |> File.read!()
  end

  @doc """
  Returns the content of the runtime bundle.
  """
  @spec read_runtime_bundle() :: String.t()
  def read_runtime_bundle do
    [runtime_bundle_path] =
      Reflection.bundles_dir()
      |> Path.join("runtime-????????.js")
      |> Path.wildcard()

    File.read!(runtime_bundle_path)
  end

  @doc """
  Asserts that the CSS selector matches no visible element. `text:` narrows the
  matches to the elements containing it.

  Pass `wait_time: ms` to assert absence only after waiting `ms` first, so an
  appearance arriving within that window is still caught.
  """
  def refute_has(page, selector, opts \\ []) do
    if wait_time = opts[:wait_time], do: Page.wait_for_timeout!(page, wait_time)

    page
    |> visible(selector, opts)
    |> Expect.to_have_count!(0)

    page
  end

  @doc """
  Refutes that an element matching the CSS selector displays `text`. The negative
  counterpart to `assert_text/3`; accepts the same `opts` as `refute_has/3`.
  """
  def refute_text(page, selector, text, opts \\ []) do
    refute_has(page, selector, Keyword.put(opts, :text, text))
  end

  def reload(page) do
    Page.reload!(page)
    page
  end

  @doc """
  Runs the script in the page, as `execute_script/3` does, and returns its result.
  """
  def script_result(page, script, args \\ []) do
    Page.evaluate!(page, "(args) => (function () {\n#{script}\n}).apply(null, args)", args)
  end

  def resize_window(page, width, height) do
    Page.set_viewport_size!(page, %{width: width, height: height})
    page
  end

  def scroll_to(page, x, y) do
    execute_script(page, "window.scrollTo(#{x}, #{y});")
  end

  @doc """
  Selects the option with the given value in the select element matching the CSS selector.
  """
  def select_option(page, selector, value) do
    page
    |> locator(selector)
    |> Locator.select_option!(value)

    page
  end

  @doc """
  Clears the field matching the CSS selector and types the value into it key by key,
  for the tests that count the key events. Cleared from a script: Playwright clears a
  field by pressing Delete, a key event of its own.
  """
  def type_in(page, selector, with: value) do
    field = locator(page, selector)
    Locator.evaluate!(field, "(field) => { field.value = ''; }")
    Locator.press_sequentially!(field, to_string(value))

    page
  end

  @doc """
  Presses the key (or a chord such as `"Control+k"`) in the page, or in the element
  matching the CSS selector.
  """
  def send_keys(page, key) do
    page
    |> Page.keyboard()
    |> Keyboard.press!(key)

    page
  end

  def send_keys(page, selector, key) do
    page
    |> locator(selector)
    |> Locator.press!(key)

    page
  end

  @doc """
  Sets a cookie for the app's URL in the page's context.
  """
  def set_cookie(page, name, value) do
    page
    |> Page.context()
    |> BrowserContext.add_cookies!([%{name: name, value: value, url: Endpoint.url()}])

    page
  end

  @doc """
  Shortens the SSE heartbeat for this browser's next stream to `interval_ms`, then
  returns the `page` so the helper can be piped.

  A stream that dies without closing is only noticed by the client's heartbeat
  watchdog, two intervals after the last heartbeat. At the production interval that
  is longer than the wait budget, so a test that kills the stream and waits for the
  reconnect asks for a shorter one.

  Scoped by cookie, so concurrently running test files are unaffected.
  """
  @spec simulate_fast_sse_heartbeat(Page.t(), pos_integer) :: Page.t()
  def simulate_fast_sse_heartbeat(page, interval_ms) do
    set_cookie(page, SSE.heartbeat_interval_cookie(), to_string(interval_ms))
  end

  @doc """
  Arms a delay on every page bundle this browser fetches from now on, then
  returns the `page` so the helper can be piped.

  A navigation shows the destination as soon as the server describes it and
  mounts it once its bundle arrives. Over a local loop those two are
  milliseconds apart, which is too narrow for a test to act in between. This
  widens the gap to `delay_ms`.

  Scoped by cookie, so concurrently running test files are unaffected.
  """
  @spec simulate_slow_page_bundle(Page.t(), pos_integer) :: Page.t()
  def simulate_slow_page_bundle(page, delay_ms) do
    set_cookie(page, SlowPageBundle.cookie(), to_string(delay_ms))
  end

  @doc """
  Arms a delay on this browser's next SSE attach, then returns the `page` so
  the helper can be piped.

  Holds the stream open long enough for a command dispatched during page boot to
  reach the server while the instance still has no `SubscriptionRegistry` entry.
  That race is real but unreproducible over a local loop, where the attach always
  wins: the client calls `Sse.connect()` synchronously at mount while the action
  queued by `init/3` is dispatched a tick later.

  Scoped by cookie, so concurrently running test files are unaffected.
  """
  @spec simulate_slow_sse_attach(Page.t(), pos_integer) :: Page.t()
  def simulate_slow_sse_attach(page, delay_ms) do
    set_cookie(page, SSE.attach_delay_cookie(), to_string(delay_ms))
  end

  @doc """
  Simulates a network blip by killing the SSE process attached to the given
  `instance_id`.

  After this call the client's `EventSource` fires `onerror` and the
  JS-driven reconnect cycle begins: backoff, then POST handshake (the
  receipts in `App.subscriptionReceiptRegistry` are re-validated), then a
  fresh `EventSource` GET that re-registers bindings via
  `SubscriptionRegistry.attach_connection`. Callers typically follow with
  `wait_for_no_subscription/2` to gate the registry GC and then
  `wait_for_subscription/2` to gate the reconnect-attach.
  """
  @spec simulate_sse_disconnect(String.t()) :: :ok
  def simulate_sse_disconnect(instance_id) do
    [{^instance_id, entry}] = :ets.lookup(SubscriptionRegistry.ets_table_name(), instance_id)
    sse_pid = entry.sse_pid

    # Killing the SSE process makes Ranch log an expected `:killed` request-process
    # exit at :error level. That line is emitted asynchronously by the connection
    # process as the exit propagates, so the capture window is held open until the
    # killed process is confirmed down rather than closing the instant
    # Process.exit/2 returns.
    ExUnit.CaptureLog.capture_log(fn ->
      ref = Process.monitor(sse_pid)
      Process.exit(sse_pid, :kill)

      receive do
        {:DOWN, ^ref, :process, ^sse_pid, _reason} -> :ok
      after
        1_000 -> :ok
      end
    end)

    :ok
  end

  @doc """
  Installs a fake clock in the page's context, which `run_for/2` advances. Time still
  passes on it as it does, so only a test that waits out a client timer needs it. Install
  it before the page is opened.
  """
  def install_clock(page) do
    page
    |> Page.clock()
    |> Clock.install!()

    page
  end

  @doc """
  Advances the page's clock (see `install_clock/1`) by `duration` ms, firing the timers
  due by then.
  """
  def run_for(page, duration) do
    page
    |> Page.clock()
    |> Clock.run_for!(duration)

    page
  end

  def sleep(page, duration) do
    Page.wait_for_timeout!(page, duration)
    page
  end

  @doc """
  Opens `page_module` in a second tab of `origin`'s browser, which shares its
  cookies and so its Hologram session. Use it to give a connection a same-session
  sibling.
  """
  def visit_as_sibling(origin, page_module, params \\ []) do
    origin
    |> Page.context()
    |> BrowserContext.new_page!()
    |> visit(page_module, params)
  end

  @doc """
  Blocks until the registry holds a connection for `instance_id`, then returns
  `instance_id`. Raises if none appears within the expect timeout.

  Scoped to one instance, unlike `wait_for_subscription/5`, which counts every
  connection holding a channel and so can be satisfied by another tab.
  """
  def wait_for_connection(instance_id) do
    wait_until(
      fn -> connection?(instance_id) end,
      "Timed out waiting for a connection for instance #{inspect(instance_id)}"
    )

    instance_id
  end

  @doc """
  Blocks until the registry no longer holds a connection for `instance_id`, then
  returns `instance_id`. Raises if the connection is still there after `max_wait_ms`.

  Takes its own limit rather than the expect timeout, because a test using it asserts
  how soon the connection goes, not only that it does.
  """
  def wait_for_no_connection(instance_id, max_wait_ms) do
    wait_until(
      fn -> !connection?(instance_id) end,
      "Connection for instance #{inspect(instance_id)} still registered after #{max_wait_ms} ms",
      timeout: max_wait_ms
    )

    instance_id
  end

  @doc """
  Blocks until no `SubscriptionRegistry` entry holds a subscription on `channel`,
  then returns the `page` so the helper can be piped. Pass a `cid` to narrow
  the wait to a single `{channel, cid}` binding - needed to gate a single-cid
  `unsubscribe` whose channel keeps other cids bound, where the channel-wide
  wait would never return. Raises if the subscription persists past
  the expect timeout.
  """
  def wait_for_no_subscription(page, channel, cid \\ nil) do
    wait_until(
      fn -> !has_subscription?(channel, cid) end,
      "Timed out waiting for subscription to drop on #{inspect(channel)} (cid: #{inspect(cid)})"
    )

    page
  end

  @doc """
  Blocks until the `page`'s own connection holds a binding on `channel` - or,
  when `cid` is given, a `{channel, cid}` binding specifically - and can receive
  broadcasts on it, then returns the `page`. Raises if it does not within
  the expect timeout.

  Resolves this browser's connection specifically. `wait_for_subscription/4`
  counts every connection in the registry, so in a single-page test a tab
  left by an earlier test on the same channel can satisfy it before this
  page's binding exists: a departed tab's SSE process is only reaped once a
  write to its dead socket fails, which may not happen until the next heartbeat.
  """
  def wait_for_own_subscription(page, channel, cid \\ nil) do
    wait_until(
      fn ->
        entry = registry_entry(page)
        entry != nil and receiving?(entry, channel, cid)
      end,
      "Timed out waiting for this page's subscription on #{inspect(channel)} (cid: #{inspect(cid)})"
    )

    page
  end

  @doc """
  Blocks until at least `count` (default 1) `SubscriptionRegistry` connections
  hold a binding on `channel` - or, when `cid` is given, a `{channel, cid}`
  binding specifically - then returns the `page` so the helper can be piped.
  Raises if the count is not reached within the expect timeout.

  Gate any broadcast whose recipients a test asserts on: subscriptions register
  asynchronously after the page mounts (handshake POST + SSE attach), and
  `Phoenix.PubSub` is fire-and-forget, so a broadcast that fires first reaches
  no one - a missed delivery, or a refute that passes vacuously because the
  asserted-on page was never there. Pass `count` > 1 to require *every*
  participating connection in a multi-page test. Pass a `cid` when several
  bindings share one connection (e.g. multiple components on one page), where a
  connection count can't tell whether a specific cid is bound.

  A connection counts once its SSE process can receive broadcasts on `channel`,
  not merely once the registry records the binding. Every connection in the
  registry counts, a departed tab from an earlier test included, so a
  single-page test on a channel other tests use gates with
  `wait_for_own_subscription/3` instead.
  """
  def wait_for_subscription(page, channel, count \\ 1, cid \\ nil) do
    wait_until(
      fn -> subscription_count(channel, cid) >= count end,
      "Timed out waiting for #{count} subscription(s) on #{inspect(channel)} (cid: #{inspect(cid)})"
    )

    page
  end

  @doc """
  Blocks until the document `mark_document/1` marked has been replaced with a new one, then
  returns the `page`.
  """
  def wait_for_unmarked_document(page) do
    Page.wait_for_function!(page, "() => globalThis.__hologramMarkedDocument !== true")

    page
  end

  @doc """
  Blocks until the `page`'s own SSE process records `user_id`, then returns
  the `page`. Gates on a handler-driven identity change (login or logout)
  having propagated to the connection before its effects are asserted - e.g.
  before broadcasting to check whether a binding was kept or dropped. Raises if
  the value does not appear within the expect timeout.

  Resolves this browser's connection specifically, so another tab of the same
  session lingering in the registry does not affect it. A departed tab's SSE
  process is only reaped once a write to its dead socket fails, which may not
  happen until the next heartbeat.
  """
  def wait_for_user_id(page, user_id) do
    wait_until(
      fn -> current_user_id(page) == user_id end,
      "Timed out waiting for connection user_id #{inspect(user_id)}"
    )

    page
  end

  defp bound?(entry, channel, cid) do
    Enum.any?(entry.bindings, fn {{ch, c}, _user_id} ->
      ch == channel and (is_nil(cid) or c == cid)
    end)
  end

  # The file the bundle at the given URL is served from, in the dir the compiler writes the bundles
  # to.
  defp bundle_file_path(bundle_url) do
    Path.join(Reflection.bundles_dir(), Path.basename(bundle_url))
  end

  defp connection?(instance_id) do
    :ets.member(SubscriptionRegistry.ets_table_name(), instance_id)
  end

  defp has_subscription?(channel, cid) do
    SubscriptionRegistry.ets_table_name()
    |> :ets.tab2list()
    |> Enum.any?(fn {_instance_id, entry} -> bound?(entry, channel, cid) end)
  end

  defp locator(page, selector) when is_binary(selector), do: Page.locator(page, selector)
  defp locator(_page, %Locator{} = locator), do: locator

  # Whether the connection holds the binding and its SSE process has subscribed to
  # the channel's PubSub topic. The registry records a binding before the SSE
  # process subscribes, which it does only when it handles the `{:sub, channel}`
  # message the registry sends it, and a broadcast in between reaches no one.
  defp receiving?(entry, channel, cid) do
    bound?(entry, channel, cid) and
      Realtime.channel_topic(channel) in Registry.keys(Hologram.PubSub, entry.sse_pid)
  end

  defp registry_entry(page) do
    instance_id = current_instance_id(page)

    case :ets.lookup(SubscriptionRegistry.ets_table_name(), instance_id) do
      [{^instance_id, entry}] -> entry
      [] -> nil
    end
  end

  defp subscription_count(channel, cid) do
    SubscriptionRegistry.ets_table_name()
    |> :ets.tab2list()
    |> Enum.count(fn {_instance_id, entry} -> receiving?(entry, channel, cid) end)
  end

  # A locator of the visible elements matching the CSS selector, narrowed by `text:` to the
  # ones containing it, case-sensitively.
  defp visible(page, selector, opts) do
    locator =
      page
      |> locator(selector)
      |> Locator.filter(visible: true)

    case opts[:text] do
      nil -> locator
      text when is_binary(text) -> Locator.filter(locator, has_text: ~r/#{Regex.escape(text)}/)
      regex -> Locator.filter(locator, has_text: regex)
    end
  end

  # Polls `fun` until it returns a truthy value, failing with `message` after the expect
  # timeout, or `timeout:`.
  defp wait_until(fun, message, opts \\ []) do
    Expect.poll!(fun, &assert(&1, message), opts)
  end
end
