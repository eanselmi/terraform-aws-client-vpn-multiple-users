<!-- markdownlint-disable -->

# This Terraform module provides a convenient solution for deploying AWS client vpn solution with the ability to manage multuple users using self-signed certificated. [![Latest Release](https://img.shields.io/github/v/release/eanselmi/terraform-aws-client-vpn-multiple-users.svg)](https://github.com/eanselmi/terraform-aws-client-vpn-multiple-users/releases/latest)

<!-- markdownlint-restore -->

![image](https://i.ibb.co/LxHCSNH/clientvpn.jpg)

<br/>

# How does it work?

## This module will facilitate the deployment of the following resources:

- AWS Client vpn endpoint
- Subnet associations
- Certificates for each user stored in aws parameter store
- ACM certificates
- S3 bucket for storing the Openvpn config files
- Openvpn config file for each user

<br/>

## Inputs

| Name                   | Description                                                                                            | Type                | Default | Required |
| ---------------------- | ------------------------------------------------------------------------------------------------------ | ------------------- | ------- | :------: | --- | ------------------------------------------- | --------- | ---- | --- |
| organization_name      | Name of the organization                                                                               | `string`            | `{}`    |   yes    |
| project-name           | Name of the project                                                                                    | `string`            | `{}`    |   yes    |
| aws-vpn-client-list    | Set of users (example "john"), the firrst item of the list will be the certificate of the server       | `set(string)`       | `{}`    |   yes    |
| vpc_id                 | Id of the VPC                                                                                          | `string`            | `{}`    |   yes    |
| subnets_id             | List of the subnets to deploy the vpn endpoint                                                         | `list(string)`      | `{}`    |   yes    |
| client_cidr_block      | CIDR block for vpn users                                                                               | `string`            | `{}`    |   yes    |
| split_tunnel           | Flag to indicate if split tunnel must be used                                                          | `bool`              | `{}`    |   yes    |
| vpn_inactive_period    | Flag to indicate (in minutes) when a user should be disconnected if there is no activity in the tunnel | `numeric`           | `{}`    |   yes    |
| session_timeout_hours  | Flag to indicate (in hours) the session timeout                                                        | `numeric`           | `{}`    |   yes    |
| logs_retention_in_days | Retention perior for vpn logs in cloudwatch                                                            | `numeric`           | `{}`    |   yes    |
| additional_routes      | List of additional routes                                                                              | `list(map(string))` | `{}`    |   yes    |     | Retention perior for vpn logs in cloudwatch | `numeric` | `{}` | yes |

## Example

```
locals {
  cliet_vpn = {
    organization_name      = "mycompany"
    project-name           = "client-vpn"
    aws-vpn-client-list    = ["root", "john", "michael", "clara"]
    client_cidr_block      = "172.24.0.0/22"
    split_tunnel           = true
    vpn_inactive_period    = 1800
    session_timeout_hours  = 8
    logs_retention_in_days = 7
    additional_routes = [{
      destination_cidr = "10.100.0.0/16"
      description      = "strging"
      subnet_id        = subnet-0b509a1c548112f26
    }]
  }
}
module "client-vpn" {
  source  = "eanselmi/client-vpn-multiple-users/aws"
  version = "1.0.2"
  organization_name      = local.cliet_vpn.organization_name
  project-name           = local.cliet_vpn.project-name
  aws-vpn-client-list    = local.cliet_vpn.aws-vpn-client-list
  vpc_id                 = vpc-0a959fbbb6e218299
  subnets_id             = [subnet-0b509a1c548112f30]
  client_cidr_block      = local.cliet_vpn.client_cidr_block
  split_tunnel           = local.cliet_vpn.split_tunnel
  vpn_inactive_period    = local.cliet_vpn.vpn_inactive_period
  session_timeout_hours  = local.cliet_vpn.session_timeout_hours
  logs_retention_in_days = local.cliet_vpn.logs_retention_in_days
  additional_routes      = local.cliet_vpn.additional_routes
}

```

## How to remove/revoke users

An important part is how to delete or revoke a user; it is not enough to remove them from the list and delete their certificate. The certificate must be revoked, and this must be done outside of Terraform, and the VPN must be updated. These are the steps:

1. From AWS-Parameter-Store, download the certificate and private key of the CA
2. From AWS-Parameter-Store, download the certificate that we want to revoke
3. We open a terminal and go to the directory where we are going to manage the downloaded certificates
4. Adjust the default_crl_days variable in your openssl.cnf config file (default value is 30 days, you can find the file with openssl version -d
   )
5. To revoke the certificate, please execute "openssl ca -revoke user.cer -keyfile ca.key -cert ca.cer"
6. Now update the CRL "openssl ca -gencrl -out revocations.crl -keyfile ca.key -cert ca.cer"
7. We import the CRL to our VPN endpoint "aws ec2 import-client-vpn-client-certificate-revocation-list --certificate-revocation-list file://revocations.crl --client-vpn-endpoint-id endpoint_id --region region" We can import the CRL using the AWS console
8. Validate CRL expiration date using "openssl crl -in revocations.crl -text"

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.1.7 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.4.0 |
| <a name="requirement_tls"></a> [tls](#requirement_tls)                   | 3.1.0    |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 4.4.0 |
| <a name="provider_tls"></a> [tls](#provider_tls) | 3.1.0    |

## Modules

No modules.

## Resources

| Name                                                                                                                                                                | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_acm_certificate.ca](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)                                               | resource    |
| [aws_acm_certificate.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)                                           | resource    |
| [aws_acm_certificate.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)                                           | resource    |
| [aws_cloudwatch_log_group.vpn-logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                               | resource    |
| [aws_cloudwatch_log_stream.vpn-logs-stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream)                      | resource    |
| [aws_ec2_client_vpn_authorization_rule.vpn-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_authorization_rule)   | resource    |
| [aws_ec2_client_vpn_endpoint.vpn-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_endpoint)                       | resource    |
| [aws_ec2_client_vpn_network_association.vpn-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_network_association) | resource    |
| [aws_ec2_client_vpn_route.routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_client_vpn_route)                                 | resource    |
| [aws_s3_bucket.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                             | resource    |
| [aws_s3_bucket_policy.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)                               | resource    |
| [aws_s3_bucket_public_access_block.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block)     | resource    |
| [aws_s3_object.vpn-config-file](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)                                              | resource    |
| [aws_security_group.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                | resource    |
| [aws_ssm_parameter.vpn_ca_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                          | resource    |
| [aws_ssm_parameter.vpn_ca_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                           | resource    |
| [aws_ssm_parameter.vpn_client_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                      | resource    |
| [aws_ssm_parameter.vpn_client_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                       | resource    |
| [aws_ssm_parameter.vpn_server_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                      | resource    |
| [aws_ssm_parameter.vpn_server_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                       | resource    |
| [tls_cert_request.client](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/cert_request)                                                  | resource    |
| [tls_cert_request.server](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/cert_request)                                                  | resource    |
| [tls_locally_signed_cert.client](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/locally_signed_cert)                                    | resource    |
| [tls_locally_signed_cert.server](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/locally_signed_cert)                                    | resource    |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/private_key)                                                        | resource    |
| [tls_private_key.client](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/private_key)                                                    | resource    |
| [tls_private_key.server](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/private_key)                                                    | resource    |
| [tls_self_signed_cert.ca](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/self_signed_cert)                                              | resource    |
| [aws_iam_policy_document.vpn-config-files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                      | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                         | data source |

## Inputs

| Name                                                                                                | Description                                    | Type                | Default | Required |
| --------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ------------------- | ------- | :------: |
| <a name="input_additional_routes"></a> [additional_routes](#input_additional_routes)                | Additional Routes                              | `list(map(string))` | `[]`    |    no    |
| <a name="input_aws-vpn-client-list"></a> [aws-vpn-client-list](#input_aws-vpn-client-list)          | VPN client list                                | `set(string)`       | n/a     |   yes    |
| <a name="input_client_cidr_block"></a> [client_cidr_block](#input_client_cidr_block)                | AWS VPN client cidr block                      | `string`            | n/a     |   yes    |
| <a name="input_logs_retention_in_days"></a> [logs_retention_in_days](#input_logs_retention_in_days) | VPN client list                                | `number`            | n/a     |   yes    |
| <a name="input_organization_name"></a> [organization_name](#input_organization_name)                | Organization name                              | `string`            | n/a     |   yes    |
| <a name="input_project-name"></a> [project-name](#input_project-name)                               | Project name                                   | `string`            | n/a     |   yes    |
| <a name="input_session_timeout_hours"></a> [session_timeout_hours](#input_session_timeout_hours)    | Session timeout hours                          | `number`            | n/a     |   yes    |
| <a name="input_split_tunnel"></a> [split_tunnel](#input_split_tunnel)                               | Split tunnel traffic                           | `bool`              | n/a     |   yes    |
| <a name="input_subnets_id"></a> [subnets_id](#input_subnets_id)                                     | Subnet list for client vpn network association | `list(string)`      | n/a     |   yes    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                 | VPC ID                                         | `string`            | n/a     |   yes    |
| <a name="input_vpn_inactive_period"></a> [vpn_inactive_period](#input_vpn_inactive_period)          | VPN inactive period in seconds                 | `number`            | n/a     |   yes    |

## Outputs

No outputs.

<br/>

![image](https://i.ibb.co/2s7cWzz/coffee.jpg)

### If you find this module useful, please consider helping me with a coffee so I can keep creating more modules like this one :)

## https://www.buymeacoffee.com/PeE5BDn/

### We welcome any ideas, corrections, or feedback you may have. Your input is greatly appreciated and will contribute to further improving our module.

<br/>

## [If you found this Terraform module helpful, we would appreciate hearing from you. Please feel free to reach out to me on LinkedIn to share your feedback.](https://www.linkedin.com/in/nazareno-anselmi/)
