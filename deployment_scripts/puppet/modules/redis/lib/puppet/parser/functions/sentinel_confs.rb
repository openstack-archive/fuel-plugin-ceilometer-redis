module Puppet::Parser::Functions
  newfunction(:sentinel_confs, :type => :rvalue) do |args|
    if args.length != 6
      raise "Wrong number of arguments"
    end
    nodes = args[0]
    port = args[1]
    quorum = args[2]
    parallel_syncs = args[3]
    down_after_milliseconds = args[4]
    failover_timeout = args[5]
    hash = {}

    nodes.each do |value|
      name = value['name']
      addr = value['addr']
      hash[name] = {
                     'monitor' => addr + ' ' + port + ' ' + quorum,
                     'down-after-milliseconds' => down_after_milliseconds,
                     'failover-timeout' => failover_timeout,
                     'parallel-syncs' => parallel_syncs }
    end

    hash
  end
end
