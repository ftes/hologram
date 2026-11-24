windows? = match?({:win32, _name}, :os.type())

# A static file whose path holds what the inline asset-manifest script cannot carry raw: a
# quote, a backslash, and - the directory's trailing "<" meeting the file's leading "script>" -
# a closing script tag. Planted here rather than committed, because every one of those
# characters is illegal in a Windows file name, so a repo carrying the file could not be
# checked out there at all. It has to exist before the Hologram app boots, which in the test
# env happens in Hologram.Test.setup/0 below, where the static dir is scanned once. Read by
# test/asset_manifest_test.exs through HologramFeatureTests.AssetManifestPage.
unless windows? do
  hostile_dir =
    Path.join([
      Application.app_dir(:hologram_feature_tests, "priv/static"),
      "hostile",
      ~S|quote"backslash\tag<|
    ])

  File.mkdir_p!(hostile_dir)

  hostile_dir
  |> Path.join("script>.txt")
  |> File.write!("")
end

Hologram.Test.setup()

# The file planted above cannot exist on Windows, and neither can the bug it exercises - a
# static path there can never hold any of the characters the manifest escapes. The one test
# that reads it is therefore skipped on Windows permanently, not pending a fix. Same tag as
# the lib suite uses, see test/elixir/test_helper.exs.
exclude_opts = if windows?, do: [:skip_on_windows], else: []

ExUnit.start(exclude: exclude_opts)
