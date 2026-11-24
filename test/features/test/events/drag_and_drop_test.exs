defmodule HologramFeatureTests.Events.DragAndDropTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.DragAndDropPage
  alias HologramFeatureTests.Events.DragAndDropWindowPage

  # The tests dispatch the drag events from a script, with a DataTransfer of their own. A
  # script-built DataTransfer stays writable during every event, so the placeholder can be read
  # back after dispatch. dispatchEvent returns false when a listener prevented the default.
  @dispatch_script """
  window.dispatchDrag = (selector, type, {data = {}, files = [], relatedSelector = null} = {}) => {
    const dataTransfer = new DataTransfer();

    for (const [format, value] of Object.entries(data)) {
      dataTransfer.setData(format, value);
    }

    for (const [name, content, mimeType] of files) {
      dataTransfer.items.add(new File([content], name, {type: mimeType}));
    }

    const relatedTarget = relatedSelector === null ? null : document.querySelector(relatedSelector);

    const event = new DragEvent(type, {bubbles: true, cancelable: true, dataTransfer, relatedTarget});
    const notPrevented = document.querySelector(selector).dispatchEvent(event);

    return {notPrevented, types: Array.from(dataTransfer.types)};
  };
  """

  defp dispatch_drag(page, selector, type, opts \\ "{}") do
    script_result(
      page,
      @dispatch_script <>
        "return window.dispatchDrag(#{inspect(selector)}, #{inspect(type)}, #{opts});"
    )
  end

  test "$drop carries the drag data and types", %{page: page} do
    page = visit(page, DragAndDropPage)

    dispatch_drag(page, "#zone", "drop", ~s'{data: {"text/plain": "Buy milk"}}')

    assert_text(
      page,
      "#result",
      ~s'{:dropped, %{data: %{"text/plain" => "Buy milk"}, files: [], types: ["text/plain"]}}'
    )
  end

  test "$drop carries the dropped files", %{page: page} do
    page = visit(page, DragAndDropPage)

    dispatch_drag(page, "#zone", "drop", ~s'{files: [["notes.txt", "hello", "text/plain"]]}')

    assert_text(
      page,
      "#result",
      ~s'{:dropped, %{data: %{}, files: [{"notes.txt", "text/plain", true}], types: ["Files"]}}'
    )
  end

  test "$drag_start lets the drag start", %{page: page} do
    page = visit(page, DragAndDropPage)

    assert %{"notPrevented" => true} = dispatch_drag(page, "#item", "dragstart")
  end

  test "$drag_start puts the placeholder on a drag that carries no data", %{page: page} do
    page = visit(page, DragAndDropPage)

    assert %{"types" => ["application/x-hologram"]} =
             dispatch_drag(page, "#item", "dragstart")

    assert_text(
      page,
      "#result",
      "{:drag_started, %{data: %{}, files: [], items: [], types: []}}"
    )
  end

  test "$drag_start puts no placeholder on a drag that carries data", %{page: page} do
    page = visit(page, DragAndDropPage)

    assert %{"types" => ["text/plain"]} =
             dispatch_drag(page, "#item", "dragstart", ~s'{data: {"text/plain": "Buy flour"}}')
  end

  test "$drag_start carries the drag data", %{page: page} do
    page = visit(page, DragAndDropPage)

    dispatch_drag(page, "#item", "dragstart", ~s'{data: {"text/plain": "Buy bread"}}')

    assert_text(
      page,
      "#result",
      ~s'{:drag_started, %{data: %{"text/plain" => "Buy bread"}, files: [], items: [%{kind: :string, type: "text/plain"}], types: ["text/plain"]}}'
    )
  end

  test "a $drop binding makes the element a drop target", %{page: page} do
    page = visit(page, DragAndDropPage)

    # A drag over a drop target mostly lands on what's inside it.
    assert %{"notPrevented" => false} = dispatch_drag(page, "#target_child", "dragenter")
    assert %{"notPrevented" => false} = dispatch_drag(page, "#target_child", "dragover")
    assert %{"notPrevented" => false} = dispatch_drag(page, "#target_child", "drop")
  end

  test "a nil $drop binding leaves the element alone", %{page: page} do
    page = visit(page, DragAndDropPage)

    assert %{"notPrevented" => true} = dispatch_drag(page, "#nil_target_child", "dragenter")
    assert %{"notPrevented" => true} = dispatch_drag(page, "#nil_target_child", "dragover")
    assert %{"notPrevented" => true} = dispatch_drag(page, "#nil_target_child", "drop")
  end

  test "$drag_enter and $drag_leave fire only at the element's edge", %{page: page} do
    page = visit(page, DragAndDropPage)

    # Into the zone from outside the page, onto its child and back, then out of the zone onto
    # another element. The browser fires dragenter on the element entered before dragleave on the
    # one left.
    dispatch_drag(page, "#zone", "dragenter")
    dispatch_drag(page, "#zone_child", "dragenter", ~s'{relatedSelector: "#zone"}')
    dispatch_drag(page, "#zone", "dragleave", ~s'{relatedSelector: "#zone_child"}')
    dispatch_drag(page, "#zone", "dragenter", ~s'{relatedSelector: "#zone_child"}')
    dispatch_drag(page, "#zone_child", "dragleave", ~s'{relatedSelector: "#zone"}')
    dispatch_drag(page, "#zone", "dragleave", ~s'{relatedSelector: "#item"}')

    page
    |> assert_text("#leave_count", "1")
    |> assert_text("#enter_count", "1")
  end

  test "a <window> $drop gets a drop anywhere on the page", %{page: page} do
    page = visit(page, DragAndDropWindowPage)

    assert %{"notPrevented" => false} = dispatch_drag(page, "#area", "dragover")

    assert %{"notPrevented" => false} =
             dispatch_drag(page, "#area", "drop", ~s'{data: {"text/plain": "Buy eggs"}}')

    assert_text(page, "#result", ~s'{:dropped, %{"text/plain" => "Buy eggs"}}')
  end
end
