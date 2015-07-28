module Puppet::Parser::Functions
  newfunction(:redis_backend_url, :type => :rvalue) do |args|
    if args.length != 3
      raise "Wrong number of arguments"
    end
    nodes = args[0]
    port = args[1]
    timeout = args[2]

    backend_url="redis://" + nodes[0] + ":" + port + "?sentinel=" + nodes[0]

    nodes.each do |value|
      if value != nodes[0]
        backend_url=backend_url + "&sentinel_fallback=" + value + ":" + port + "?sentinel=" + value
      end
    end
    backend_url=backend_url + "&timeout=" + timeout

    backend_url
  end
end
