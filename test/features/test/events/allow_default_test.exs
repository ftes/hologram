defmodule HologramFeatureTests.Events.AllowDefaultTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.AllowDefault.Page1
  alias HologramFeatureTests.Events.AllowDefault.Page2

  test "allow_default lets the native form submission proceed while a plain binding prevents it",
       %{page: page} do
    page
    |> visit(Page1)
    |> click("#prevented_submit")
    |> assert_text("#result", "{false, true}")
    |> click("#allowed_submit")
    |> assert_page(Page2)
  end
end
