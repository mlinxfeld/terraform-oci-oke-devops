
resource "oci_devops_deploy_pipeline" "FoggyKitchenDevOpsProjectDeployPipeline" {
  provider     = oci.targetregion
  project_id   = oci_devops_project.FoggyKitchenDevOpsProject.id
  display_name = "FoggyKitchenDevOpsProjectDeployPipeline"
  description  = "FoggyKitchen DevOps Project Deploy Pipeline"

  deploy_pipeline_parameters {
    items {
      name          = "BUILDRUN_HASH"
      default_value = ""
      description   = ""
    }
  }
}

resource "oci_devops_deploy_stage" "FoggyKitchenDevOpsProjectDeployHelmStage" {
  provider           = oci.targetregion
  deploy_pipeline_id = oci_devops_deploy_pipeline.FoggyKitchenDevOpsProjectDeployPipeline.id
  
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.FoggyKitchenDevOpsProjectDeployPipeline.id
    }
  }
  
  display_name                      = "FoggyKitchenDevOpsProjectDeployHelmStage"
  description                       = "FoggyKitchen DevOps Project Deploy Helm Stage"
  deploy_stage_type                 = "OKE_HELM_CHART_DEPLOYMENT"
  release_name                      = var.release_name
  values_artifact_ids               = [oci_devops_deploy_artifact.FoggyKitchenDevOpsDeployValuesYamlArtifact.id]
  helm_chart_deploy_artifact_id     = oci_devops_deploy_artifact.FoggyKitchenDevOpsProjectDeployHelmArtifact.id
  oke_cluster_deploy_environment_id = oci_devops_deploy_environment.FoggyKitchenDevOpsOKEEnvironment.id
}

resource "oci_devops_deploy_artifact" "FoggyKitchenDevOpsDeployValuesYamlArtifact" {
  provider                   = oci.targetregion
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  project_id                 = oci_devops_project.FoggyKitchenDevOpsProject.id
  display_name               = "values.yaml"

  deploy_artifact_source {
    deploy_artifact_source_type = "INLINE"
    base64encoded_content       = replace(file("${path.module}/manifest/values.yaml"), "<NODE_SERVICE_REPO>", "${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.FoggyKitchenDevOpsProjectContainerRepository.display_name}")
  }
}



