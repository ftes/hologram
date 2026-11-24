defmodule HologramFeatureTests.CookiesTest do
  use HologramFeatureTests.TestCase, async: true

  alias Hologram.Runtime.Cookie
  alias HologramFeatureTests.Cookies.Page1
  alias HologramFeatureTests.Cookies.Page2
  alias HologramFeatureTests.Cookies.Page3
  alias HologramFeatureTests.Cookies.Page4
  alias HologramFeatureTests.Cookies.Page5
  alias HologramFeatureTests.Cookies.Page6
  alias HologramFeatureTests.EmptyPage

  describe "page init cookies handling" do
    test "write cookie with default settings", %{page: page} do
      assert cookies(page) == []

      visit(page, Page3)

      value = Cookie.encode("cookie_value")

      assert [
               %{
                 domain: "localhost",
                 httpOnly: true,
                 name: "cookie_key",
                 path: "/",
                 sameSite: "Lax",
                 secure: true,
                 value: ^value
               },
               %{name: "phoenix_session"}
             ] = cookies(page)
    end

    test "write cookie with custom settings", %{page: page} do
      assert cookies(page) == []

      visit(page, Page4)

      path = Page4.__route__()
      value = Cookie.encode("cookie_value")

      assert [
               %{
                 domain: "localhost",
                 httpOnly: false,
                 name: "cookie_key",
                 path: ^path,
                 sameSite: "Strict",
                 secure: false,
                 value: ^value
               },
               %{name: "phoenix_session"}
             ] = cookies(page)
    end

    test "read string-encoded cookie", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(EmptyPage)
      |> set_cookie("cookie_key", "cookie_value")
      |> visit(Page1)
      |> assert_text("cookie_value")
    end

    test "read Hologram-encoded cookie", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(EmptyPage)
      |> set_cookie("cookie_key", Cookie.encode(%{a: 1, b: 2}))
      |> visit(Page2)
      |> assert_text("%{a: 1, b: 2, c: 3}")
    end

    test "delete cookie", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(EmptyPage)
      |> set_cookie("cookie_key", "cookie_value")
      |> visit(Page5)

      assert [%{name: "phoenix_session"}] = cookies(page)
    end
  end

  describe "command cookies handling" do
    test "write cookie with default settings", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(Page6)
      |> click_button("Write cookie with default settings")
      |> assert_text("command_executed? = true")

      value = Cookie.encode("default_settings_cookie_value")

      assert [
               %{
                 domain: "localhost",
                 httpOnly: true,
                 name: "default_settings_cookie_key",
                 path: "/",
                 sameSite: "Lax",
                 secure: true,
                 value: ^value
               },
               %{name: "phoenix_session"}
             ] = cookies(page)
    end

    test "write cookie with custom settings", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(Page6)
      |> click_button("Write cookie with custom settings")
      |> assert_text("command_executed? = true")

      path = Page6.__route__()
      value = Cookie.encode("custom_settings_cookie_value")

      assert [
               %{
                 domain: "localhost",
                 httpOnly: false,
                 name: "custom_settings_cookie_key",
                 path: ^path,
                 sameSite: "Strict",
                 secure: false,
                 value: ^value
               },
               %{name: "phoenix_session"}
             ] = cookies(page)
    end

    test "read string-encoded cookie", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(EmptyPage)
      |> set_cookie("string_encoded_cookie_key", "string_encoded_cookie_value")
      |> visit(Page6)
      |> click_button("Read string-encoded cookie")
      |> assert_text(~s'command_executed? = true, cookie_value = "string_encoded_cookie_value"')
    end

    test "read Hologram-encoded cookie", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(EmptyPage)
      |> set_cookie("hologram_encoded_cookie_key", Cookie.encode(%{a: 1, b: 2}))
      |> visit(Page6)
      |> click_button("Read Hologram-encoded cookie")
      |> assert_text(~s'command_executed? = true, cookie_value = %{a: 1, b: 2, c: 3}')
    end

    test "delete cookie", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(EmptyPage)
      |> set_cookie("cookie_key", "cookie_value")
      |> visit(Page6)
      |> click_button("Delete cookie")
      |> assert_text(~s'command_executed? = true')

      assert [%{name: "phoenix_session"}] = cookies(page)
    end
  end
end
