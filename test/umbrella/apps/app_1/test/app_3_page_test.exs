defmodule App3.PageTest do
  use App1.TestCase, async: true

  test "renders a page defined in a sibling library app", %{page: page} do
    page
    |> visit(App3.Page)
    |> assert_text("#message", "Hello from app_3!")
  end
end
