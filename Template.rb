require_relative "lib/machine"
require_relative "lib/network"

CloudFormation do
  Description "Template to launch a Jitsi instance"

  ::ZONE = FnSelect(0, FnGetAZs(""))

  network
  machine
end
