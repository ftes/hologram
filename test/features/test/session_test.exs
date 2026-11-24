defmodule HologramFeatureTests.SessionTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Session.Page1
  alias HologramFeatureTests.Session.Page2
  alias HologramFeatureTests.Session.Page3
  alias HologramFeatureTests.Session.Page4
  alias HologramFeatureTests.Session.Page5
  alias HologramFeatureTests.Session.Page6

  describe "page init session handling" do
    test "write to session and read from session", %{page: page} do
      assert cookies(page) == []

      visit(page, Page1)

      assert [%{name: "phoenix_session"}] = cookies(page)

      page
      |> visit(Page2)
      |> assert_text("session_value = :abc")
    end

    test "delete from session", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(Page1)
      |> visit(Page3)
      |> visit(Page2)
      |> assert_text("session_value = nil")
    end
  end

  describe "command session handling" do
    test "write to session", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(Page4)
      |> click_button("Write to session")
      |> assert_text("command_executed? = true")

      assert [%{name: "phoenix_session"}] = cookies(page)

      page
      |> visit(Page2)
      |> assert_text("session_value = :abc")
    end

    test "read from session", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(Page1)
      |> visit(Page5)
      |> click_button("Read from session")
      |> assert_text("command_executed? = true, session_value = :abc")
    end

    test "delete from session", %{page: page} do
      assert cookies(page) == []

      page
      |> visit(Page1)
      |> visit(Page6)
      |> click_button("Delete from session")
      |> assert_text("command_executed? = true")
      |> visit(Page2)
      |> assert_text("session_value = nil")
    end
  end
end
