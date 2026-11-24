defmodule HologramFeatureTests.ActionsTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Actions.LateResultDestinationPage
  alias HologramFeatureTests.Actions.LateResultPage
  alias HologramFeatureTests.Actions.Page1
  alias HologramFeatureTests.Actions.Page10
  alias HologramFeatureTests.Actions.Page11
  alias HologramFeatureTests.Actions.Page12
  alias HologramFeatureTests.Actions.Page13
  alias HologramFeatureTests.Actions.Page14
  alias HologramFeatureTests.Actions.Page15
  alias HologramFeatureTests.Actions.Page16
  alias HologramFeatureTests.Actions.Page17
  alias HologramFeatureTests.Actions.Page18
  alias HologramFeatureTests.Actions.Page19
  alias HologramFeatureTests.Actions.Page2
  alias HologramFeatureTests.Actions.Page20
  alias HologramFeatureTests.Actions.Page21
  alias HologramFeatureTests.Actions.Page22
  alias HologramFeatureTests.Actions.Page23
  alias HologramFeatureTests.Actions.Page24
  alias HologramFeatureTests.Actions.Page25
  alias HologramFeatureTests.Actions.Page26
  alias HologramFeatureTests.Actions.Page27
  alias HologramFeatureTests.Actions.Page28
  alias HologramFeatureTests.Actions.Page29
  alias HologramFeatureTests.Actions.Page3
  alias HologramFeatureTests.Actions.Page4
  alias HologramFeatureTests.Actions.Page5
  alias HologramFeatureTests.Actions.Page6
  alias HologramFeatureTests.Actions.Page7
  alias HologramFeatureTests.Actions.Page8
  alias HologramFeatureTests.Actions.Page9

  describe "syntax" do
    test "text syntax", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_1']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_1, %\{event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "expression shorthand syntax without params", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_2']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_2, %\{event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "expression shorthand syntax with params", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_3']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_3, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "expression longhand syntax", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_4']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_4, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "multi-chunk syntax", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_5']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_5, %\{event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "layout action" do
    test "triggered from layout (default target)", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='layout_action_1']")
      |> assert_text(
        "#layout_result",
        ~r/\{:layout_action_1, %\{event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from page", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='layout_action_2']")
      |> assert_text(
        "#layout_result",
        ~r/\{:layout_action_2, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from component", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='layout_action_3']")
      |> assert_text(
        "#layout_result",
        ~r/\{:layout_action_3, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "page action" do
    # Covered in preceding (syntax) tests:
    # feature "triggered from page (default target)"

    test "triggered from layout", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_6']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_6, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from component", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_7']")
      |> assert_text(
        "#page_result",
        ~r/\{:page_action_7, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "component action" do
    test "triggered from layout", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='component_1_action_3']")
      |> assert_text(
        "#component_1_result",
        ~r/\{:component_1_action_3, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from page", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='component_1_action_2']")
      |> assert_text(
        "#component_1_result",
        ~r/\{:component_1_action_2, %\{a: 1, b: 2, event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end

    test "triggered from component (default target)", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='component_1_action_1']")
      |> assert_text(
        "#component_1_result",
        ~r/\{:component_1_action_1, %\{event: %\{.*page_x: [0-9]+\.[0-9]+.*\}\}\}/
      )
    end
  end

  describe "component struct mutations" do
    test "emitted context", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_8']")
      |> assert_text("#component_1_prop_1", ":updated_value")
    end

    test "next action", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_9']")
      |> assert_text("#page_result", ~s/{:page_action_10, %{x: 10, y: 20}}/)
    end

    test "next action executes exactly once", %{page: page} do
      page
      |> visit(Page19)
      |> click_button("Run Page 19 Action A")
      |> assert_text("#page_result", "{:page_19_action_b, 1}")
      |> click_button("Run Page 19 Action C")
      |> assert_text("#page_result", "{:page_19_action_c, 1}")
    end

    test "next command", %{page: page} do
      page
      |> visit(Page1)
      |> click("button[id='page_action_11']")
      |> assert_text("#page_result", ~s/{:page_action_12, %{x: 10, y: 20}}/)
    end

    # Covered in navigation test suite
    # feature "next page"

    # Covered in preceding (syntax) tests:
    # feature "state"
  end

  describe "actions queued in server-side init/3" do
    test "page init/3, target not specified", %{page: page} do
      page
      |> visit(Page2)
      |> assert_text("#page_result", ~s'{:page_action_result, %{queued_from: :page}}')
    end

    test "page init/3, target is specified", %{page: page} do
      page
      |> visit(Page3)
      |> assert_text(
        "#component_1_result",
        ~s'{:component_1_action_result, %{queued_from: :page}}'
      )
    end

    test "page init/3 action executes exactly once", %{page: page} do
      page
      |> visit(Page16)
      |> assert_text("#page_result", "{:page_16_action_a, 1}")
      |> click_button("Run Page 16 Action B")
      |> assert_text("#page_result", "{:page_16_action_b, 1}")
    end

    test "component init/3, target not specified", %{page: page} do
      page
      |> visit(Page4)
      |> assert_text(
        "#component_2_result",
        ~s'{:component_2_action_result, %{queued_from: :component_2}}'
      )
    end

    test "component init/3, target is specified", %{page: page} do
      page
      |> visit(Page5)
      |> assert_text(
        "#component_4_result",
        ~s'{:component_4_action_result, %{queued_from: :component_3}}'
      )
    end

    test "component init/3 action executes exactly once", %{page: page} do
      page
      |> visit(Page17)
      |> assert_text("#component_19_result", "{:component_19_action_a, 1}")
      |> click_button("Run Component 19 Action B")
      |> assert_text("#component_19_result", "{:component_19_action_b, 1}")
    end

    # The order of execution is based on CIDs in ascending alphabetical order
    # (page's CID is "page", layout's CID is "layout")
    test "all actions queued in server-side inits are executed in deterministic order", %{
      page: page
    } do
      page
      |> visit(Page6)
      |> assert_text(
        "#combined_result",
        "[:component_5_action_executed, :component_9_action_executed, :layout_action_executed, :component_7_action_executed, :page_action_executed, :component_6_action_executed]"
      )
    end
  end

  describe "actions queued in component client-side init/2" do
    test "target not specified", %{page: page} do
      page
      |> visit(Page8)
      |> assert_text("Component11 is hidden")
      |> click_button("Show component")
      |> assert_text(
        "#component_11_result",
        ~s'{:component_11_action_result, %{queued_from: :component_11}}'
      )
    end

    test "target specified", %{page: page} do
      page
      |> visit(Page7)
      |> assert_text("#page_result", "nil")
      |> assert_text("Component10 is hidden")
      |> click_button("Show component")
      |> assert_text(
        "#page_result",
        ~s'{:page_action_result, %{queued_from: :component_10}}'
      )
    end

    test "component init/2 action executes exactly once", %{page: page} do
      page
      |> visit(Page18)
      |> assert_text("Component20 is hidden")
      |> click_button("Show component")
      |> assert_text("#component_20_result", "{:component_20_action_a, 1}")
      |> click_button("Run Component 20 Action B")
      |> assert_text("#component_20_result", "{:component_20_action_b, 1}")
    end

    # The order of execution is based on queued order (not on CIDs in ascending alphabetical order as for init/3)
    test "all actions queued in client-side inits are executed in deterministic order", %{
      page: page
    } do
      page
      |> visit(Page9)
      |> assert_text("#combined_result", "[]")
      |> assert_text("Components are hidden")
      |> click_button("Show components")
      |> assert_text(
        "#combined_result",
        "[:component_12_action_executed, :component_14_action_executed, :component_16_action_executed, :component_13_action_executed]"
      )
    end
  end

  describe "with delay" do
    # The delays run on the page's clock, advanced by run_for/2 rather than waited out.
    setup %{page: page} do
      install_clock(page)
      :ok
    end

    test "queued in page init/3", %{page: page} do
      page
      |> visit(Page10)
      |> assert_text("#result", "nil")
      |> run_for(2_000)
      |> assert_text("#result", "nil")
      |> run_for(1_000)
      |> assert_text("#result", ":delayed_action_10_executed")
    end

    test "queued in component init/3", %{page: page} do
      page
      |> visit(Page11)
      |> assert_text("#result", "nil")
      |> run_for(2_000)
      |> assert_text("#result", "nil")
      |> run_for(1_000)
      |> assert_text("#result", ":delayed_action_11_executed")
    end

    test "queued in component init/2", %{page: page} do
      page
      |> visit(Page12)
      |> assert_text("#result", "nil")
      |> click_button("Show component")
      |> assert_text("#result", "nil")
      |> run_for(2_000)
      |> assert_text("#result", "nil")
      |> run_for(1_000)
      |> assert_text("#result", ":delayed_action_12_executed")
    end

    test "queued in another action", %{page: page} do
      page
      |> visit(Page14)
      |> assert_text("#result", "nil")
      |> click_button("Run instant action")
      |> assert_text("#result", "nil")
      |> run_for(2_000)
      |> assert_text("#result", "nil")
      |> run_for(1_000)
      |> assert_text("#result", ":delayed_action_14_executed")
    end

    test "queued in command", %{page: page} do
      page
      |> visit(Page13)
      |> assert_text("#result", "nil")
      |> click_button("Push command")
      |> assert_text("#result", "nil")
      |> run_for(2_000)
      |> assert_text("#result", "nil")
      |> run_for(1_000)
      |> assert_text("#result", ":delayed_action_13_executed")
    end

    test "queued in template", %{page: page} do
      page
      |> visit(Page15)
      |> assert_text("#result", "nil")
      |> click_button("Run delayed action")
      |> assert_text("#result", "nil")
      |> run_for(2_000)
      |> assert_text("#result", "nil")
      |> run_for(1_000)
      |> assert_text("#result", ":delayed_action_15_executed")
    end
  end

  describe "pending actions and navigation" do
    # The delays run on the page's clock, advanced by run_for/2 rather than waited out.
    setup %{page: page} do
      install_clock(page)
      :ok
    end

    # Positive control for the cancellation scenarios that follow: the same click schedules a
    # dispatch that fires when the user stays put.
    test "a pending delayed action fires when the user stays on the page", %{page: page} do
      page
      |> visit(Page20)
      |> assert_text("#layout_result", "nil")
      |> click_button("Run delayed layout action")
      |> assert_text("#layout_result", "nil")
      |> run_for(2_000)
      |> assert_text("#layout_result", "nil")
      |> run_for(1_500)
      |> assert_text("#layout_result", ~s/"layout_action_ran"/)
    end

    # The layout's cid is the same string on both pages, so the destination's registry answers
    # for it - a target that still resolves is no evidence the dispatch is still valid. Waiting
    # out the rest of the delay on the destination proves the dispatch was cancelled rather than
    # merely deferred: the layout is re-rendered there, so a post-navigation fire would show up
    # in its result.
    test "navigating to another page cancels a pending action targeting the layout",
         %{page: page} do
      page
      |> visit(Page20)
      |> click_button("Run delayed layout action")
      |> click_link("Page 21 link")
      |> assert_page(Page21)
      |> assert_text("Page 21 title")
      |> run_for(3_500)
      |> assert_text("#layout_result", "nil")
    end

    # The component is mounted on one page only, so after the navigation its cid is registered
    # nowhere and the dispatch resolves to nothing at all. Interacting with the destination
    # afterwards gives it time to run - an uncaught error from the stale dispatch fails the
    # test, whatever the page shows.
    test "navigating to another page cancels a pending action whose component is gone",
         %{page: page} do
      page
      |> visit(Page20)
      |> click_button("Run delayed component action")
      |> click_link("Page 21 link")
      |> assert_page(Page21)
      |> run_for(3_500)
      |> assert_text("Page 21 title")
    end

    # Going back restores the registry from a snapshot rather than from mount data, reaching the
    # cancellation down a different path than a forward navigation does.
    test "going back to another page cancels a pending action targeting the layout",
         %{page: page} do
      page
      |> visit(Page21)
      |> click_link("Page 20 link")
      |> assert_page(Page20)
      |> click_button("Run delayed layout action")
      |> go_back()
      |> assert_page(Page21)
      |> run_for(3_500)
      |> assert_text("#layout_result", "nil")
    end

    # The page cid resolves on the destination too, but to a different module - one with no
    # clause for the action the previous page scheduled. A dispatch that survives the navigation
    # raises there rather than merely doing the wrong thing.
    test "navigating to another page cancels a pending action targeting the page",
         %{page: page} do
      page
      |> visit(Page20)
      |> click_button("Run delayed page action")
      |> click_link("Page 21 link")
      |> assert_page(Page21)
      |> run_for(3_500)
      |> assert_text("Page 21 title")
    end

    # Positive control for the continuation drop below: the same click arms a continuation that
    # fires when the user stays put, proving the fixture schedules a real one.
    test "an async action's continuation fires when the user stays on the page",
         %{page: page} do
      page
      |> visit(Page22)
      |> click_button("Run async continuation action")
      |> assert_text("#result", "nil")
      |> run_for(3_000)
      |> assert_text("#result", ":async_continuation_ran")
    end

    # The await spans the navigation, so the parent settles only after the swap - a window the
    # timer cancellation never covered, no timer being armed yet when it ran. The parent settles on
    # a page that has been left, so its whole result is dropped before the continuation is ever
    # put; on the destination the continuation would raise, Page21 having no action clause for it,
    # which would fail the test as an uncaught error.
    test "navigating to another page drops the continuation of an async action",
         %{page: page} do
      page
      |> visit(Page22)
      |> click_button("Run async continuation action")
      |> click_link("Page 21 link")
      |> assert_page(Page21)
      |> run_for(3_000)
      |> assert_text("Page 21 title")
    end
  end

  # Each slow action awaits 3 seconds before producing its result, and each drop test waits 3.5
  # after navigating, so the result settles on the page navigated to. A surviving component result
  # faults on the registry write there, and a surviving command fails on the server and raises on
  # the client; both fail the test as uncaught errors (see track_js_errors/1). A
  # surviving layout or page result raises nothing, so those tests read the result the destination
  # renders. A surviving navigation pulls the browser off the destination.
  describe "result after navigation" do
    # The delays run on the page's clock, advanced by run_for/2 rather than waited out. Except
    # where a surviving result would show only after a server round trip (a command, a
    # component fault, a navigation): run_for/2 returns as soon as the timer fires, so those
    # tests wait the time out.
    setup %{page: page} do
      install_clock(page)
      :ok
    end

    # Positive control for the component drop below: the same button's result lands when the user
    # stays put, proving the fixture runs a real slow action whose result is written.
    test "a slow component action's result lands when the user stays on the page",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow component action")
      |> assert_text("#component_result", "nil")
      |> assert_text("#component_result", ~s/"component_result_ran"/)
    end

    # Positive control for the layout drops below, which read the same result: without it, an
    # action that never wrote would leave "nil" there too.
    test "a slow layout action's result lands when the user stays on the page",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow layout action")
      |> assert_text("#layout_result", "nil")
      |> assert_text("#layout_result", ~s/"layout_result_ran"/)
    end

    # Positive control for the page drop below, which reads the same result: without it, an action
    # that never wrote would leave "nil" there too.
    test "a slow page action's result lands when the user stays on the page",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow page action")
      |> assert_text("#page_result", "nil")
      |> assert_text("#page_result", ~s/"page_result_ran"/)
    end

    # Positive control for the command drop: the command the result puts is sent and its reply
    # lands when the user stays put.
    test "a slow action's command lands when the user stays on the page",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow command action")
      |> assert_text("#page_result", "nil")
      |> assert_text("#page_result", ~s/"page_command_ran"/)
    end

    # Positive control for the navigation drop: the navigation the result puts happens when the
    # user stays put.
    test "a slow action's navigation lands when the user stays on the page",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow navigating action")
      |> assert_page(Page21)
      |> assert_text("Page 21 title")
    end

    # The component is mounted on the late result page only, so a surviving result targets a cid
    # the destination's registry does not hold and faults there.
    test "navigating to another page drops the result of an action targeting a component",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow component action")
      |> click_link("Destination link")
      |> assert_page(LateResultDestinationPage)
      |> sleep(3_500)
      |> assert_text("Late result destination title")
    end

    # The layout cid resolves on the destination too, to a new instance of the same module, so a
    # surviving result would not raise: it would show on the destination's layout.
    test "navigating to another page drops the result of an action targeting the layout",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow layout action")
      |> click_link("Destination link")
      |> assert_page(LateResultDestinationPage)
      |> run_for(3_500)
      |> assert_text("#layout_result", "nil")
    end

    # The page cid resolves on the destination too, to a module that renders the same key, so a
    # surviving result would show there.
    test "navigating to another page drops the result of an action targeting the page",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow page action")
      |> click_link("Destination link")
      |> assert_page(LateResultDestinationPage)
      |> run_for(3_500)
      |> assert_text("#page_result", "nil")
    end

    # The destination has no command clause, so a surviving command fails on the server and the
    # client raises on its reply.
    test "navigating to another page drops the command an action's result puts",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow command action")
      |> click_link("Destination link")
      |> assert_page(LateResultDestinationPage)
      |> sleep(3_500)
      |> assert_text("Late result destination title")
    end

    # A surviving navigation would take the browser to Page21.
    test "navigating to another page drops the navigation an action's result puts",
         %{page: page} do
      page
      |> visit(LateResultPage)
      |> click_button("Run slow navigating action")
      |> click_link("Destination link")
      |> assert_page(LateResultDestinationPage)
      |> sleep(3_500)
      |> assert_page(LateResultDestinationPage)
      |> assert_text("Late result destination title")
    end

    # Going back restores the registry from a snapshot rather than from mount data, so the result
    # settles after a transition that reached the epoch bump down a different path.
    test "going back to another page drops the result of an action targeting the layout",
         %{page: page} do
      page
      |> visit(LateResultDestinationPage)
      |> click_link("Late result link")
      |> assert_page(LateResultPage)
      |> click_button("Run slow layout action")
      |> go_back()
      |> assert_page(LateResultDestinationPage)
      |> run_for(3_500)
      |> assert_text("#layout_result", "nil")
    end
  end

  describe "one action at a time" do
    # A burst of events dispatched faster than a microtask tick, the way fast keyboard repeat
    # dispatches them. Each one must read the state the one before it wrote. The page's action/3
    # has a clause that awaits, which makes every clause of it commit its result a tick after
    # reading the state - the increment clause included.
    test "every dispatch of a burst lands", %{page: page} do
      page
      |> visit(Page23)
      |> execute_script("""
      const button = document.getElementById("increment");

      for (let i = 0; i < 30; i++) {
        button.dispatchEvent(new MouseEvent("click", {bubbles: true}));
      }
      """)
      |> assert_text("#count", "30")
    end

    # The slow action is still awaiting when the fast one is dispatched. Run side by side, the
    # fast one would read the log before the slow one wrote to it, and the slow one's write would
    # then replace the fast one's.
    test "an action dispatched behind an asynchronous one waits for it", %{page: page} do
      page
      |> visit(Page23)
      |> execute_script("""
      for (const id of ["append_slow", "append_fast"]) {
        document.getElementById(id).dispatchEvent(new MouseEvent("click", {bubbles: true}));
      }
      """)
      |> assert_text("#log", "[:slow, :fast]")
    end
  end

  # A page can start an action in two ways: by queueing one in init/3, and by dispatching one from
  # a script in its template. The script's dispatch is buffered on a document load and waits for
  # the page's code after a client-side navigation, and the order of the two actions is the same
  # either way.
  describe "actions a page starts with" do
    test "run in the same order on a document load", %{page: page} do
      page
      |> visit(Page24, via: "load")
      |> assert_text("#log", ~s/[init: "load", script: "load"]/)
    end

    test "run in the same order after a client-side navigation", %{page: page} do
      page
      |> visit(Page25)
      |> click_link("Page 24 link")
      |> assert_page(Page24, via: "link")
      |> assert_text("#log", ~s/[init: "link", script: "link"]/)
    end
  end

  describe "one action at a time, per component" do
    # The page's action is still awaiting when the component's is dispatched. Only the page is
    # held: the component's action writes the component's state, which nothing is about to
    # overwrite.
    test "another component's action runs while one awaits", %{page: page} do
      page
      |> visit(Page26)
      |> click_button("Await slowly")
      |> click_button("Increment component 22")
      |> assert_text("#component_22_count", "1")
      |> assert_text("#page_result", "nil")
    end

    # The awaiting action belongs to the page being left. The destination's page actions share
    # its cid and must not inherit its wait.
    test "the destination is not held by an action awaiting on the page left",
         %{page: page} do
      page
      |> visit(Page26)
      |> click_button("Await forever")
      |> click_link("Page 27 link")
      |> assert_page(Page27)
      |> click_button("Put page 27 result")
      |> assert_text("#page_result", ~s/"Page 27 result"/)
    end
  end

  describe "a next action with no delay" do
    # The submit action's render is the only thing that shows "loading": the next action awaits,
    # and renders nothing until its promise resolves. A next action that ran before the browser
    # paints must not take that paint away.
    test "leaves the result of its parent on screen while it awaits", %{page: page} do
      page
      |> visit(Page29)
      |> click_button("Submit Page 29 Form")
      |> assert_text("#status", "loading")
      |> assert_text("#status", "done")
    end

    # The editor shows its draft while editing and the owner's value otherwise. The commit leaves
    # editing and forwards the draft to the owner in a next action, so a frame painted between the
    # two would show the owner's old value in the editor. The text is sampled on every animation
    # frame, since a mutation observer would also record the DOM change of the editor's own render,
    # which still happens before the owner's.
    test "runs before the browser paints", %{page: page} do
      page
      |> visit(Page28)
      |> assert_text("#component_24_shown", "ORIGINAL")
      |> click_button("Edit Component 24 Draft")
      |> assert_text("#component_24_shown", "NEW")
      |> execute_script("""
      globalThis.shownSamples = [];

      const sample = () => {
        globalThis.shownSamples.push(document.getElementById("component_24_shown").textContent);
        requestAnimationFrame(sample);
      };

      requestAnimationFrame(sample);
      """)
      |> click_button("Commit Component 24 Draft")
      |> assert_text("#component_24_shown", "NEW")
      # Gives the sampler a few frames past the commit's last render. The real bound is one frame,
      # the rest is margin.
      |> sleep(200)

      samples = script_result(page, "return globalThis.shownSamples;")
      assert samples != []
      assert Enum.uniq(samples) == ["NEW"]
    end
  end
end
