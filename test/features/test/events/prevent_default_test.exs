defmodule HologramFeatureTests.Events.PreventDefaultTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.PreventDefaultPage

  test "prevent_default blocks the native default while a plain binding allows it",
       %{page: page} do
    page
    |> visit(PreventDefaultPage)
    |> send_keys("#prevented_input", "Enter")
    |> assert_text("#result", "{true, false, false, false}")
    |> send_keys("#plain_input", "Enter")
    |> assert_text("#result", "{true, false, true, true}")
  end
end
