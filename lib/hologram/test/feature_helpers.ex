defmodule Hologram.Test.FeatureHelpers do
  @moduledoc false

  # This is not public API yet - it is consumed by the Hologram feature tests
  # and umbrella tests apps.
  # TODO: consider promoting to public API (docs, stable surface), so that
  # client apps can use these helpers in their own Playwright suites.

  # playwright_ex is not a Hologram dependency - client apps that use these
  # helpers bring their own. This lets the module compile without it present.
  @compile {:no_warn_undefined,
            [Playwright.BrowserContext, Playwright.Expect, Playwright.Page, Playwright.WebError]}

  alias Hologram.Router

  # Waits in the page: the mounted page is the expected one and both server
  # connections are up. Polled by the browser, so it settles as soon as they do.
  @mounted_script """
  (page) =>
    globalThis.Hologram?.mountedPage === page &&
      globalThis.Hologram["wsConnected?"] === true &&
      globalThis.Hologram["sseConnected?"] === true
  """

  @doc """
  Asserts that the page has navigated to the given page: blocks until the
  current path matches the page's route, the Hologram client runtime has
  mounted the page, and its server connections are established.
  """
  @spec assert_page(struct, module, keyword) :: struct
  def assert_page(page, page_module, params \\ []) do
    path = Router.Helpers.page_path(page_module, params)

    Playwright.Page.wait_for_url!(page, &(&1.path == path))
    wait_for_page_mounting(page, page_module)
  end

  @doc """
  Runs `fun` and returns the first uncaught error it raised in the page, which
  `track_js_errors/1` then doesn't fail the test on. Waits for the error, as the
  page may raise it after `fun` returns.
  """
  @spec take_js_error((-> any)) :: Exception.t()
  def take_js_error(fun) do
    errors = Process.get(:hologram_js_errors)
    Agent.update(errors, &%{&1 | expecting?: true})

    try do
      fun.()

      Playwright.Expect.poll!(
        fn -> Agent.get(errors, & &1.expected) end,
        &if(&1 == [], do: ExUnit.Assertions.flunk("no uncaught JavaScript error"))
      )

      errors
      |> Agent.get_and_update(&{&1.expected, %{&1 | expected: []}})
      |> List.last()
    after
      Agent.update(errors, &%{&1 | expecting?: false})
    end
  end

  @doc """
  Fails the test on an uncaught error in any page of the context, unless it is
  expected with `take_js_error/1`. The contexts of a test share one record, which
  is checked again at the test's end: a listener can't fail a test that has
  finished.
  """
  @spec track_js_errors(struct) :: :ok
  def track_js_errors(context) do
    errors = js_errors()

    Playwright.BrowserContext.on(context, :web_error, fn web_error ->
      error = Playwright.WebError.error(web_error)

      unless record_js_error(errors, error) do
        ExUnit.Assertions.flunk("uncaught JavaScript error: #{Exception.message(error)}")
      end
    end)

    :ok
  end

  @doc """
  Visits the given path or URL in the page, without waiting for any Hologram
  page mounting or server connections.
  """
  @spec visit(struct, String.t()) :: struct
  def visit(page, path_or_url) when is_binary(path_or_url) do
    Playwright.Page.goto!(page, path_or_url)
    page
  end

  @doc """
  Visits the page module in the page and blocks until the Hologram client
  runtime has mounted it and established its server connections, so that
  subsequent interactions can't race the runtime's event listener attachment.
  """
  @spec visit(struct, module, keyword) :: struct
  def visit(page, page_module, params \\ []) do
    path = Router.Helpers.page_path(page_module, params)

    Playwright.Page.goto!(page, path)
    wait_for_page_mounting(page, page_module)
  end

  # The test's record of uncaught errors, started with its check at the test's end.
  defp js_errors do
    case Process.get(:hologram_js_errors) do
      nil ->
        # Unlinked, so the on_exit callback can still read it once the test process is gone.
        {:ok, errors} = Agent.start(fn -> %{expecting?: false, expected: [], unexpected: []} end)
        Process.put(:hologram_js_errors, errors)
        ExUnit.Callbacks.on_exit(fn -> check_js_errors(errors) end)
        errors

      errors ->
        errors
    end
  end

  defp check_js_errors(errors) do
    %{unexpected: unexpected} = Agent.get(errors, & &1)
    Agent.stop(errors)

    if unexpected != [] do
      messages =
        unexpected
        |> Enum.reverse()
        |> Enum.map(&Exception.message/1)

      ExUnit.Assertions.flunk("uncaught JavaScript errors: #{inspect(messages)}")
    end
  end

  # Records the error, and returns whether it was expected. An error after the record
  # is gone (the test has ended) counts as unexpected.
  defp record_js_error(errors, error) do
    Agent.get_and_update(errors, fn
      %{expecting?: true} = state -> {true, %{state | expected: [error | state.expected]}}
      state -> {false, %{state | unexpected: [error | state.unexpected]}}
    end)
  catch
    :exit, _reason -> false
  end

  defp wait_for_page_mounting(page, page_module) do
    Playwright.Page.wait_for_function!(page, @mounted_script, inspect(page_module))

    page
  end
end
