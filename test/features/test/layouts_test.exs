defmodule HologramFeatureTests.LayoutsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Layouts.NoPropsPage
  alias HologramFeatureTests.Layouts.PropsPassedExplicitelyPage
  alias HologramFeatureTests.Layouts.PropsPassedImplicitelyPage

  test "no props", %{page: page} do
    page
    |> visit(NoPropsPage)
    |> assert_text("#layout_result", ~s'%{cid: "layout"}')
  end

  test "props passed explicitely", %{page: page} do
    page
    |> visit(PropsPassedExplicitelyPage)
    |> assert_text("#layout_result", ~s'%{a: "abc", b: 123, cid: "layout"}')
  end

  test "props passed implicitely", %{page: page} do
    page
    |> visit(PropsPassedImplicitelyPage)
    |> assert_text("#layout_result", ~s'%{a: "abc", b: 123, cid: "layout"}')
  end
end
