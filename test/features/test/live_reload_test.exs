defmodule HologramFeatureTests.LiveReloadTest do
  # Not async: a live reload event reaches every tab in the VM, a page's digest is swapped in
  # the registry every tab reads from, and the asset path registry every page is rendered with
  # is restarted.
  use HologramFeatureTests.TestCase, async: false

  alias Hologram.Assets.ManifestCache
  alias Hologram.Assets.PageDigestRegistry
  alias Hologram.Assets.PathRegistry
  alias Hologram.Commons.PLT
  alias Hologram.Reflection
  alias Hologram.Router.Helpers, as: RouterHelpers
  alias HologramFeatureTests.LiveReload.Page1
  alias HologramFeatureTests.LiveReload.Page2
  alias HologramFeatureTests.LiveReload.Page3
  alias HologramFeatureTests.LiveReload.Page4

  # How long a tab has to not reload before it counts as not reloading.
  @no_reload_wait_ms 1_000

  @overlay "#hologram-live-reload-error-overlay"

  @phoenix_reload_frame ~s(iframe[src*="/phoenix/live_reload/frame"])

  @reload_timeout_ms 10_000

  # The stylesheet Page4's layout links through asset_path/1.
  @digest_stylesheet_static_path "assets/live_reload_digest.css"

  defp broadcast_live_reload(message) do
    Phoenix.PubSub.broadcast(Hologram.PubSub, "hologram_live_reload", message)
  end

  # The file the page's bundle with the given digest is served from, in the dir the compiler writes
  # the bundles to.
  defp bundle_file_path(page_module, digest) do
    bundle_file_name =
      page_module
      |> RouterHelpers.page_bundle_path(digest)
      |> Path.basename()

    Path.join(Reflection.bundles_dir(), bundle_file_name)
  end

  defp computed_color(page) do
    script_result(page, "return getComputedStyle(document.getElementById('styled')).color;")
  end

  # The static path `mix phx.digest` gives a copy of the Page4 stylesheet in the given color: the
  # stylesheet's own, with the MD5 of the copy's content in it.
  defp digest_stylesheet_copy_static_path(color) do
    digest =
      color
      |> stylesheet_css()
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "assets/live_reload_digest-#{digest}.css"
  end

  # Serves the page under another digest, as the server does once a live reload has rebuilt it:
  # its bundle is copied under the new digest (same code, a new name) and the registry names the
  # copy. Both are undone when the test exits.
  defp give_page_another_digest(page_module) do
    table_name = PageDigestRegistry.ets_table_name()
    plt = %PLT{table_name: table_name, table_ref: :ets.whereis(table_name)}

    old_digest = PageDigestRegistry.lookup(page_module)

    # 5 random bytes encode to 8 chars of esbuild's base32 alphabet, the shape of a real digest.
    new_digest =
      5
      |> :crypto.strong_rand_bytes()
      |> Base.encode32()

    old_bundle_path = bundle_file_path(page_module, old_digest)
    new_bundle_path = bundle_file_path(page_module, new_digest)

    File.cp!(old_bundle_path, new_bundle_path)
    File.cp!(old_bundle_path <> ".gz", new_bundle_path <> ".gz")
    File.cp!(old_bundle_path <> ".map", new_bundle_path <> ".map")
    PLT.put(plt, page_module, new_digest)

    on_exit(fn ->
      PLT.put(plt, page_module, old_digest)
      File.rm(new_bundle_path)
      File.rm(new_bundle_path <> ".gz")
      File.rm(new_bundle_path <> ".map")
    end)
  end

  # Rebuilds the asset paths from the app's static dir and the bundles dir, as the server's start
  # does: the asset path registry, restarted, and the asset manifest the pages are rendered with.
  # The registry ends up as live reload's update after a change to the static files leaves it, and
  # the test app runs no live reload.
  defp rebuild_asset_paths do
    :ok = Supervisor.terminate_child(Hologram.Supervisor, PathRegistry)
    {:ok, _pid} = Supervisor.restart_child(Hologram.Supervisor, PathRegistry)

    ManifestCache.reload()
  end

  defp static_file_path(static_path) do
    Application.app_dir(:hologram_feature_tests, Path.join("priv/static", static_path))
  end

  defp stylesheet_css(color) do
    "#styled { color: #{color}; }\n"
  end

  # The stylesheet Page3's layout links, written through the app dir the server serves static files
  # from. Removed when the test exits.
  defp stylesheet_path do
    Application.app_dir(:hologram_feature_tests, "priv/static/assets/live_reload.css")
  end

  defp wait_for_computed_color(page, color) do
    page
    |> Page.locator("#styled")
    |> Expect.to_have_css!("color", color, timeout: @reload_timeout_ms)

    page
  end

  # The path the stylesheet link Page4 rendered points at, read once the link it was kept as is the
  # only one left, with no swap copy next to it, and holds the given path.
  defp wait_for_digest_stylesheet_path(page, path) do
    Page.wait_for_function!(
      page,
      """
      (path) => {
        const links = document.querySelectorAll('link[href*="live_reload_digest"]');
        const link = globalThis.__digestStylesheetLink;

        return links.length === 1 && links[0] === link && new URL(link.href).pathname === path;
      }
      """,
      path,
      timeout: @reload_timeout_ms
    )

    page
  end

  # Every document load renders a new instance id, an in-app navigation keeps it.
  defp wait_for_new_document(page, old_instance_id) do
    Page.wait_for_function!(
      page,
      """
      (oldInstanceId) => {
        const instanceId = globalThis.Hologram?.instanceId;

        return instanceId != null && instanceId !== oldInstanceId;
      }
      """,
      old_instance_id,
      timeout: @reload_timeout_ms
    )

    page
  end

  # A swap is done once the copy that kept the page styled is gone and the link the page rendered
  # holds the fresh URL.
  defp wait_for_stylesheet_swapped(page) do
    Page.wait_for_function!(
      page,
      """
      () => {
        const links = document.querySelectorAll('link[href*="live_reload.css"]');
        const link = globalThis.__stylesheetLink;

        return links.length === 1 && links[0] === link && link.href.includes("_hologram_css");
      }
      """,
      nil,
      timeout: @reload_timeout_ms
    )

    page
  end

  defp write_digest_stylesheet(color) do
    @digest_stylesheet_static_path
    |> static_file_path()
    |> write_static_file(stylesheet_css(color))
  end

  # Writes a copy of the Page4 stylesheet in the given color, under the name `mix phx.digest` gives
  # it, and returns the copy's static path.
  defp write_digest_stylesheet_copy(color) do
    copy_static_path = digest_stylesheet_copy_static_path(color)

    copy_static_path
    |> static_file_path()
    |> write_static_file(stylesheet_css(color))

    copy_static_path
  end

  # Plug.Static tags a file with its size and mtime, in seconds, and the colors' CSS is the same
  # length, so a rewrite within the second of the last write would keep the tag, and the browser
  # its cached copy. Waiting out the second keeps the tags apart.
  defp write_static_file(path, content) do
    Process.sleep(1_000 - rem(System.os_time(:millisecond), 1_000) + 10)
    File.write!(path, content)
  end

  defp write_stylesheet(color) do
    write_static_file(stylesheet_path(), "#styled { color: #{color}; }\n")
  end

  describe "reload event" do
    test "a tab on a rebuilt page reloads", %{page: page} do
      page = visit(page, Page1)
      instance_id = current_instance_id(page)

      broadcast_live_reload({:reload, [Page1]})

      page
      |> wait_for_new_document(instance_id)
      |> assert_page(Page1)
    end

    test "a tab on another page does not reload", %{page: page} do
      page = visit(page, Page2)
      instance_id = current_instance_id(page)

      broadcast_live_reload({:reload, [Page1]})
      Page.wait_for_timeout!(page, @no_reload_wait_ms)

      assert current_instance_id(page) == instance_id
    end

    test "every tab reloads when the runtime bundle was rebuilt", %{page: page} do
      page = visit(page, Page2)
      instance_id = current_instance_id(page)

      broadcast_live_reload({:reload, :all})

      page
      |> wait_for_new_document(instance_id)
      |> assert_page(Page2)
    end
  end

  describe "css changed event" do
    setup do
      assets_dir = Path.dirname(stylesheet_path())
      File.mkdir_p!(assets_dir)
      write_stylesheet("rgb(255, 0, 0)")

      on_exit(fn ->
        File.rm(stylesheet_path())
        # Left alone when it holds anything else.
        File.rmdir(assets_dir)
      end)
    end

    test "applies the new CSS without reloading the tab", %{page: page} do
      page =
        page
        |> visit(Page3)
        |> wait_for_computed_color("rgb(255, 0, 0)")

      instance_id = current_instance_id(page)

      # Kept to tell that the swap gives the link element the page rendered the fresh URL rather
      # than replacing it.
      execute_script(page, """
      globalThis.__stylesheetLink = document.querySelector('link[href*="/assets/live_reload.css"]');
      """)

      write_stylesheet("rgb(0, 0, 255)")
      broadcast_live_reload(:css_changed)

      page
      |> wait_for_computed_color("rgb(0, 0, 255)")
      |> wait_for_stylesheet_swapped()

      assert computed_color(page) == "rgb(0, 0, 255)"

      Page.wait_for_timeout!(page, @no_reload_wait_ms)

      assert current_instance_id(page) == instance_id
    end
  end

  describe "digested stylesheet" do
    setup do
      assets_dir =
        @digest_stylesheet_static_path
        |> static_file_path()
        |> Path.dirname()

      File.mkdir_p!(assets_dir)

      on_exit(fn ->
        assets_dir
        |> File.ls!()
        |> Enum.filter(&String.starts_with?(&1, "live_reload_digest"))
        |> Enum.map(&Path.join(assets_dir, &1))
        |> Enum.each(&File.rm!/1)

        # Left alone when it holds anything else.
        File.rmdir(assets_dir)

        rebuild_asset_paths()
      end)
    end

    test "links the plain file over a digested copy that no longer holds its content", %{
      page: page
    } do
      write_digest_stylesheet("rgb(0, 128, 0)")
      write_digest_stylesheet_copy("rgb(255, 165, 0)")
      rebuild_asset_paths()

      page
      |> visit(Page4)
      |> wait_for_computed_color("rgb(0, 128, 0)")

      assert script_result(page, """
             return new URL(document.querySelector('link[href*="live_reload_digest"]').href).pathname;
             """) == "/" <> @digest_stylesheet_static_path
    end

    test "swaps a stylesheet whose digested copy no longer holds its content to the plain file without reloading the tab",
         %{page: page} do
      write_digest_stylesheet("rgb(128, 0, 128)")
      copy_static_path = write_digest_stylesheet_copy("rgb(128, 0, 128)")
      rebuild_asset_paths()

      page =
        page
        |> visit(Page4)
        |> wait_for_computed_color("rgb(128, 0, 128)")

      instance_id = current_instance_id(page)

      assert script_result(page, """
             return new URL(document.querySelector('link[href*="live_reload_digest"]').href).pathname;
             """) == "/" <> copy_static_path

      execute_script(page, """
      globalThis.__digestStylesheetLink = document.querySelector('link[href*="live_reload_digest"]');
      """)

      write_digest_stylesheet("rgb(0, 128, 128)")
      rebuild_asset_paths()
      broadcast_live_reload(:css_changed)

      page
      |> wait_for_computed_color("rgb(0, 128, 128)")
      |> wait_for_digest_stylesheet_path("/" <> @digest_stylesheet_static_path)
      # The link loads the plain file again after the swap, so polled.
      |> wait_for_computed_color("rgb(0, 128, 128)")

      Page.wait_for_timeout!(page, @no_reload_wait_ms)

      assert current_instance_id(page) == instance_id

      # A render after the swap links the plain file too: the tab took the new asset paths.
      page
      |> click_button("Increment")
      |> assert_has("#count", text: "1")

      assert script_result(page, """
             const links = document.querySelectorAll('link[href*="live_reload_digest"]');

             return Array.from(links, (link) => new URL(link.href).pathname);
             """) == ["/" <> @digest_stylesheet_static_path]

      # The render recreates the link, which loads the plain file afresh, so polled.
      wait_for_computed_color(page, "rgb(0, 128, 128)")
    end
  end

  describe "Phoenix's live reload frame" do
    # The server sends the page with the frame, as Phoenix's live reload plug does in dev. Until
    # #1380 the first render removes it anyway, along with every other node it did not render.
    test "is removed from the page", %{page: page} do
      page = visit(page, Page3)

      assert script_result(page, "return fetch(location.pathname).then(r => r.text());") =~
               "/phoenix/live_reload/frame"

      refute_has(page, @phoenix_reload_frame)
    end
  end

  describe "compilation error event" do
    test "shows the compilation error", %{page: page} do
      page = visit(page, Page1)

      broadcast_live_reload({:compilation_error, [[%{text: "boom", tone: "banner"}]]})

      assert_text(page, @overlay, "boom")
    end
  end

  describe "compiled event" do
    test "takes the compilation error down without reloading the tab", %{page: page} do
      page = visit(page, Page1)
      instance_id = current_instance_id(page)

      broadcast_live_reload({:compilation_error, [[%{text: "boom", tone: "banner"}]]})
      assert_has(page, @overlay)

      broadcast_live_reload(:compiled)
      refute_has(page, @overlay)
      Page.wait_for_timeout!(page, @no_reload_wait_ms)

      assert current_instance_id(page) == instance_id
    end
  end

  describe "navigating to a page whose code the tab holds" do
    test "loads the page afresh when the server has rebuilt it since", %{page: page} do
      page =
        page
        |> visit(Page1)
        |> click_link("Page 2 link")
        |> assert_page(Page2)
        |> click_link("Page 1 link")
        |> assert_page(Page1)

      instance_id = current_instance_id(page)

      give_page_another_digest(Page2)

      page
      |> click_link("Page 2 link")
      |> wait_for_new_document(instance_id)
      |> assert_page(Page2)
    end

    test "navigates in the app when the page is current", %{page: page} do
      page =
        page
        |> visit(Page1)
        |> click_link("Page 2 link")
        |> assert_page(Page2)
        |> click_link("Page 1 link")
        |> assert_page(Page1)

      instance_id = current_instance_id(page)

      page
      |> click_link("Page 2 link")
      |> assert_page(Page2)

      assert current_instance_id(page) == instance_id
    end
  end

  describe "going back to a page" do
    test "reloads it with fresh state when its snapshot was taken with other code", %{
      page: page
    } do
      page =
        page
        |> visit(Page1)
        |> click_button("Increment")
        |> assert_text("#count", "1")
        |> click_link("Page 2 link")
        |> assert_page(Page2)

      instance_id = current_instance_id(page)

      give_page_another_digest(Page1)

      page
      |> go_back()
      |> wait_for_new_document(instance_id)
      |> assert_page(Page1)
      |> assert_text("#count", "0")
    end

    # Returning from outside the app loads a new document, which restores the page's snapshot
    # rather than mounting from mount data. The snapshot it saves on leaving has to carry the
    # document's digest all the same, or a later rebuild would go unnoticed on the way back.
    test "reloads it when it was rebuilt since a document restored it", %{page: page} do
      page =
        page
        |> visit(Page1)
        |> click_link("Page 2 link")
        |> assert_page(Page2)
        |> visit("/external")
        |> assert_text("External Page")
        |> go_back()
        |> assert_page(Page2)
        |> click_link("Page 1 link")
        |> assert_page(Page1)

      instance_id = current_instance_id(page)

      give_page_another_digest(Page2)

      page
      |> go_back()
      |> wait_for_new_document(instance_id)
      |> assert_page(Page2)
    end

    test "restores its state when its snapshot fits the code", %{page: page} do
      page =
        page
        |> visit(Page1)
        |> click_button("Increment")
        |> assert_text("#count", "1")
        |> click_link("Page 2 link")
        |> assert_page(Page2)

      instance_id = current_instance_id(page)

      page
      |> go_back()
      |> assert_page(Page1)
      |> assert_text("#count", "1")

      assert current_instance_id(page) == instance_id
    end
  end
end
