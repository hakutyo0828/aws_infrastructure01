#NAT-GW01
resource "aws_nat_gateway" "nat_gw01" {
  allocation_id                      = "eipalloc-0312fa4cb90b241cb"
  connectivity_type                  = "public"
  private_ip                         = "10.0.0.234"
  region                             = "ap-northeast-1"
  secondary_allocation_ids           = []
  #secondary_private_ip_address_count = 0
  secondary_private_ip_addresses     = []
  subnet_id                          = "subnet-0a5a9a5507517ec42"
  tags = {
    Name = "test-ngw-01"
  }
  tags_all = {
    Name = "test-ngw-01"
  }
}

#NAT-GW02
resource "aws_nat_gateway" "nat_gw02" {
  allocation_id                      = "eipalloc-0490325cb20787918"
  connectivity_type                  = "public"
  private_ip                         = "10.0.16.43"
  region                             = "ap-northeast-1"
  secondary_allocation_ids           = []
  #secondary_private_ip_address_count = 0
  secondary_private_ip_addresses     = []
  subnet_id                          = "subnet-0023cac1a329a4b8c"
  tags = {
    Name = "test-ngw-02"
  }
  tags_all = {
    Name = "test-ngw-02"
  }
}
