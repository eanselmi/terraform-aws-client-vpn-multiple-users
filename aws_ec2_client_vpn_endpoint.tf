resource "aws_ec2_client_vpn_endpoint" "vpn-client" {
  description            = var.project-name
  server_certificate_arn = aws_acm_certificate.server.arn
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.vpn.id]
  client_cidr_block      = var.client_cidr_block
  session_timeout_hours  = var.session_timeout_hours

  split_tunnel = var.split_tunnel
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client["root"].arn
  }
  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn-logs.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn-logs-stream.name
  }
  tags = {
    Name = "${var.organization_name}"
  }
}
resource "aws_ec2_client_vpn_network_association" "vpn-client" {
  count                  = length(var.subnets_id)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  subnet_id              = var.subnets_id[count.index]
}
resource "aws_ec2_client_vpn_authorization_rule" "vpn-client" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
  depends_on = [
    aws_ec2_client_vpn_endpoint.vpn-client,
    aws_ec2_client_vpn_network_association.vpn-client
  ]
}

resource "aws_ec2_client_vpn_route" "routes" {
  count                  = length(var.additional_routes)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn-client.id
  destination_cidr_block = var.additional_routes[count.index].destination_cidr
  target_vpc_subnet_id   = var.additional_routes[count.index].subnet_id
}
