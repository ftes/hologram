defmodule HologramFeatureTests.JavaScriptInteropTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.JavaScriptInterop.AsyncPage
  alias HologramFeatureTests.JavaScriptInterop.DispatchActionPage
  alias HologramFeatureTests.JavaScriptInterop.DispatchEventPage
  alias HologramFeatureTests.JavaScriptInterop.DOMPatchingPage
  alias HologramFeatureTests.JavaScriptInterop.NpmImportPage
  alias HologramFeatureTests.JavaScriptInterop.PendingActionsPage
  alias HologramFeatureTests.JavaScriptInterop.PendingActionsSourcePage
  alias HologramFeatureTests.JavaScriptInterop.SyncPage

  describe "JS.call/2" do
    test "calls imported function directly", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Call receiverless function")
      |> assert_text("#call_result", "{27, true}")
    end

    test "calls global function", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Call global function")
      |> assert_text("#call_result", "{42, true}")
    end
  end

  describe "JS.call/3 with sync methods" do
    test "sync method", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Call sync method")
      |> assert_text("#call_result", "{3, true}")
    end

    test "callback interop", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Callback interop")
      |> assert_text("#call_result", "[2, 4, 6]")
    end
  end

  # Async tests use JS.call/3 but cover JS.call/2 as well, since both go through
  # the same call/4 runtime implementation and Promise handling.
  describe "JS.call/3 with async methods" do
    test "async method", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Call async method")
      |> assert_text("#call_result", "{30, true}")
    end

    test "promise-returning method", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Call promise method")
      |> assert_text("#call_result", "{300, true}")
    end

    test "async andalso", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async andalso")
      |> assert_text("#call_result", ":andalso_right")
    end

    test "async anonymous function call", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async anonymous function call")
      |> assert_text("#call_result", "{27, true}")
    end

    test "async apply", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async apply")
      |> assert_text("#call_result", "{31, true}")
    end

    test "async case", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async case")
      |> assert_text("#call_result", ":matched")
    end

    test "async comprehension", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async comprehension")
      |> assert_text("#call_result", "[30, 60, 90]")
    end

    test "async cond", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async cond")
      |> assert_text("#call_result", ":correct")
    end

    test "async dynamic call", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async dynamic call")
      |> assert_text("#call_result", "{33, true}")
    end

    test "async orelse", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async orelse")
      |> assert_text("#call_result", ":orelse_right")
    end

    test "async with", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async with")
      |> assert_text("#call_result", "{:ok, 40}")
    end

    # TODO: add "async try" feature test once async try expression is fully implemented
  end

  test "JS.delete/2", %{page: page} do
    page
    |> visit(SyncPage)
    |> click_button("Delete property")
    |> assert_text("#call_result", ~s({"undefined", true}))
  end

  describe "JS.dispatch_event" do
    test "dispatch_event/2 (CustomEvent, no opts)", %{page: page} do
      page
      |> visit(DispatchEventPage)
      |> click_button("Dispatch default")
      |> assert_text("#call_result", ~s("test:alpha"))
    end

    test "dispatch_event/3 with opts (CustomEvent, with detail)", %{page: page} do
      page
      |> visit(DispatchEventPage)
      |> click_button("Dispatch with detail")
      |> assert_text("#call_result", "{99, true}")
    end

    test "dispatch_event/3 with type (MouseEvent, no opts)", %{page: page} do
      page
      |> visit(DispatchEventPage)
      |> click_button("Dispatch with event type")
      |> assert_text("#call_result", ~s("MouseEvent"))
    end

    test "dispatch_event/4 (CustomEvent, cancelable)", %{page: page} do
      page
      |> visit(DispatchEventPage)
      |> click_button("Dispatch cancelable")
      |> assert_text("#call_result", "{false, true}")
    end

    test "dispatch on :document target", %{page: page} do
      page
      |> visit(DispatchEventPage)
      |> click_button("Dispatch on document")
      |> assert_text("#call_result", ~s("test:delta"))
    end
  end

  describe "JS.eval/1" do
    test "sync", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Evaluate expression")
      |> assert_text("#call_result", "{7, true}")
    end

    test "async (Promise -> Task)", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async eval")
      |> assert_text("#call_result", "{88, true}")
    end
  end

  describe "JS.exec/1" do
    test "sync", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Execute code")
      |> assert_text("#call_result", "{5, true}")
    end

    test "async (Promise -> Task)", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async exec")
      |> assert_text("#call_result", "{66, true}")
    end
  end

  describe "JS.get/2" do
    test "sync", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Get property")
      |> assert_text("#call_result", "{10, true}")
    end

    test "async (Promise -> Task)", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async get")
      |> assert_text("#call_result", "{77, true}")
    end
  end

  test "JS.instanceof/2", %{page: page} do
    page
    |> visit(SyncPage)
    |> click_button("Instanceof check")
    |> assert_text("#call_result", "{true, true}")
  end

  describe "JS.new/2" do
    test "sync", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("New instance")
      |> assert_text("#call_result", "{42, true}")
    end

    test "async (Promise -> Task)", %{page: page} do
      page
      |> visit(AsyncPage)
      |> click_button("Async new")
      |> assert_text("#call_result", "{51, true}")
    end
  end

  test "JS.set/3", %{page: page} do
    page
    |> visit(SyncPage)
    |> click_button("Set property")
    |> assert_text("#call_result", "{20, true}")
  end

  test "JS.typeof/1", %{page: page} do
    page
    |> visit(SyncPage)
    |> click_button("Typeof value")
    |> assert_text("#call_result", ~s("object"))
  end

  describe "~JS sigil" do
    test "DOM manipulation", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Run JS sigil void")
      |> assert_text("#js_sigil_result", "Hologram")
    end

    test "return value is boxed", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Run JS sigil returning value")
      |> assert_text("#call_result", "{11, true}")
    end
  end

  describe "Hologram.dispatchAction()" do
    test "with params", %{page: page} do
      page
      |> visit(DispatchActionPage)
      |> execute_script(
        "Hologram.dispatchAction('dispatch_with_params', 'page', {amount: 42, label: 'test'});"
      )
      |> assert_text("#call_result", ~s({42, "test"}))
    end

    test "without params", %{page: page} do
      page
      |> visit(DispatchActionPage)
      |> execute_script("Hologram.dispatchAction('dispatch_without_params', 'page');")
      |> assert_text("#call_result", ":dispatched")
    end

    test "pending action dispatched before runtime loads", %{page: page} do
      page
      |> visit(PendingActionsPage)
      |> assert_text("#call_result", "{99, true}")
    end

    test "action dispatched by an inline script after a client-side navigation",
         %{page: page} do
      page
      |> visit(PendingActionsSourcePage)
      |> click_link("Pending actions link")
      |> assert_page(PendingActionsPage)
      |> assert_text("#call_result", "{99, true}")
    end

    # The target comes straight from the caller here, so a cid nothing is registered under is a
    # mistake in the calling code rather than a dispatch that outlived its page. It is named as
    # one, which is what puts it in front of whoever mistyped it.
    test "target that no component is registered under", %{page: page} do
      expected_msg = ~s(invalid action target, there is no component with CID: "no_such_cid")

      assert_client_error page, ArgumentError, expected_msg, fn ->
        page
        |> visit(DispatchActionPage)
        |> execute_script("Hologram.dispatchAction('whatever', 'no_such_cid');")
      end
    end
  end

  describe "binding resolution" do
    test "global", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Resolve global")
      |> assert_text("#call_result", "{4, true}")
    end

    test "imported", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Resolve imported")
      |> assert_text("#call_result", "{12, true}")
    end

    test "object ref", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Resolve object ref")
      |> assert_text("#call_result", "{15, true}")
    end
  end

  describe "js_import path resolution" do
    test "colocated file (relative to caller)", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Call colocated function")
      |> assert_text("#call_result", "{24, true}")
    end

    test "assets dir file (relative to caller)", %{page: page} do
      page
      |> visit(SyncPage)
      |> click_button("Call assets dir function")
      |> assert_text("#call_result", "{16, true}")
    end

    test "npm package", %{page: page} do
      page
      |> visit(NpmImportPage)
      |> click_button("Call npm method")
      |> assert_text("#call_result", "{123, true}")
    end
  end

  describe "DOM patching" do
    test "JS-managed subtree is preserved after state change", %{page: page} do
      page
      |> visit(DOMPatchingPage)
      |> click_button("Populate JS subtree")
      |> assert_text("#counter", "1")
      |> assert_text("#js_managed", "JS managed content")
      |> click_button("Increment counter")
      |> assert_text("#counter", "2")
      |> assert_text("#js_managed", "JS managed content")
    end
  end
end
