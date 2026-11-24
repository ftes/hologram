defmodule HologramClusterTests.RealtimeHelpers do
  @moduledoc """
  Assertion helpers for realtime cluster tests: resolving which peer holds what,
  and gating on cluster-side effects landing before they are asserted.
  """

  import HologramClusterTests.Cluster, only: [rpc: 4]
  import Playwright.Test.Assertions

  alias Hologram.Realtime
  alias Hologram.Realtime.SubscriptionRegistry
  alias Playwright.Expect

  # The awaited effect lands within a round trip when routing works, so ten seconds
  # without it is a broken premise, not slowness.
  @timeout 10_000

  @doc """
  Returns the browser page's tab id, read from the browser's own JS context -
  correct no matter which peer serves the tab's requests.
  """
  @spec instance_id_of(Playwright.Page.t()) :: String.t()
  def instance_id_of(page) do
    Playwright.Page.evaluate!(page, "() => globalThis.Hologram.instanceId")
  end

  @doc """
  Returns the subscription registry entries held by the given peer.
  """
  @spec registry_entries(map) :: list
  def registry_entries(peer) do
    table = rpc(peer, SubscriptionRegistry, :ets_table_name, [])
    rpc(peer, :ets, :tab2list, [table])
  end

  @doc """
  Blocks until some connection on the given peer holds a binding on `channel`,
  or raises once the time budget is spent.
  """
  @spec wait_for_channel_binding(map, any) :: :ok
  def wait_for_channel_binding(peer, channel) do
    wait_until(
      fn ->
        peer
        |> registry_entries()
        |> Enum.any?(fn {_instance_id, entry} -> bound?(entry, channel) end)
      end,
      "no binding on #{inspect(channel)} ever appeared on #{inspect(peer.node)}"
    )
  end

  @doc """
  Blocks until a subscriber for `channel`'s PubSub topic exists on the given
  peer, or raises once the time budget is spent.

  A binding in the registry does not yet mean deliverability: the stream joins
  the channel's topic one message-pump iteration after the binding is written,
  and a broadcast dispatched into that gap is silently lost. This is the gate
  for "a broadcast will now reach the tab".
  """
  @spec wait_for_channel_subscriber(map, any) :: :ok
  def wait_for_channel_subscriber(peer, channel) do
    topic = Realtime.channel_topic(channel)

    wait_until(
      fn -> rpc(peer, Registry, :lookup, [Hologram.PubSub, topic]) != [] end,
      "no subscriber for #{inspect(channel)} ever appeared on #{inspect(peer.node)}"
    )
  end

  @doc """
  Blocks until a connection is registered on the given peer, or raises once the
  time budget is spent.
  """
  @spec wait_for_connection(map) :: :ok
  def wait_for_connection(peer) do
    wait_until(
      fn -> registry_entries(peer) != [] end,
      "no connection ever registered on #{inspect(peer.node)}"
    )
  end

  defp bound?(entry, channel) do
    Enum.any?(entry.bindings, fn {{bound_channel, _cid}, _user_id} -> bound_channel == channel end)
  end

  defp wait_until(fun, message) do
    Expect.poll!(fun, &assert(&1, message), timeout: @timeout)
    :ok
  end
end
