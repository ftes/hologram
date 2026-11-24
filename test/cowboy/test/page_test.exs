defmodule HologramCowboyTests.PageTest do
  use HologramCowboyTests.TestCase, async: false

  alias HologramCowboyTests.PlainPage

  test "a page request is served", %{page: page} do
    page
    |> visit(PlainPage)
    |> assert_text("#text", "Served through Cowboy")
  end
end
