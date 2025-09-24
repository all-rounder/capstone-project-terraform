locals {
  name_prefix = "capstone-project"
  tags = {
    Project = local.name_prefix
    Owner   = "dev-team"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(local.tags, { Name = "${local.name_prefix}-vpc" })
}

# Public subnets (3)
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = length(var.availability_zones) >= 3 ? var.availability_zones[tonumber(each.key)] : null
  map_public_ip_on_launch = true
  tags = merge(local.tags, { Name = "${local.name_prefix}-public-${each.key}" , Tier = "public" })
}

# Private subnets (3)
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = length(var.availability_zones) >= 3 ? var.availability_zones[tonumber(each.key)] : null
  map_public_ip_on_launch = false
  tags = merge(local.tags, { Name = "${local.name_prefix}-private-${each.key}" , Tier = "private" })
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "${local.name_prefix}-igw" })
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, { Name = "${local.name_prefix}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# EIP + NAT Gateway per AZ (one per public subnet)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  tags = merge(local.tags, { Name = "${local.name_prefix}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags = merge(local.tags, { Name = "${local.name_prefix}-natgw-${each.key}" })
  depends_on = [aws_internet_gateway.igw]
}

# Private route tables -> each private subnet routes via NAT in the same AZ (same index)
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id = aws_vpc.main.id
  tags = merge(local.tags, { Name = "${local.name_prefix}-private-rt-${each.key}" })
}

resource "aws_route" "private_nat_route" {
  for_each = aws_subnet.private
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  # map private index to NAT of same index
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Security Group for bastion (SSH)
resource "aws_security_group" "bastion_sg" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Allow SSH inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-bastion-sg" })
}

# Look up canonical Ubuntu 24.04 AMI (most_recent)
data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Import existing key pair (must exist in the region)
resource "aws_key_pair" "capstone_key_pair" {
  key_name   = "capstone-key"
  public_key = file("~/.ssh/capstone-project-key.pub")
}

# Bastion EC2 instance in first public subnet
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu_24.id
  instance_type = "t3.small"
  subnet_id     = aws_subnet.public[0].id
  key_name      = aws_key_pair.capstone_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/templates/bastion_userdata.tpl", {
    ansible_git_repo     = var.ansible_git_repo
    ansible_playbook_file = var.ansible_playbook_file
  })

  tags = merge(local.tags, { Name = "${local.name_prefix}-bastion", Role = "bastion" })
}

