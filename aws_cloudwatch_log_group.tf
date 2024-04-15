resource "aws_cloudwatch_log_group" "vpn-logs" {
  name              = "${var.project-name}/vpn/logs/"
  retention_in_days = var.logs_retention_in_days
}
resource "aws_cloudwatch_log_stream" "vpn-logs-stream" {
  name           = "connection_logs"
  log_group_name = aws_cloudwatch_log_group.vpn-logs.name
}
