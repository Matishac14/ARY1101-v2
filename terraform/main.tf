# --- DATA SOURCES ---
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --- VPC & NETWORKING ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/22"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "vpc-matias-fernandez" }
}

resource "aws_subnet" "pub_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-pub-matias-fernandez" }
}

resource "aws_subnet" "pub_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "subnet-pub2-matias-fernandez" }
}

resource "aws_subnet" "priv_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "subnet-priv-matias-fernandez" }
}

resource "aws_subnet" "priv_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "subnet-priv2-matias-fernandez" }
}

# --- GATEWAYS & ROUTING ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "igw-matias-fernandez" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "eip-matias-fernandez" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.pub_1.id
  tags          = { Name = "nat-matias-fernandez" }
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "rtb-pub-matias-fernandez" }
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table" "priv" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "rtb-priv-matias-fernandez" }
}

resource "aws_route_table_association" "priv_1" {
  subnet_id      = aws_subnet.priv_1.id
  route_table_id = aws_route_table.priv.id
}

resource "aws_route_table_association" "priv_2" {
  subnet_id      = aws_subnet.priv_2.id
  route_table_id = aws_route_table.priv.id
}

# --- SECURITY GROUPS ---
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-matias-fernandez"
  description = "Traffic for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-matias-fernandez"
  description = "Traffic for App Instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 3002
    to_port         = 3002
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg-matias-fernandez"
  description = "Traffic for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- LOAD BALANCER ---
resource "aws_lb" "alb" {
  name               = "alb-matias-fernandez"
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
  security_groups    = [aws_security_group.alb_sg.id]
  tags               = { Name = "alb-matias-fernandez" }
}

resource "aws_lb_target_group" "tg_frontend" {
  name        = "tg-frontend-matias-fernandez"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check { path = "/" }
}

resource "aws_lb_target_group" "tg_productos" {
  name        = "tg-productos-matias-fernandez"
  port        = 3001
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check { path = "/api/productos" }
}

resource "aws_lb_target_group" "tg_pedidos" {
  name        = "tg-pedidos-matias-fernandez"
  port        = 3002
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  health_check { path = "/api/pedidos" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }
}

resource "aws_lb_listener_rule" "productos" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_productos.arn
  }
  condition {
    path_pattern { values = ["/api/productos*"] }
  }
}

resource "aws_lb_listener_rule" "pedidos" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_pedidos.arn
  }
  condition {
    path_pattern { values = ["/api/pedidos*"] }
  }
}

# --- DATABASE (RDS) ---
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group-matias-fernandez"
  subnet_ids = [aws_subnet.priv_1.id, aws_subnet.priv_2.id]
}

resource "aws_db_instance" "rds" {
  identifier              = "rds-matias-fernandez"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  storage_type            = "gp2"
  db_name                 = "technova"
  username                = "admin"
  password                = var.db_master_password
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  apply_immediately       = true
  monitoring_interval     = 0 # OBLIGATORIO Learner Lab
  backup_retention_period = 0
}

# --- COMPUTE (EC2) ---
resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.priv_1.id
  iam_instance_profile        = "LabInstanceProfile"
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = false

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    rds_endpoint   = aws_db_instance.rds.address
    db_master_pass = var.db_master_password
    db_user_pass   = var.db_user_password
  }))

  depends_on = [aws_db_instance.rds]

  tags = { Name = "ec2-matias-fernandez" }
}

# --- TARGET GROUP ATTACHMENTS ---
resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.tg_frontend.arn
  target_id        = aws_instance.ec2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "productos" {
  target_group_arn = aws_lb_target_group.tg_productos.arn
  target_id        = aws_instance.ec2.id
  port             = 3001
}

resource "aws_lb_target_group_attachment" "pedidos" {
  target_group_arn = aws_lb_target_group.tg_pedidos.arn
  target_id        = aws_instance.ec2.id
  port             = 3002
}