module "stock2023" {
    source = "github.com/magfest/terraform-aws-ubersystem-ecs"
    ecs_cluster             = aws_ecs_cluster.uber.arn
    ecs_task_role           = aws_iam_role.task_role.arn
    subnet_ids              = [
        aws_subnet.primary.id,
        aws_subnet.secondary.id
    ]
    uber_web_securitygroups = [
        aws_security_group.uber_backend.id
    ]
    rabbitmq_securitygroups = [
        aws_security_group.uber_rabbitmq.id
    ]
    redis_securitygroups    = [
        aws_security_group.uber_redis.id
    ]
    vpc_id                  = aws_vpc.uber.id
    hostname                = "stock2023.dev.magevent.net"
    zonename                = var.zonename
    ubersystem_container    = "ghcr.io/magfest/magprime:main"
    loadbalancer_arn        = aws_lb.ubersystem.arn
    loadbalancer_dns_name   = aws_lb.ubersystem.dns_name
    lb_web_listener_arn     = aws_lb_listener.ubersystem_web_https.arn
    lb_priority             = 10
    prefix                  = "stck23"
    event                   = "stock"
    year                    = "2023"
    environment             = "prod"
    db_endpoint             = aws_db_instance.uber.endpoint
    db_hostname             = aws_db_instance.uber.address
    db_username             = aws_db_instance.uber.username
    db_password             = aws_secretsmanager_secret_version.password.secret_string
    rds_instance            = [
        aws_db_instance.uber.endpoint
    ]
    uber_db_name            = "stock2023"
    uber_db_username        = "stock2023"
    efs_id                  = aws_efs_file_system.ubersystem_static.id
    efs_dir                 = "/stock2023"
}

module "west2023" {
    source = "github.com/magfest/terraform-aws-ubersystem-ecs"
    ecs_cluster             = aws_ecs_cluster.uber.arn
    ecs_task_role           = aws_iam_role.task_role.arn
    subnet_ids              = [
        aws_subnet.primary.id,
        aws_subnet.secondary.id
    ]
    uber_web_securitygroups = [
        aws_security_group.uber_backend.id
    ]
    rabbitmq_securitygroups = [
        aws_security_group.uber_rabbitmq.id
    ]
    redis_securitygroups    = [
        aws_security_group.uber_redis.id
    ]
    vpc_id                  = aws_vpc.uber.id
    hostname                = "west2023.dev.magevent.net"
    zonename                = var.zonename
    ubersystem_container    = "ghcr.io/magfest/magprime:main"
    loadbalancer_arn        = aws_lb.ubersystem.arn
    loadbalancer_dns_name   = aws_lb.ubersystem.dns_name
    lb_web_listener_arn     = aws_lb_listener.ubersystem_web_https.arn
    lb_priority             = 11
    prefix                  = "west23"
    event                   = "west"
    year                    = "2023"
    environment             = "prod"
    db_endpoint             = aws_db_instance.uber.endpoint
    db_hostname             = aws_db_instance.uber.address
    db_username             = aws_db_instance.uber.username
    db_password             = aws_secretsmanager_secret_version.password.secret_string
    rds_instance            = [
        aws_db_instance.uber.endpoint
    ]
    uber_db_name            = "west2023"
    uber_db_username        = "west2023"
    efs_id                  = aws_efs_file_system.ubersystem_static.id
    efs_dir                 = "/west2023"
}