/*This template aims is to create the following architecture

1 VPC
1 Subnet FrontEnd
1 Subnet BackEnd
1 Subnet Bastion
2 VM FrontEnd Web Apache + Elastic Load Balancer
2 VM Backend DB PostgreSQL 
1 VM Linux Bastion
1 public IP on FrontEnd
1 public IP on Bastion
1 external Load Balancer
NAT Gateway
Internet Gateway
EBS Volume
NSG on FrontEnd Subnet
    Allow HTTP HTTPS from Internet through ALB
    Allow Access to internet egress
    Allow PostgreSQL to DB Tier
NSG on Backend Subnet
    Allow PostgreSQL Access from Web tier
    Allow egress Internet
NSG on Bastion
    Allow SSH from internet
    Allow SSH to all subnet
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
    availability_zone = "${var.AWSAZ1}"

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


# Creating NACL for frontend

resource "aws_network_acl" "NACL-FrontEnd" {

    vpc_id = "${aws_vpc.vpc-basiclinux.id}"
    subnet_ids = ["${aws_subnet.Subnet-BasicLinuxFrontEnd1.id}","${aws_subnet.Subnet-BasicLinuxFrontEnd2.id}"]

        tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "NACL-FrontEnd"
    }
}

resource "aws_network_acl_rule" "NACL-FrontEnd-HTTPin" {
    
    network_acl_id = "${aws_network_acl.NACL-FrontEnd.id}"

    rule_number = 1003
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = "80"
    to_port = "80"


}

resource "aws_network_acl_rule" "NACL-FrontEnd-HTTPSin" {
    
    network_acl_id = "${aws_network_acl.NACL-FrontEnd.id}"

    rule_number = 1004
    egress = false
    protocol = "tcp"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = "443"
    to_port = "443"


}

resource "aws_network_acl_rule" "NACL-FrontEnd-anyout" {
    
    network_acl_id = "${aws_network_acl.NACL-FrontEnd.id}"

    rule_number = 1005
    egress = true
    protocol = "-1"
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = "0"
    to_port = "0"
  

}

######################################################################
# Security Group
######################################################################

#Security Group for ELB

resource "aws_security_group" "NSG-ELB" {

    name = "NSG-ELB"
    description = "Security Group for ELB"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        
    }
}

#Rules for SG ELB HTTP In

resource "aws_security_group_rule" "NSG-ELB-HTTPIn" {

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-ELB.id}"
    

}

#Rules for SG Front End * outbound

resource "aws_security_group_rule" "NSG-ELB-AnyOut" {

    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-ELB.id}"
    

}




#Security Group for FrontEnd

resource "aws_security_group" "NSG-FrontEnd" {

    name = "NSG-FrontEnd"
    description = "Security Group for FrontEnd"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        
    }
}

#Rules for SG Front End HTTP In

resource "aws_security_group_rule" "NSG-FrontEnd-HTTPIn" {

    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-FrontEnd.id}"
    

}


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

#Security Group for Bastion
resource "aws_security_group" "NSG-Bastion" {

    name = "NSG-Bastion"
    description = "Security Gruop for Backend"
    vpc_id = "${aws_vpc.vpc-basiclinux.id}"

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        
    }
}


#Rules for SG Bastion SSH In

resource "aws_security_group_rule" "NSG-Bastion-SSHIn" {

    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_security_group.NSG-Bastion.id}"
    

}

#Rules for SG Bastion * outbound

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

}

resource "aws_route_table" "natgw" {

    vpc_id                  = "${aws_vpc.vpc-basiclinux.id}" 
    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = "${aws_nat_gateway.BasicLinuxnatgw.id}"
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

resource "aws_s3_bucket" "basiclinuxelblogstorage" {

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
        Name        = "BasicLinux-ELBLogStorage"
    }
    
}

# Creating ELB Classic for front end http / https

resource "aws_elb" "BasicLinux-WebELB" {

    name                = "BasicLinuxWebELB"
    subnets             = ["${aws_subnet.Subnet-BasicLinuxFrontEnd1.id}","${aws_subnet.Subnet-BasicLinuxFrontEnd2.id}"]
    security_groups      = ["${aws_security_group.NSG-ELB.id}"]
    depends_on          = ["aws_s3_bucket.basiclinuxelblogstorage","aws_instance.Web1","aws_instance.Web2"]
    /*    access_logs {

        bucket          = "dfrelblogs"
        bucket_prefix   = "log"
        interval        = 60
    }
    */
    listener {
        
        instance_port       = 80
        instance_protocol   = "http"
        lb_port             = 80
        lb_protocol         = "http"

    }

    health_check {

        healthy_threshold       = 2
        unhealthy_threshold     = 2
        timeout                 = 3
        target                  = "HTTP:80/"
        interval                = 30

    }

    instances                   = ["${aws_instance.Web1.id}","${aws_instance.Web2.id}"]
    cross_zone_load_balancing   = true
    idle_timeout                = 400
    connection_draining         = true
    connection_draining_timeout = 400

    tags {
        environment = "${var.TagEnvironment}"
        usage       = "${var.TagUsage}"
        Name        = "BasicLinux-WebELB"
    }
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
