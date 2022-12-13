
resource "oci_devops_repository" "FoggyKitchenDevOpsProjectRepository" {
  provider        = oci.targetregion
  project_id      = oci_devops_project.FoggyKitchenDevOpsProject.id
  name            = var.repository_name
  default_branch  = var.repository_branch
  description     = "FoggyKitchenDevOpsProjectRepository"
  repository_type = "HOSTED"
}

resource "null_resource" "FoggyKitchenCloneRepositoryLocally" {

  depends_on = [oci_devops_project.FoggyKitchenDevOpsProject, oci_devops_repository.FoggyKitchenDevOpsProjectRepository]

  provisioner "local-exec" {
    command = "echo '(1) Cleaning local repo: '; rm -rf ${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name}"
  }

  provisioner "local-exec" {
    command = "echo '(2) Repo to clone: https://devops.scmservice.${var.region}.oci.oraclecloud.com/namespaces/${local.ocir_namespace}/projects/${oci_devops_project.FoggyKitchenDevOpsProject.name}/repositories/${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name}'"
  }

  provisioner "local-exec" {
    command = "echo '(3) Starting git clone command... '; echo 'Username: Before' ${var.ocir_user_name}; echo 'Username: After' ${local.encode_user}; echo 'auth_token' ${local.auth_token}; git clone https://${local.encode_user}:${local.auth_token}@devops.scmservice.${var.region}.oci.oraclecloud.com/namespaces/${local.ocir_namespace}/projects/${oci_devops_project.FoggyKitchenDevOpsProject.name}/repositories/${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name};"
  }

  provisioner "local-exec" {
    command = "echo '(4) Finishing git clone command: '; ls -latr ${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name}"
  }
}

resource "null_resource" "FoggyKitchenCloneRepositoryFromGitHub" {

  provisioner "local-exec" {
    command = "rm -rf ./${var.github_repo_name}"
  }

  provisioner "local-exec" {
    command = "git clone ${var.github_repo} ${var.github_repo_name}; ls -lart ${var.github_repo_name}"
  }
}

resource "null_resource" "FoggyKitchenCopyFiles" {

  depends_on = [null_resource.FoggyKitchenCloneRepositoryLocally]

  provisioner "local-exec" {
    command = "cd ${var.github_repo_name}; rsync -a --exclude='.*' . ../${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name}; cd .."
  }
}

resource "null_resource" "FoggyKitchenPushCode" {

  depends_on = [null_resource.FoggyKitchenCopyFiles]

  provisioner "local-exec" {
    command = "cd ./${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name}; git config --global user.email 'test@example.com'; git config --global user.name '${var.ocir_user_name}';git add .; git commit -m 'added latest files'; git push origin '${var.repository_default_branch}'"
  }
}

