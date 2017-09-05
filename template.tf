/*This template aims is to create the following architecture

1 VPC
1 Subnet FrontEnd
1 Subnet BackEnd
1 Subnet Bastion
2 VM FrontEnd Web Apache + Elastic Load Balancer
2 VM Backend DB mySQL 
1 VM Linux Bastion
2 public IP on FrontEnd
1 public IP on Bastion
1 external Load Balancer
NAT Gateway
Internet Gateway
EBS Volume
NSG on FrontEnd Subnet
    Allow HTTP HTTPS from Internet through ALB
    Allow Access to internet egress
    Allow MySQL to DB Tier
    Allow SSH from Bastion
NSG on Backend Subnet
    Allow MySQL Access from Web tier
    Allow SSH from Bastion
    Allow egress Internet
NSG on Bastion
    Allow SSH from internet
    Allow any to all subnet
    Allow Internet access egress


*/
######################################################################
# Access to AWS
######################################################################


# Configure the Microsoft Azure Provider with Azure provider variable defined in AzureDFProvider.tf

provider "aws" {

    access_key  = "${var.AWSAccessKey}"
    secret_key  = "${var.AWSSecretKey}"
    region      = "${var.AWSRegion}"
    
}



######################################################################
# Foundations resources, including VPC
######################################################################


# Creating VPC

resource "aws_vpc" "vpc-basiclinux" {

    cidr_block = "172.17.0.0/16"

     tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "vpc-basiclinux"
    }
}

######################################################################
# Subnet
######################################################################



# Creating Subnet FrontEnd

resource "aws_subnet" "Subnet-BasicLinuxFrontEnd1" {

    
    vpc_id      = "${aws_vpc.vpc-basiclinux.id}"
    cidr_block  = "172.17.0.0/25"
    availability_zone = "${var.AWSAZ1}"
    #map_public_ip_on_launch = true

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Subnet-BasicLinuxFrontEnd1"
    } 
}


# Creating Subnet FrontEnd2

resource "aws_subnet" "Subnet-BasicLinuxFrontEnd2" {

    vpc_id      = "${aws_vpc.vpc-basiclinux.id}"
    cidr_block  = "172.17.0.128/25"
    availability_zone = "${var.AWSAZ2}"
    #map_public_ip_on_launch = true

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Subnet-BasicLinuxFrontEnd2"
    } 
}


# Creating Subnet BackEnd1

resource "aws_subnet" "Subnet-BasicLinuxBackEnd1" {

    vpc_id      = "${aws_vpc.vpc-basiclinux.id}"
    cidr_block  = "172.17.1.0/25"
    availability_zone = "${var.AWSAZ1}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Subnet-BasicLinuxBackEnd1"
    } 
}


# Creating Subnet BackEnd2

resource "aws_subnet" "Subnet-BasicLinuxBackEnd2" {

    vpc_id      = "${aws_vpc.vpc-basiclinux.id}"
    cidr_block  = "172.17.1.128/25"
    availability_zone = "${var.AWSAZ2}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Subnet-BasicLinuxBackEnd2"
    } 
}

# Creating Subnet Bastion1

resource "aws_subnet" "Subnet-BasicLinuxBastion1" {

    vpc_id      = "${aws_vpc.vpc-basiclinux.id}"
    cidr_block  = "172.17.2.0/25"
    availability_zone = "${var.AWSAZ3}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Subnet-BasicLinuxBastion1"
    } 
}

######################################################################
# NACL
######################################################################


######################################################################
# Security Group
######################################################################


######################################################################
#Security Group for ALB
######################################################################

resource "aws_security_group" "NSG-ALB" {

    name = "NSG-ALB"
    description = "Security Group for ALB"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NSG-ALB"
        
    }
}


######################################################################
#Security Group Rules section for ALB
######################################################################

#Rule for SG ALB HTTP In

resource "aws_security_group_rule" "NSG-ALB-HTTPIn" {

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-ALB.id}"
    

}

#Rule for SG ALB HTTPS In

resource "aws_security_group_rule" "NSG-ALB-HTTPSIn" {

    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-ALB.id}"
    

}

#Rule for SG Front End * outbound

resource "aws_security_group_rule" "NSG-ALB-AnyOut" {

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-ALB.id}"
    

}



######################################################################
#Security Group for FE
######################################################################

resource "aws_security_group" "NSG-FrontEnd" {

    name = "NSG-FrontEnd"
    description = "Security Group for FrontEnd"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NSG-FrontEnd"
    }
}

######################################################################
#Security Group Rules section for FE
######################################################################

#Rules for SG Front End HTTP In

resource "aws_security_group_rule" "NSG-FrontEnd-HTTPInFromFE1" {

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["172.17.0.0/25"]
    security_group_id = "${aws_security_group.NSG-FrontEnd.id}"
    

}

resource "aws_security_group_rule" "NSG-FrontEnd-HTTPInFromFE2" {

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["172.17.0.128/25"]
    security_group_id = "${aws_security_group.NSG-FrontEnd.id}"
    

}

#resource "aws_security_group_rule" "NSG-FrontEnd-HTTPInFromWebInstance" {
#
#    type = "ingress"
#    from_port = 80
#    to_port = 80
#    protocol = "tcp"
#    cidr_blocks = ["${aws_instance.Web1.private_ip}/32","${aws_instance.Web2.private_ip}/32"]
#    security_group_id = "${aws_security_group.NSG-FrontEnd.id}"
#    
#
#}

# Rule for SG Front End SSH in from Bastion

resource "aws_security_group_rule" "NSG-FrontEnd-SSHIn" {

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["172.17.2.0/25"]
    security_group_id = "${aws_security_group.NSG-FrontEnd.id}"
    

}

#Rules for SG Front End * outbound

resource "aws_security_group_rule" "NSG-FrontEnd-AnyOut" {

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-FrontEnd.id}"
    

}

######################################################################
#Security Group for FE
######################################################################

resource "aws_security_group" "NSG-BackEnd" {

    name = "NSG-BackEnd"
    description = "Security Group for BackEnd"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NSG-BackEnd"
    }
}

######################################################################
#Security Group Rules section for FE
######################################################################

#Rules for SG Front End HTTP In

resource "aws_security_group_rule" "NSG-BackEnd-MySQLInFromFE1" {

    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["172.17.0.0/25"]
    security_group_id = "${aws_security_group.NSG-BackEnd.id}"
    

}

resource "aws_security_group_rule" "NSG-BackEnd-MySQLInFromFE2" {

    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["172.17.0.128/25"]
    security_group_id = "${aws_security_group.NSG-BackEnd.id}"
    

}
# Rule for SG Front End SSH in from Bastion

resource "aws_security_group_rule" "NSG-BackEnd-SSHIn" {

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["172.17.2.0/25"]
    security_group_id = "${aws_security_group.NSG-BackEnd.id}"
    

}

#Rules for SG Front End * outbound

resource "aws_security_group_rule" "NSG-BackEnd-AnyOut" {

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-BackEnd.id}"
    

}

######################################################################
#Security Group for Bastion
######################################################################


resource "aws_security_group" "NSG-Bastion" {

    name = "NSG-Bastion"
    description = "Security Group for Bastion"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NSG-Bastion"
    }
}

######################################################################
#Security Group Rules section for Bastion
######################################################################


#Rules for SG Bastion SSH In

resource "aws_security_group_rule" "NSG-Bastion-SSHIn" {

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-Bastion.id}"
    

}

#Rules for SG Bastion HTTP In

resource "aws_security_group_rule" "NSG-Bastion-HTTPIn" {

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-Bastion.id}"
    

}



#Rule for SG Bastion * outbound

resource "aws_security_group_rule" "NSG-Bastion-AnyOut" {

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-Bastion.id}"
    

}




######################################################################
# Internet GW
######################################################################

resource "aws_internet_gateway" "BasicLinuxIGW" {

    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "BasicLinux-IGW"
    }
    
}

######################################################################
# route
######################################################################

resource "aws_route_table" "internetaccess" {

    vpc_id                  = "${aws_vpc.vpc-basiclinux.id}" 
    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = "${aws_internet_gateway.BasicLinuxIGW.id}"
    }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Basiclinux-internetaccessRoute"
    }

}

resource "aws_route_table" "natgw" {

    vpc_id                  = "${aws_vpc.vpc-basiclinux.id}" 
    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = "${aws_nat_gateway.BasicLinuxnatgw.id}"
    }

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Basiclinux-natgwroute"
    }

}


resource "aws_route_table_association" "SubnetWeb1-association" {

    subnet_id       = "${aws_subnet.Subnet-BasicLinuxFrontEnd1.id}"
    route_table_id  = "${aws_route_table.internetaccess.id}"
}


resource "aws_route_table_association" "SubnetWeb2-association" {

    subnet_id       = "${aws_subnet.Subnet-BasicLinuxFrontEnd2.id}"
    route_table_id  = "${aws_route_table.internetaccess.id}"
}

resource "aws_route_table_association" "SubnetDB1-association" {

    subnet_id       = "${aws_subnet.Subnet-BasicLinuxBackEnd1.id}"
    route_table_id  = "${aws_route_table.natgw.id}"
}


resource "aws_route_table_association" "SubnetDB2-association" {

    subnet_id       = "${aws_subnet.Subnet-BasicLinuxBackEnd2.id}"
    route_table_id  = "${aws_route_table.natgw.id}"
}

resource "aws_route_table_association" "SubnetBastion1-association" {

    subnet_id       = "${aws_subnet.Subnet-BasicLinuxBastion1.id}"
    route_table_id  = "${aws_route_table.internetaccess.id}"
}

######################################################################
# Public IP Address
######################################################################



# Creating Public IP for Bastion

resource "aws_eip" "BasicLinuxBastion-EIP" {

    vpc = true
    network_interface = "${aws_network_interface.NIC-Bastion.id}"


}

# Creating Public IP for Web1

resource "aws_eip" "BasicLinuxWeb1-EIP" {

    vpc = true
    network_interface = "${aws_network_interface.NIC-Web1.id}"


}

# Creating Public IP for Web2

resource "aws_eip" "BasicLinuxWeb2-EIP" {

    vpc = true
    network_interface = "${aws_network_interface.NIC-Web2.id}"


}

# Creating Public IP for Nat Gateway

resource "aws_eip" "BasicLinuxnatgw-EIP" {

    vpc = true


}

######################################################################
# NAT Gateway for Bastion access
######################################################################

resource "aws_nat_gateway" "BasicLinuxnatgw" {

    allocation_id = "${aws_eip.BasicLinuxnatgw-EIP.id}"
    subnet_id = "${aws_subnet.Subnet-BasicLinuxFrontEnd1.id}"
}

######################################################################
# Load Balancing
######################################################################

# Creating S3 bucket for logs

resource "aws_s3_bucket" "basiclinuxalblogstorage" {

    bucket = "dfrelblogs"
    /*policy = <<EOF
    {

        "Version":"2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::156460612806:root"
                },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::dfrelblogs/*"
            }
        ]
    }
    EOF
    */
        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "BasicLinux-ALBLogStorage"
    }
    
}

# Creating ALB Classic for front end http / https

resource "aws_alb" "BasicLinux-WebALB" {

    name                = "BasicLinux-WebALB"
    internal            = false
    subnets             = ["${aws_subnet.Subnet-BasicLinuxFrontEnd1.id}","${aws_subnet.Subnet-BasicLinuxFrontEnd2.id}"]
    security_groups     = ["${aws_security_group.NSG-ALB.id}"]
    idle_timeout        = 60
    depends_on          = ["aws_s3_bucket.basiclinuxalblogstorage","aws_instance.Web1","aws_instance.Web2"]
    
    /*    access_logs {

        bucket          = "dfrelblogs"
        bucket_prefix   = "log"
        interval        = 60
    }
    */


    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "BasicLinux-WebALB"
    }
}

# Creating alb listener

resource "aws_alb_listener" "BasicLinuxWebALBListenerHTTP" {

    load_balancer_arn   = "${aws_alb.BasicLinux-WebALB.arn}"
    port                = "80"
    protocol            = "HTTP"

    default_action {

        target_group_arn = "${aws_alb_target_group.BasicLinuxWebALBTargetGroup.arn}"
        type = "forward"
    }

}

# Creating alb listener rule

resource "aws_alb_listener_rule" "BasicLinuxWebALBListenerHTTPRule" {

    listener_arn    = "${aws_alb_listener.BasicLinuxWebALBListenerHTTP.arn}"
    priority        = 100

    action {

        type                = "forward"
        target_group_arn    = "${aws_alb_target_group.BasicLinuxWebALBTargetGroup.arn}"
    }

    condition {

        field   = "path-pattern"
        values  = ["/"]
    }
}

# Creating alb target group

resource "aws_alb_target_group" "BasicLinuxWebALBTargetGroup" {

    name = "BasicLinuxWebALBTargetGroup"
    port = 80
    protocol = "HTTP"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"
}

# Creating alb targer group attachment for instance Web1

resource "aws_alb_target_group_attachment" "BasicLinuxWebALBTargetGroupAttachmentWeb1" {

    target_group_arn    = "${aws_alb_target_group.BasicLinuxWebALBTargetGroup.id}"
    target_id           = "${aws_instance.Web1.id}"
    port                = 80
}

# Creating alb targer group attachment for instance Web2

resource "aws_alb_target_group_attachment" "BasicLinuxWebALBTargetGroupAttachmentWeb2" {

    target_group_arn    = "${aws_alb_target_group.BasicLinuxWebALBTargetGroup.id}"
    target_id           = "${aws_instance.Web2.id}"
    port                = 80
}

###########################################################################
# EBS Volume
###########################################################################

# EBS for Web frontend VMs

resource "aws_volume_attachment" "ebsweb1attach" {

    device_name         = "/dev/sde" # it seems that's AWS reserves sdx from a to d so starting from sde is recommanded. For paravirtual, use sde1, sde2...
    volume_id           = "${aws_ebs_volume.ebsvol-web1.id}"
    instance_id         = "${aws_instance.Web1.id}"
}

resource "aws_ebs_volume" "ebsvol-web1" {
    availability_zone   = "${var.AWSAZ1}"
    size                = 31
}


resource "aws_volume_attachment" "ebsweb2attach" {

    device_name         = "/dev/sde"
    volume_id           = "${aws_ebs_volume.ebsvol-web2.id}"
    instance_id         = "${aws_instance.Web2.id}"
}

resource "aws_ebs_volume" "ebsvol-web2" {
    availability_zone   = "${var.AWSAZ2}"
    size                = 31
}

# EBS for DB Backend VMs

resource "aws_volume_attachment" "ebsDB1attach" {

    device_name         = "/dev/sde" # it seems that's AWS reserves sdx from a to d so starting from sde is recommanded. For paravirtual, use sde1, sde2...
    volume_id           = "${aws_ebs_volume.ebsvol-DB1.id}"
    instance_id         = "${aws_instance.DB1.id}"
}

resource "aws_ebs_volume" "ebsvol-DB1" {
    availability_zone   = "${var.AWSAZ1}"
    size                = 31
}


resource "aws_volume_attachment" "ebsDB2attach" {

    device_name         = "/dev/sde"
    volume_id           = "${aws_ebs_volume.ebsvol-DB2.id}"
    instance_id         = "${aws_instance.DB2.id}"
}

resource "aws_ebs_volume" "ebsvol-DB2" {
    availability_zone   = "${var.AWSAZ2}"
    size                = 31
}

# EBS for Bastion VM

resource "aws_volume_attachment" "ebsbastionattach" {

    device_name         = "/dev/sde"
    volume_id           = "${aws_ebs_volume.ebsvol-bastion.id}"
    instance_id         = "${aws_instance.Bastion.id}"
}

resource "aws_ebs_volume" "ebsvol-bastion" {
    availability_zone   = "${var.AWSAZ3}"
    size                = 31
}


###########################################################################
#NICs creation
###########################################################################

# NIC Creation for Web FrontEnd VMs

resource aws_network_interface "NIC-Web1" {

    subnet_id = "${aws_subnet.Subnet-BasicLinuxFrontEnd1.id}"
    private_ips = ["172.17.0.10"]

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NIC-Web1"
    }


}

resource "aws_network_interface" "NIC-Web2" {

    subnet_id = "${aws_subnet.Subnet-BasicLinuxFrontEnd2.id}"
    private_ips = ["172.17.0.138"]

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NIC-Web2"
    }


}

# NIC Creation for DB BackEnd VMs

resource aws_network_interface "NIC-DB1" {

    subnet_id = "${aws_subnet.Subnet-BasicLinuxBackEnd1.id}"
    private_ips = ["172.17.1.10"]

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NIC-DB1"
    }


}

resource "aws_network_interface" "NIC-DB2" {

    subnet_id = "${aws_subnet.Subnet-BasicLinuxBackEnd2.id}"
    private_ips = ["172.17.1.138"]

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NIC-DB2"
    }


}

# NIC Creation for Bastion VMs

resource "aws_network_interface" "NIC-Bastion" {

    subnet_id = "${aws_subnet.Subnet-BasicLinuxBastion1.id}"
    private_ips = ["172.17.2.10"]

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NIC-Bastion"
    }


}


###########################################################################
# NIC SG association
###########################################################################

# NIC Front End SG association

resource "aws_network_interface_sg_attachment" "NICWebFrontEnd1-SGAttachment" {

    
    security_group_id       = "${aws_security_group.NSG-FrontEnd.id}"
    network_interface_id    = "${aws_network_interface.NIC-Web1.id}"

}

resource "aws_network_interface_sg_attachment" "NICFWebFrontEnd2-SGAttachment" {

    
    security_group_id       = "${aws_security_group.NSG-FrontEnd.id}"
    network_interface_id    = "${aws_network_interface.NIC-Web2.id}"

}

# NIC Backend SG Association

resource "aws_network_interface_sg_attachment" "NICDBBackEnd1-SGAttachment" {

    
    security_group_id       = "${aws_security_group.NSG-BackEnd.id}"
    network_interface_id    = "${aws_network_interface.NIC-DB1.id}"

}

resource "aws_network_interface_sg_attachment" "NICDBBackEnd2-SGAttachment" {

    
    security_group_id       = "${aws_security_group.NSG-BackEnd.id}"
    network_interface_id    = "${aws_network_interface.NIC-DB2.id}"

}

# NIC Bastion SG Association

resource "aws_network_interface_sg_attachment" "NICBastion-SGAttachment" {

    
    security_group_id       = "${aws_security_group.NSG-Bastion.id}"
    network_interface_id    = "${aws_network_interface.NIC-Bastion.id}"

}


###########################################################################
#VMs Creation
###########################################################################

# AWS Keypair

resource "aws_key_pair" "AWSWebKey" {
  key_name   = "AWSWebKey"
  public_key = "${var.AWSKeypair}"
  }


# Web FrontEnd VMs creation

resource "aws_instance" "Web1" {

    ami = "${var.AMIId}"
    instance_type = "${var.VMSize}"
    key_name = "${aws_key_pair.AWSWebKey.key_name}"
    network_interface {
        network_interface_id = "${aws_network_interface.NIC-Web1.id}"
        device_index = 0

    }
    user_data = "${file("userdataweb.sh")}"
     tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Web1"
    }
} 

resource "aws_instance" "Web2" {

    ami = "${var.AMIId}"
    instance_type = "${var.VMSize}"
    key_name = "${aws_key_pair.AWSWebKey.key_name}"
    network_interface {
        network_interface_id = "${aws_network_interface.NIC-Web2.id}"
        device_index = 0

    }
    user_data = "${file("userdataweb.sh")}"
     tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Web2"
    }
} 


# DB BackEnd VMs Creation

resource "aws_instance" "DB1" {

    ami = "${var.AMIId}"
    instance_type = "${var.VMSize}"
    key_name = "${aws_key_pair.AWSWebKey.key_name}"
    network_interface {
        network_interface_id = "${aws_network_interface.NIC-DB1.id}"
        device_index = 0

    }
    user_data = "${file("userdatadb.sh")}"
     tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "DB1"
    }
} 

resource "aws_instance" "DB2" {

    ami = "${var.AMIId}"
    instance_type = "${var.VMSize}"
    key_name = "${aws_key_pair.AWSWebKey.key_name}"
    network_interface {
        network_interface_id = "${aws_network_interface.NIC-DB2.id}"
        device_index = 0

    }
    user_data = "${file("userdatadb.sh")}"
     tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "DB2"
    }
} 


# Bastion VM Creation

resource "aws_instance" "Bastion" {

    ami = "${var.AMIId}"
    instance_type = "${var.VMSize}"
    key_name = "${aws_key_pair.AWSWebKey.key_name}"
    network_interface {
        network_interface_id = "${aws_network_interface.NIC-Bastion.id}"
        device_index = 0

    }
    user_data = "${file("userdatabastion.sh")}"
     tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "Bastion"
    }
} 



#####################################################################################
# Output
#####################################################################################



output "Public IP Bastion" {
  value = "${aws_instance.Bastion.public_ip}"
}

output "Public IP Web1" {
  value = "${aws_instance.Web1.public_ip}"
}

output "Public IP Web2" {
  value = "${aws_instance.Web2.public_ip}"
}

output "Private IP  Web1" {
  value = "${aws_instance.Web1.private_ip}"
}

output "Private IP  Web2" {
  value = "${aws_instance.Web2.private_ip}"
}

output "Private IP  DB1" {
  value = "${aws_instance.DB1.private_ip}"
}

output "Private IP  DB2" {
  value = "${aws_instance.DB2.private_ip}"
}

output "FQDN du Web Load Balancer" {
  value = "${aws_alb.BasicLinux-WebALB.dns_name}"
}