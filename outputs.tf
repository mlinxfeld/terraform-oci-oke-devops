
output "cluster_instruction" {
value = <<EOT
1.  Open OCI Cloud Shell.

2.  Execute below command to setup OKE cluster access:

$ oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.FoggyKitchenOKECluster.id}

3.  Get PODs names:

$ kubectl get pods 

4.  Get services

$ kubectl get services

EOT
}

output "oracle_linux_images" {
  value = local.oracle_linux_images
}

#output "oracle_linux_image_names" {
#  value = local.oracle_linux_image_names
#}
