defmodule HologramFeatureTests.ServerCreatedStructsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.CallGraph.ServerCreatedStructsPage
  alias HologramFeatureTests.StructBroadcaster

  @channel :server_created_structs

  test "struct created in broadcast params renders on the client", %{page: page} do
    page = visit(page, ServerCreatedStructsPage)

    wait_for_subscription(page, @channel)

    StructBroadcaster.broadcast_struct(@channel)

    assert_text(page, "#broadcast-result", "broadcast struct(created in broadcast)")
  end

  test "struct created in command renders on the client", %{page: page} do
    page
    |> visit(ServerCreatedStructsPage)
    |> click_button("Load struct")
    |> assert_text("#command-result", "command struct(created in command)")
  end

  test "struct created in server init renders after client re-render", %{page: page} do
    page
    |> visit(ServerCreatedStructsPage)
    |> assert_text("#init-result", "struct(created in init)")
    |> click_button("Relabel")
    |> assert_text("#label", "relabeled")
    |> assert_text("#init-result", "struct(created in init)")
  end
end
