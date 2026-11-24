defmodule HologramFeatureTests.Events.StopPropagationTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.StopPropagationPage

  test "stop_propagation keeps the outer binding from firing while a plain binding bubbles",
       %{page: page} do
    page
    |> visit(StopPropagationPage)
    |> click("#plain_button")
    |> assert_text("#result", "{true, true, false, false}")
    |> click("#stopped_button")
    |> assert_text("#result", "{true, true, true, false}")
  end
end
