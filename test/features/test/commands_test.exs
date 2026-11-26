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

  # Hold the real reply in the browser until the destination is mounted. A component or page
  # reply that survives raises there; a surviving layout reply instead changes its result.
  describe "reply after navigation" do
    # Positive control for the drops below: the same button's reply lands when the user stays put,
    # proving the fixture sends a real command whose reply arrives.
    test "a slow command's reply lands when the user stays on the page", %{page: page} do
      page
      |> visit(LateReplyPage)
      |> hold_command_reply("Run slow component command")
      |> assert_text("#component_result", "nil")
      |> release_command_reply()
      |> assert_text("#component_result", ~s/"component_reply_ran"/)
    end

    # The component is mounted on the late reply page only, so a surviving reply targets a cid the
    # destination's registry does not hold and raises there.
    test "navigating to another page drops the reply of a command targeting a component",
         %{page: page} do
      page
      |> visit(LateReplyPage)
      |> hold_command_reply("Run slow component command")
      |> click_link("Destination link")
      |> assert_page(LateReplyDestinationPage)
      |> release_command_reply()
      |> assert_text("Late reply destination title")
    end

    # The layout cid resolves on the destination too, to a new instance of the same module, so a
    # surviving reply would not raise: it would write the destination layout's result.
    test "navigating to another page drops the reply of a command targeting the layout",
         %{page: page} do
      page
      |> visit(LateReplyPage)
      |> hold_command_reply("Run slow layout command")
      |> click_link("Destination link")
      |> assert_page(LateReplyDestinationPage)
      |> release_command_reply()
      |> assert_text("#layout_result", ~r/^nil$/)
    end

    # The page cid resolves on the destination too, but to a module that defines no action at all,
    # so a surviving reply raises there.
    test "navigating to another page drops the reply of a command targeting the page",
         %{page: page} do
      page
      |> visit(LateReplyPage)
      |> hold_command_reply("Run slow page command")
      |> click_link("Destination link")
      |> assert_page(LateReplyDestinationPage)
      |> release_command_reply()
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
      |> hold_command_reply("Run slow layout command")
      |> go_back()
      |> assert_page(LateReplyDestinationPage)
      |> release_command_reply()
      |> assert_text("#layout_result", ~r/^nil$/)
    end
  end

  defp hold_command_reply(page, button) do
    Page.evaluate!(page, """
    () => {
      const fetch = window.fetch;
      const barrier = window.commandReplyBarrier = {};
      const held = new Promise((resolve) => { barrier.release = resolve; });
      barrier.consumed = new Promise((resolve) => { barrier.finish = resolve; });

      window.fetch = async (url, options) => {
        if (url !== "/hologram/command") return fetch(url, options);

        window.fetch = fetch;
        const response = await fetch(url, options);
        const payload = await response.clone().json();

        if (!response.ok || payload.status !== 1 || payload.chunks.length !== 0) {
          throw new Error("Expected a successful command reply with no chunks to load");
        }

        response.json = async () => {
          // The command continuation schedules its action on a timer. The first
          // task runs after that continuation; the second runs after its timer.
          setTimeout(() => setTimeout(barrier.finish, 0), 0);
          return payload;
        };

        barrier.ready = true;
        await held;
        return response;
      };
    }
    """)

    click_button(page, button)
    Page.wait_for_function!(page, "() => window.commandReplyBarrier.ready")
    page
  end

  defp release_command_reply(page) do
    Page.evaluate!(page, """
    () => {
      const barrier = window.commandReplyBarrier;
      barrier.release();
      return barrier.consumed;
    }
    """)

    page
  end
end
