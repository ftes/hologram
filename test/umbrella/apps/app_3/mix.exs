defmodule App3.MixProject do
  use Mix.Project

  defp deps do
    [
      {:hologram,
       git: "https://github.com/ftes/hologram.git",
       ref: "e3ac31ddbe19cb25432c8f6834c20368c3c1eba4"}
    ]
  end

  def project do
    [
      app: :app_3,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps: deps(),
      deps_path: "../../deps",
      elixir: "~> 1.0",
      elixirc_options: [warnings_as_errors: true],
      elixirc_paths: ["app"],
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end
end
