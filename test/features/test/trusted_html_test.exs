defmodule HologramFeatureTests.TrustedHtmlTest do
  use HologramFeatureTests.TestCase, async: true

  alias Hologram.Router.Helpers, as: RouterHelpers
  alias HologramFeatureTests.TrustedHtml.Page1
  alias HologramFeatureTests.TrustedHtml.Page2
  alias HologramFeatureTests.TrustedHtml.Page3
  alias HologramFeatureTests.TrustedHtml.Page4
  alias HologramFeatureTestsWeb.Endpoint

  @no_warnings "return window.trustedHtmlWarnings.length === 0;"

  # The range comments follow the content directly, so the exact match shows the script is gone.
  test "the server renders trusted HTML into the page, normalized and without its scripts" do
    conn =
      :get
      |> Plug.Test.conn(RouterHelpers.page_path(Page1))
      |> Endpoint.call(Endpoint.init([]))

    assert conn.resp_body =~
             ~s(<div id="content"><!--hologram-html--><p class="trusted">Hello <strong>world</strong></p><!--/hologram-html--></div>)

    assert conn.resp_body =~
             ~s(<div id="malformed"><!--hologram-html--><div class="unclosed"><em>open</em></div><!--/hologram-html--></div>)

    assert conn.resp_body =~
             ~s(<table id="direct_table"><!--hologram-html--><tbody><tr><td>direct row 1</td></tr></tbody><!--/hologram-html--></table>)
  end

  test "renders trusted HTML as markup, without its scripts", %{page: page} do
    page
    |> visit(Page1)
    |> assert_text("#content p.trusted strong", "world")
    |> assert_none("#content script")
    |> assert_script_result(@no_warnings, true)
  end

  test "keeps malformed trusted HTML to its place", %{page: page} do
    page
    |> visit(Page1)
    |> assert_text("#malformed > div.unclosed > em", "open")
    |> assert_text("#malformed + p#after_malformed", "after")
    |> assert_script_result(@no_warnings, true)
  end

  test "renders trusted table rows inside the table", %{page: page} do
    page
    |> visit(Page1)
    |> assert_text("#rows_table > tbody#rows > tr > td", "row 1")
    |> assert_text("#direct_table > tbody > tr > td", "direct row 1")
    |> assert_script_result(@no_warnings, true)
  end

  test "an action replaces trusted HTML, without its scripts", %{page: page} do
    page
    |> visit(Page1)
    |> click_button("Replace content")
    |> assert_text("#content p.replaced em", "content")
    |> refute_has("#content p.trusted")
    |> assert_none("#content script")
  end

  test "an action replaces trusted table rows", %{page: page} do
    page
    |> visit(Page1)
    |> click_button("Add row")
    |> assert_text("#rows > tr:nth-child(2) > td", "row 2")
    |> assert_has("#rows > tr", count: 2)
  end

  test "an action replaces trusted table rows placed directly in a table", %{page: page} do
    page
    |> visit(Page1)
    |> click_button("Add direct row")
    |> assert_text("#direct_table > tbody > tr:nth-child(2) > td", "direct row 2")
    |> assert_has("#direct_table > tbody > tr", count: 2)
    |> refute_has("#direct_table > tr")
  end

  test "renders trusted HTML on a page navigated to, without its scripts", %{page: page} do
    page
    |> visit(Page1)
    |> click_link("Page 2 link")
    |> assert_page(Page2)
    |> assert_text("#content p.navigated b", "page")
    |> assert_none("#content script")
  end

  # The browser caps the console entry an uncaught error writes, eliding the message well before
  # the page module's name ends, so only the start of the message is matched.
  test "raises when the browser moves trusted HTML out of place", %{page: page} do
    # Visited by path, since the page never mounts.
    assert_js_error(page, "trusted HTML rendered in HologramFeatureTests", fn ->
      visit(page, Page3.__route__())
    end)
  end

  test "keeps trusted HTML something else changed before Hologram started, and warns", %{
    page: page
  } do
    warned = """
    return window.trustedHtmlWarnings.length === 1 &&
      window.trustedHtmlWarnings[0].startsWith(
        "Hologram: the page's nodes for trusted HTML rendered in HologramFeatureTests.TrustedHtml.Page4 differ"
      );
    """

    page
    |> visit(Page4)
    |> assert_text("#content b", "changed")
    |> assert_script_result(warned, true)
    |> click_button("Replace content")
    |> assert_text("#content i", "replaced")
    |> refute_has("#content b")
  end
end
