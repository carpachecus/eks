resource "null_resource" "apply_aws_auth" {
  provisioner "local-exec" {
    command = "kubectl apply -f aws-auth.yaml"
    working_dir = "${path.module}"  # Esto apunta a terraform/eks
    environment = {
      KUBECONFIG = "~/.kube/config"
    }
  }

  depends_on = [module.eks]  # Asegura que EKS esté listo antes
}
