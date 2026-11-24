Hologram.Test.setup()

ExUnit.start()

# The peers this suite starts are full distributed-Erlang nodes, so the test runner must
# be one as well. epmd has to be up before a node can enable distribution - `-daemon` is
# a no-op when it already is. Longnames against 127.0.0.1 rather than a short name, since
# short names depend on hostname resolution, which differs between dev machines and CI
# runners.
System.cmd("epmd", ["-daemon"])

{:ok, _pid} = Node.start(:"cluster_test@127.0.0.1", :longnames)
Node.set_cookie(:hologram_cluster_tests)
