resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::585768155983:user/terraform-user"
        username = "terraform-user"
        groups   = ["system:masters"]
      }
    ])
  }
}
