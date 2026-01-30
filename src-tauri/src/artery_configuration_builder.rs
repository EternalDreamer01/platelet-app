use std::{
    collections::HashMap,
    fs::{self, create_dir, File},
    io::Write,
    process::{Command, ExitStatus},
};

use strfmt::strfmt;
use std::path::PathBuf;

use crate::{config_template_path::ConfigTemplatePath, misc::folder_exist};

// TODO: Add proper thiserror enum and stop returning string as error

#[derive(Default)]
pub struct ArteryConfigurationBuilder {
    artery_path: String,
    project_name: String,
    map_path: String,
    trips_number: u64,
    config_template_paths: ConfigTemplatePath,
}

impl ArteryConfigurationBuilder {
    pub fn new(artery_path: String) -> ArteryConfigurationBuilder {
        let tauri_home: std::string::String = std::env::var("PLATELET_TAURI_HOME")
			.expect("tauri_home is not set");
		
        ArteryConfigurationBuilder {
			map_path: format!("{}/assets/map.osm", tauri_home),
            artery_path,
            trips_number: 10,
            ..Default::default()
        }
    }

    pub fn project_name(mut self, project_name: String) -> Self {
        self.project_name = project_name;
        self
    }

    pub fn map_path(mut self, map_path: String) -> Self {
        self.map_path = map_path;
        self
    }

    pub fn config_template_paths(mut self, config_template_paths: ConfigTemplatePath) -> Self {
        self.config_template_paths = config_template_paths;
        self
    }

	fn build_net(osmfile_path: &str, netfile_path: &str) -> Result<ExitStatus, String> {
		// println!("netconvert exists: {}", Path::new("/usr/bin/netconvert").exists());

		let output = Command::new("/usr/bin/netconvert") // absolute path
			.args([
				"--osm-files",
				osmfile_path,
				"--output-file",
				netfile_path,
				"--geometry.remove",
				"--roundabouts.guess",
				"--ramps.guess",
				"--junctions.join",
				"--tls.guess-signals",
				"--tls.discard-simple",
				"--tls.join",
			])
			.output()
			.map_err(|e| format!("Can't spawn net building command: {}", e))?;

		if !output.status.success() {
			return Err(format!(
				"netconvert failed:\n{}",
				String::from_utf8_lossy(&output.stderr)
			));
		}

		Ok(output.status)
	}


    fn build_trips(
        netfile_path: &str,
        tripsfile_path: &str,
        trips_number: u64,
    ) -> Result<ExitStatus, String> {
		let sumo_home = std::env::var("SUMO_HOME")
			.map_err(|_| "Environment variable SUMO_HOME is not set")?;
		let mut random_trips = PathBuf::from(&sumo_home);
		random_trips.push("tools");
		random_trips.push("randomTrips.py");
	
        Ok(Command::new("python3")
			.arg(random_trips)
			.arg("-n")
			.arg(netfile_path)
			.arg("-p")
			.arg(trips_number.to_string())
			.arg("-o")
			.arg(tripsfile_path)
            .spawn()
            .map_err(|e| format!("Can't spawn trips building command: {}", e))?
            .wait()
            .map_err(|e| format!("Can't wait for trips building command to end: {}", e))?)
    }

    fn build_routes(
        netfile_path: &str,
        tripsfile_path: &str,
        routefile_path: &str,
    ) -> Result<ExitStatus, String> {
        Ok(Command::new("duarouter")
            .args([
                "-n",
                netfile_path,
                "--route-files",
                tripsfile_path,
                "-o",
                routefile_path,
                "--ignore-errors",
            ])
            .spawn()
            .map_err(|e| format!("Can't spawn trips building command: {}", e))?
            .wait()
            .map_err(|e| format!("Can't wait for trips building command to end: {}", e))?)
    }

    fn build_sumo_config_files(&self, scenario_path: String) -> Result<(), String> {
        let netfile_path = format!("{}/{}.net.xml", scenario_path, self.project_name);
        let tripsfile_path = format!("{}/{}.trips.xml", scenario_path, self.project_name);
        let routefile_path = format!("{}/{}.rou.xml", scenario_path, self.project_name);

        /* TODO: Check programs status code */
        Self::build_net(&self.map_path, &netfile_path)?;
        Self::build_trips(&netfile_path, &tripsfile_path, self.trips_number)?;
        Self::build_routes(&netfile_path, &tripsfile_path, &routefile_path)?;

        let sumocfg_path = format!("{}/{}.sumocfg", scenario_path, self.project_name);

        let config_template = fs::read_to_string(&self.config_template_paths.sumocfg_path)
            .map_err(|e| format!("Can't read base config file {}: {}", &self.config_template_paths.sumocfg_path, e))?;

        let replace_vars = HashMap::from([
            ("netfile".to_string(), netfile_path.as_str()),
            ("routefile".to_string(), &routefile_path.as_str()),
        ]);

        let custom_config = strfmt(&config_template, &replace_vars)
            .map_err(|e| format!("Can't update config template : {}", e))?;

        let mut f = File::create(sumocfg_path)
            .map_err(|e| format!("Can't create sumocfg file: {}", e.to_string()))?;

        f.write_all(custom_config.as_bytes())
            .map_err(|e| e.to_string())?;
        println!("{}", custom_config);

        Ok(())
    }

    fn build_omnet_config_file(&self, scenario_path: String) -> Result<(), String> {
        let sumocfg_path = format!("{}/{}.sumocfg", scenario_path, self.project_name);

		let tauri_home: std::string::String = std::env::var("PLATELET_TAURI_HOME")
			.expect("tauri_home is not set");
		
        fs::copy(
            &format!("{}/assets/vehicles.xml", tauri_home),
            scenario_path.to_owned() + "/vehicles.xml",
        )
        .map_err(|e| {
            format!(
                "Can't copy vehicle.xml from ./assets/vehicles.xml to {}: {}",
                scenario_path,
                e.to_string()
            )
        })?;
        fs::copy(
            &self.config_template_paths.services_path,
            scenario_path.to_owned() + "/services.xml",
        )
        .map_err(|e| {
            format!(
                "Can't copy services.xml from {} to {}: {}",
                &self.config_template_paths.services_path,
                scenario_path,
                e.to_string()
            )
        })?;

        let omnetpp_config = fs::read_to_string(&self.config_template_paths.omnetpp_path)
            .map_err(|e| format!("Can't read omnet base file: {}", e.to_string()))?;

        let replace_vars = HashMap::from([("sumocfg".to_string(), sumocfg_path.as_str())]);

        let omnetpp_config = strfmt(&omnetpp_config, &replace_vars).map_err(|e| {
            format!(
                "Can't replace variables from template {}: {}",
                &self.config_template_paths.omnetpp_path,
                e.to_string()
            )
        })?;
        let omnetpp_config_path = scenario_path + "/omnetpp.ini";
        let mut omnetpp_config_file =
            File::create(omnetpp_config_path.to_owned()).map_err(|e| {
                format!(
                    "Can't create file {}: {}",
                    omnetpp_config_path,
                    e.to_string()
                )
            })?;

        omnetpp_config_file
            .write_all(omnetpp_config.as_bytes())
            .map_err(|e| format!("Can't write {}: {}", omnetpp_config_path, e.to_string()))?;

        Ok(())
    }

	fn update_cmake_file(&self, scenario_path: String) -> Result<(), String> {
        println!("{}", scenario_path);
		// Paths
		let mut cmake_scenario_path = PathBuf::from(scenario_path.clone());
		cmake_scenario_path.push("CMakeLists.txt");

		// let mut cmake_root_path = PathBuf::from(&self.artery_path);
		// cmake_root_path.push("scenarios");
		// cmake_root_path.push("CMakeLists.txt");

		// Write per-project CMakeLists.txt
		let mut cmake_scenario_file = File::create(&cmake_scenario_path)
			.map_err(|e| format!("Can't create {}: {}", cmake_scenario_path.display(), e))?;

		cmake_scenario_file
			.write_all(format!(r#"
cmake_minimum_required(VERSION 3.20)
project({0})

set(ARTERY_HOME "$ENV{{ARTERY_HOME}}")
set(CMAKE_MODULE_PATH "${{ARTERY_HOME}}/cmake")

add_subdirectory(${{ARTERY_HOME}} artery)

# set(PROJECT_NAME ${{PROJECT_NAME}})
set(ASSETS "$ENV{{tauri_home}}/assets")
add_opp_run(
	${{PROJECT_NAME}}
	CONFIG omnetpp.ini
)
"#, self.project_name).as_bytes())
			.map_err(|e| format!("Can't write to {}: {}", cmake_scenario_path.display(), e))?;

		// Update root CMakeLists.txt
		// let mut cmake_root_file = OpenOptions::new()
		// 	.read(true)
		// 	.append(true)
		// 	// .create(true)
		// 	.open(&cmake_scenario_path)
		// 	.map_err(|e| format!("Can't open {}: {}", cmake_scenario_path.display(), e))?;

		let mut omnetpp_scenario_path = PathBuf::from(scenario_path);
		omnetpp_scenario_path.push("omnetpp.ini");
		let omnetpp_content = std::fs::read_to_string(&omnetpp_scenario_path)
			.map_err(|e| format!("Can't read {}: {}", omnetpp_scenario_path.display(), e))?;
		let omnetpp_content = omnetpp_content.replace("${PROJECT_NAME}", &self.project_name);
		fs::write(&omnetpp_scenario_path, omnetpp_content)
				.map_err(|e| format!("Can't write to {}: {}", omnetpp_scenario_path.display(), e))?;
		Ok(())
	}


    pub fn build(self) -> Result<(), String> {
        let scenario_path = format!("{}/scenarios/{}", self.artery_path, self.project_name);

        if !folder_exist(&scenario_path) {
            create_dir(scenario_path.to_owned())
                .map_err(|e| format!("Can't create build directory at {}: {}", scenario_path, e))?;
        }

        self.build_sumo_config_files(scenario_path.to_owned())?;
        self.build_omnet_config_file(scenario_path.to_owned())?;
        self.update_cmake_file(scenario_path)?;
        Ok(())
    }
}
