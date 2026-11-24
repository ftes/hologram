defmodule HologramCowboyTests.CommandTest do
  use HologramCowboyTests.TestCase, async: false

  alias HologramCowboyTests.CommandPage

  test "a command round-trips", %{page: page} do
    page
    |> visit(CommandPage)
    |> click("#run")
    |> assert_text("#result", "answered with 42")
  end
end
