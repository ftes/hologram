defmodule HologramFeatureTests.SecurityTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Security.Page1
  alias HologramFeatureTests.Security.Page2
  alias HologramFeatureTests.Security.Page3
  alias HologramFeatureTests.Security.Page4
  alias HologramFeatureTests.Security.Page5

  describe "CSRF protection" do
    test "initial page request is successful", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Test Action 1")
      |> assert_text("#result", "101")
    end

    test "subsequent page request is successful", %{page: page} do
      page
      |> visit(Page1)
      |> click_link("Navigate to Page 2")
      |> assert_page(Page2)
      |> click_button("Test Action 2")
      |> assert_text("#result", "301")
    end

    test "command request is successful when CSRF token is valid", %{page: page} do
      page
      |> visit(Page1)
      |> click_button("Test Command")
      |> assert_text("#result", "201")
    end

    test "command request fails when CSRF token is invalid", %{page: page} do
      assert_js_error page,
                      "command failed: 403",
                      fn ->
                        page
                        |> visit(Page1)
                        |> execute_script(
                          "globalThis.Hologram.csrfToken = 'invalid-token-12345';"
                        )
                        |> click_button("Test Command")
                      end
    end

    test "command request fails when CSRF token is not present", %{page: page} do
      assert_js_error page,
                      "command failed: 403",
                      fn ->
                        page
                        |> visit(Page1)
                        |> execute_script("delete globalThis.Hologram.csrfToken;")
                        |> click_button("Test Command")
                      end
    end
  end

  describe "XSS protection" do
    test "text nodes escaping", %{page: page} do
      page
      |> visit(Page3)
      # no escaping
      |> assert_script_result("return window.xss1", true)
      # HTML entities
      |> assert_script_result("return window.xss2", nil)
      # server-side escaping
      |> assert_script_result("return window.xss3", nil)
      |> click_button("Show script #4")
      # client-side escaping
      |> assert_script_result("return window.xss4", nil)
    end

    test "attributes escaping", %{page: page} do
      page
      |> visit(Page4)
      # server-side escaping
      |> assert_script_result("return window.xss1", nil)
      |> click_button("Show div #2")
      # client-side escaping
      |> assert_script_result("return window.xss2", nil)
    end

    test "form inputs controlled attributes are not escaped", %{page: page} do
      page
      |> visit(Page5)
      |> click_button("Set values")
      |> assert_input_value("#text_input", "a < b")
      |> assert_input_value("#email_input", "c < d")
      |> assert_input_value("#textarea_input", "d < e")
      |> assert_input_value("#select_input", "b < c")
    end
  end
end
