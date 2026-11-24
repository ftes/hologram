defmodule HologramEcosystemTests.Helpers do
  @moduledoc """
  Browser helpers for the tests: page-returning, so they pipe.
  """

  alias Playwright.Expect
  alias Playwright.Locator
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
  Clicks the element matching the CSS selector.
  """
  def click(page, selector) do
    page
    |> Page.locator(selector)
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
end
