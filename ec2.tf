#踏み台サーバー
resource "aws_instance" "ec2_bastion" {
  ami                                  = "ami-01ead1eca9a200e01"
  associate_public_ip_address          = true
  availability_zone                    = "ap-northeast-1a"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = false
  enable_primary_ipv6                  = null
  get_password_data                    = false
  hibernation                          = false
  host_id                              = null
  host_resource_group_arn              = null
  iam_instance_profile                 = null
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "t2.micro"
  # ipv6_address_count                   = 0
  # ipv6_addresses                       = []
  key_name                             = "test-key"
  monitoring                           = false
  placement_group                      = null
  placement_partition_number           = 0
  private_ip                           = "10.0.13.181"
  region                               = "ap-northeast-1"
  secondary_private_ips                = []
  security_groups                      = []
  source_dest_check                    = true
  subnet_id                            = "subnet-0a5a9a5507517ec42"
  tags = {
    Name = "test-ec2-bastion"
  }
  tags_all = {
    Name = "test-ec2-bastion"
  }
  tenancy                     = "default"
  user_data                   = null
  user_data_base64            = null
  user_data_replace_on_change = null
  volume_tags                 = null
  vpc_security_group_ids      = ["sg-033a37fbc45d8fd9b", "sg-0fcd5294b638b1929"]
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  # cpu_options {
  #   amd_sev_snp      = null
  #   core_count       = 1
  #   threads_per_core = 1
  # }
  credit_specification {
    cpu_credits = "standard"
  }
  enclave_options {
    enabled = false
  }
  maintenance_options {
    auto_recovery = "default"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    # iops                  = 100
    kms_key_id            = null
    tags                  = {}
    tags_all              = {}
    throughput            = 0
    volume_size           = 8
    volume_type           = "gp2"
  }
}

#Web01サーバー
resource "aws_instance" "ec2_web01" {
  ami                                  = "ami-01ead1eca9a200e01"
  associate_public_ip_address          = false
  availability_zone                    = "ap-northeast-1a"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = false
  enable_primary_ipv6                  = null
  get_password_data                    = false
  hibernation                          = false
  host_id                              = null
  host_resource_group_arn              = null
  iam_instance_profile                 = null
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "t2.micro"
  # ipv6_address_count                   = 0
  # ipv6_addresses                       = []
  key_name                             = "test-key"
  monitoring                           = false
  placement_group                      = null
  placement_partition_number           = 0
  private_ip                           = "10.0.75.61"
  region                               = "ap-northeast-1"
  secondary_private_ips                = []
  security_groups                      = []
  source_dest_check                    = true
  subnet_id                            = "subnet-02e4659f4f9508a49"
  tags = {
    Name = "test-ec2-web01"
  }
  tags_all = {
    Name = "test-ec2-web01"
  }
  tenancy                     = "default"
  user_data                   = null
  user_data_base64            = null
  user_data_replace_on_change = null
  volume_tags                 = null
  vpc_security_group_ids      = ["sg-0fcd5294b638b1929"]
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  # cpu_options {
  #   amd_sev_snp      = null
  #   core_count       = 1
  #   threads_per_core = 1
  # }
  credit_specification {
    cpu_credits = "standard"
  }
  enclave_options {
    enabled = false
  }
  maintenance_options {
    auto_recovery = "default"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    # iops                  = 100
    kms_key_id            = null
    tags                  = {}
    tags_all              = {}
    throughput            = 0
    volume_size           = 8
    volume_type           = "gp2"
  }
}

#Web02サーバー
resource "aws_instance" "ec2_web02" {
  ami                                  = "ami-01ead1eca9a200e01"
  associate_public_ip_address          = false
  availability_zone                    = "ap-northeast-1c"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = false
  enable_primary_ipv6                  = null
  get_password_data                    = false
  hibernation                          = false
  host_id                              = null
  host_resource_group_arn              = null
  iam_instance_profile                 = null
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "t2.micro"
  # ipv6_address_count                   = 0
  # ipv6_addresses                       = []
  key_name                             = "test-key"
  monitoring                           = false
  placement_group                      = null
  placement_partition_number           = 0
  private_ip                           = "10.0.91.216"
  region                               = "ap-northeast-1"
  secondary_private_ips                = []
  security_groups                      = []
  source_dest_check                    = true
  subnet_id                            = "subnet-007c1603e4a7a6ed4"
  tags = {
    Name = "test-ec2-web02"
  }
  tags_all = {
    Name = "test-ec2-web02"
  }
  tenancy                     = "default"
  user_data                   = null
  user_data_base64            = null
  user_data_replace_on_change = null
  volume_tags                 = null
  vpc_security_group_ids      = ["sg-0fcd5294b638b1929"]
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  # cpu_options {
  #   amd_sev_snp      = null
  #   core_count       = 1
  #   threads_per_core = 1
  # }
  credit_specification {
    cpu_credits = "standard"
  }
  enclave_options {
    enabled = false
  }
  maintenance_options {
    auto_recovery = "default"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    # iops                  = 100
    kms_key_id            = null
    tags                  = {}
    tags_all              = {}
    throughput            = 0
    volume_size           = 8
    volume_type           = "gp2"
  }
}
