use std::{
    fs::{create_dir_all, File},
    io::{Read, Write},
};

use serde::{Deserialize, Serialize};
use thiserror::Error;

use crate::{
    artery_configuration_builder::ArteryConfigurationBuilder, config_template_path::ConfigTemplatePath, security_configuration::SecurityConfiguration
};
#[derive(Debug, Error)]
pub enum ProjectError {
    #[error("Can't save project settings: {0}")]
    Save(String),
    #[error("Can't load project settings: {0}")]
    Load(String),
    #[error("Can't build artery configuration file: {0}")]
    BuildArteryConfiguration(String),
    #[error("Can't build security configuration: {0}")]
    BuildSecurityConfiguration(String),
}

#[derive(Default, Debug, Serialize, Deserialize, Clone)]
pub struct Project {
    pub project_name: String,
    pub artery_path: String,
    pub map_path: Option<String>,
    gen_time: f64,
    pub vehicle_number: u64,
    pub security_configuration: SecurityConfiguration,
    pub config_template_paths: ConfigTemplatePath,
}

impl Project {
    pub fn new(project_name: String, artery_path: String) -> Project {
        Project {
            project_name,
            artery_path,
            map_path: None,
            gen_time: 0.0,
            vehicle_number: 0,
            security_configuration: SecurityConfiguration::default(),
            config_template_paths: ConfigTemplatePath::default(),
        }
    }

    pub fn merge(&mut self, other: Project) {
        self.project_name = other.project_name;
        self.artery_path = other.artery_path;
        self.map_path = other.map_path;
        self.gen_time = other.gen_time;
        self.vehicle_number = other.vehicle_number;
        self.security_configuration = other.security_configuration;
        self.config_template_paths = other.config_template_paths;
    }

	pub fn save_project_settings(&self) -> Result<(), ProjectError> {
		let project_path = format!(
			"{}/scenarios/{}",
			self.artery_path, self.project_name
		);

		// Create all directories if missing
		create_dir_all(&project_path)
    		.map_err(|e: std::io::Error| ProjectError::Save(e.to_string()))?;

		let file_path = format!("{}/{}.platelet", project_path, self.project_name);

		let mut f = File::create(&file_path)
			.map_err(|e| ProjectError::Save(e.to_string()))?;

		let json = serde_json::to_string(self)
			.map_err(|e| ProjectError::Save(e.to_string()))?;

		f.write_all(json.as_bytes())
			.map_err(|e| ProjectError::Save(e.to_string()))?;

		Ok(())
	}

    pub fn load_project_settings(project_settings_path: String) -> Result<Project, ProjectError> {
        let mut f =
            File::open(project_settings_path).map_err(|e| ProjectError::Load(e.to_string()))?;

        let mut settings = String::new();
        f.read_to_string(&mut settings)
            .map_err(|e| ProjectError::Load(e.to_string()))?;

        match serde_json::from_str(&settings) {
            Ok(project) => Ok(project),
            Err(e) => Err(ProjectError::Load(e.to_string())),
        }
    }

	pub fn build_project_artery_configuration(&self) -> Result<(), ProjectError> {
		let map_path = self.map_path.as_ref().ok_or_else(|| {
			ProjectError::BuildArteryConfiguration("Map path is missing".to_string())
		})?;

		ArteryConfigurationBuilder::new(self.artery_path.clone())
			.project_name(self.project_name.clone())
			.map_path(map_path.clone())
			.config_template_paths(self.config_template_paths.clone())
			.build()
			.map_err(|e| ProjectError::BuildArteryConfiguration(e.to_string()))?;

		self.security_configuration
			.generate_certificates(format!(
				"{}/scenarios/{}",
				self.artery_path, self.project_name
			))
			.map_err(|e| ProjectError::BuildSecurityConfiguration(e.to_string()))?;

		Ok(())
	}

}
