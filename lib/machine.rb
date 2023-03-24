require "base64"
require "yaml"
require "zlib"

def machine

  Parameter "KeyName" do
    Type "AWS::EC2::KeyPair::KeyName"
    Description "Name of the key used to access the machine via SSH."
  end

  Parameter "ImageId" do
    Type "AWS::EC2::Image::Id"
    Description "Debian-based image for the EC2 instance to run the Jitsi programs."
  end

  Parameter "InstanceType" do
    Type "String"
    Default "t3.small"
    Description "Type for the EC2 instance."
  end

  Parameter "MachineEnabled" do
    Type "String"
    Description "Indicate if the EC2 instance should be running (Yes/No)."
    AllowedValues %w(Yes No)
  end

  Parameter "IPForSSH" do
    Type "String"
    Description "IP to allow SSH access"
    Default "255.255.255.255/32"
  end

  Parameter "DNSRecordName" do
    Type "String"
    Default "call"
    Description "Name of the record in DNS zone"
  end

  Parameter "DNSZoneName" do
    Type "String"
    Description "Name of the DNS zone"
  end

  Parameter "DNSZoneId" do
    Type "String"
    Description "DNS zone where the hostname for the instance will be created."
  end

  Parameter "MaxUptimeTime" do
    Type "String"
    Default "4h"
    Description "Stop the instance if uptime exceeds this time."
  end

  Condition "MachineIsEnabled", FnEquals(Ref("MachineEnabled"), "Yes")

  EC2_Instance "MainInstance" do
    Condition "MachineIsEnabled"
    SubnetId Ref("VPCSubnet")
    ImageId Ref("ImageId")
    InstanceType Ref("InstanceType")
    KeyName Ref("KeyName")
    SecurityGroupIds [ Ref("SecurityGroup") ]
    #IamInstanceProfile Ref("MachineProfile")
    Tags [
      { Key: "Name", Value: FnJoin("-", [ Ref("AWS::StackName"), "MainInstance" ]) },
    ]

    UserData FnBase64(FnSub(make_user_data))

    #BlockDeviceMappings [
    #  {
    #    DeviceName: "/dev/sda1",
    #    Ebs: {
    #      VolumeSize: Ref("PBXMachineVolumeSize"),
    #      VolumeType: "gp2",
    #      DeleteOnTermination: true
    #    }
    #  }
    #]
  end

  Route53_RecordSet "DNSRecord" do
    Condition "MachineIsEnabled"
    HostedZoneId Ref("DNSZoneId")
    Name FnSub("${DNSRecordName}.${DNSZoneName}")
    Comment "IP address of the Jitsi server"
    Type "A"
    TTL 300
    ResourceRecords [ FnGetAtt("MainInstance", "PublicIp") ]
  end

  Output "PublicIp" do
    Condition "MachineIsEnabled"
    Value FnGetAtt("MainInstance", "PublicIp")
  end
end

def make_user_data
  root = File.expand_path("../user-data", __FILE__)

  write_files = []
  runcmd = []

  packages = %w(
    docker.io
    docker-compose
  )

  runcmd << %w(apt-get remove -y snapd)

  # Env files.
  Dir["#{root}/*.env"].each do |envfile|
    write_files << {
      "path" => "/etc/#{File.basename(envfile)}",
      "content" => File.read(envfile),
    }
  end

  # TODO Use a Lambda function to limit the uptime.
  runcmd << [
    "systemd-run",
    "--unit", "run-max-uptime-time",
    "--no-block",
    "--on-active=${MaxUptimeTime}",
    "poweroff"
  ]

  # Scripts.
  Dir["#{root}/*.sh"].each do |shfile|
    dest = "/usr/local/bin/#{File.basename(shfile)}"
    runcmd << [
      "systemd-run",
      "--unit", "run-" + File.basename(shfile, ".sh"),
      "--no-block",
      dest
    ]

    content = StringIO.new
    gz = Zlib::GzipWriter.new(content, 9)
    gz.mtime = 0
    gz.write(File.read(shfile))
    gz.close

    write_files << {
      "path" => dest,
      "permissions" => "0755",
      "encoding" => "gzip+base64",
      "content" => Base64.strict_encode64(content.string),
    }
  end

  config = {
    "packages" => packages,
    "runcmd" => runcmd,
    "write_files" => write_files,
  }

  [ "#cloud-config\n", config.to_yaml ].join
end
