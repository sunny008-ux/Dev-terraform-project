module "vpc" {
  source = "../../modules/vpc"

  vpc_name            = var.vpc_name
  vpc_cidr            = "10.0.0.0/16"
  az                  = "${var.aws_region}a"
  public_subnet_cidr  = "10.0.10.0/24"
  private_subnet_cidr = "10.0.20.0/24"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "sg" {
  name   = "devops-project-sg"
  vpc_id = module.vpc.vpc_id

  # SSH
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API (Master)
  ingress {
    description = "K8s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Worker <-> Master communication
  ingress {
    description = "Node to Node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow NodePort range"
    from_port   = 30000
    to_port     = 32767
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

module "ec2_instance_1" {
  source = "../../modules/ec2"

  instance_name = "Master"
  instance_type = "m7i-flex.large"
  key_name      = var.key_name

  ami       = "ami-0b6c6ebed2801a5cb"
  subnet_id = module.vpc.public_subnet_id
  vpc_id    = module.vpc.vpc_id
  sg_id     = aws_security_group.sg.id

  user_data_file = "../../modules/ec2/scripts/install.sh"
}

module "ec2_instance_2" {
  source = "../../modules/ec2"

  instance_name = "Node_1"
  instance_type = "m7i-flex.large"
  key_name      = var.key_name

  ami       = "ami-0b6c6ebed2801a5cb"
  subnet_id = module.vpc.public_subnet_id
  vpc_id    = module.vpc.vpc_id
  sg_id     = aws_security_group.sg.id

  user_data_file = "../../modules/ec2/scripts/worker.sh.tpl"
}

module "ec2_instance_3" {
  source = "../../modules/ec2"

  instance_name = "Node_2"
  instance_type = "m7i-flex.large"
  key_name      = var.key_name

  ami       = "ami-0b6c6ebed2801a5cb"
  subnet_id = module.vpc.public_subnet_id
  vpc_id    = module.vpc.vpc_id
  sg_id     = aws_security_group.sg.id

  user_data_file = "../../modules/ec2/scripts/worker.sh.tpl"
}

