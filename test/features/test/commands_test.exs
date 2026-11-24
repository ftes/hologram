defmodule HologramFeatureTests.CommandsTest do
  use HologramFeatureTests.TestCase, async: true
  alias HologramFeatureTests.Commands.LateReplyDestinationPage
  alias HologramFeatureTests.Commands.LateReplyPage
  alias HologramFeatureTests.CommandsPage

  describe "layout command" do
    test "triggered from layout (default target)", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='layout_command_1']")
      |> assert_text(
        "#layout_result",
        ~r/\{:layout_command_1, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from page", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='layout_command_2']")
      |> assert_text(
        "#layout_result",
        ~r/\{:layout_command_2, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from component", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='layout_command_3']")
      |> assert_text(
        "#layout_result",
        ~r/\{:layout_command_3, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "page command" do
    test "triggered from layout", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='page_command_1']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_command_1, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from page (default target)", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='page_command_2']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_command_2, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from component", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='page_command_3']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_command_3, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "component command" do
    test "triggered from layout", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='component_2_command_1']")
      |> assert_text(
        "#component_2_result",
        ~r/\{:component_2_command_1, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from page", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='component_2_command_2']")
      |> assert_text(
        "#component_2_result",
        ~r/\{:component_2_command_2, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from component (default target)", %{page: page} do
      page
      |> visit(CommandsPage)
      |> click("button[id='component_2_command_3']")
      |> assert_text(
        "#component_2_result",
        ~r/\{:component_2_command_3, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "server struct mutations" do
    # Covered in preceding (layout command, page command, component command) tests:
    # feature "next_action"
  end

  # Each slow command sleeps 3 seconds before replying, and each drop test waits 3.5 after
  # navigating, so the reply arrives on the page navigated to. A component or page reply that
  # survives raises there, which fails the test (see track_js_errors/1). A layout reply that
  # survives raises nothing, so its tests read the layout's result.
  describe "reply after navigation" do
    # Positive control for the drops below: the same button's reply lands when the user stays put,
    # proving the fixture sends a real command whose reply arrives.
    test "a slow command's reply lands when the user stays on the page", %{page: page} do
      page
      |> visit(LateReplyPage)
      |> click_button("Run slow component command")
      |> assert_text("#component_result", "nil")
      |> assert_text("#component_result", ~s/"component_reply_ran"/)
    end

    # The component is mounted on the late reply page only, so a surviving reply targets a cid the
    # destination's registry does not hold and raises there.
    test "navigating to another page drops the reply of a command targeting a component",
         %{page: page} do
      page
      |> visit(LateReplyPage)
      |> click_button("Run slow component command")
      |> click_link("Destination link")
      |> assert_page(LateReplyDestinationPage)
      |> sleep(3_500)
      |> assert_text("Late reply destination title")
    end

    # The layout cid resolves on the destination too, to a new instance of the same module, so a
    # surviving reply would not raise: it would write the destination layout's result.
    test "navigating to another page drops the reply of a command targeting the layout",
         %{page: page} do
      page
      |> visit(LateReplyPage)
      |> click_button("Run slow layout command")
      |> click_link("Destination link")
      |> assert_page(LateReplyDestinationPage)
      |> sleep(3_500)
      |> assert_text("#layout_result", "nil")
    end

    # The page cid resolves on the destination too, but to a module that defines no action at all,
    # so a surviving reply raises there.
    test "navigating to another page drops the reply of a command targeting the page",
         %{page: page} do
      page
      |> visit(LateReplyPage)
      |> click_button("Run slow page command")
      |> click_link("Destination link")
      |> assert_page(LateReplyDestinationPage)
      |> sleep(3_500)
      |> assert_text("Late reply destination title")
    end

    # Going back restores the registry from a snapshot rather than from mount data, so the reply
    # arrives after a transition that reached the epoch bump down a different path.
    test "going back to another page drops the reply of a command targeting the layout",
         %{page: page} do
      page
      |> visit(LateReplyDestinationPage)
      |> click_link("Late reply link")
      |> assert_page(LateReplyPage)
      |> click_button("Run slow layout command")
      |> go_back()
      |> assert_page(LateReplyDestinationPage)
      |> sleep(3_500)
      |> assert_text("#layout_result", "nil")
    end
  end
end
