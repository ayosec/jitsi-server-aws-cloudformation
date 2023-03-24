require_relative "lib/machine"
require_relative "lib/network"

CloudFormation do
  Description "Template to launch a Jitsi instance"

  ::ZONE = FnSelect(0, FnGetAZs(""))

  Parameter "UserPassword" do
    Type "String"
    NoEcho true
    Description "Password for the admin users in Jitsi and Etherpad."
  end

  Parameter "LetsEncryptEmail" do
    Type "String"
    Description "Email for the letsencrypt certificate."
  end

  network
  machine
end
