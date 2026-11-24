defmodule HologramFeatureTests.Events.ScrollTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.ScrollPage

  test "scrolling an element dispatches with its scroll position", %{page: page} do
    page
    |> visit(ScrollPage)
    |> execute_script(
      "const el = document.getElementById('scroller'); el.scrollLeft = 120; el.scrollTop = 250;"
    )
    |> assert_text("#element_result", "{120.0, 250.0}")
  end

  test "scrolling the page dispatches to a window binding", %{page: page} do
    page
    |> visit(ScrollPage)
    |> execute_script("window.scrollTo(180, 300);")
    |> assert_text("#window_result", "{180.0, 300.0}")
  end

  test "scrolling the page dispatches to a document binding", %{page: page} do
    page
    |> visit(ScrollPage)
    |> execute_script("window.scrollTo(140, 220);")
    |> assert_text("#document_result", "{140.0, 220.0}")
  end
end
