defmodule HologramFeatureTests.Events.MouseMoveTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.Events.MouseMovePage

  test "mouse move", %{page: page} do
    coord_regex = "[1-9][0-9]*\\.[0-9]+"

    page
    |> visit(MouseMovePage)
    |> hover("#my_div")

    # Hovering moves the mouse to the element's center; this moves it on from there.
    %{"x" => x, "y" => y} =
      script_result(page, """
      const rect = document.getElementById("my_div").getBoundingClientRect();
      return {x: rect.x + rect.width / 2 + 10, y: rect.y + rect.height / 2 + 20};
      """)

    page
    |> Page.mouse()
    |> Mouse.move!(x, y)

    assert_text(
      page,
      "#result",
      ~r/%\{event: %\{client_x: #{coord_regex}, client_y: #{coord_regex}, movement_x: #{coord_regex}, movement_y: #{coord_regex}, offset_x: #{coord_regex}, offset_y: #{coord_regex}, page_x: #{coord_regex}, page_y: #{coord_regex}, screen_x: #{coord_regex}, screen_y: #{coord_regex}\}\}/
    )
  end
end
