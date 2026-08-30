locals { name = "${var.project}-${var.environment}" }
resource "aws_vpc" "this" { cidr_block = var.vpc_cidr enable_dns_hostnames = true enable_dns_support = true tags = { Name = "${local.name}-vpc" } }
resource "aws_internet_gateway" "this" { vpc_id = aws_vpc.this.id }
resource "aws_subnet" "public" { count = 2 vpc_id = aws_vpc.this.id cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index) availability_zone = var.azs[count.index] map_public_ip_on_launch = false tags = { Name = "${local.name}-public-${count.index + 1}" } }
resource "aws_subnet" "private" { count = 2 vpc_id = aws_vpc.this.id cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 2) availability_zone = var.azs[count.index] tags = { Name = "${local.name}-private-${count.index + 1}" } }
resource "aws_subnet" "db" { count = 2 vpc_id = aws_vpc.this.id cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 4) availability_zone = var.azs[count.index] tags = { Name = "${local.name}-db-${count.index + 1}" } }
resource "aws_route_table" "public" { vpc_id = aws_vpc.this.id route { cidr_block = "0.0.0.0/0" gateway_id = aws_internet_gateway.this.id } }
resource "aws_route_table_association" "public" { count = 2 subnet_id = aws_subnet.public[count.index].id route_table_id = aws_route_table.public.id }
# Private workloads deliberately have no default route; add NAT only when needed.
resource "aws_security_group" "endpoint" { name = "${local.name}-vpce" vpc_id = aws_vpc.this.id ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = [var.vpc_cidr] } egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] } }
resource "aws_vpc_endpoint" "ssm" { for_each = toset(["ssm", "ssmmessages", "ec2messages"]) vpc_id = aws_vpc.this.id service_name = "com.amazonaws.${var.region}.${each.value}" vpc_endpoint_type = "Interface" subnet_ids = aws_subnet.private[*].id security_group_ids = [aws_security_group.endpoint.id] private_dns_enabled = true }
