resource "aws_instance" "ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name

  user_data = var.user_data_file != "" ? templatefile(var.user_data_file, {
  master_ip = var.master_ip
}) : null

  root_block_device {
    volume_size = 20      # GB
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = var.instance_name
  }
}
