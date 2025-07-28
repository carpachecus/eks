apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::585768155983:user/terraform-user
      username: terraform-user
      groups:
        - system:masters

resource "null_resource" "apply_aws_auth" {
  provisioner "local-exec" {
    command = "kubectl apply -f aws_auth.yaml"
    environment = {
      KUBECONFIG = "~/.kube/config"
    }
  }

  depends_on = [module.eks]
}
