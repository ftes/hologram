defmodule App1.HomePageTest do
  use App1.TestCase, async: true

  test "renders content defined in the endpoint app", %{page: page} do
    page
    |> visit(App1.HomePage)
    |> assert_text("Umbrella home page")
  end

  test "runs an action calling a sibling app's code", %{page: page} do
    page
    |> visit(App1.HomePage)
    |> click_button("Fetch app_2 message")
    |> assert_text("#result", "Hello from app_2!")
  end
end
