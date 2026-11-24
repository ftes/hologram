defmodule HologramFeatureTests.Events.DragSourceTest do
  use HologramFeatureTests.TestCase, async: true

  alias HologramFeatureTests.Events.DragSourcePage

  # The tests dispatch the drag events from a script, with a DataTransfer of their own. Chrome
  # ignores the allowed effects, the drop effect and the drag image set on a DataTransfer a script
  # built, so the script records them instead. The given data stands for what the browser puts on
  # a drag before the page's listeners run.
  @drag_script """
  window.dispatchDrag = (selector, type, data = {}) => {
    const dataTransfer = new DataTransfer();
    const dragImages = [];

    for (const [format, value] of Object.entries(data)) {
      dataTransfer.setData(format, value);
    }

    const recorded = {dropEffect: "none", effectAllowed: "uninitialized"};

    for (const property of ["dropEffect", "effectAllowed"]) {
      Object.defineProperty(dataTransfer, property, {
        get: () => recorded[property],
        set: (value) => (recorded[property] = value)
      });
    }

    dataTransfer.setDragImage = (element, x, y) => dragImages.push([element.id, x, y]);

    const event = new DragEvent(type, {bubbles: true, cancelable: true, dataTransfer});
    document.querySelector(selector).dispatchEvent(event);

    return {
      data: Object.fromEntries(
        Array.from(dataTransfer.types).map((format) => [format, dataTransfer.getData(format)])
      ),
      dragImages,
      dropEffect: dataTransfer.dropEffect,
      effectAllowed: dataTransfer.effectAllowed
    };
  };
  """

  defp dispatch_drag(page, selector, type, data \\ "{}") do
    script_result(
      page,
      @drag_script <>
        "return window.dispatchDrag(#{inspect(selector)}, #{inspect(type)}, #{data});"
    )
  end

  test "$data_transfer puts the drag data on the drag", %{page: page} do
    page = visit(page, DragSourcePage)

    assert %{"data" => data} = dispatch_drag(page, "#item", "dragstart")
    assert data == %{"application/x-task" => "42", "text/plain" => "Buy milk"}
  end

  test "$data_transfer keeps the browser's own data on the drag", %{page: page} do
    page = visit(page, DragSourcePage)

    # A link inside the source drags with what the browser puts on a link, and the source's
    # declaration, whose nil removes the link's URL.
    assert %{"data" => data} =
             dispatch_drag(
               page,
               "#item_link",
               "dragstart",
               ~s'{"text/html": "<a href=\\"https://example.com\\">Link</a>", "text/uri-list": "https://example.com"}'
             )

    assert data == %{
             "application/x-task" => "42",
             "text/html" => ~s'<a href="https://example.com">Link</a>',
             "text/plain" => "Buy milk"
           }
  end

  test "$data_transfer puts the drag data on the drag before $drag_start reads it", %{
    page: page
  } do
    page = visit(page, DragSourcePage)

    dispatch_drag(page, "#item", "dragstart")

    assert_text(
      page,
      "#result",
      ~s'{:drag_started, %{"application/x-task" => "42", "text/plain" => "Buy milk"}}'
    )
  end

  test "$data_transfer sets the allowed effects", %{page: page} do
    page = visit(page, DragSourcePage)

    assert %{"effectAllowed" => "move"} = dispatch_drag(page, "#item", "dragstart")
  end

  test "$data_transfer sets the drag image", %{page: page} do
    page = visit(page, DragSourcePage)

    assert %{"dragImages" => [["preview", 16, 8]]} = dispatch_drag(page, "#item", "dragstart")
  end

  test "the nearest $data_transfer source makes the drag", %{page: page} do
    page = visit(page, DragSourcePage)

    result = dispatch_drag(page, "#chip", "dragstart")

    assert result == %{
             "data" => %{"application/x-tag" => "urgent"},
             "dragImages" => [],
             "dropEffect" => "none",
             "effectAllowed" => "uninitialized"
           }
  end

  test "$data_transfer sets the drop effect on a drop target", %{page: page} do
    page = visit(page, DragSourcePage)

    # A drag over a drop target mostly lands on what's inside it.
    assert %{"dropEffect" => "move"} = dispatch_drag(page, "#zone_child", "dragover")

    assert_text(page, "#result", "{:dragged_over, :move}")
  end

  test "the nearest drop target's drop effect wins", %{page: page} do
    page = visit(page, DragSourcePage)

    assert %{"dropEffect" => "link"} = dispatch_drag(page, "#inner_zone_child", "dragover")

    assert_text(page, "#result", "{:dragged_over, :link}")
  end
end
