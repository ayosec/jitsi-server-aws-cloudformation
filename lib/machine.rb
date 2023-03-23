def machine

  Parameter "KeyName" do
    Type "AWS::EC2::KeyPair::KeyName"
    Description "Name of the key used to access the machine via SSH."
  end

  Parameter "ImageId" do
    Type "AWS::EC2::Image::Id"
    Description "Image for the EC2 instance to run the Jitsi programs."
  end

  Parameter "InstanceType" do
    Type "String"
    Description "Type for the EC2 instance."
  end

  Parameter "MachineEnabled" do
    Type "String"
    Description "Indicate if the EC2 instance should be running."
    AllowedValues %w(Yes No)
  end

  Parameter "IPForSSH" do
    Type "String"
    Description "IP to allow SSH access"
    Default "255.255.255.255/32"
  end

  Parameter "DNSZoneName" do
    Type "String"
    Description "Name of the DNS zone"
  end

  Parameter "DNSZoneId" do
    Type "String"
    Description "DNS zone where the hostname for the instance will be created."
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
    Name FnSub("call.${DNSZoneName}")
    Comment "IP addres of the Jitsi server"
    Type "A"
    TTL 300
    ResourceRecords [ FnGetAtt("MainInstance", "PublicIp") ]
  end

  Output "PublicIp" do
    Condition "MachineIsEnabled"
    Value FnGetAtt("MainInstance", "PublicIp")
  end
end
