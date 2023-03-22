def network
  Parameter "VPCCidrBlock" do
    Type "String"
    Default "10.1.0.0/16"
  end

  EC2_VPC "VPC" do
    CidrBlock Ref("VPCCidrBlock")
    EnableDnsSupport true
    EnableDnsHostnames true
    Tags [ { Key: "Name", Value: Ref("AWS::StackName") } ]
  end

  EC2_InternetGateway "VPCInternetGateway"

  EC2_VPCGatewayAttachment "VPCAttachGateway" do
    VpcId Ref("VPC")
    InternetGatewayId Ref("VPCInternetGateway")
  end

  EC2_RouteTable "VPCRouteTable" do
    VpcId Ref("VPC")
  end

  EC2_Subnet "VPCSubnet" do
    VpcId Ref("VPC")
    AvailabilityZone ZONE
    MapPublicIpOnLaunch true
    CidrBlock FnJoin("/", [ FnSelect(0, FnSplit("/", Ref("VPCCidrBlock"))), "24" ])
  end

  EC2_SubnetRouteTableAssociation "VPCSubnetRouteTableAssociation" do
    SubnetId Ref("VPCSubnet")
    RouteTableId Ref("VPCRouteTable")
  end

  EC2_Route "VPCPublicInternetRoute" do
    DependsOn "VPCAttachGateway"
    RouteTableId Ref("VPCRouteTable")
    DestinationCidrBlock "0.0.0.0/0"
    GatewayId Ref("VPCInternetGateway")
  end

  Output "VPC" do
    Value Ref("VPC")
  end

end