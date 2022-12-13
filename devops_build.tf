resource "oci_devops_build_pipeline" "FoggyKitchenDevOpsProjectBuildPipeline" {
  provider     = oci.targetregion
  project_id   = oci_devops_project.FoggyKitchenDevOpsProject.id
  display_name = "FoggyKitchenDevOpsProjectBuildPipeline"
  description  = "FoggyKitchen DevOps Project Build Pipeline"
  
  build_pipeline_parameters {
        items {
            name = "USER_AUTH_TOKEN"
            default_value = var.ocir_user_password
            description = "User auth token to push helm packages."
        }
        items {
            name = "HELM_REPO_USER"
            default_value = var.ocir_user_name
            description = "User to push helm packages."
        }
        items {
            name = "HELM_REPO_URL"
            default_value = "oci://${local.ocir_docker_repository}/${local.ocir_namespace}/${var.helm_repo_name}"
            description = "Helm repo URL to push helm packages."
        }
        items {
            name = "HELM_REPO"
            default_value = "${local.ocir_docker_repository}"
            description = "Helm repo name"
        }
    }
}

resource "oci_devops_build_pipeline_stage" "FoggyKitchenDevOpsProjectBuildPipelineStage" {
  provider                  = oci.targetregion
  build_pipeline_id         = oci_devops_build_pipeline.FoggyKitchenDevOpsProjectBuildPipeline.id
  build_pipeline_stage_type = "BUILD"
  display_name              = "FoggyKitchenDevOpsProjectBuildPipelineStage"
  description               = "FoggyKitchen DevOps Project Build Pipeline Stage"

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.FoggyKitchenDevOpsProjectBuildPipeline.id
    }
  }

  build_source_collection {
    items {
      connection_type = "DEVOPS_CODE_REPOSITORY"
      branch          = var.build_source_collection_branch
      name            = var.build_source_collection_name
      repository_id   = oci_devops_repository.FoggyKitchenDevOpsProjectRepository.id
      repository_url  = "https://devops.scmservice.${var.region}.oci.oraclecloud.com/namespaces/${local.ocir_namespace}/projects/${oci_devops_project.FoggyKitchenDevOpsProject.name}/repositories/${oci_devops_repository.FoggyKitchenDevOpsProjectRepository.name}"
    }
  }

  build_spec_file                    = "build_spec.yaml"
  image                              = "OL7_X86_64_STANDARD_10"
  stage_execution_timeout_in_seconds = 36000

  wait_criteria {
    wait_duration = "waitDuration"
    wait_type     = "ABSOLUTE_WAIT"
  }
}

resource "oci_devops_build_pipeline_stage" "FoggyKitchenDevOpsProjectDeliverArtifactStage" {
  provider   = oci.targetregion
  depends_on = [oci_devops_build_pipeline_stage.FoggyKitchenDevOpsProjectBuildPipelineStage]
  
  build_pipeline_id         = oci_devops_build_pipeline.FoggyKitchenDevOpsProjectBuildPipeline.id
  build_pipeline_stage_type = "DELIVER_ARTIFACT"
  display_name              = "FoggyKitchenDevOpsProjectDeliverArtifactStage"
  description               = "FoggyKitchen DevOps Project Deliver Artifact Stage"

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.FoggyKitchenDevOpsProjectBuildPipelineStage.id
    }
  }
  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.FoggyKitchenDevOpsProjectDeployArtifact.id
      artifact_name = "APPLICATION_DOCKER_IMAGE"
    }
  }
}

resource "oci_devops_deploy_artifact" "FoggyKitchenDevOpsProjectDeployArtifact" {
  provider                   = oci.targetregion
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "DOCKER_IMAGE"
  project_id                 = oci_devops_project.FoggyKitchenDevOpsProject.id
  display_name               = oci_artifacts_container_repository.FoggyKitchenDevOpsProjectContainerRepository.display_name

  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri                   = "${local.ocir_docker_repository}/${local.ocir_namespace}/${oci_artifacts_container_repository.FoggyKitchenDevOpsProjectContainerRepository.display_name}:0.1.0-$${BUILDRUN_HASH}"
    image_digest                = " "
    repository_id               = oci_devops_repository.FoggyKitchenDevOpsProjectRepository.id
  }
}


resource "oci_devops_build_pipeline_stage" "FoggyKitchenDevOpsProjectDeployStage" {
  provider   = oci.targetregion
  depends_on = [oci_devops_build_pipeline_stage.FoggyKitchenDevOpsProjectDeliverArtifactStage]

  build_pipeline_id         = oci_devops_build_pipeline.FoggyKitchenDevOpsProjectBuildPipeline.id
  build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"
  display_name              = "FoggyKitchenDevOpsProjectDeployStage"

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.FoggyKitchenDevOpsProjectDeliverArtifactStage.id
    }
  }

  deploy_pipeline_id             = oci_devops_deploy_pipeline.FoggyKitchenDevOpsProjectDeployPipeline.id
  is_pass_all_parameters_enabled = true 
}

resource "oci_devops_build_run" "FoggyKitchenDevOpsProjectBuildPipelineRun" {
    provider          = oci.targetregion
    depends_on        = [oci_containerengine_cluster.FoggyKitchenOKECluster]
    count             = var.execute_build_pipeline ? 1 : 0
    build_pipeline_id = oci_devops_build_pipeline.FoggyKitchenDevOpsProjectBuildPipeline.id
    display_name      = "FoggyKitchenDevOpsProjectBuildPipelineRun"

    build_run_arguments {
        items {
            name = "USER_AUTH_TOKEN"
            value = var.ocir_user_password
        }
        
        items {
            name = "HELM_REPO_USER"
            value = var.ocir_user_name
        }

        items {
            name = "HELM_REPO_URL"
            value = "oci://${local.ocir_docker_repository}/${local.ocir_namespace}/${var.helm_repo_name}"
        }

        items {
            name = "HELM_REPO"
            value = "${local.ocir_docker_repository}"
        }
    }
}
