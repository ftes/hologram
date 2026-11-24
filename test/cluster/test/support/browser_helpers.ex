defmodule HologramClusterTests.BrowserHelpers do
  @moduledoc """
  Browser helpers for the tests: page-returning, so they pipe.
  """

  alias Playwright.BrowserContext
  alias Playwright.Expect
  alias Playwright.Page

  @doc """
  Asserts that the page, or the element matching the CSS selector, shows the text.
  """
  def assert_text(page, text), do: assert_text(page, "body", text)

  def assert_text(page, selector, text) do
    page
    |> Page.locator(selector)
    |> Expect.to_contain_text!(text, use_inner_text: true)

    page
  end

  @doc """
  Sets a cookie for the base URL in the page's context.
  """
  def set_cookie(page, name, value) do
    page
    |> Page.context()
    |> BrowserContext.add_cookies!([
      %{name: name, value: value, url: Playwright.Test.info().use[:base_url]}
    ])

    page
  end
end
